import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pkg from "whatsapp-web.js";
const { MessageMedia } = pkg;

import { config, catalog } from "../config.js";
import { findContacts, allContacts, resolveRecipient } from "./contacts.js";
import { searchKnowledge, allTopics } from "./knowledge.js";
import * as tickets from "./tickets.js";
import * as outbox from "./outbox.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const mediaRoot = path.resolve(__dirname, "..", config.mediaDir);
const logDir = path.resolve(__dirname, "..", "logs");

/**
 * The agent's tool belt.
 *
 * Tools are scoped by role: "team" members can send to anyone, "customer"
 * chats can only ever cause a reply in their own chat or open a ticket. That
 * scoping is the security boundary — a customer message is data, never a
 * command to message someone else, no matter what it says.
 */

const IMAGE_EXT = /\.(jpe?g|png|webp|gif)$/i;

function listPhotoFiles() {
  if (!fs.existsSync(mediaRoot)) return [];
  return fs.readdirSync(mediaRoot).filter((f) => IMAGE_EXT.test(f));
}

function appendLog(file, entry) {
  try {
    fs.mkdirSync(logDir, { recursive: true });
    fs.appendFileSync(
      path.join(logDir, file),
      JSON.stringify({ at: new Date().toISOString(), ...entry }) + "\n"
    );
  } catch (err) {
    console.error(`[log] Could not write ${file}:`, err.message);
  }
}

function resolvePhoto(ref, ctx) {
  const wanted = String(ref || "").trim();
  if (!wanted) return { error: "No photo specified." };

  if (wanted === "last_received") {
    if (!ctx.lastMedia) return { error: "No photo has been sent to this chat recently." };
    return { media: ctx.lastMedia, label: "the photo you sent" };
  }

  const item = catalog.find((c) => c.id === wanted);
  const filename = item ? item.photo : wanted;

  // Only plain filenames inside media/ — blocks ../../etc/passwd.
  const safe = path.basename(filename);
  const filePath = path.join(mediaRoot, safe);
  if (!fs.existsSync(filePath)) {
    const available = listPhotoFiles();
    return {
      error:
        `No photo named "${wanted}". Available: ` +
        (available.length ? available.join(", ") : "(media folder is empty)"),
    };
  }
  return { media: MessageMedia.fromFilePath(filePath), label: safe };
}

function resolveTargets(recipients, ctx) {
  const list = Array.isArray(recipients) ? recipients : [recipients];
  if (list.length > config.maxRecipientsPerSend) {
    return {
      error: `Too many recipients (${list.length}). The limit is ${config.maxRecipientsPerSend} per send.`,
    };
  }
  const targets = [];
  const errors = [];
  for (const r of list) {
    const resolved = resolveRecipient(r);
    if (resolved.error) errors.push(resolved.error);
    else targets.push(resolved);
  }
  if (errors.length) return { error: errors.join(" ") };
  if (!targets.length) return { error: "No valid recipients." };
  return { targets };
}

// ------------------------------------------------------------- tool schemas

const fn = (name, description, properties = {}, required = []) => ({
  type: "function",
  function: { name, description, parameters: { type: "object", properties, required } },
});

const str = (description) => ({ type: "string", description });
const strArray = (description) => ({ type: "array", items: { type: "string" }, description });

