import "dotenv/config";

/**
 * Central configuration for the company WhatsApp bot.
 *
 * Everything a non-developer needs to change lives here (or in the .env file).
 * Edit the strings below, drop your images into the ./media folder, list your
 * colleagues in contacts.json, and you are done.
 */

const list = (value) =>
  String(value || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);

export const config = {
  // Shown to the operator on startup and used in customer-facing copy.
  companyName: process.env.COMPANY_NAME || "Payfonte",

  // Business hours are informational — used in replies only.
  businessHours: process.env.BUSINESS_HOURS || "Mon–Fri, 9am–6pm",

  // Human handoff text shown when a customer asks for a person.
  humanContact:
    process.env.HUMAN_CONTACT || "a team member will reply here as soon as possible",

  // How long (ms) to stay quiet after greeting a customer, so we don't spam
  // the same welcome message on every single line they type.
  greetingCooldownMs: Number(process.env.GREETING_COOLDOWN_MS) || 6 * 60 * 60 * 1000,

  // Only reply in 1:1 chats by default. Set to true to also answer in groups.
  respondInGroups: process.env.RESPOND_IN_GROUPS === "true",

  // Folder (relative to the bot) where catalog photos live.
  mediaDir: "media",

  // Country code prepended to local numbers written as "0801...".
  // 234 = Nigeria. Change to your primary market.
  defaultCountryCode: process.env.DEFAULT_COUNTRY_CODE || "234",

  // ---------------------------------------------------------------- AI agent

  // ChatGPT powers the "do what I ask" behaviour. Without a key the bot still
  // runs, falling back to simple keyword auto-replies.
  openaiApiKey: process.env.OPENAI_API_KEY || "",

  // Any chat model your OpenAI account can access.
  openaiModel: process.env.OPENAI_MODEL || "gpt-5",

  // Max tool-calling rounds per message before the agent gives up. Raise for
  // longer multi-step jobs; each step is one model call.
  maxAgentSteps: Number(process.env.MAX_AGENT_STEPS) || 8,

  // Conversation turns kept in memory per chat.
  maxHistoryMessages: Number(process.env.MAX_HISTORY_MESSAGES) || 30,

  // Let customers (non-team numbers) talk to the AI too. They get a strictly
  // limited tool set — they can never cause a message to a third party.
  aiForCustomers: process.env.AI_FOR_CUSTOMERS !== "false",

  // ------------------------------------------------------------ authorization

  /**
   * TEAM ALLOWLIST — the security boundary of this bot.
   *
   * Only these numbers can tell the bot to message other people. Everyone
   * else is treated as a customer and gets the safe, reply-only assistant.
   * Comma-separated, any format: "+234801...,08012345678".
   *
   * Leave empty and NOBODY gets send-to-anyone powers.
   */
  teamNumbers: list(process.env.TEAM_NUMBERS),

  // Where handoff alerts go (a manager's number or an internal group id).
  escalationChatId: process.env.ESCALATION_CHAT_ID || "",

  // ------------------------------------------------------------- safety rails

  // Ask a human to reply YES before any message goes to a third party.
  // Strongly recommended. Set to "false" for a fully hands-off bot.
  requireConfirmation: process.env.REQUIRE_CONFIRMATION !== "false",

  // How long a staged send waits for a YES before expiring.
  confirmTimeoutMs: Number(process.env.CONFIRM_TIMEOUT_MS) || 10 * 60 * 1000,

  // Hard ceiling on outbound messages per rolling hour, across all chats.
  maxSendsPerHour: Number(process.env.MAX_SENDS_PER_HOUR) || 60,

  // Max recipients in a single send instruction.
  maxRecipientsPerSend: Number(process.env.MAX_RECIPIENTS_PER_SEND) || 10,

  // Throughput controls for handling many conversations at once.
  concurrency: Number(process.env.CONCURRENCY) || 8,
  maxQueuePerChat: Number(process.env.MAX_QUEUE_PER_CHAT) || 10,

  // Separate send budgets by kind — see src/outbox.js for why one shared
  // limit does not work.
  maxRepliesPerHour: Number(process.env.MAX_REPLIES_PER_HOUR) || 2000,
  maxInternalPerHour: Number(process.env.MAX_INTERNAL_PER_HOUR) || 200,

  // How many times one colleague can be paged per hour before the rest are
  // batched into a digest instead.
  maxEscalationsPerHour: Number(process.env.MAX_ESCALATIONS_PER_HOUR) || 15,
  digestIntervalMs: Number(process.env.DIGEST_INTERVAL_MS) || 15 * 60 * 1000,

  // Sign relayed answers with the colleague's name.
  signRelayedReplies: process.env.SIGN_RELAYED_REPLIES !== "false",

  // Optional backend for check_reference (order/transaction lookups).
  lookupApiUrl: process.env.LOOKUP_API_URL || "",
  lookupApiKey: process.env.LOOKUP_API_KEY || "",

  /**
   * Connected external systems the bot can push to ("send this to Slack").
   *
   * Named targets only — the AI picks a name, never a URL, so it cannot be
   * talked into posting company data to an arbitrary host. Add your own:
   *   myapp: process.env.MYAPP_WEBHOOK_URL
   */
  webhooks: Object.fromEntries(
    Object.entries({
      slack: process.env.SLACK_WEBHOOK_URL,
      internal: process.env.INTERNAL_WEBHOOK_URL,
    }).filter(([, url]) => Boolean(url))
  ),
};

/**
 * The product / info catalog.
 *
 * Each entry maps customer keywords -> a photo + caption. When a customer's
 * message contains any of the `keywords`, the bot sends `photo` with `caption`.
 * The AI can also send any of these by `id`. Put the images in ./media.
 */
export const catalog = [
  {
    id: "catalog",
    keywords: ["catalog", "catalogue", "products", "menu", "price", "prices", "pricelist"],
    photo: "catalog.jpg",
    caption:
      "Here is our current catalog 📋\nReply with the name of any item for more photos and pricing.",
  },
  {
    id: "location",
    keywords: ["location", "address", "where", "directions", "map"],
    photo: "location.jpg",
    caption: "📍 Here's how to find us. We look forward to seeing you!",
  },
];

/**
 * Simple keyword auto-replies used when the AI is switched off or unavailable.
 */
export const textReplies = [
  {
    keywords: ["hours", "open", "opening", "closed", "time"],
    reply: () => `We're open ${config.businessHours}. 🕘`,
  },
  {
    keywords: ["delivery", "shipping", "deliver", "ship"],
    reply: () =>
      "🚚 We offer delivery! Share your address and the item you'd like, and we'll confirm the cost and timing.",
  },
  {
    keywords: ["thanks", "thank you", "thankyou", "cheers"],
    reply: () => "You're welcome! 😊 Let us know if there's anything else.",
  },
];
