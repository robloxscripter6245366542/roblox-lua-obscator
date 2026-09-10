import qrcode from "qrcode-terminal";
import pkg from "whatsapp-web.js";
const { Client, LocalAuth } = pkg;

import { config } from "./config.js";
import { buildResponses } from "./src/replies.js";
import { runAgent, isAgentEnabled, clearMemory } from "./src/agent.js";
import { toChatId } from "./src/contacts.js";
import { createQueue, createDeduper } from "./src/queue.js";
import { entryCount } from "./src/knowledge.js";
import * as tickets from "./src/tickets.js";
import * as outbox from "./src/outbox.js";

/**
 * Payfonte WhatsApp assistant.
 *
 * Two audiences, one number:
 *   • TEAM members (allowlisted) get an agent that can send messages and
 *     photos to people and connected apps, and answer escalated customers.
 *   • CUSTOMERS get a support assistant that answers from the knowledge base,
 *     and when it doesn't know, messages the right colleague with what the
 *     customer needs — then relays their answer back.
 *
 * Built to handle many conversations at once: work is queued per chat (in
 * order) and processed in parallel across chats (capped).
 */

const client = new Client({
  authStrategy: new LocalAuth({ dataPath: ".wwebjs_auth" }),
  puppeteer: {
    headless: true,
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"],
  },
});

outbox.attachClient(client);

const queue = createQueue({
  concurrency: config.concurrency,
  maxDepthPerChat: config.maxQueuePerChat,
});
const isDuplicate = createDeduper();

// Team numbers, normalized once at startup so lookups are a plain Set hit.
const teamChatIds = new Set(config.teamNumbers.map(toChatId).filter(Boolean));

// The most recent photo each chat sent us, so "send this to John" works.
const lastMediaByChat = new Map();

function roleFor(chatId) {
  return teamChatIds.has(chatId) ? "team" : "customer";
}

// ------------------------------------------------------------- client events

client.on("qr", (qr) => {
  console.log("\nScan this QR code with WhatsApp (Settings → Linked devices):\n");
  qrcode.generate(qr, { small: true });
});

client.on("authenticated", () => console.log("[auth] Session authenticated."));
client.on("auth_failure", (msg) => console.error("[auth] Authentication failed:", msg));

client.on("ready", () => {
  console.log(`\n✅ ${config.companyName} WhatsApp assistant is online.`);
  console.log(`   AI agent:      ${isAgentEnabled() ? `on (${config.openaiModel})` : "off (no OPENAI_API_KEY)"}`);
  console.log(`   Knowledge:     ${entryCount()} entries`);
  console.log(`   Team members:  ${teamChatIds.size}`);
  console.log(`   Departments:   ${tickets.knownDepartments().join(", ") || "none configured"}`);
  console.log(`   Concurrency:   ${config.concurrency} chats in parallel`);
  console.log(`   Confirm sends: ${config.requireConfirmation ? "yes" : "no"}\n`);

  if (!teamChatIds.size) {
    console.warn(
      "[config] TEAM_NUMBERS is empty — nobody can instruct the bot to message " +
        "others, and escalations have no owner. Add your team to .env.\n"
    );
  }
});

client.on("disconnected", (reason) => {
  console.warn("[conn] Disconnected:", reason, "— attempting to reinitialize.");
  client.initialize().catch((err) => console.error("[conn] Reinit failed:", err));
});

// ------------------------------------------------------------ message router

client.on("message", (message) => {
  // Cheap synchronous filters first — never queue work we won't do.
  if (message.from === "status@broadcast" || message.fromMe) return;
  if (isDuplicate(message.id?._serialized)) return;

  queue.enqueue(message.from, () => handleMessage(message)).catch((err) => {
    if (err?.message === "chat_queue_full") {
      console.warn(`[queue] Dropping message from ${message.from} — chat queue full.`);
      return;
    }
    console.error("[queue] Job failed:", err);
  });
});