const schemas = {
  // ---- knowledge & self-service (available to everyone) ----
  search_knowledge_base: fn(
    "search_knowledge_base",
    "Search the company knowledge base for the answer to a customer question. " +
      "ALWAYS try this before saying you don't know. Returns matching Q&A entries " +
      "with a confidence level.",
    { query: str("The customer's question, or the key topic words.") },
    ["query"]
  ),

  list_topics: fn(
    "list_topics",
    "List the topics the knowledge base covers. Useful when a customer asks a " +
      "broad 'what can you help with?' question.",
    {}
  ),

  get_business_info: fn(
    "get_business_info",
    "Get basic company facts: opening hours, company name, how to reach a human.",
    {}
  ),

  list_photos: fn(
    "list_photos",
    "List the photos available to send (catalog images and other media files).",
    {}
  ),

  reply_with_photo: fn(
    "reply_with_photo",
    "Send a photo to the person you are currently chatting with — catalog, " +
      "price list, location map, etc.",
    { photo: str("A catalog id or filename."), caption: str("Optional caption.") },
    ["photo"]
  ),

  // ---- customer service actions ----
  escalate_to_team: fn(
    "escalate_to_team",
    "Hand this customer's request to the right colleague when you cannot answer " +
      "it yourself. This messages that person on WhatsApp with the customer's " +
      "question and opens a ticket. USE THIS instead of guessing or apologising " +
      "vaguely — it is the correct action whenever the knowledge base does not " +
      "cover what they asked.",
    {
      department: str(
        "Which team should handle it, e.g. billing, technical, sales, accounts, general."
      ),
      summary: str("One short line describing what the customer needs."),
      urgency: {
        type: "string",
        enum: ["normal", "high"],
        description: "Use 'high' only for outages, lost money, or an angry customer.",
      },
    },
    ["department", "summary"]
  ),

  save_customer_details: fn(
    "save_customer_details",
    "Record details the customer gives you (name, email, company, what they " +
      "want) so the team has them. Use when a customer introduces themselves or " +
      "asks to be contacted.",
    {
      name: str("Customer's name."),
      email: str("Email address."),
      company: str("Company name."),
      note: str("What they are interested in or need."),
    },
    []
  ),

  request_callback: fn(
    "request_callback",
    "Log that the customer wants a callback at a particular time, and notify " +
      "the team.",
    {
      preferred_time: str("When they'd like to be contacted, in their words."),
      topic: str("What the callback is about."),
    },
    ["preferred_time"]
  ),

  check_reference: fn(
    "check_reference",
    "Look up a transaction, order, or account reference the customer quotes. " +
      "Returns the status if the lookup service is configured.",
    { reference: str("The reference or ID the customer gave.") },
    ["reference"]
  ),

  // ---- team-only ----
  find_contact: fn(
    "find_contact",
    "Look up people in the company contact directory by name or alias. Use " +
      "before sending when a name might be ambiguous.",
    { name: str("Name or partial name.") },
    ["name"]
  ),

  list_contacts: fn("list_contacts", "List everyone in the company contact directory.", {}),

  send_text: fn(
    "send_text",
    "Send a WhatsApp text message to one or more people.",
    { to: strArray("Contact names or phone numbers."), message: str("The message body.") },
    ["to", "message"]
  ),

  send_photo: fn(
    "send_photo",
    "Send a photo to one or more people. Use 'last_received' as the photo when " +
      "the user says 'send this to X' just after sending an image.",
    {
      to: strArray("Contact names or phone numbers."),
      photo: str("Catalog id, filename, or 'last_received'."),
      caption: str("Optional caption."),
    },
    ["to", "photo"]
  ),

  send_to_app: fn(
    "send_to_app",
    "Push a message and optional photo to a connected external system such as " +
      "Slack or an internal service.",
    {
      target: str("Name of the configured app target."),
      message: str("The message to post."),
      photo: str("Optional photo: catalog id, filename, or 'last_received'."),
    },
    ["target", "message"]
  ),

  list_open_tickets: fn(
    "list_open_tickets",
    "List customer escalations currently waiting for an answer.",
    { mine_only: { type: "boolean", description: "Only tickets assigned to this person." } }
  ),

  reply_to_customer: fn(
    "reply_to_customer",
    "Answer an escalated customer. The message is relayed straight into the " +
      "customer's own WhatsApp chat and the ticket is closed.",
    { ticket: str("The ticket id, e.g. T-12345601."), message: str("The answer to send.") },
    ["ticket", "message"]
  ),

  close_ticket: fn(
    "close_ticket",
    "Close a ticket without replying (duplicate, already handled elsewhere).",
    { ticket: str("The ticket id."), note: str("Why it's being closed.") },
    ["ticket"]
  ),

  get_stats: fn(
    "get_stats",
    "Report bot health: messages handled, open tickets, and remaining send budget.",
    {}
  ),
};

// ---------------------------------------------------------- tool handlers

