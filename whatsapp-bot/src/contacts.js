import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { config } from "../config.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const contactsFile = path.resolve(__dirname, "..", "contacts.json");

/**
 * The company contact directory: how a name like "John" becomes a WhatsApp
 * number. Lives in contacts.json (gitignored — it holds real phone numbers).
 * Copy contacts.example.json to get started.
 */
let directory = [];

export function loadContacts() {
  if (!fs.existsSync(contactsFile)) {
    console.warn(
      "[contacts] No contacts.json found — the bot can still send to raw phone " +
        "numbers, but not to people by name. Copy contacts.example.json to start."
    );
    directory = [];
    return directory;
  }
  try {
    const parsed = JSON.parse(fs.readFileSync(contactsFile, "utf8"));
    directory = Array.isArray(parsed) ? parsed : parsed.contacts || [];
    console.log(`[contacts] Loaded ${directory.length} contacts.`);
  } catch (err) {
    console.error("[contacts] contacts.json is not valid JSON:", err.message);
    directory = [];
  }
  return directory;
}

export function allContacts() {
  return directory;
}

/**
 * Turn a loose phone number into a WhatsApp chat id.
 * Accepts "+234 801 234 5678", "08012345678", "2348012345678", etc.
 * Numbers starting with 0 get the configured default country code.
 */
export function toChatId(raw) {
  if (!raw) return null;
  const trimmed = String(raw).trim();

  // Already a WhatsApp id (individual or group).
  if (/@(c|g)\.us$/.test(trimmed)) return trimmed;

  let digits = trimmed.replace(/[^\d]/g, "");
  if (!digits) return null;

  // International prefixes: "00234..." -> "234..."
  if (digits.startsWith("00")) digits = digits.slice(2);
  // National format: "0801..." -> "<cc>801..."
  else if (digits.startsWith("0")) digits = config.defaultCountryCode + digits.slice(1);

  // Too short to be a real number — refuse rather than message a stranger.
  if (digits.length < 8) return null;

  return `${digits}@c.us`;
}

const norm = (s) => String(s || "").toLowerCase().trim();

/**
 * Look up people by name or alias. Returns ALL plausible matches so the agent
 * can ask "which John?" instead of guessing and messaging the wrong person.
 */
export function findContacts(query) {
  const q = norm(query);
  if (!q) return [];

  const candidates = directory.map((c) => ({
    ...c,
    _names: [c.name, ...(c.aliases || [])].map(norm),
  }));

  const exact = candidates.filter((c) => c._names.includes(q));
  if (exact.length) return exact.map(strip);

  const starts = candidates.filter((c) => c._names.some((n) => n.startsWith(q)));
  if (starts.length) return starts.map(strip);

  const partial = candidates.filter((c) =>
    c._names.some((n) => n.includes(q) || q.includes(n))
  );
  return partial.map(strip);
}

function strip({ _names, ...rest }) {
  return rest;
}

/**
 * Resolve a recipient string to { chatId, label }.
 *
 * Order matters: a directory name wins over a raw number, so "send to Ops
 * Team" uses the saved group id rather than trying to parse it as digits.
 * Returns { error } when ambiguous or unknown — the agent surfaces that to
 * the user rather than sending to the wrong person.
 */
export function resolveRecipient(recipient) {
  const raw = String(recipient || "").trim();
  if (!raw) return { error: "No recipient given." };

  const matches = findContacts(raw);

  if (matches.length === 1) {
    const chatId = matches[0].chatId || toChatId(matches[0].number);
    if (!chatId) {
      return { error: `Contact "${matches[0].name}" has no usable number.` };
    }
    return { chatId, label: matches[0].name };
  }

  if (matches.length > 1) {
    return {
      error:
        `"${raw}" matches ${matches.length} contacts: ` +
        `${matches.map((m) => m.name).join(", ")}. Ask which one they mean.`,
    };
  }

  // Not a known name — try it as a phone number.
  const chatId = toChatId(raw);
  if (chatId) return { chatId, label: raw };

  return {
    error: `"${raw}" is not in the contact directory and is not a valid phone number.`,
  };
}

loadContacts();
