import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pkg from "whatsapp-web.js";
const { MessageMedia } = pkg;
import { config, catalog, textReplies } from "../config.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const mediaRoot = path.resolve(__dirname, "..", config.mediaDir);

// Remembers the last time we greeted each customer, so the welcome/menu
// message isn't re-sent on every message. Resets when the bot restarts.
const lastGreeted = new Map();

const norm = (text) => (text || "").toLowerCase().trim();

const matches = (text, keywords) => keywords.some((k) => text.includes(k));

/**
 * Load a photo from the media folder as a WhatsApp MessageMedia object.
 * Returns null (and logs a warning) if the file is missing, so a typo in the
 * config never crashes the bot.
 */
function loadPhoto(filename) {
  const filePath = path.join(mediaRoot, filename);
  if (!fs.existsSync(filePath)) {
    console.warn(`[media] missing file: ${filePath} — skipping photo, sending text only`);
    return null;
  }
  return MessageMedia.fromFilePath(filePath);
}

function greetingText() {
  const items = catalog.map((c) => `• *${c.id}*`).join("\n");
  return (
    `👋 Hi, thanks for messaging *${config.companyName}*!\n\n` +
    `I'm an automated assistant. You can ask me for:\n${items}\n` +
    `• *hours* — our opening times\n` +
    `• *delivery* — delivery info\n` +
    `• *human* — talk to a person\n\n` +
    `How can I help today?`
  );
}

/**
 * Decide how to respond to one incoming customer message.
 *
 * Returns an array of actions the caller executes in order. Each action is
 * either { type: "text", body } or { type: "photo", media, caption }.
 * Returns an empty array when the bot should stay silent.
 */
export function buildResponses(rawText, chatId) {
  const text = norm(rawText);
  const actions = [];

  if (!text) return actions;

  // 1. Explicit request for a human — hand off and stop.
  if (matches(text, ["human", "agent", "person", "representative", "support", "help me"])) {
    actions.push({
      type: "text",
      body: `No problem 🙌 — ${config.humanContact}.`,
    });
    return actions;
  }

  // 2. Catalog photo requests.
  for (const item of catalog) {
    if (matches(text, item.keywords)) {
      const media = loadPhoto(item.photo);
      if (media) {
        actions.push({ type: "photo", media, caption: item.caption });
      } else {
        actions.push({ type: "text", body: item.caption });
      }
      return actions;
    }
  }

  // 3. Text keyword replies.
  for (const rule of textReplies) {
    if (matches(text, rule.keywords)) {
      actions.push({ type: "text", body: rule.reply() });
      return actions;
    }
  }

  // 4. Greeting / fallback menu — rate-limited so we don't repeat it constantly.
  const now = Date.now();
  const last = lastGreeted.get(chatId) || 0;
  if (now - last > config.greetingCooldownMs) {
    lastGreeted.set(chatId, now);
    actions.push({ type: "text", body: greetingText() });
  } else {
    // Already greeted recently; give a gentle nudge instead of the full menu.
    actions.push({
      type: "text",
      body:
        "I didn't quite catch that 🤔. Try *catalog*, *hours*, *delivery*, or *human* to reach a team member.",
    });
  }

  return actions;
}
