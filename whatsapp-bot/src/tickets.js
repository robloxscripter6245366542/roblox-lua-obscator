import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { config } from "../config.js";
import { allContacts, toChatId } from "./contacts.js";
import * as outbox from "./outbox.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const logDir = path.resolve(__dirname, "..", "logs");
const ticketLog = path.join(logDir, "tickets.jsonl");

/**
 * Escalation tickets.
 *
 * When the agent can't answer a customer, it opens a ticket, works out WHICH
 * colleague handles that topic, and messages them on WhatsApp with the
 * customer's question and context. That colleague can then answer through the
 * bot, and the reply is relayed back to the customer in their own chat.
 */

const open = new Map(); // ticketId -> ticket
let counter = 0;

function nextId() {
  counter++;
  return `T-${String(Date.now()).slice(-6)}${String(counter).padStart(2, "0")}`;
}

function persist(ticket) {
  try {
    fs.mkdirSync(logDir, { recursive: true });
    fs.appendFileSync(ticketLog, JSON.stringify(ticket) + "\n");
  } catch (err) {
    console.error("[tickets] Could not write ticket log:", err.message);
  }
}

// ------------------------------------------------------------------ routing

/**
 * Find who handles a department. Contacts opt in via a "departments" array in
 * contacts.json, e.g. { "name": "Mary", "departments": ["billing"] }.
 *
 * Falls back progressively so an escalation is never silently lost: exact
 * department -> general -> the configured escalation chat.
 */
export function routeToOwner(department) {
  const wanted = String(department || "").toLowerCase().trim();
  const contacts = allContacts();

  const byDept = contacts.filter((c) =>
    (c.departments || []).some((d) => String(d).toLowerCase() === wanted)
  );
  if (byDept.length) {
    // Round-robin within the department so one person isn't buried.
    const pick = byDept[counter % byDept.length];
    return { chatId: pick.chatId || toChatId(pick.number), label: pick.name, matched: wanted };
  }

  const general = contacts.filter((c) =>
    (c.departments || []).some((d) => String(d).toLowerCase() === "general")
  );
  if (general.length) {
    const pick = general[counter % general.length];
    return { chatId: pick.chatId || toChatId(pick.number), label: pick.name, matched: "general" };
  }

  if (config.escalationChatId) {
    const chatId = toChatId(config.escalationChatId);
    if (chatId) return { chatId, label: "escalation contact", matched: "fallback" };
  }

  return { error: "No team member is configured to receive escalations." };
}

export function knownDepartments() {
  const set = new Set();
  for (const c of allContacts()) {
    for (const d of c.departments || []) set.add(String(d).toLowerCase());
  }
  return [...set].sort();
}

// --------------------------------------------------- notification throttling

/**
 * At volume, a single confusing product change can make hundreds of customers
 * ask the same question at once. Notifying a colleague hundreds of times is
 * worse than useless, so past a per-hour threshold we stop paging and collect
 * the rest into a digest.
 */
const notifyTimes = new Map(); // ownerChatId -> timestamps[]
const suppressed = new Map(); // ownerChatId -> ticket[]

function canNotify(ownerChatId) {
  const now = Date.now();
  const cutoff = now - 60 * 60 * 1000;
  const times = (notifyTimes.get(ownerChatId) || []).filter((t) => t > cutoff);
  notifyTimes.set(ownerChatId, times);
  return times.length < config.maxEscalationsPerHour;
}

function recordNotify(ownerChatId) {
  const times = notifyTimes.get(ownerChatId) || [];
  times.push(Date.now());
  notifyTimes.set(ownerChatId, times);
}

/**
 * Send the digest of anything suppressed while over the per-hour threshold.
 * Called on a timer from index.js.
 */
export async function flushDigests() {
  for (const [ownerChatId, list] of suppressed) {
    if (!list.length) continue;
    suppressed.set(ownerChatId, []);

    const lines = list
      .slice(0, 20)
      .map((t) => `• ${t.id} — ${t.summary} (${t.customerLabel})`)
      .join("\n");
    const extra = list.length > 20 ? `\n…and ${list.length - 20} more.` : "";

    try {
      await outbox.sendInternal(
        ownerChatId,
        `📋 *${list.length} escalations waiting*\n\n${lines}${extra}\n\n` +
          `Reply "reply to <ticket> <message>" to answer any of them.`,
        { via: "digest" }
      );
    } catch (err) {
      console.error("[tickets] Digest send failed:", err.message);
    }
  }
}

