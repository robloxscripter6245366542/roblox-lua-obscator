# Company WhatsApp Bot

An automated WhatsApp assistant for a company. It **replies to customers**
and **sends photos** (catalog, price list, location, etc.) based on what the
customer asks.

Built on [`whatsapp-web.js`](https://github.com/pedroslopez/whatsapp-web.js),
so it uses a real WhatsApp account via **Linked Devices** — no Meta Business
verification, no monthly API fees. You scan a QR code once and it stays
logged in.

## What it does

- 👋 Greets new customers with a menu of what they can ask for.
- 🖼️ Sends photos on request (`catalog`, `location`, or anything you configure).
- 💬 Auto-replies to common questions (opening hours, delivery, thanks).
- 🙋 Hands off to a human when the customer asks for one.
- 🔁 Won't spam the welcome message — it's rate-limited per customer.
- 🧯 Fails safe: a missing photo file logs a warning instead of crashing.

## Setup

Requires **Node.js 18+**.

```bash
cd whatsapp-bot
npm install
cp .env.example .env      # then edit .env with your company details
```

Add your photos to the `media/` folder (see `media/README.md`), and edit
`config.js` to set your catalog items, keywords, and captions.

## Run

```bash
npm start
```

On first run a **QR code** prints in the terminal. On the phone with the
company WhatsApp:

> WhatsApp → **Settings → Linked devices → Link a device** → scan the QR code.

Once it prints `✅ … bot is online`, message the account from another phone to
test it. The login is saved in `.wwebjs_auth/`, so restarts don't need a
re-scan.

## Customizing

Everything a non-developer needs is in **`config.js`**:

- `companyName`, `businessHours`, `humanContact` — text shown to customers.
- `catalog` — keyword → photo + caption mappings (the photo-sending feature).
- `textReplies` — keyword → text-only auto-replies.
- `respondInGroups` — set to answer in group chats too (off by default).

The reply logic lives in `src/replies.js` if you want to change behavior.

## How it decides what to reply

For each incoming message, in order:

1. Asks for a **human** → hand-off message, stop.
2. Matches a **catalog** keyword → send that photo + caption.
3. Matches a **text reply** keyword → send that text.
4. Otherwise → the **welcome menu** (first time / after cooldown) or a short
   "didn't catch that" nudge.

## Notes & limits

- `whatsapp-web.js` is an unofficial library that automates WhatsApp Web.
  Use it with a number you control and in line with WhatsApp's Terms of
  Service. For high-volume or officially-supported messaging, migrate to the
  [WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp).
- Keep the process running (e.g. with `pm2`, a systemd service, or a small
  always-on host) so the bot stays online.
- Never commit your `.env` or `.wwebjs_auth/` folder — they're gitignored.