const handlers = {
  search_knowledge_base: async ({ query }) => {
    const results = searchKnowledge(query);
    if (!results.length) {
      return {
        found: 0,
        instruction:
          "Nothing in the knowledge base covers this. Do NOT invent an answer — " +
          "use escalate_to_team so a colleague can help, and tell the customer " +
          "you're checking with the team.",
      };
    }
    return { found: results.length, results };
  },

  list_topics: async () => ({ topics: allTopics() }),

  get_business_info: async () => ({
    company: config.companyName,
    businessHours: config.businessHours,
    humanContact: config.humanContact,
  }),

  list_photos: async () => ({
    catalog: catalog.map((c) => ({ id: c.id, file: c.photo })),
    files: listPhotoFiles(),
  }),

  reply_with_photo: async ({ photo, caption }, ctx) => {
    const resolved = resolvePhoto(photo, ctx);
    if (resolved.error) return { error: resolved.error };
    // Always the current chat — a customer can never redirect this elsewhere.
    await outbox.sendPhoto(ctx.chatId, resolved.media, caption || "", {
      bucket: "reply",
      via: "agent_reply",
    });
    return { status: "sent", detail: `Sent ${resolved.label} to this chat.` };
  },

  escalate_to_team: async ({ department, summary, urgency }, ctx) => {
    const result = await tickets.createTicket({
      chatId: ctx.chatId,
      customerLabel: ctx.senderLabel,
      department,
      summary,
      question: ctx.currentMessage || summary,
      urgency: urgency === "high" ? "high" : "normal",
    });
    if (result.error) {
      return {
        error: result.error,
        instruction:
          "Tell the customer a colleague will follow up, and share the human " +
          "contact details. Do not promise a specific time.",
      };
    }
    return {
      ...result,
      instruction:
        `Ticket ${result.ticketId} opened and ${result.owner} has been notified. ` +
        `Tell the customer their request is with the team and someone will get ` +
        `back to them. Do not promise an exact time.`,
    };
  },

  save_customer_details: async (details, ctx) => {
    appendLog("customers.jsonl", { chatId: ctx.chatId, ...details });
    return { status: "saved", detail: "Details recorded for the team." };
  },

  request_callback: async ({ preferred_time, topic }, ctx) => {
    appendLog("callbacks.jsonl", {
      chatId: ctx.chatId,
      customer: ctx.senderLabel,
      preferred_time,
      topic: topic || "",
    });
    const result = await tickets.createTicket({
      chatId: ctx.chatId,
      customerLabel: ctx.senderLabel,
      department: "sales",
      summary: `Callback requested for ${preferred_time}${topic ? ` about ${topic}` : ""}`,
      question: ctx.currentMessage || "",
      urgency: "normal",
    });
    return {
      status: "logged",
      ticketId: result.ticketId || null,
      detail: "Callback request saved and the team notified.",
    };
  },

  check_reference: async ({ reference }, ctx) => {
    // Optional integration point: set LOOKUP_API_URL to your backend and it
    // receives { reference } and returns whatever JSON you want surfaced.
    if (!config.lookupApiUrl) {
      return {
        available: false,
        instruction:
          "Reference lookup is not connected. Use escalate_to_team with " +
          "department 'accounts' so a colleague can check it manually.",
      };
    }
    try {
      const res = await fetch(config.lookupApiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(config.lookupApiKey ? { Authorization: `Bearer ${config.lookupApiKey}` } : {}),
        },
        body: JSON.stringify({ reference, chatId: ctx.chatId }),
        signal: AbortSignal.timeout(10000),
      });
      if (!res.ok) return { error: `Lookup service returned ${res.status}.` };
      return { available: true, result: await res.json() };
    } catch (err) {
      return { error: `Lookup failed: ${err.message}` };
    }
  },

  find_contact: async ({ name }) => {
    const matches = findContacts(name);
    if (!matches.length) return { found: 0, note: `No contact matching "${name}".` };
    return { found: matches.length, contacts: matches };
  },

  list_contacts: async () => ({
    count: allContacts().length,
    contacts: allContacts().map((c) => ({
      name: c.name,
      role: c.role || null,
      departments: c.departments || [],
    })),
  }),

  send_text: async ({ to, message }, ctx) => {
    const resolved = resolveTargets(to, ctx);
    if (resolved.error) return { error: resolved.error };

    const action = {
      type: "text",
      body: message,
      targets: resolved.targets,
      requestedBy: ctx.senderLabel,
    };

    if (config.requireConfirmation) {
      outbox.stagePending(ctx.chatId, action);
      return {
        status: "awaiting_confirmation",
        note:
          `Staged for ${resolved.targets.map((t) => t.label).join(", ")}. Tell the ` +
          `user exactly what will be sent to whom and ask them to reply YES.`,
      };
    }
    return { status: "sent", summary: await outbox.executePending(action) };
  },

  send_photo: async ({ to, photo, caption }, ctx) => {
    const resolvedPhoto = resolvePhoto(photo, ctx);
    if (resolvedPhoto.error) return { error: resolvedPhoto.error };
    const resolved = resolveTargets(to, ctx);
    if (resolved.error) return { error: resolved.error };

    const action = {
      type: "photo",
      media: resolvedPhoto.media,
      caption: caption || "",
      targets: resolved.targets,
      requestedBy: ctx.senderLabel,
    };

    if (config.requireConfirmation) {
      outbox.stagePending(ctx.chatId, action);
      return {
        status: "awaiting_confirmation",
        note:
          `Staged ${resolvedPhoto.label} for ${resolved.targets.map((t) => t.label).join(", ")}. ` +
          `Tell the user what will be sent to whom and ask them to reply YES.`,
      };
    }
    return { status: "sent", summary: await outbox.executePending(action) };
  },

  send_to_app: async ({ target, message, photo }, ctx) => {
    const url = config.webhooks[target];
    if (!url) {
      const names = Object.keys(config.webhooks);
      return {
        error:
          `Unknown app target "${target}". Configured targets: ` +
          (names.length ? names.join(", ") : "(none configured)"),
      };
    }

    const payload = {
      text: message,
      from: ctx.senderLabel,
      sentAt: new Date().toISOString(),
    };

    if (photo) {
      const resolved = resolvePhoto(photo, ctx);
      if (resolved.error) return { error: resolved.error };
      payload.photo = {
        filename: resolved.media.filename || resolved.label,
        mimetype: resolved.media.mimetype,
        base64: resolved.media.data,
      };
    }

    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(15000),
      });
      if (!res.ok) return { error: `${target} responded ${res.status} ${res.statusText}` };
      return { ok: true, detail: `Posted to ${target}.` };
    } catch (err) {
      return { error: `Could not reach ${target}: ${err.message}` };
    }
  },

  list_open_tickets: async ({ mine_only } = {}, ctx) => {
    const list = mine_only
      ? tickets.openTicketsFor(ctx.chatId)
      : tickets.allOpenTickets();
    return {
      count: list.length,
      tickets: list.slice(0, 25).map((t) => ({
        id: t.id,
        from: t.customerLabel,
        needs: t.summary,
        department: t.department,
        owner: t.ownerLabel,
        urgency: t.urgency,
        openedAt: t.openedAt,
      })),
    };
  },

  reply_to_customer: async ({ ticket, message }, ctx) => {
    try {
      return await tickets.replyToTicket(ticket, message, ctx.senderLabel);
    } catch (err) {
      return { error: err.message };
    }
  },

  close_ticket: async ({ ticket, note }) => tickets.closeTicket(ticket, note || ""),

  get_stats: async () => ({
    tickets: tickets.stats(),
    sendBudget: outbox.budget(),
    knowledgeTopics: allTopics().length,
  }),
};

