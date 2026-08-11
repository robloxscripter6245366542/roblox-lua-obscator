import qrcode from "qrcode-terminal";
import pkg from "whatsapp-web.js";
const { Client, LocalAuth } = pkg;

import { config } from "./config.js";
import { buildResponses } from "./src/replies.js";

/**
 * WhatsApp company bot.
 *
 * Uses whatsapp-web.js, which drives a real WhatsApp Web session under the
 * hood. On first run it prints a QR code — scan it once from the company's
 * WhatsApp app (Settings → Linked devices). The session is saved locally
 * (.wwebjs_auth) so you won't need to scan again on restart.
 */

const client = new Client({
  authStrategy: new LocalAuth({ dataPath: ".wwebjs_auth" }),
  puppeteer: {
    headless: true,
    // These flags let Chromium run in restricted / container environments.
    args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--disable-dev-shm-usage",
    ],
  },
});

client.on("qr", (qr) => {
  console.log("\nScan this QR code with WhatsApp (Settings → Linked devices):\n");
  qrcode.generate(qr, { small: true });
});

client.on("authenticated", () => {
  console.log("[auth] Session authenticated.");
});

client.on("auth_failure", (msg) => {
  console.error("[auth] Authentication failed:", msg);
});

client.on("ready", () => {
  console.log(`\n✅ ${config.companyName} WhatsApp bot is online and listening.\n`);
});

client.on("disconnected", (reason) => {
  console.warn("[conn] Disconnected:", reason, "— attempting to reinitialize.");
  client.initialize().catch((err) => console.error("[conn] Reinit failed:", err));
});

client.on("message", async (message) => {
  try {
    // Ignore status broadcasts and messages sent by ourselves.
    if (message.from === "status@broadcast" || message.fromMe) return;

    const chat = await message.getChat();
    if (chat.isGroup && !config.respondInGroups) return;

    // Only handle plain text and captions; ignore stickers, calls, etc.
    const body = message.body || "";
    if (!body.trim()) return;

    const actions = buildResponses(body, message.from);

    for (const action of actions) {
      if (action.type === "text") {
        await message.reply(action.body);
      } else if (action.type === "photo") {
        await client.sendMessage(message.from, action.media, {
          caption: action.caption,
        });
      }
    }
  } catch (err) {
    console.error("[message] Error handling message:", err);
  }
});

console.log(`Starting ${config.companyName} WhatsApp bot…`);
client.initialize().catch((err) => {
  console.error("[startup] Failed to initialize:", err);
  process.exit(1);
});

// Graceful shutdown so the browser process is cleaned up.
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
