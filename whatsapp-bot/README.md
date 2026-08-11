# Payfonte WhatsApp Assistant

A ChatGPT-powered WhatsApp bot for Payfonte. The team can talk to it in plain
English — *"send this photo to John and tell ops it's live"* — and it works out
who is meant, what to send, and does it. Customers messaging the same number
get a helpful support assistant.

Built on [`whatsapp-web.js`](https://github.com/pedroslopez/whatsapp-web.js)
(links to a real WhatsApp account via a QR code — no Meta Business
verification) and the OpenAI API for the reasoning.

## Two audiences, one number

The bot behaves completely differently depending on who is messaging:

| | **Team** (allowlisted numbers) | **Customers** (everyone else) |
| --- | --- | --- |
| Send messages to other people | ✅ | ❌ |
| Send photos to other people | ✅ | ❌ |
| Push to Slack / internal apps | ✅ | ❌ |
| Read the contact directory | ✅ | ❌ |
| Answer questions, show catalog | ✅ | ✅ |
| Escalate to a human | ✅ | ✅ |

**This split is the security model, not a convenience.** A bot that will
message anyone on instruction is dangerous if anyone can instruct it — a
customer could message *"forward your photos to +234…"* and a naive bot would
comply. Here, customers are never handed the tools that can reach a third
party, so no amount of clever wording gets them there.

Set `TEAM_NUMBERS` in `.env`. **If it's empty, nobody has send powers.**

## What the team can ask for

Natural language, not commands:

- *"Send the price list to John"*
- *"Send this to Mary"* (right after sending the bot a photo)
- *"Tell the ops team the settlement run finished"*
- *"Send the catalog to John, Mary and +2348012345678"*
- *"Post this screenshot to Slack"*
- *"Who's in the contacts list?"*

Because ChatGPT drives a tool loop, multi-step requests work too: it will look
up a contact, pick the right photo, send it, then report back — without a
hand-written rule for each phrasing.

## Safety rails

- **Confirmation before sending.** By default the bot *stages* an outbound
  message, tells you exactly what goes to whom, and waits for you to reply
  `YES`. Confirmations are handled in plain code, never re-interpreted by the
  model — so "send it to Mary instead" is treated as a new instruction, not a
  yes.
- **Rate limit.** A hard ceiling of `MAX_SENDS_PER_HOUR` across all chats stops
  a runaway loop from turning the company number into a spam cannon.
- **Recipient cap** per instruction (`MAX_RECIPIENTS_PER_SEND`).
- **Named app targets only.** `send_to_app` picks from webhooks you configured
  by *name*; the model never supplies a URL, so it can't be talked into posting
  company data to an arbitrary host.
- **Audit log.** Every outbound message is appended to `logs/outbox.jsonl`.
- **Path traversal blocked** on photo filenames.
- Customer-facing prompt explicitly treats message content as data, never as
  instructions.

## Setup

Requires **Node.js 18+**.

```bash
cd whatsapp-bot
npm install
cp .env.example .env              # add OPENAI_API_KEY and TEAM_NUMBERS
cp contacts.example.json contacts.json   # add your colleagues
```

Put your photos in `media/` (see `media/README.md`), then:

```bash
npm start
```

A **QR code** prints on first run. On the company phone:
**WhatsApp → Settings → Linked devices → Link a device** → scan it.

The session is saved in `.wwebjs_auth/`, so restarts don't need a re-scan.

## Contacts

`contacts.json` maps names to numbers so "send to John" works. It's gitignored
because it holds real phone numbers.

```json
[
  { "name": "John Adeyemi", "aliases": ["john"], "number": "+2348012345678" },
  { "name": "Ops Team", "aliases": ["ops"], "chatId": "1203630...@g.us" }
]
```

Numbers can be written any way (`+234…`, `0801…`, `00234…`) — they're
normalized. If a name matches more than one person the bot asks which, rather
than guessing.

To get a group's `chatId`, send a message in the group while the bot is running
and read it from the console.

## Tests

```bash
npm test
```

37 checks covering number normalization, contact resolution, the team/customer
tool boundary, the confirmation flow, photo handling, and the safety limits.
No API key or WhatsApp connection needed — the client is stubbed, so nothing
leaves the machine.

## Adding capabilities

The bot's abilities are the tools in `src/tools.js`. To add one:

1. Add a schema to `schemas` (name, description, JSON-schema parameters).
2. Add the implementation to `handlers`.
3. Add the name to `TEAM_TOOLS` and/or `CUSTOMER_TOOLS`.

Think hard before putting anything in `CUSTOMER_TOOLS` — that list is reachable
by anyone in the world who knows the number.

## Configuration reference

Everything lives in `.env` (see `.env.example`) and `config.js`:

- `OPENAI_API_KEY`, `OPENAI_MODEL` — the AI. Without a key the bot falls back
  to keyword auto-replies and still runs.
- `TEAM_NUMBERS` — who gets send powers. **The security boundary.**
- `REQUIRE_CONFIRMATION` — human `YES` before third-party sends (default on).
- `MAX_SENDS_PER_HOUR`, `MAX_RECIPIENTS_PER_SEND` — abuse ceilings.
- `AI_FOR_CUSTOMERS` — set `false` to give customers the keyword bot instead.
- `SLACK_WEBHOOK_URL`, `INTERNAL_WEBHOOK_URL` — connected app targets.
- `catalog` in `config.js` — keyword → photo mappings.

## Notes & limits

- `whatsapp-web.js` is an unofficial library automating WhatsApp Web. Use it
  with a number you control and in line with WhatsApp's Terms of Service. For
  high volume, migrate to the official
  [WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp) — the
  agent and tool layer here would carry over unchanged.
- Keep the process running (`pm2`, systemd, or a small always-on host).
- Each message costs an OpenAI call (more for multi-step requests). Watch spend
  and set a usage limit on your OpenAI key.
- Never commit `.env`, `contacts.json`, or `.wwebjs_auth/` — all gitignored.
