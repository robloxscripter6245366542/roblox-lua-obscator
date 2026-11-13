// Vaultix Market — checkout, orders, profiles and wallet.
// Loaded after app.js and shares its helpers ($, esc, money, date, badge, state, gameTile, toast…).

const STATUS = {
  pending: ["Awaiting payment", "wait"],
  paid: ["Paid · awaiting delivery", "info"],
  delivered: ["Delivered · awaiting confirmation", "info"],
  completed: ["Completed", "ok"],
  disputed: ["Problem reported", "risk"],
  refunded: ["Refunded", "muted"],
  cancelled: ["Cancelled", "muted"],
};
const pill = (s) => { const [t, k] = STATUS[s] || [s, "muted"]; return `<span class="pill ${k}">${esc(t)}</span>`; };
const year = (t) => new Date(t).getFullYear();
const when = (t) => new Date(t).toLocaleString(undefined, { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
const r2 = (n) => Math.round(n * 100) / 100;
const feeFor = (price, method) => (method === "balance" ? 0 : r2(price * state.fees.pct + state.fees.fixed));
const avatarHtml = (u, cls = "") => `<span class="pavatar ${cls}">${esc((u.name || "?")[0].toUpperCase())}${u.verified ? `<span class="pv ok">✓</span>` : ""}</span>`;
function sellerChips(s) {
  return `<span class="chips">
    ${s.verified ? `<span class="chip-s ok">✓ Verified since ${year(s.verifiedAt || s.createdAt)}</span>` : `<span class="chip-s risk">! Risky · not verified</span>`}
    <span class="chip-s">👍 ${s.reviews ? `${s.positive}% positive` : "No ratings yet"}</span>
    <span class="chip-s">★ ${s.reviews || 0} review${s.reviews === 1 ? "" : "s"}</span>
    <span class="chip-s">${s.sales || 0} sale${s.sales === 1 ? "" : "s"}</span>
  </span>`;
}

/* ============================== router ============================== */
let page = null;
let poll = null;
function startRouter() { window.addEventListener("hashchange", route); route(); }
function route() {
  const [name, id] = location.hash.replace(/^#\/?/, "").split("?")[0].split("/");
  stopPoll();
  if (name === "wallet") {
    history.replaceState(null, "", location.pathname + location.search);
    page = null; showMarket();
    if (state.me) Market.stripeStatus().catch(() => {}).then(loadMe).then(() => openAccount("wallet"));
    return;
  }
  page = (name === "checkout" || name === "order") && id ? { name, id } : null;
  if (page) showPage(); else showMarket();
}
function showMarket() { $("#marketView").hidden = false; $("#pageView").hidden = true; }
function showPage() {
  closeDrawer();
  $("#marketView").hidden = true; $("#pageView").hidden = false;
  window.scrollTo({ top: 0 });
  if (page.name === "checkout") renderCheckout(); else renderOrder();
}
function rerenderPage() { if (page && page.name === "checkout") renderCheckout(); }
function stopPoll() { if (poll) { clearTimeout(poll); poll = null; } }

/* ============================== checkout ============================== */
let payMethod = "card";
const METHODS = [
  { id: "card", label: "Credit or debit card", api: "card", tags: ["VISA", "Mastercard", "AMEX", "Discover", "+ more"] },
  { id: "apple", label: "Apple Pay", api: "card", tags: ["Apple Pay"] },
  { id: "google", label: "Google Pay", api: "card", tags: ["Google Pay"] },
  { id: "crypto", label: "Cryptocurrency", api: "crypto", tags: ["USDC", "stablecoins"] },
  { id: "balance", label: "Vaultix balance", api: "balance", tags: [] },
];

function renderCheckout() {
  const l = state.listings.find((x) => x.id === page.id);
  const v = $("#pageView");
  if (!l) {
    v.innerHTML = `<a class="back" href="#/">← Back to market</a><section class="empty"><h2>This listing isn't available</h2><p>It sold out or the seller removed it.</p><a class="btn sell" href="#/">Browse the market</a></section>`;
    return;
  }
  const s = l.seller, mine = state.me && state.me.id === s.id;
  const m = METHODS.find((x) => x.id === payMethod) || METHODS[0];
  const fee = feeFor(l.price, m.api), total = r2(l.price + fee);
  const bal = state.wallet ? state.wallet.available : 0;
  v.innerHTML = `
    <a class="back" href="#/">← Back to market</a>
    <div class="co">
      <div class="co-main">
        <h1 class="page-title">Checkout</h1>
        <section class="panel">
          <div class="co-item">
            <span class="co-art">${cardArt(l)}</span>
            <div class="co-item-text">
              <p class="muted">${esc(l.game)} · ${esc(l.category)}</p>
              <h2>${esc(l.title)}</h2>
              <p class="muted small">Delivery: the seller delivers in your order chat · ${l.stock ?? 1} in stock</p>
            </div>
          </div>
          <div class="co-seller">
            <span class="muted">Seller</span>
            <button class="link-btn strong" data-user="${esc(s.id)}" type="button">@${esc(s.name)}</button>
            ${sellerChips(s)}
          </div>
        </section>
        ${s.verified ? "" : `
        <label class="warn check">
          <input type="checkbox" id="riskOk" />
          <span><b>This seller is not verified.</b> Nobody has checked who they are. Your money is held until you confirm delivery, but check everything before you confirm.</span>
        </label>`}
        <h2 class="sub">Payment method</h2>
        <div class="pm-list" role="radiogroup" aria-label="Payment method">
          ${METHODS.map((x) => {
            const disabled = x.id === "balance" && (!state.me || bal < r2(l.price));
            const extra = x.id === "balance" ? `<span class="muted small">${state.me ? `${money(bal)} available` : "Sign in to use"}</span>` : "";
            return `<label class="pm${payMethod === x.id ? " on" : ""}${disabled ? " is-disabled" : ""}">
              <input type="radio" name="pm" value="${x.id}" ${payMethod === x.id ? "checked" : ""} ${disabled ? "disabled" : ""} />
              <span class="pm-dot" aria-hidden="true"></span>
              <span class="pm-label">${x.label}${extra}</span>
              <span class="pm-tags">${x.tags.map((t) => `<span class="ptag">${t}</span>`).join("")}</span>
            </label>`;
          }).join("")}
        </div>
        <p class="secure">🔒 ${m.api === "balance" ? "Paid instantly from your Vaultix balance. No fee." : "You'll enter your payment details on Stripe's secure page. Vaultix never sees your card number."}</p>
      </div>
      <aside class="co-sum">
        <section class="panel sticky">
          <h2>Order summary</h2>
          <div class="sum-row"><span>Order price</span><b>${money(l.price)}</b></div>
          <div class="sum-row"><span>Payment fee <span class="tip" title="Covers card and payment processing. ${Math.round(state.fees.pct * 1000) / 10}% + ${money(state.fees.fixed)}. No fee when paying with your balance.">?</span></span><b>${money(fee)}</b></div>
          <div class="sum-row total"><span>Total</span><b>${money(total)}</b></div>
          <button class="btn pay wide" id="payBtn" type="button" ${mine ? "disabled" : ""}>🔒 ${mine ? "This is your listing" : `Pay ${money(total)}`}</button>
          <p class="form-err" id="payErr" role="alert"></p>
          <p class="muted small">By placing an order you agree that Vaultix holds your payment until you confirm delivery or staff settle a dispute.</p>
          <ul class="promise">
            <li><b>We don't pay the seller until you're happy.</b><span>Your money is held while the seller delivers.</span></li>
            <li><b>Not delivered? Get a refund.</b><span>Report a problem and staff will review the order.</span></li>
            <li><b>3 days to check your item.</b><span>After delivery the order confirms itself unless you report a problem.</span></li>
          </ul>
        </section>
      </aside>
    </div>`;
}

$("#pageView").addEventListener("change", (e) => {
  if (e.target.name === "pm") { payMethod = e.target.value; renderCheckout(); }
});
$("#pageView").addEventListener("click", async (e) => {
  if (e.target.closest("#payBtn")) return pay();
  const act = e.target.closest("[data-order-act]");
  if (act) return orderAction(act.dataset.orderAct, act);
});

async function pay() {
  const l = state.listings.find((x) => x.id === page.id);
  if (!l) return;
  const err = $("#payErr"); err.textContent = "";
  if (!state.me) return openJoin(() => { renderCheckout(); pay(); });
  if (!l.seller.verified && !($("#riskOk") || {}).checked) { err.textContent = "Tick the box to confirm you understand this seller isn't verified."; return; }
  if (!Market.canPay) { err.textContent = Market.NEEDS_SERVER; return; }
  const m = METHODS.find((x) => x.id === payMethod) || METHODS[0];
  const btn = $("#payBtn"); btn.disabled = true; btn.textContent = "Starting secure checkout…";
  try {
    const r = await Market.checkout(l.id, m.api);
    if (r.url) { location.href = r.url; return; } // Stripe hosted checkout
    await Promise.all([refresh(), loadMe()]);
    location.hash = `#/order/${r.orderId}`;
  } catch (ex) {
    err.textContent = ex.message; btn.disabled = false; btn.textContent = "Try again";
  }
}

/* ============================== order page ============================== */
let pollCount = 0;
async function renderOrder() {
  const v = $("#pageView");
  if (!state.me) {
    v.innerHTML = `<a class="back" href="#/">← Back to market</a><section class="empty"><h2>Sign in to see this order</h2><p>Orders are only visible to the buyer and the seller.</p></section>`;
    return;
  }
  let o;
  try { o = (await Market.order(page.id)).order; }
  catch (ex) { v.innerHTML = `<a class="back" href="#/">← Back to market</a><section class="empty"><h2>Order not found</h2><p>${esc(ex.message)}</p></section>`; return; }
  if (!page || page.id !== o.id) return;
  const buyer = o.role === "buyer";
  const other = buyer ? o.seller : o.buyer;
  const steps = ["paid", "delivered", "completed"];
  const reached = { pending: -1, paid: 0, delivered: 1, completed: 2, disputed: 1, refunded: -1, cancelled: -1 }[o.status];

  v.innerHTML = `
    <a class="back" href="#/">← Back to market</a>
    <div class="ord-head">
      <div><p class="muted mono">Order ${esc(o.id)} · ${date(o.createdAt)}</p><h1 class="page-title">${esc(o.title)}</h1></div>
      ${pill(o.status)}
    </div>
    ${["refunded", "cancelled"].includes(o.status) ? "" : `
    <ol class="steps">
      ${["Paid", "Delivered", "Completed"].map((t, i) => `<li class="${i <= reached ? "done" : ""}${i === reached + 1 && o.status !== "disputed" ? " now" : ""}"><span>${i + 1}</span>${t}</li>`).join("")}
    </ol>`}
    <div class="co">
      <div class="co-main">
        <section class="panel">${orderActions(o, buyer)}</section>
        ${o.delivery ? `<section class="panel"><h2>Delivery details</h2><pre class="delivery">${esc(o.delivery)}</pre><p class="muted small">Delivered ${when(o.deliveredAt)}</p></section>` : ""}
        ${o.review ? `<section class="panel"><h2>Buyer's review</h2><p>${o.review.positive ? "👍 Positive" : "👎 Negative"}${o.review.text ? ` — “${esc(o.review.text)}”` : ""}</p></section>` : ""}
        <section class="panel chat">
          <h2>Chat with @${esc(other ? other.name : "user")}</h2>
          <div class="msgs" id="msgs">${(o.messages || []).length
            ? o.messages.map((m) => `<div class="msg ${m.from === o.role ? "me" : ""}"><span class="msg-who">${m.from === o.role ? "You" : "@" + esc(other ? other.name : m.from)} · ${when(m.at)}</span><p>${esc(m.text)}</p></div>`).join("")
            : `<p class="muted small">No messages yet. ${o.status === "pending" ? "Chat opens once the order is paid." : "Say hi and agree on how the item is delivered."}</p>`}</div>
          ${["pending", "cancelled"].includes(o.status) ? "" : `
          <form class="chat-form" id="chatForm"><input name="text" maxlength="500" placeholder="Write a message…" autocomplete="off" required /><button class="btn sell" type="submit">Send</button></form>`}
        </section>
      </div>
      <aside class="co-sum">
        <section class="panel sticky">
          <h2>Summary</h2>
          <div class="co-item small">${gameTile(o.game)}<div><p class="muted small">${esc(o.game)} · ${esc(o.category)}</p><b>${esc(o.title)}</b></div></div>
          ${buyer ? `
            <div class="sum-row"><span>Order price</span><b>${money(o.price)}</b></div>
            <div class="sum-row"><span>Payment fee</span><b>${money(o.fee)}</b></div>
            <div class="sum-row total"><span>You paid</span><b>${money(o.total)}</b></div>
            <p class="muted small">Paid with ${o.method === "balance" ? "Vaultix balance" : o.method === "crypto" ? "crypto (Stripe)" : "card / wallet (Stripe)"}</p>`
          : `
            <div class="sum-row"><span>Sale price</span><b>${money(o.price)}</b></div>
            <div class="sum-row"><span>Vaultix fee (${Math.round(state.fees.commission * 100)}%)</span><b>−${money(o.commission)}</b></div>
            <div class="sum-row total"><span>You receive</span><b>${money(o.sellerNet)}</b></div>
            <p class="muted small">Added to your balance when the buyer confirms.</p>`}
          <div class="party">
            <span class="muted small">${buyer ? "Seller" : "Buyer"}</span>
            <button class="link-btn strong" data-user="${esc(other ? other.id : "")}" type="button">@${esc(other ? other.name : "deleted user")}</button>
            ${buyer && other ? badge(other, true) : ""}
            ${other && other.contact && o.status !== "pending" ? `<p class="muted small">Contact: <span class="mono">${esc(other.contact)}</span></p>` : ""}
          </div>
        </section>
      </aside>
    </div>`;

  // Waiting for Stripe's webhook after returning from checkout
  if (o.status === "pending" && buyer && pollCount < 24) {
    pollCount++;
    poll = setTimeout(() => { if (page && page.name === "order") renderOrder(); }, 2500);
  } else pollCount = 0;
  if (o.status !== "pending") { refresh(); loadMe(); }
}

function orderActions(o, buyer) {
  const auto = o.autoCompleteAt ? `<p class="muted small">If nothing is reported, this order confirms itself on ${when(o.autoCompleteAt)}.</p>` : "";
  const reviewForm = (label) => `
    <div class="rate" role="radiogroup" aria-label="Rate the seller">
      <label><input type="radio" name="rate" value="up" checked /> 👍 Positive</label>
      <label><input type="radio" name="rate" value="down" /> 👎 Negative</label>
    </div>
    <textarea id="reviewText" maxlength="300" rows="2" placeholder="Leave a short review (optional)"></textarea>
    <button class="btn sell" data-order-act="${label}" type="button">${label === "confirm" ? "Confirm & release payment" : "Post review"}</button>`;
  const problem = `<details class="problem"><summary>Report a problem</summary>
      <textarea id="disputeText" maxlength="500" rows="3" placeholder="What went wrong? Staff will read this and the chat."></textarea>
      <button class="btn danger" data-order-act="dispute" type="button">Report problem & hold payment</button></details>`;
  if (buyer) {
    switch (o.status) {
      case "pending": return `<h2>Waiting for payment…</h2><p class="muted">If you just paid, this page updates by itself in a few seconds.</p><button class="btn ghost" data-order-act="cancel" type="button">Cancel order</button>`;
      case "paid": return `<h2>The seller is preparing your order</h2><p class="muted">Your money is held by Vaultix. Use the chat below to give the seller anything they need (e.g. your username).</p>${problem}`;
      case "delivered": return `<h2>Did you get everything?</h2><p class="muted">Check the delivery details below. Confirming releases the money to the seller.</p>${reviewForm("confirm")}${problem}${auto}`;
      case "completed": return o.review ? `<h2>Order complete 🎉</h2><p class="muted">Thanks for your review.</p>` : `<h2>Order complete 🎉</h2><p class="muted">How was the seller?</p>${reviewForm("review")}`;
      case "disputed": return `<h2>Problem reported</h2><p class="muted">Staff are reviewing your order. Your payment is on hold until they refund you or release it.</p><p class="small">You said: “${esc(o.dispute ? o.dispute.reason : "")}”</p>`;
      case "refunded": return `<h2>Refunded</h2><p class="muted">${esc(o.refundReason || "This order was refunded.")} ${o.method === "balance" ? "The money is back in your balance." : "Stripe returns the money to your payment method, usually within 5–10 days."}</p>`;
      default: return `<h2>Order cancelled</h2><p class="muted">No payment was taken.</p>`;
    }
  }
  switch (o.status) {
    case "pending": return `<h2>Waiting for the buyer to pay</h2><p class="muted">You'll be able to deliver once payment is confirmed.</p>`;
    case "paid": return `<h2>Deliver the order</h2><p class="muted">The buyer has paid and Vaultix is holding the money. Send the item, then add the details here (login, trade info, codes…). Only the buyer can see them.</p>
      <textarea id="deliverText" maxlength="2000" rows="4" placeholder="e.g. Username: … / Password: … / Traded to …"></textarea>
      <div class="btnrow"><button class="btn sell" data-order-act="deliver" type="button">Mark as delivered</button><button class="btn danger" data-order-act="refund" type="button">Can't deliver — refund buyer</button></div>`;
    case "delivered": return `<h2>Waiting for the buyer to confirm</h2><p class="muted">You'll get ${money(o.sellerNet)} added to your balance when they confirm.</p>${auto}`;
    case "completed": return `<h2>Sale complete 🎉</h2><p class="muted">${money(o.sellerNet)} was added to your balance.</p>`;
    case "disputed": return `<h2>The buyer reported a problem</h2><p class="small">“${esc(o.dispute ? o.dispute.reason : "")}”</p><p class="muted">Staff will review the chat and decide. Explain what happened in the chat, or refund the buyer yourself.</p><button class="btn danger" data-order-act="refund" type="button">Refund buyer</button>`;
    case "refunded": return `<h2>Refunded</h2><p class="muted">${esc(o.refundReason || "This order was refunded.")}</p>`;
    default: return `<h2>Order cancelled</h2><p class="muted">The buyer didn't complete payment.</p>`;
  }
}

async function orderAction(act, btn) {
  const id = page.id;
  const val = (sel) => (($(sel) || {}).value || "").trim();
  const rate = () => { const r = document.querySelector('input[name="rate"]:checked'); return r ? r.value === "up" : true; };
  try {
    btn.disabled = true;
    if (act === "deliver") {
      if (!val("#deliverText")) throw new Error("Add the delivery details first.");
      await Market.orderAction("deliver", id, { text: val("#deliverText") });
      toast("Marked as delivered.");
    } else if (act === "confirm") {
      if (!confirm("Confirm you received everything? The money will be released to the seller.")) { btn.disabled = false; return; }
      await Market.orderAction("confirm", id, { positive: rate(), review: val("#reviewText") });
      toast("Order complete. Thanks!");
    } else if (act === "review") {
      await Market.orderAction("review", id, { positive: rate(), review: val("#reviewText") });
      toast("Review posted.");
    } else if (act === "dispute") {
      if (val("#disputeText").length < 5) throw new Error("Describe the problem (at least 5 characters).");
      await Market.orderAction("dispute", id, { reason: val("#disputeText") });
      toast("Problem reported. Payment is on hold.");
    } else if (act === "cancel") {
      await Market.orderAction("cancel", id);
      toast("Order cancelled.");
    } else if (act === "refund") {
      if (!confirm("Refund the buyer in full and cancel this sale?")) { btn.disabled = false; return; }
      await Market.orderAction("cancel", id);
      toast("Buyer refunded.");
    }
    await renderOrder();
  } catch (ex) { toast(ex.message); btn.disabled = false; }
}

$("#pageView").addEventListener("submit", async (e) => {
  if (e.target.id !== "chatForm") return;
  e.preventDefault();
  const input = e.target.elements.text, text = input.value.trim();
  if (!text) return;
  try { input.disabled = true; await Market.orderAction("message", page.id, { text }); await renderOrder(); const m = $("#msgs"); if (m) m.scrollTop = m.scrollHeight; }
  catch (ex) { toast(ex.message); input.disabled = false; }
});

/* ============================== side drawer ============================== */
function openDrawer(html) {
  $("#drawerBody").innerHTML = html;
  const d = $("#drawer");
  d.classList.add("open"); d.setAttribute("aria-hidden", "false");
  $("#drawerBack").hidden = false;
  document.body.classList.add("no-scroll");
  d.focus();
}
function closeDrawer() {
  const d = $("#drawer");
  if (!d.classList.contains("open")) return;
  d.classList.remove("open"); d.setAttribute("aria-hidden", "true");
  $("#drawerBack").hidden = true;
  document.body.classList.remove("no-scroll");
}
$("#drawerBack").addEventListener("click", closeDrawer);
document.addEventListener("keydown", (e) => { if (e.key === "Escape") closeDrawer(); });

// Any @seller link outside the card grid opens their profile.
document.addEventListener("click", (e) => {
  const w = e.target.closest("[data-user]");
  if (!w || e.target.closest("#sections") || !w.dataset.user) return;
  e.preventDefault();
  document.querySelectorAll("dialog[open]").forEach((d) => d.close());
  openProfile(w.dataset.user);
});

/* ---------- public profile ---------- */
async function openProfile(id) {
  openDrawer(`<div class="drawer-pad"><p class="muted">Loading profile…</p></div>`);
  let p;
  try { p = await Market.profile(id); } catch (ex) { $("#drawerBody").innerHTML = `<div class="drawer-pad"><p>${esc(ex.message)}</p></div>`; return; }
  const u = p.user, isMe = state.me && state.me.id === u.id;
  $("#drawerBody").innerHTML = `
    <div class="drawer-head">
      ${avatarHtml(u, "lg")}
      <div><h2>@${esc(u.name)}</h2><p class="muted small">Member since ${date(u.createdAt)}</p></div>
      <button class="x" data-drawer-close aria-label="Close">×</button>
    </div>
    <div class="drawer-pad">
      ${sellerChips(u)}
      ${u.bio ? `<p class="bio">${esc(u.bio)}</p>` : ""}
      ${u.verified ? "" : `<div class="warn"><b>Not verified.</b><span>Staff haven't checked this seller yet. Payments are still held until you confirm delivery.</span></div>`}
      ${isMe ? `<button class="btn sell wide" data-account="orders" type="button">Open my account</button>` : ""}
      <h3 class="dh">Listings (${p.listings.length})</h3>
      <div class="dlist">${p.listings.length ? p.listings.map((l) => `
        <button class="drow" data-listing="${esc(l.id)}" type="button">${gameTile(l.game)}<span class="drow-t"><b>${esc(l.title)}</b><span class="muted small">${esc(l.game)} · ${esc(l.category)}</span></span><b>${money(l.price)}</b></button>`).join("")
        : `<p class="muted small">No listings right now.</p>`}</div>
      <h3 class="dh">Reviews (${u.reviews || 0})</h3>
      <div class="dlist">${p.reviews.length ? p.reviews.map((r) => `
        <div class="review"><span>${r.positive ? "👍" : "👎"}</span><div><p>${r.text ? esc(r.text) : `<span class="muted">${r.positive ? "Positive" : "Negative"}, no comment</span>`}</p><p class="muted small">@${esc(r.by)} · ${esc(r.game)} · ${date(r.at)}</p></div></div>`).join("")
        : `<p class="muted small">No reviews yet.</p>`}</div>
    </div>`;
}

/* ---------- my account ---------- */
let accTab = "orders";
let myOrders = null;
async function openAccount(tab) {
  if (!state.me) return openJoin();
  accTab = tab || accTab;
  openDrawer(`<div class="drawer-pad"><p class="muted">Loading…</p></div>`);
  await Promise.all([loadMe(), Market.myOrders().then((r) => (myOrders = r.orders)).catch(() => (myOrders = []))]);
  renderAccount();
}
function renderAccount() {
  const me = state.me; if (!me) return closeDrawer();
  const w = state.wallet;
  const tabs = [["orders", "Purchases"], ["sales", "Sales"], ["wallet", "Wallet"], ["listings", "Listings"], ["profile", "Profile"]];
  $("#drawerBody").innerHTML = `
    <div class="drawer-head">
      ${avatarHtml(me, "lg")}
      <div><h2>@${esc(me.name)}</h2><p class="small">${badge(me, true)} ${w ? `<span class="muted">· Balance</span> <b>${money(w.available)}</b>` : ""}</p></div>
      <button class="x" data-drawer-close aria-label="Close">×</button>
    </div>
    <nav class="dtabs" role="tablist">${tabs.map(([k, t]) => `<button role="tab" aria-selected="${accTab === k}" data-tab="${k}" type="button">${t}</button>`).join("")}</nav>
    <div class="drawer-pad">${accountTab()}</div>`;
}
function orderRows(list, role) {
  if (!list.length) return `<p class="muted small">${role === "buyer" ? "You haven't bought anything yet." : "No sales yet."}</p>`;
  return list.map((o) => `
    <a class="drow" href="#/order/${esc(o.id)}">${gameTile(o.game)}<span class="drow-t"><b>${esc(o.title)}</b><span class="small">${pill(o.status)} <span class="muted">${date(o.createdAt)}</span></span></span><b>${money(role === "buyer" ? o.total : o.sellerNet)}</b></a>`).join("");
}
function accountTab() {
  const me = state.me, w = state.wallet;
  if (!Market.canPay && ["orders", "sales", "wallet"].includes(accTab)) return `<div class="warn"><b>Needs the server.</b><span>${esc(Market.NEEDS_SERVER)}</span></div>`;
  const orders = myOrders || [];
  if (accTab === "orders") return `<div class="dlist">${orderRows(orders.filter((o) => o.role === "buyer"), "buyer")}</div>`;
  if (accTab === "sales") {
    const s = orders.filter((o) => o.role === "seller");
    const todo = s.filter((o) => o.status === "paid").length;
    return `${todo ? `<div class="safe"><b>${todo} order${todo === 1 ? "" : "s"} waiting for you to deliver.</b></div>` : ""}<div class="dlist">${orderRows(s, "seller")}</div>`;
  }
  if (accTab === "wallet") return walletTab(me, w);
  if (accTab === "listings") {
    const mine = state.listings.filter((l) => l.seller.id === me.id);
    return `<button class="btn sell wide" data-new-listing type="button">+ New listing</button>
      <div class="dlist">${mine.length ? mine.map((l) => `
        <div class="drow">${gameTile(l.game)}<span class="drow-t"><b>${esc(l.title)}</b><span class="muted small">${money(l.price)} · ${l.stock ?? 1} in stock</span></span><button class="btn danger sm" data-del="${esc(l.id)}" type="button">Remove</button></div>`).join("")
        : `<p class="muted small">You have no listings.</p>`}</div>`;
  }
  // profile
  return `
    ${me.verified
      ? `<div class="safe"><b>You're verified</b> since ${date(me.verifiedAt || me.createdAt)}. Buyers see a green badge on your listings.</div>`
      : `<div class="warn"><b>Your listings show as Risky.</b><span>To get verified, send the site owner your user ID below.</span></div>`}
    <p class="muted small">User ID</p><div class="contact" style="user-select:all">${esc(me.id)}</div>
    <form class="dform" id="profileForm">
      <label>Contact (only shown to people you trade with)<input name="contact" maxlength="80" value="${esc(me.contact || "")}" /></label>
      <label>Bio <span class="opt">shown on your profile</span><textarea name="bio" maxlength="160" rows="2">${esc(me.bio || "")}</textarea></label>
      <button class="btn sell" type="submit">Save</button>
    </form>
    <div class="btnrow"><button class="btn ghost" data-user="${esc(me.id)}" type="button">View public profile</button><button class="btn danger" id="signOut" type="button">Sign out</button></div>
    <p class="muted small">Your login is saved only in this browser. If you sign out you can't sign back in to this account.</p>`;
}

let payoutMethod = "stripe";
function walletTab(me, w) {
  if (!w) return `<p class="muted">Couldn't load your wallet.</p>`;
  const stripeOk = me.stripeConnected && me.stripeReady;
  const field = {
    stripe: stripeOk
      ? `<div class="safe small">Bank or debit card connected through Stripe. Withdrawals are sent there after staff approve them.</div>`
      : `<p class="muted small">Add your bank account or debit card on Stripe's secure page. Vaultix never sees the numbers.</p><button class="btn ghost" data-stripe-connect type="button">${me.stripeConnected ? "Finish Stripe setup" : "Connect bank or debit card"}</button>`,
    paypal: `<label>PayPal email<input name="details" type="email" maxlength="120" placeholder="you@example.com" /></label>`,
    crypto: `<div class="two"><label>Coin & network<select name="network">${["USDT (TRC20)", "USDT (ERC20)", "BTC", "ETH", "LTC"].map((n) => `<option>${n}</option>`).join("")}</select></label>
      <label>Wallet address<input name="details" maxlength="120" placeholder="Paste your address" autocomplete="off" /></label></div>
      <p class="muted small">Double-check the address and network. Crypto sent to a wrong address can't be recovered.</p>`,
    bank: `<label>Bank details<textarea name="details" rows="3" maxlength="300" placeholder="Account holder, IBAN or account number, SWIFT/BIC, bank name, country"></textarea></label>`,
  }[payoutMethod];
  const labels = { stripe: "Bank / debit card (Stripe)", paypal: "PayPal", crypto: "Crypto", bank: "Bank transfer" };
  return `
    <div class="wallet">
      <div class="wcard main"><span class="muted small">Available</span><b>${money(w.available)}</b></div>
      <div class="wcard"><span class="muted small">Pending</span><b>${money(w.pending)}</b><span class="muted small">in open orders</span></div>
      <div class="wcard"><span class="muted small">Total earned</span><b>${money(w.earned)}</b></div>
    </div>
    <p class="muted small">You can spend your balance at checkout (no payment fee) or withdraw it.</p>
    <h3 class="dh">Withdraw</h3>
    <form class="dform" id="payoutForm">
      <div class="pchoice" role="radiogroup" aria-label="Payout method">${Object.entries(labels).map(([k, t]) => `
        <label class="${payoutMethod === k ? "on" : ""}"><input type="radio" name="pmethod" value="${k}" ${payoutMethod === k ? "checked" : ""} />${t}</label>`).join("")}</div>
      ${field}
      <label>Amount (min $10)<span class="amt"><input name="amount" type="number" min="10" step="0.01" max="${Math.max(0, w.available)}" placeholder="0.00" /><button class="btn ghost sm" data-max type="button">Max</button></span></label>
      <p class="form-err" id="payoutErr" role="alert"></p>
      <button class="btn sell" type="submit" ${payoutMethod === "stripe" && !stripeOk ? "disabled" : ""}>Request withdrawal</button>
      <p class="muted small">Staff check every withdrawal before it's sent, usually within 1–2 days.</p>
    </form>
    <h3 class="dh">History</h3>
    <div class="dlist">${state.payouts.length ? state.payouts.map((p) => `
      <div class="drow"><span class="drow-t"><b>${money(p.amount)} · ${esc(labels[p.method] || p.method)}</b><span class="muted small">${esc(p.details)} · ${date(p.createdAt)}${p.note ? ` · ${esc(p.note)}` : ""}</span></span>${{ requested: `<span class="pill info">Requested</span>`, paid: `<span class="pill ok">Sent</span>`, rejected: `<span class="pill muted">Rejected</span>` }[p.status] || ""}</div>`).join("")
      : `<p class="muted small">No withdrawals yet.</p>`}</div>`;
}

$("#drawer").addEventListener("click", async (e) => {
  if (e.target.closest("[data-drawer-close]")) return closeDrawer();
  const t = e.target.closest("[data-tab]");
  if (t) { accTab = t.dataset.tab; return renderAccount(); }
  const a = e.target.closest("[data-account]");
  if (a) return openAccount(a.dataset.account);
  const l = e.target.closest("[data-listing]");
  if (l) { const x = state.listings.find((y) => y.id === l.dataset.listing); if (x) { closeDrawer(); openListing(x); } return; }
  if (e.target.closest("a.drow")) return closeDrawer();
  if (e.target.closest("[data-new-listing]")) { closeDrawer(); return openPost(); }
  const del = e.target.closest("[data-del]");
  if (del) {
    if (!confirm("Remove this listing from the market?")) return;
    try { await Market.remove(del.dataset.del); await refresh(); renderAccount(); toast("Listing removed."); } catch (ex) { toast(ex.message); }
    return;
  }
  if (e.target.closest("#signOut")) {
    if (!confirm("Sign out? You won't be able to sign back in to this account.")) return;
    Market.signOut(); state.me = null; state.wallet = null; myOrders = null; renderAvatar(); closeDrawer(); render();
    return;
  }
  if (e.target.closest("[data-max]")) { const f = $("#payoutForm"); f.elements.amount.value = Math.max(0, state.wallet.available).toFixed(2); return; }
  const sc = e.target.closest("[data-stripe-connect]");
  if (sc) {
    sc.disabled = true; sc.textContent = "Opening Stripe…";
    try { const r = await Market.stripeConnect(); location.href = r.url; } catch (ex) { toast(ex.message); sc.disabled = false; }
  }
});
$("#drawer").addEventListener("change", (e) => {
  if (e.target.name === "pmethod") { payoutMethod = e.target.value; renderAccount(); }
});
$("#drawer").addEventListener("submit", async (e) => {
  e.preventDefault();
  const f = e.target, btn = f.querySelector("[type=submit]");
  if (f.id === "profileForm") {
    try { btn.disabled = true; await Market.updateProfile({ contact: f.elements.contact.value, bio: f.elements.bio.value }); await loadMe(); toast("Profile saved."); renderAccount(); }
    catch (ex) { toast(ex.message); btn.disabled = false; }
  }
  if (f.id === "payoutForm") {
    $("#payoutErr").textContent = "";
    try {
      btn.disabled = true;
      await Market.payout({
        method: payoutMethod, amount: f.elements.amount.value,
        details: f.elements.details ? f.elements.details.value : "",
        network: f.elements.network ? f.elements.network.value : undefined,
      });
      await loadMe(); toast("Withdrawal requested. Staff will process it soon."); renderAccount();
    } catch (ex) { $("#payoutErr").textContent = ex.message; btn.disabled = false; }
  }
});