// ------------------------------------------------------------ ticket actions

export async function createTicket({
  chatId,
  customerLabel,
  department,
  summary,
  question,
  urgency = "normal",
}) {
  const owner = routeToOwner(department);
  if (owner.error) return { error: owner.error };

  const ticket = {
    id: nextId(),
    status: "open",
    openedAt: new Date().toISOString(),
    customerChatId: chatId,
    customerLabel,
    department: owner.matched,
    ownerChatId: owner.chatId,
    ownerLabel: owner.label,
    summary,
    question,
    urgency,
  };

  open.set(ticket.id, ticket);
  persist(ticket);

  const urgencyTag = urgency === "high" ? "🔴 URGENT" : "🟡";
  const body =
    `${urgencyTag} *Customer needs help* — ${ticket.id}\n\n` +
    `*From:* ${customerLabel}\n` +
    `*Topic:* ${ticket.department}\n` +
    `*Needs:* ${summary}\n\n` +
    `*They asked:*\n"${String(question).slice(0, 700)}"\n\n` +
    `Reply here with:  reply to ${ticket.id} <your answer>\n` +
    `and I'll send it straight to them.`;

  if (!canNotify(owner.chatId)) {
    const pendingList = suppressed.get(owner.chatId) || [];
    pendingList.push(ticket);
    suppressed.set(owner.chatId, pendingList);
    return {
      ticketId: ticket.id,
      owner: owner.label,
      notified: false,
      note: "Ticket logged; the owner is at their alert limit and will get a digest shortly.",
    };
  }

  try {
    await outbox.sendInternal(owner.chatId, body, { via: "escalation", ticket: ticket.id });
    recordNotify(owner.chatId);
    return { ticketId: ticket.id, owner: owner.label, notified: true };
  } catch (err) {
    // The ticket still exists and is logged even if the notification failed.
    console.error("[tickets] Could not notify owner:", err.message);
    return {
      ticketId: ticket.id,
      owner: owner.label,
      notified: false,
      note: `Ticket logged but the notification failed: ${err.message}`,
    };
  }
}

export function getTicket(id) {
  return open.get(String(id || "").toUpperCase().trim()) || null;
}

export function openTicketsFor(ownerChatId) {
  return [...open.values()].filter(
    (t) => t.status === "open" && (!ownerChatId || t.ownerChatId === ownerChatId)
  );
}

export function allOpenTickets() {
  return [...open.values()].filter((t) => t.status === "open");
}

export function closeTicket(id, note = "") {
  const ticket = getTicket(id);
  if (!ticket) return { error: `No open ticket ${id}.` };
  ticket.status = "closed";
  ticket.closedAt = new Date().toISOString();
  ticket.closeNote = note;
  persist(ticket);
  open.delete(ticket.id);
  return { ok: true, ticketId: ticket.id };
}

/**
 * Relay a team member's answer back to the customer who opened the ticket.
 */
export async function replyToTicket(id, message, fromLabel) {
  const ticket = getTicket(id);
  if (!ticket) {
    return { error: `No open ticket ${id}. Use list_open_tickets to see current ones.` };
  }

  const body = config.signRelayedReplies
    ? `${message}\n\n— ${fromLabel}, ${config.companyName}`
    : message;

  await outbox.sendReply(ticket.customerChatId, body, {
    via: "ticket_reply",
    ticket: ticket.id,
  });

  ticket.status = "closed";
  ticket.closedAt = new Date().toISOString();
  ticket.answeredBy = fromLabel;
  ticket.answer = message;
  persist(ticket);
  open.delete(ticket.id);

  return { ok: true, ticketId: ticket.id, customer: ticket.customerLabel };
}

export function stats() {
  return { open: open.size, opened: counter };
}
