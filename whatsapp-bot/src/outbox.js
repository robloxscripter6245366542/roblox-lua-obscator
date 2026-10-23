import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { config } from "../config.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const logDir = path.resolve(__dirname, "..", "logs");
const auditFile = path.join(logDir, "outbox.jsonl");

/**
 * Everything that leaves the bot goes through here, so there is exactly one
 * place enforcing limits and writing the audit log.
 */

let client = null;
export function attachClient(c) {
  client = c;
}

// ---------------------------------------------------------------- rate limit

/**
 * Sends are budgeted separately by kind, because the risk profiles are
 * completely different:
 *
 *   reply    — answering someone who just messaged us. Zero spam risk, and at
 *              volume this is nearly all traffic. Generous ceiling, present
 *              only to catch a runaway loop.
 *   internal — paging a colleague (escalations, digests). Moderate.
 *   outreach — messaging a third party on instruction. This is the one that
 *              can turn the company number into a spam cannon. Strict.
 *
 * One shared budget would mean a busy support day silently blocks replies, or
 * a loose limit leaves outreach unguarded. Neither is acceptable.
 */
const buckets = {
  reply: { limit: () => config.maxRepliesPerHour, times: [] },
  internal: { limit: () => config.maxInternalPerHour, times: [] },
  outreach: { limit: () => config.maxSendsPerHour, times: [] },
};

function prune(bucket) {
  const cutoff = Date.now() - 60 * 60 * 1000;
  while (bucket.times.length && bucket.times[0] < cutoff) bucket.times.shift();
}

function enforce(kind, count = 1) {
  const bucket = buckets[kind];
  if (!bucket) throw new Error(`Unknown send bucket "${kind}".`);
  prune(bucket);
  const limit = bucket.limit();
  if (bucket.times.length + count > limit) {
    throw new Error(
      `Hourly ${kind} limit reached (${limit}/hour). Refusing to send.`
    );
  }
}

export function budget() {
  const out = {};
  for (const [kind, bucket] of Object.entries(buckets)) {
    prune(bucket);
    out[kind] = { used: bucket.times.length, limit: bucket.limit() };
  }
  return out;
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

async function dispatch(kind, chatId, content, options, meta) {
  if (!client) throw new Error("WhatsApp client not ready yet.");
  if (!chatId) throw new Error("No recipient chat id.");
  enforce(kind);
  await client.sendMessage(chatId, content, options);
  buckets[kind].times.push(Date.now());
  return { ok: true, to: chatId };
}

/** Reply to someone who messaged us. */
export async function sendReply(chatId, body, meta = {}) {
  const res = await dispatch("reply", chatId, body, {}, meta);
  audit({ kind: "reply", to: chatId, body: String(body).slice(0, 500), ...meta });
  return res;
}

/** Page a colleague (escalation, digest, handoff). */
export async function sendInternal(chatId, body, meta = {}) {
  const res = await dispatch("internal", chatId, body, {}, meta);
  audit({ kind: "internal", to: chatId, body: String(body).slice(0, 500), ...meta });
  return res;
}

/** Message a third party on a team member's instruction. */
export async function sendOutreach(chatId, body, meta = {}) {
  const res = await dispatch("outreach", chatId, body, {}, meta);
  audit({ kind: "outreach", to: chatId, body: String(body).slice(0, 500), ...meta });
  return res;
}

export async function sendPhoto(chatId, media, caption, meta = {}) {
  const kind = meta.bucket || "outreach";
  const res = await dispatch(kind, chatId, media, caption ? { caption } : {}, meta);
  audit({
    kind: `${kind}_photo`,
    to: chatId,
    filename: media?.filename || meta.filename || null,
    caption: String(caption || "").slice(0, 500),
    ...meta,
  });
  return res;
}

// ------------------------------------------------- confirmation before send

/**
 * Staged actions awaiting a human "yes".
 *
 * Messaging a third party is not undoable, so by default the agent proposes
 * and a person confirms. Confirmation is resolved deterministically in code —
 * the staged action runs exactly as described, never re-interpreted.
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
 * Anchored at both ends on purpose: "send it to Mary instead" is a new
 * instruction that happens to start with "send", and treating it as a "yes"
 * would fire the staged message at the wrong person.
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

/** Run a previously staged action. Returns a human-readable summary. */
export async function executePending(action) {
  const results = [];
  for (const target of action.targets) {
    try {
      if (action.type === "photo") {
        await sendPhoto(target.chatId, action.media, action.caption, {
          bucket: "outreach",
          via: "confirmed",
          requestedBy: action.requestedBy,
        });
      } else {
        await sendOutreach(target.chatId, action.body, {
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
