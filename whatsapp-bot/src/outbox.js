import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { config } from "../config.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const logDir = path.resolve(__dirname, "..", "logs");
const auditFile = path.join(logDir, "outbox.jsonl");

/**
 * Everything that leaves the bot goes through here, so there is exactly one
 * place enforcing the rate limit and writing the audit log. Tools never touch
 * the WhatsApp client directly.
 */

let client = null;
export function attachClient(c) {
  client = c;
}

// ---------------------------------------------------------------- rate limit

const sentTimestamps = [];

function pruneWindow() {
  const cutoff = Date.now() - 60 * 60 * 1000;
  while (sentTimestamps.length && sentTimestamps[0] < cutoff) sentTimestamps.shift();
}

/**
 * Guard against a runaway agent loop or an abusive instruction turning the
 * company number into a spam cannon. Throws before anything is sent.
 */
function enforceRateLimit(count = 1) {
  pruneWindow();
  if (sentTimestamps.length + count > config.maxSendsPerHour) {
    throw new Error(
      `Hourly send limit reached (${config.maxSendsPerHour}/hour). ` +
        `Refusing to send. Raise MAX_SENDS_PER_HOUR if this is expected.`
    );
  }
}

export function remainingSends() {
  pruneWindow();
  return Math.max(0, config.maxSendsPerHour - sentTimestamps.length);
}

// ---------------------------------------------------------------- audit log

function audit(entry) {
  try {
    fs.mkdirSync(logDir, { recursive: true });
    fs.appendFileSync(
      auditFile,
      JSON.stringify({ at: new Date().toISOString(), ...entry }) + "\n"
    );
  } catch (err) {
    console.error("[audit] Could not write audit log:", err.message);
  }
}

// ---------------------------------------------------------------- sending

export async function sendText(chatId, body, meta = {}) {
  if (!client) throw new Error("WhatsApp client not ready yet.");
  enforceRateLimit();
  await client.sendMessage(chatId, body);
  sentTimestamps.push(Date.now());
  audit({ kind: "text", to: chatId, body: body.slice(0, 500), ...meta });
  return { ok: true, to: chatId };
}

export async function sendPhoto(chatId, media, caption, meta = {}) {
  if (!client) throw new Error("WhatsApp client not ready yet.");
  enforceRateLimit();
  await client.sendMessage(chatId, media, caption ? { caption } : {});
  sentTimestamps.push(Date.now());
  audit({
    kind: "photo",
    to: chatId,
    filename: media?.filename || meta.filename || null,
    caption: (caption || "").slice(0, 500),
    ...meta,
  });
  return { ok: true, to: chatId };
}

// ------------------------------------------------- confirmation before send

/**
 * Staged actions awaiting a human "yes".
 *
 * Messaging a third party on the company's behalf is not undoable, so by
 * default the agent proposes and a person confirms. Confirmation is handled
 * deterministically in code — the pending action is executed as-is, never
 * re-interpreted by the model.
 */
const pending = new Map();

export function stagePending(chatId, action) {
  pending.set(chatId, { action, expiresAt: Date.now() + config.confirmTimeoutMs });
  return action;
}

export function peekPending(chatId) {
  const entry = pending.get(chatId);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    pending.delete(chatId);
    return null;
  }
  return entry.action;
}

export function clearPending(chatId) {
  pending.delete(chatId);
}

/**
 * Confirmations must be the WHOLE message, not a prefix of one.
 *
 * These are anchored at both ends on purpose: "send it to Mary instead" is a
 * new instruction that happens to start with "send", and treating it as a
 * "yes" would fire the previously staged message at the wrong person.
 */
const AFFIRMATIVE =
  /^(y|yes|yeah|yep|ok|okay|k|confirm|confirmed|send|send it|go|go ahead|do it|sure|proceed|please do)[\s!.,👍✅🙏]*$/i;
const NEGATIVE =
  /^(n|no|nope|cancel|stop|don'?t|dont|abort|nevermind|never mind|wait)[\s!.,🚫❌]*$/i;

export function isAffirmative(text) {
  return AFFIRMATIVE.test(String(text || "").trim());
}

export function isNegative(text) {
  return NEGATIVE.test(String(text || "").trim());
}

/**
 * Run a previously staged action. Returns a human-readable summary line.
 */
export async function executePending(action) {
  const results = [];
  for (const target of action.targets) {
    try {
      if (action.type === "photo") {
        await sendPhoto(target.chatId, action.media, action.caption, {
          via: "confirmed",
          requestedBy: action.requestedBy,
        });
      } else {
        await sendText(target.chatId, action.body, {
          via: "confirmed",
          requestedBy: action.requestedBy,
        });
      }
      results.push(`✅ ${target.label}`);
    } catch (err) {
      results.push(`❌ ${target.label}: ${err.message}`);
    }
  }
  return results.join("\n");
}
