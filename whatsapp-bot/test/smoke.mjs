/**
 * Smoke tests for the bot's logic layer.
 *
 * Runs without an OpenAI key and without a WhatsApp connection: the client is
 * stubbed, so every send is captured in-memory instead of leaving the machine.
 *
 *   npm test
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");

// --- Environment must be set BEFORE importing config.js. -------------------
process.env.COMPANY_NAME = "Payfonte";
process.env.TEAM_NUMBERS = "+2348011111111,08022222222";
process.env.DEFAULT_COUNTRY_CODE = "234";
process.env.REQUIRE_CONFIRMATION = "true";
process.env.MAX_SENDS_PER_HOUR = "60";
process.env.SLACK_WEBHOOK_URL = "https://hooks.example.com/test";

// --- Fixtures --------------------------------------------------------------
const contactsFile = path.join(root, "contacts.json");
const testPhoto = path.join(root, "media", "_test_photo.png");
const createdContacts = !fs.existsSync(contactsFile);
if (createdContacts) {
  fs.copyFileSync(path.join(root, "contacts.example.json"), contactsFile);
}
fs.mkdirSync(path.join(root, "media"), { recursive: true });
fs.writeFileSync(testPhoto, Buffer.from("89504e470d0a1a0a", "hex"));

let passed = 0;
const failures = [];
function check(name, fn) {
  try {
    fn();
    passed++;
    console.log(`  ✓ ${name}`);
  } catch (err) {
    failures.push({ name, err });
    console.log(`  ✗ ${name}\n      ${err.message}`);
  }
}

try {
  const { config } = await import("../config.js");
  const contacts = await import("../src/contacts.js");
  const outbox = await import("../src/outbox.js");
  const tools = await import("../src/tools.js");
  const tickets = await import("../src/tickets.js");

  // Capture sends instead of transmitting them.
  const sent = [];
  outbox.attachClient({
    async sendMessage(chatId, content, opts = {}) {
      sent.push({ chatId, content, opts });
    },
  });

  console.log("\nphone number normalization");
  check("international format", () =>
    assert.equal(contacts.toChatId("+234 801 234 5678"), "2348012345678@c.us")
  );
  check("local 0-prefixed gets country code", () =>
    assert.equal(contacts.toChatId("08012345678"), "2348012345678@c.us")
  );
  check("00 prefix stripped", () =>
    assert.equal(contacts.toChatId("002348012345678"), "2348012345678@c.us")
  );
  check("existing chat id passes through", () =>
    assert.equal(contacts.toChatId("2348012345678@c.us"), "2348012345678@c.us")
  );
  check("group id passes through", () =>
    assert.equal(contacts.toChatId("12036300000@g.us"), "12036300000@g.us")
  );
  check("junk rejected", () => assert.equal(contacts.toChatId("hello"), null));
  check("too-short number rejected", () => assert.equal(contacts.toChatId("123"), null));

  console.log("\ncontact resolution");
  check("resolves by alias", () => {
    const r = contacts.resolveRecipient("john");
    assert.equal(r.chatId, "2348012345678@c.us");
    assert.equal(r.label, "John Adeyemi");
  });
  check("resolves a group by alias", () => {
    const r = contacts.resolveRecipient("ops");
    assert.ok(r.chatId.endsWith("@g.us"), `got ${r.chatId}`);
  });
  check("resolves a raw number not in directory", () => {
    const r = contacts.resolveRecipient("+2349099999999");
    assert.equal(r.chatId, "2349099999999@c.us");
  });
  check("unknown name errors instead of guessing", () => {
    const r = contacts.resolveRecipient("Zebediah");
    assert.ok(r.error, "expected an error");
    assert.equal(r.chatId, undefined);
  });

  console.log("\nrole scoping (the security boundary)");
  const teamTools = tools.toolsForRole("team");
  const custTools = tools.toolsForRole("customer");
  const names = (t) => t.schemas.map((s) => s.function.name);
  check("team can send to third parties", () =>
    assert.ok(names(teamTools).includes("send_text"))
  );
  check("customer CANNOT send text to third parties", () =>
    assert.ok(!names(custTools).includes("send_text"))
  );
  check("customer CANNOT send photos to third parties", () =>
    assert.ok(!names(custTools).includes("send_photo"))
  );
  check("customer CANNOT reach external apps", () =>
    assert.ok(!names(custTools).includes("send_to_app"))
  );
  check("customer CANNOT read the contact directory", () => {
    assert.ok(!names(custTools).includes("list_contacts"));
    assert.ok(!names(custTools).includes("find_contact"));
  });
  check("isAllowed rejects out-of-scope tool for customer", () =>
    assert.equal(custTools.isAllowed("send_text"), false)
  );

  console.log("\nsending + confirmation flow");
  const teamCtx = {
    chatId: "2348011111111@c.us",
    role: "team",
    senderLabel: "Tester",
    lastMedia: null,
  };

  check("send_text stages instead of sending immediately", async () => {});
  const staged = await tools.runTool(
    "send_text",
    { to: ["john"], message: "Invoice is ready" },
    teamCtx
  );
  check("send_text returns awaiting_confirmation", () =>
    assert.equal(staged.status, "awaiting_confirmation")
  );
  check("nothing left the bot before confirmation", () =>
    assert.equal(sent.length, 0)
  );

  const pendingAction = outbox.peekPending(teamCtx.chatId);
  check("action is staged for the right recipient", () => {
    assert.ok(pendingAction, "expected a pending action");
    assert.equal(pendingAction.targets[0].label, "John Adeyemi");
    assert.equal(pendingAction.body, "Invoice is ready");
  });

  check("'yes' is recognized as confirmation", () =>
    assert.ok(outbox.isAffirmative("yes"))
  );
  check("'cancel' is recognized as a refusal", () =>
    assert.ok(outbox.isNegative("cancel"))
  );
  check("unrelated text is neither", () => {
    assert.ok(!outbox.isAffirmative("send it to Mary instead"));
    assert.ok(!outbox.isNegative("send it to Mary instead"));
  });

  await outbox.executePending(pendingAction);
  check("message is delivered after confirmation", () => {
    assert.equal(sent.length, 1);
    assert.equal(sent[0].chatId, "2348012345678@c.us");
    assert.equal(sent[0].content, "Invoice is ready");
  });

  console.log("\nphoto handling");
  const photoRes = await tools.runTool(
    "send_photo",
    { to: ["john"], photo: "_test_photo.png", caption: "here" },
    teamCtx
  );
  check("known photo stages successfully", () =>
    assert.equal(photoRes.status, "awaiting_confirmation")
  );

  const missing = await tools.runTool(
    "send_photo",
    { to: ["john"], photo: "does-not-exist.jpg" },
    teamCtx
  );
  check("missing photo returns a helpful error", () => {
    assert.ok(missing.error);
    assert.match(missing.error, /No photo named/);
  });

  const traversal = await tools.runTool(
    "send_photo",
    { to: ["john"], photo: "../../../../etc/passwd" },
    teamCtx
  );
  check("path traversal is refused", () => {
    assert.ok(traversal.error, "expected traversal to be rejected");
  });

  const noMedia = await tools.runTool(
    "send_photo",
    { to: ["john"], photo: "last_received" },
    { ...teamCtx, lastMedia: null }
  );
  check("'last_received' with no photo errors cleanly", () =>
    assert.match(noMedia.error, /No photo has been sent/)
  );

  const withMedia = await tools.runTool(
    "send_photo",
    { to: ["john"], photo: "last_received" },
    { ...teamCtx, lastMedia: { mimetype: "image/png", data: "AAAA" } }
  );
  check("'last_received' works when a photo was received", () =>
    assert.equal(withMedia.status, "awaiting_confirmation")
  );

  console.log("\ncustomer path stays in its own chat");
  const custCtx = {
    chatId: "2349055555555@c.us",
    role: "customer",
    senderLabel: "Customer",
    lastMedia: null,
  };
  const before = sent.length;
  const replied = await tools.runTool(
    "reply_with_photo",
    { photo: "_test_photo.png", caption: "our catalog" },
    custCtx
  );
  check("reply_with_photo sends to the customer's own chat", () => {
    assert.equal(replied.status, "sent");
    assert.equal(sent.length, before + 1);
    assert.equal(sent[sent.length - 1].chatId, custCtx.chatId);
  });

  console.log("\nexternal app targets");
  const badTarget = await tools.runTool(
    "send_to_app",
    { target: "https://evil.example.com/steal", message: "data" },
    teamCtx
  );
  check("arbitrary URLs are refused (named targets only)", () => {
    assert.ok(badTarget.error);
    assert.match(badTarget.error, /Unknown app target/);
  });
  check("configured target is recognized", () =>
    assert.ok(Object.keys(config.webhooks).includes("slack"))
  );

  console.log("\nrecipient limits");
  const tooMany = await tools.runTool(
    "send_text",
    { to: Array(50).fill("+2349099999999"), message: "spam" },
    teamCtx
  );
  check("recipient cap is enforced", () => {
    assert.ok(tooMany.error);
    assert.match(tooMany.error, /Too many recipients/);
  });

  console.log("\nknowledge base");
  const kb = await import("../src/knowledge.js");
  check("finds a relevant answer", () => {
    const hits = kb.searchKnowledge("what are your fees?");
    assert.ok(hits.length > 0, "expected a match");
    assert.match(hits[0].answer, /1\.5%/);
  });
  check("matches on synonyms via tags", () => {
    const hits = kb.searchKnowledge("how much do you charge");
    assert.ok(hits.length > 0, "expected a match for 'charge'");
  });
  check("returns nothing for an unrelated question", () => {
    const hits = kb.searchKnowledge("do you sell bicycles in Antarctica");
    assert.equal(hits.length, 0);
  });
  check("exposes topics", () => assert.ok(kb.allTopics().length > 5));

  console.log("\nescalation: agent doesn't know -> colleague is messaged");
  const custCtx2 = {
    chatId: "2349077777777@c.us",
    role: "customer",
    senderLabel: "Ada",
    lastMedia: null,
    currentMessage: "Can I settle directly to a US dollar account?",
  };
  const beforeEsc = sent.length;
  const esc = await tools.runTool(
    "escalate_to_team",
    { department: "billing", summary: "Wants USD settlement", urgency: "normal" },
    custCtx2
  );
  check("ticket is created", () => assert.ok(esc.ticketId, JSON.stringify(esc)));
  check("routed to the billing owner", () => assert.equal(esc.owner, "Mary Okonkwo"));
  check("colleague was actually messaged", () => {
    assert.equal(esc.notified, true);
    assert.equal(sent.length, beforeEsc + 1);
    const note = sent[sent.length - 1];
    assert.equal(note.chatId, "2348087654321@c.us");
    assert.match(note.content, /Customer needs help/);
    assert.match(note.content, /Wants USD settlement/);
    assert.match(note.content, /USD? dollar account/i);
  });
  check("notification tells them how to answer", () =>
    assert.match(sent[sent.length - 1].content, new RegExp(`reply to ${esc.ticketId}`, "i"))
  );

  console.log("\nescalation: colleague's answer is relayed to the customer");
  const beforeRelay = sent.length;
  const relayed = await tickets.replyToTicket(
    esc.ticketId,
    "Yes — USD settlement is available on request.",
    "Mary Okonkwo"
  );
  check("relay reports success", () => assert.equal(relayed.ok, true));
  check("customer receives the answer in their own chat", () => {
    assert.equal(sent.length, beforeRelay + 1);
    const reply = sent[sent.length - 1];
    assert.equal(reply.chatId, custCtx2.chatId);
    assert.match(reply.content, /USD settlement is available/);
  });
  check("reply is signed by the colleague", () =>
    assert.match(sent[sent.length - 1].content, /Mary Okonkwo/)
  );
  check("ticket is closed after answering", () =>
    assert.equal(tickets.getTicket(esc.ticketId), null)
  );
  check("replying to an unknown ticket errors", async () => {});
  const badTicket = await tickets.replyToTicket("T-999999", "hi", "Someone");
  check("unknown ticket is refused", () => assert.ok(badTicket.error));

  console.log("\nescalation routing fallbacks");
  check("unknown department falls back to general", () => {
    const owner = tickets.routeToOwner("astrophysics");
    assert.ok(!owner.error, JSON.stringify(owner));
    assert.equal(owner.matched, "general");
  });
  check("known departments are discoverable", () => {
    const depts = tickets.knownDepartments();
    assert.ok(depts.includes("billing"), depts.join(","));
  });

  console.log("\ncustomer cannot choose who gets messaged");
  const custTools2 = tools.toolsForRole("customer");
  check("customer has escalate but not send_text", () => {
    assert.ok(custTools2.names.includes("escalate_to_team"));
    assert.ok(!custTools2.names.includes("send_text"));
    assert.ok(!custTools2.names.includes("reply_to_customer"));
  });
  check("customer cannot list or close tickets", () => {
    assert.ok(!custTools2.names.includes("list_open_tickets"));
    assert.ok(!custTools2.names.includes("close_ticket"));
  });
  check("escalate takes no recipient argument at all", () => {
    const schema = custTools2.schemas.find((s) => s.function.name === "escalate_to_team");
    const props = Object.keys(schema.function.parameters.properties);
    assert.deepEqual(props.sort(), ["department", "summary", "urgency"]);
  });

  console.log("\nsend budgets are separate");
  check("replies and outreach have different ceilings", () => {
    const b = outbox.budget();
    assert.ok(b.reply.limit > b.outreach.limit,
      `reply ${b.reply.limit} should exceed outreach ${b.outreach.limit}`);
  });

  console.log("\nqueue: ordering and concurrency");
  const { createQueue, createDeduper } = await import("../src/queue.js");
  const order = [];
  const q = createQueue({ concurrency: 4, maxDepthPerChat: 3 });
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  await Promise.all([
    q.enqueue("chatA", async () => { await sleep(20); order.push("A1"); }),
    q.enqueue("chatA", async () => { await sleep(1); order.push("A2"); }),
    q.enqueue("chatB", async () => { await sleep(1); order.push("B1"); }),
  ]);
  check("same chat runs in order despite differing durations", () => {
    assert.ok(order.indexOf("A1") < order.indexOf("A2"),
      `expected A1 before A2, got ${order.join(",")}`);
  });
  check("different chats run in parallel", () => {
    assert.ok(order.includes("B1"));
    assert.ok(order.indexOf("B1") < order.indexOf("A2"),
      `B should not wait behind A: ${order.join(",")}`);
  });

  const flood = [];
  for (let i = 0; i < 8; i++) {
    flood.push(q.enqueue("flooder", async () => { await sleep(5); }).catch((e) => e.message));
  }
  const floodResults = await Promise.all(flood);
  check("one chat cannot flood the worker pool", () =>
    assert.ok(floodResults.some((r) => r === "chat_queue_full"),
      "expected some messages to be shed")
  );

  check("a failing job does not break the chat's queue", async () => {});
  const after = [];
  await q.enqueue("chatC", async () => { throw new Error("boom"); }).catch(() => {});
  await q.enqueue("chatC", async () => { after.push("ran"); });
  check("later messages still process after a failure", () =>
    assert.deepEqual(after, ["ran"])
  );

  // Regression: the chat->promise map must drain as chats go idle, or a
  // long-running bot accumulates one entry per customer forever.
  const leakQ = createQueue({ concurrency: 8, maxDepthPerChat: 50 });
  await Promise.all(
    Array.from({ length: 200 }, (_, i) =>
      leakQ.enqueue(`leak${i}`, async () => { await sleep(1); })
    )
  );
  await new Promise((r) => setImmediate(r));
  check("idle chats are released (no unbounded memory growth)", () =>
    assert.equal(leakQ.stats().chats, 0,
      `${leakQ.stats().chats} chat chains leaked`)
  );

  console.log("\ndeduplication");
  const dedupe = createDeduper();
  check("first sighting is not a duplicate", () => assert.equal(dedupe("msg1"), false));
  check("second sighting is a duplicate", () => assert.equal(dedupe("msg1"), true));
  check("different id is not a duplicate", () => assert.equal(dedupe("msg2"), false));
  check("missing id is never a duplicate", () => assert.equal(dedupe(undefined), false));

  console.log("\nagent module");
  const agent = await import("../src/agent.js");
  check("agent reports disabled without an API key", () =>
    assert.equal(agent.isAgentEnabled(), Boolean(process.env.OPENAI_API_KEY))
  );
  check("keyword fallback still works", async () => {});
  const { buildResponses } = await import("../src/replies.js");
  check("keyword responder answers hours question", () => {
    const actions = buildResponses("what are your hours?", "x@c.us");
    assert.ok(actions.some((a) => a.type === "text" && /open/i.test(a.body)));
  });
} finally {
  fs.rmSync(testPhoto, { force: true });
  if (createdContacts) fs.rmSync(contactsFile, { force: true });
  fs.rmSync(path.join(root, "logs"), { recursive: true, force: true });
}

console.log(`\n${passed} passed, ${failures.length} failed\n`);
if (failures.length) process.exit(1);
