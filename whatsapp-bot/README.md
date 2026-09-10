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
| Search the knowledge base | ✅ | ✅ |
| Escalate to the right colleague | ✅ | ✅ |
| Answer escalated tickets | ✅ | ❌ |

**This split is the security model, not a convenience.** A bot that will
message anyone on instruction is dangerous if anyone can instruct it — a
customer could message *"forward your photos to +234…"* and a naive bot would
comply. Here, customers are never handed the tools that can reach a third
party, so no amount of clever wording gets them there.

Set `TEAM_NUMBERS` in `.env`. **If it's empty, nobody has send powers.**

## When the bot doesn't know: it asks a colleague

This is the core loop. A customer asks something the knowledge base doesn't
cover, and instead of guessing or stalling:

1. The agent searches the knowledge base. No good match.
2. It opens a **ticket** and works out which department handles it.
3. It **messages that colleague on WhatsApp** with the customer's question,
   what they need, and the ticket id.
4. It tells the customer their request is with the team.
5. The colleague replies — *"reply to T-12345601 yes, USD settlement is
   available on request"* — and the answer is **relayed straight into the
   customer's own chat**, signed with their name. The ticket closes.

Routing comes from `departments` in `contacts.json`:

```json
{ "name": "Mary Okonkwo", "number": "0808...", "departments": ["billing", "accounts"] }
```

Unknown department falls back to `general`, then to `ESCALATION_CHAT_ID`, so
an escalation is never silently lost. If one colleague gets paged more than
`MAX_ESCALATIONS_PER_HOUR`, the rest are batched into a periodic digest rather
than burying them — a single confusing product change can make hundreds of
customers ask the same thing at once.

**The agent is told never to invent an answer.** Fees, settlement times,
policies, anything about a specific account: if the knowledge base doesn't
cover it, escalating is the correct move, not a failure. A wrong answer about
money is far worse than "let me get someone who knows."

## What the bot can do

**For customers** — answer from the knowledge base, show catalog/price/location
photos, capture their name and email, log a callback request, look up a
transaction reference (if you connect a backend), and escalate to the right
colleague.

**For the team** — everything above, plus: send texts and photos to anyone by
name, message several people at once, push to Slack or an internal service,
list and answer open tickets, and check bot health with `/stats`.

Natural language, not commands:

- *"Send the price list to John"*
- *"Send this to Mary"* (right after sending the bot a photo)
- *"Tell the ops team the settlement run finished"*
- *"Post this screenshot to Slack"*
- *"What tickets are open?"*
- *"Reply to T-12345601: yes, that's supported"*

## Built for volume

- **Per-chat ordering.** Two messages from the same person are handled in
  sequence, so they can't interleave and confuse the conversation history.
- **Parallel across chats**, capped by `CONCURRENCY` — a thousand waiting
  customers don't open a thousand simultaneous OpenAI calls.
- **Per-chat queue depth limit**, so one flooding number can't consume the
  worker pool.
- **Deduplication** of redelivered message ids after a reconnect.
- **Separate send budgets** for replies / internal pages / third-party
  outreach. One shared limit would either block replies on a busy support day
  or leave outreach unguarded.
- Idle chats are released from memory, so a long-running bot doesn't grow an
  entry per customer forever (there's a regression test for this).

Measured on the queue layer: 2,000 messages across 500 chats, none dropped,
none out of order.

## Knowledge base

`knowledge.json` holds the answers the agent is allowed to give — this is what
grounds it. Copy `knowledge.example.json` (pre-filled with payments-company
FAQs: fees, settlement, KYC, refunds, coverage) and edit.

```json
{ "question": "What are your fees?", "answer": "1.5% per transaction…", "tags": ["fees", "pricing"] }
```

Search is term-overlap with tag weighting — no embeddings, no extra service.
Tags are how you catch synonyms ("charge", "cost", "rates" → fees).

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

67 checks covering number normalization, contact resolution, the team/customer
tool boundary, the confirmation flow, photo handling, knowledge-base search,
the full escalation round-trip (customer stumps the bot → colleague is paged →
their answer reaches the customer), queue ordering, flood shedding, and the
safety limits.

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
- `MAX_REPLIES_PER_HOUR` / `MAX_INTERNAL_PER_HOUR` / `MAX_SENDS_PER_HOUR` —
  separate budgets for replies, colleague pages, and third-party outreach.
- `CONCURRENCY`, `MAX_QUEUE_PER_CHAT` — throughput and flood shedding.
- `MAX_ESCALATIONS_PER_HOUR` — before a colleague's alerts become a digest.
- `LOOKUP_API_URL` — connect a backend for transaction/order lookups.
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
