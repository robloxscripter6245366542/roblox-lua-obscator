import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import pkg from "whatsapp-web.js";
const { MessageMedia } = pkg;

import { config, catalog } from "../config.js";
import { findContacts, allContacts, resolveRecipient } from "./contacts.js";
import * as outbox from "./outbox.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const mediaRoot = path.resolve(__dirname, "..", config.mediaDir);

/**
 * The agent's tool belt.
 *
 * Tools are scoped by role: "team" members can send to anyone, "customer"
 * chats can only ever cause a reply in their own chat. That scoping is the
 * security boundary — a customer message is data, never a command to message
 * someone else, no matter what it says.
 */

const IMAGE_EXT = /\.(jpe?g|png|webp|gif)$/i;

function listPhotoFiles() {
  if (!fs.existsSync(mediaRoot)) return [];
  return fs.readdirSync(mediaRoot).filter((f) => IMAGE_EXT.test(f));
}

/**
 * Resolve a photo reference to MessageMedia.
 * Accepts a catalog id ("catalog"), a filename ("pricing.jpg"), or the
 * special value "last_received" for a photo just sent to the bot.
 */
function resolvePhoto(ref, ctx) {
  const wanted = String(ref || "").trim();

  if (!wanted) return { error: "No photo specified." };

  if (wanted === "last_received") {
    if (!ctx.lastMedia) {
      return { error: "No photo has been sent to this chat recently." };
    }
    return { media: ctx.lastMedia, label: "the photo you sent" };
  }

  // Catalog id (e.g. "catalog", "location").
  const item = catalog.find((c) => c.id === wanted);
  const filename = item ? item.photo : wanted;

  // Reject path traversal — only plain filenames inside media/ are allowed.
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

/**
 * Push a message (and optionally a photo) to a configured external system —
 * a Slack webhook, an internal API, a partner app.
 *
 * Only named targets from config.webhooks are reachable. The model picks a
 * name, never a URL, so it cannot be talked into posting company data to an
 * arbitrary host.
 */
async function postToApp({ target, message, photo }, ctx) {
  const url = config.webhooks[target];
  if (!url) {
    const names = Object.keys(config.webhooks);
    return {
      error:
        `Unknown app target "${target}". Configured targets: ` +
        (names.length ? names.join(", ") : "(none configured)"),
    };
  }

  const payload = { text: message, from: ctx.senderLabel, sentAt: new Date().toISOString() };

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
    if (!res.ok) {
      return { error: `${target} responded ${res.status} ${res.statusText}` };
    }
    return { ok: true, detail: `Posted to ${target}.` };
  } catch (err) {
    return { error: `Could not reach ${target}: ${err.message}` };
  }
}

// ------------------------------------------------------------- tool schemas

const schemas = {
  find_contact: {
    type: "function",
    function: {
      name: "find_contact",
      description:
        "Look up people in the company contact directory by name or alias. " +
        "Use this before sending to confirm who the user means, especially if " +
        "the name could match more than one person.",
      parameters: {
        type: "object",
        properties: {
          name: { type: "string", description: "Name or partial name to search for." },
        },
        required: ["name"],
      },
    },
  },

  list_contacts: {
    type: "function",
    function: {
      name: "list_contacts",
      description: "List everyone in the company contact directory.",
      parameters: { type: "object", properties: {} },
    },
  },

  list_photos: {
    type: "function",
    function: {
      name: "list_photos",
      description:
        "List the photos available to send (company catalog images and any " +
        "other files in the media folder).",
      parameters: { type: "object", properties: {} },
    },
  },

  send_text: {
    type: "function",
    function: {
      name: "send_text",
      description:
        "Send a WhatsApp text message to one or more people. Use for requests " +
        "like 'tell John the invoice is ready' or 'message the ops team'.",
      parameters: {
        type: "object",
        properties: {
          to: {
            type: "array",
            items: { type: "string" },
            description:
              "Recipients: contact names from the directory, or phone numbers.",
          },
          message: { type: "string", description: "The message body to send." },
        },
        required: ["to", "message"],
      },
    },
  },

  send_photo: {
    type: "function",
    function: {
      name: "send_photo",
      description:
        "Send a photo to one or more people. Use 'last_received' as the photo " +
        "when the user says 'send this photo to X' right after sending an image.",
      parameters: {
        type: "object",
        properties: {
          to: {
            type: "array",
            items: { type: "string" },
            description: "Recipients: contact names or phone numbers.",
          },
          photo: {
            type: "string",
            description:
              "A catalog id, a filename from the media folder, or 'last_received'.",
          },
          caption: { type: "string", description: "Optional caption for the photo." },
        },
        required: ["to", "photo"],
      },
    },
  },

  send_to_app: {
    type: "function",
    function: {
      name: "send_to_app",
      description:
        "Push a message and optional photo to a connected external system " +
        "(for example Slack, or an internal Payfonte service). Use when the " +
        "user asks to send something somewhere other than WhatsApp.",
      parameters: {
        type: "object",
        properties: {
          target: { type: "string", description: "Name of the configured app target." },
          message: { type: "string", description: "The message to post." },
          photo: {
            type: "string",
            description: "Optional photo: catalog id, filename, or 'last_received'.",
          },
        },
        required: ["target", "message"],
      },
    },
  },

  reply_with_photo: {
    type: "function",
    function: {
      name: "reply_with_photo",
      description:
        "Send a photo to the person you are currently chatting with. Use this " +
        "to show a customer the catalog, price list, or location.",
      parameters: {
        type: "object",
        properties: {
          photo: { type: "string", description: "A catalog id or filename." },
          caption: { type: "string", description: "Optional caption." },
        },
        required: ["photo"],
      },
    },
  },

  handoff_to_human: {
    type: "function",
    function: {
      name: "handoff_to_human",
      description:
        "Flag that this conversation needs a real person. Use when the customer " +
        "asks for a human, is upset, or asks something you cannot answer.",
      parameters: {
        type: "object",
        properties: {
          reason: { type: "string", description: "Why a human is needed." },
        },
        required: ["reason"],
      },
    },
  },
};

