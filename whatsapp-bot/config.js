import "dotenv/config";

/**
 * Central configuration for the company WhatsApp bot.
 *
 * Everything a non-developer needs to change to run the bot for their own
 * company lives here (or in the .env file). Edit the strings below, drop your
 * images into the ./media folder, and you are done.
 */

export const config = {
  // Shown to the operator on startup. Purely cosmetic.
  companyName: process.env.COMPANY_NAME || "Acme Company",

  // Business hours are informational — used in the auto-reply text only.
  businessHours: process.env.BUSINESS_HOURS || "Mon–Fri, 9am–6pm",

  // Human handoff number/instructions shown when a customer asks for a person.
  humanContact:
    process.env.HUMAN_CONTACT || "a team member will reply here as soon as possible",

  // How long (ms) to stay quiet after greeting a customer, so we don't spam
  // the same welcome message on every single line they type.
  greetingCooldownMs: Number(process.env.GREETING_COOLDOWN_MS) || 6 * 60 * 60 * 1000,

  // Only reply in 1:1 chats by default. Set to true to also answer in groups.
  respondInGroups: process.env.RESPOND_IN_GROUPS === "true",

  // Folder (relative to the bot) where catalog photos live.
  mediaDir: "media",
};

/**
 * The product / info catalog.
 *
 * Each entry maps customer keywords -> a photo + caption. When a customer's
 * message contains any of the `keywords`, the bot sends `photo` with `caption`.
 * Put the matching image files in the ./media folder.
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
 * Simple keyword auto-replies (text only, no photo).
 * Checked after the catalog. First match wins.
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