async function handleMessage(message) {
  const chat = await message.getChat();
  if (chat.isGroup && !config.respondInGroups) return;

  const chatId = message.from;
  const role = roleFor(chatId);
  const body = (message.body || "").trim();

  // Remember incoming photos so the team can say "send this to John".
  if (message.hasMedia) {
    try {
      const media = await message.downloadMedia();
      if (media?.mimetype?.startsWith("image/")) lastMediaByChat.set(chatId, media);
    } catch (err) {
      console.error("[media] Could not download incoming media:", err.message);
    }
  }

  if (!body) return;

  const ctx = {
    chatId,
    role,
    senderLabel: message._data?.notifyName || chatId.replace("@c.us", ""),
    lastMedia: lastMediaByChat.get(chatId) || null,
  };

  // --- 1. Resolve a staged send first, deterministically. ------------------
  // A confirmation must never be re-interpreted by the model: "yes" runs
  // exactly the action that was described to the user, or nothing.
  if (role === "team") {
    const staged = outbox.peekPending(chatId);
    if (staged) {
      if (outbox.isAffirmative(body)) {
        outbox.clearPending(chatId);
        const summary = await outbox.executePending(staged);
        await message.reply(`Sent 👍\n${summary}`);
        return;
      }
      if (outbox.isNegative(body)) {
        outbox.clearPending(chatId);
        await message.reply("Cancelled — nothing was sent. 👍");
        return;
      }
      // Anything else falls through as a new instruction.
    }

    if (/^\/reset\b/i.test(body)) {
      clearMemory(chatId);
      outbox.clearPending(chatId);
      await message.reply("Conversation reset. 🧹");
      return;
    }

    if (/^\/stats\b/i.test(body)) {
      const t = tickets.stats();
      const q = queue.stats();
      await message.reply(
        `📊 *Status*\n` +
          `Open tickets: ${t.open} (${t.opened} total)\n` +
          `Handled: ${q.processed} · failed: ${q.failed} · dropped: ${q.dropped}\n` +
          `Active now: ${q.active} · queued: ${q.waiting}\n` +
          `Send budget: ${JSON.stringify(outbox.budget())}`
      );
      return;
    }
  }

  // --- 2. AI agent path. ---------------------------------------------------
  const useAgent = isAgentEnabled() && (role === "team" || config.aiForCustomers);

  if (useAgent) {
    try {
      await chat.sendStateTyping().catch(() => {});
      const reply = await runAgent(body, ctx);
      if (reply && reply.trim()) await message.reply(reply);
      return;
    } catch (err) {
      console.error("[agent] Falling back to keyword replies:", err.message);
      if (role === "team") {
        await message.reply(`⚠️ My AI brain is unavailable right now (${err.message}).`);
        return;
      }
      // Customers silently fall through to the keyword responder below, so an
      // OpenAI outage degrades service instead of dropping it.
    }
  }

  // --- 3. Keyword fallback (no AI key, or the API call failed). -------------
  for (const action of buildResponses(body, chatId)) {
    if (action.type === "text") {
      await message.reply(action.body);
    } else if (action.type === "photo") {
      await outbox.sendPhoto(chatId, action.media, action.caption, {
        bucket: "reply",
        via: "keyword",
      });
    }
  }
}

// ------------------------------------------------------------------- startup

console.log(`Starting ${config.companyName} WhatsApp assistant…`);
client.initialize().catch((err) => {
  console.error("[startup] Failed to initialize:", err);
  process.exit(1);
});

// Batch up escalations that arrived while a colleague was over their alert
// limit, so a spike of identical questions doesn't page anyone 200 times.
const digestTimer = setInterval(() => {
  tickets.flushDigests().catch((err) => console.error("[digest]", err.message));
}, config.digestIntervalMs);

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, async () => {
    console.log(`\n[shutdown] Received ${signal}, closing…`);
    clearInterval(digestTimer);
    try {
      await client.destroy();
    } finally {
      process.exit(0);
    }
  });
}