// ---------------------------------------------------------- tool handlers

const handlers = {
  find_contact: async ({ name }) => {
    const matches = findContacts(name);
    if (!matches.length) return { found: 0, note: `No contact matching "${name}".` };
    return { found: matches.length, contacts: matches };
  },

  list_contacts: async () => ({
    count: allContacts().length,
    contacts: allContacts().map((c) => ({ name: c.name, role: c.role || null })),
  }),

  list_photos: async () => ({
    catalog: catalog.map((c) => ({ id: c.id, file: c.photo })),
    files: listPhotoFiles(),
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
          `Staged for ${resolved.targets.map((t) => t.label).join(", ")}. ` +
          `Tell the user exactly what will be sent to whom, and ask them to reply YES to confirm.`,
      };
    }

    const summary = await outbox.executePending(action);
    return { status: "sent", summary };
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
          `Tell the user what will be sent to whom, and ask them to reply YES to confirm.`,
      };
    }

    const summary = await outbox.executePending(action);
    return { status: "sent", summary };
  },

  send_to_app: postToApp,

  reply_with_photo: async ({ photo, caption }, ctx) => {
    const resolved = resolvePhoto(photo, ctx);
    if (resolved.error) return { error: resolved.error };
    // Always the current chat — a customer can never redirect this elsewhere.
    await outbox.sendPhoto(ctx.chatId, resolved.media, caption || "", {
      via: "agent_reply",
    });
    return { status: "sent", detail: `Sent ${resolved.label} to this chat.` };
  },

  handoff_to_human: async ({ reason }, ctx) => {
    console.log(`[handoff] ${ctx.chatId} needs a human: ${reason}`);
    if (config.escalationChatId) {
      try {
        await outbox.sendText(
          config.escalationChatId,
          `🔔 Handoff requested\nFrom: ${ctx.senderLabel}\nReason: ${reason}`,
          { via: "handoff" }
        );
      } catch (err) {
        console.error("[handoff] Could not notify escalation chat:", err.message);
      }
    }
    return {
      status: "flagged",
      detail: "A team member has been notified. Reassure the customer.",
    };
  },
};

const TEAM_TOOLS = [
  "find_contact",
  "list_contacts",
  "list_photos",
  "send_text",
  "send_photo",
  "send_to_app",
  "reply_with_photo",
];

// Deliberately excludes every tool that can reach a third party.
const CUSTOMER_TOOLS = ["list_photos", "reply_with_photo", "handoff_to_human"];

export function toolsForRole(role) {
  const names = role === "team" ? TEAM_TOOLS : CUSTOMER_TOOLS;
  return {
    schemas: names.map((n) => schemas[n]),
    isAllowed: (name) => names.includes(name),
  };
}

export async function runTool(name, args, ctx) {
  const handler = handlers[name];
  if (!handler) return { error: `Unknown tool "${name}".` };
  return handler(args, ctx);
}

export { listPhotoFiles };