// -------------------------------------------------------------- role scoping

const TEAM_TOOLS = [
  "search_knowledge_base",
  "list_topics",
  "get_business_info",
  "list_photos",
  "reply_with_photo",
  "find_contact",
  "list_contacts",
  "send_text",
  "send_photo",
  "send_to_app",
  "list_open_tickets",
  "reply_to_customer",
  "close_ticket",
  "get_stats",
  "check_reference",
];

/**
 * Customer tools: everything needed to actually help someone, and nothing
 * that can reach a third party of the customer's choosing. escalate_to_team
 * does message a colleague, but the recipient is chosen by OUR routing rules,
 * never by the customer.
 */
const CUSTOMER_TOOLS = [
  "search_knowledge_base",
  "list_topics",
  "get_business_info",
  "list_photos",
  "reply_with_photo",
  "escalate_to_team",
  "save_customer_details",
  "request_callback",
  "check_reference",
];

export function toolsForRole(role) {
  const names = role === "team" ? TEAM_TOOLS : CUSTOMER_TOOLS;
  return {
    schemas: names.map((n) => schemas[n]),
    isAllowed: (name) => names.includes(name),
    names,
  };
}

export async function runTool(name, args, ctx) {
  const handler = handlers[name];
  if (!handler) return { error: `Unknown tool "${name}".` };
  return handler(args, ctx);
}

export { listPhotoFiles };
