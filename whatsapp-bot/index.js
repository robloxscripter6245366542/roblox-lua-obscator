import qrcode from "qrcode-terminal";
import pkg from "whatsapp-web.js";
const { Client, LocalAuth } = pkg;

import { config } from "./config.js";
import { buildResponses } from "./src/replies.js";
import { runAgent, isAgentEnabled, clearMemory } from "./src/agent.js";
import { toChatId } from "./src/contacts.js";
import * as outbox from "./src/outbox.js";

/**
 * Payfonte WhatsApp bot.
 *
 * Two audiences, one number:
 *   • TEAM members (allowlisted) get a ChatGPT agent that can send messages
 *     and photos to people and connected apps on their instruction.
 *   • CUSTOMERS get a reply-only assistant that answers questions and shows
 *     catalog photos, and can never message anyone else.
 *
 * Uses whatsapp-web.js — scan the QR once from the company phone
 * (Settings → Linked devices) and the session persists in .wwebjs_auth.
 */

const client = new Client({
  authStrategy: new LocalAuth({ dataPath: ".wwebjs_auth" }),
  puppeteer: {
    headless: true,
    // These flags let Chromium run in restricted / container environments.
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"],
  },
});

outbox.attachClient(client);

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
  console.log(`\n✅ ${config.companyName} WhatsApp bot is online.`);
  console.log(`   AI agent:      ${isAgentEnabled() ? `on (${config.openaiModel})` : "off (no OPENAI_API_KEY)"}`);
  console.log(`   Team members:  ${teamChatIds.size}`);
  console.log(`   Confirm sends: ${config.requireConfirmation ? "yes" : "no"}`);
  console.log(`   App targets:   ${Object.keys(config.webhooks).join(", ") || "none"}\n`);

  if (!teamChatIds.size) {
    console.warn(
      "[config] TEAM_NUMBERS is empty — nobody can instruct the bot to message " +
        "others. Add your team's numbers to .env to enable that.\n"
    );
  }
});

client.on("disconnected", (reason) => {
  console.warn("[conn] Disconnected:", reason, "— attempting to reinitialize.");
  client.initialize().catch((err) => console.error("[conn] Reinit failed:", err));
});

// ------------------------------------------------------------ message router

client.on("message", async (message) => {
  try {
    if (message.from === "status@broadcast" || message.fromMe) return;

    const chat = await message.getChat();
    if (chat.isGroup && !config.respondInGroups) return;

    const chatId = message.from;
    const role = roleFor(chatId);
    const body = (message.body || "").trim();

    // Remember incoming photos so the team can say "send this to John".
    if (message.hasMedia) {
      try {
        const media = await message.downloadMedia();
        if (media?.mimetype?.startsWith("image/")) {
          lastMediaByChat.set(chatId, media);
        }
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

    // --- 1. Resolve a staged send first, deterministically. --------------
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
        // Anything else falls through and is treated as a new instruction,
        // which will re-stage or replace the pending action.
      }

      if (/^\/reset\b/i.test(body)) {
        clearMemory(chatId);
        outbox.clearPending(chatId);
        await message.reply("Conversation reset. 🧹");
        return;
      }
    }

    // --- 2. AI agent path. -----------------------------------------------
    const useAgent = isAgentEnabled() && (role === "team" || config.aiForCustomers);

    if (useAgent) {
      try {
        await chat.sendStateTyping();
        const reply = await runAgent(body, ctx);
        if (reply && reply.trim()) await message.reply(reply);
        return;
      } catch (err) {
        console.error("[agent] Falling back to keyword replies:", err.message);
        if (role === "team") {
          await message.reply(
            `⚠️ My AI brain is unavailable right now (${err.message}). ` +
              `Try again shortly.`
          );
          return;
        }
        // Customers silently fall through to the keyword responder below.
      }
    }

    // --- 3. Keyword fallback (no AI key, or the API call failed). ---------
    for (const action of buildResponses(body, chatId)) {
      if (action.type === "text") {
        await message.reply(action.body);
      } else if (action.type === "photo") {
        await outbox.sendPhoto(chatId, action.media, action.caption, {
          via: "keyword",
        });
      }
    }
  } catch (err) {
    console.error("[message] Error handling message:", err);
  }
});

// ------------------------------------------------------------------- startup

console.log(`Starting ${config.companyName} WhatsApp bot…`);
client.initialize().catch((err) => {
  console.error("[startup] Failed to initialize:", err);
  process.exit(1);
});

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, async () => {
    console.log(`\n[shutdown] Received ${signal}, closing…`);
    try {
      await client.destroy();
    } finally {
      process.exit(0);
    }
  });
}
