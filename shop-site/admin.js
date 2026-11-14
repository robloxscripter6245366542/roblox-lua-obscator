// Vaultix staff page: verify sellers, settle disputed orders, approve withdrawals, add funds.
const $ = (s) => document.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const money = (n) => "$" + Number(n || 0).toFixed(2);
const day = (t) => (t ? new Date(t).toLocaleDateString() : "");
const PILL = {
  pending: ["Awaiting payment", "wait"], paid: ["Paid", "info"], delivered: ["Delivered", "info"], completed: ["Completed", "ok"],
  disputed: ["Disputed", "risk"], refunded: ["Refunded", "muted"], cancelled: ["Cancelled", "muted"],
  requested: ["Requested", "wait"], rejected: ["Rejected", "muted"],
  waiting: ["Not sent yet", "muted"], sent: ["Says it's sent", "wait"], credited: ["Added", "ok"],
};
const CRYPTO_NETWORKS = ["USDT (TRC20)", "USDT (ERC20)", "BTC", "ETH", "LTC"];
const pill = (s) => { const [t, k] = PILL[s] || [s, "muted"]; return `<span class="pill ${k}">${esc(t)}</span>`; };
const METHOD = { stripe: "Bank / card (Stripe)", paypal: "PayPal", crypto: "Crypto", bank: "Bank transfer" };

const data = { sellers: [], orders: [], payouts: [], listings: [], deposits: [], depositSettings: { bank: "", crypto: {} } };
const openLogins = {}; // listingId -> decrypted logins shown in the Listings tab
let tab = "sellers", orderFilter = "open", q = "";

function toast(msg) {
  const t = $("#toast"); t.textContent = msg; t.classList.add("show");
  clearTimeout(toast.t); toast.t = setTimeout(() => t.classList.remove("show"), 2800);
}

let quiet = false; // first automatic try (signed-in owner): don't show an error if it fails
async function load() {
  $("#err").textContent = "";
  try {
    data.sellers = (await Market.admin("adminSellers")).sellers;
    if (Market.mode === "remote") {
      data.orders = (await Market.admin("adminOrders")).orders;
      data.listings = (await Market.admin("adminListings")).listings;
      data.payouts = (await Market.admin("adminPayouts")).payouts;
      const dep = await Market.admin("adminDeposits");
      data.deposits = dep.deposits; data.depositSettings = dep.settings;
    }
    $("#app").hidden = false;
    $("#login").hidden = true;
    render();
  } catch (e) {
    $("#app").hidden = true; $("#login").hidden = false;
    if (!quiet) $("#err").textContent = e.message;
    if (e.status === 401) Market.setAdminKey("");
  }
}

function render() {
  const disputes = data.orders.filter((o) => o.status === "disputed").length;
  const requests = data.payouts.filter((p) => p.status === "requested").length;
  const toCheck = data.listings.filter((l) => !l.checked).length;
  const toAdd = data.deposits.filter((d) => d.status === "sent").length;
  $("#tabs").innerHTML = [["sellers", "Sellers", 0], ["listings", "Listings", toCheck], ["orders", "Orders", disputes], ["payouts", "Payouts", requests], ["deposits", "Add funds", toAdd]]
    .map(([k, t, n]) => `<button role="tab" data-tab="${k}" aria-selected="${tab === k}" type="button">${t}${n ? `<span class="count">${n}</span>` : ""}</button>`).join("");
  $("#view").innerHTML = tab === "sellers" ? sellersView() : tab === "listings" ? listingsView() : tab === "orders" ? ordersView() : tab === "deposits" ? depositsView() : payoutsView();
  const f = $("#filter"); if (f) { f.value = q; }
}

function sellersView() {
  const k = q.trim().toLowerCase();
  const list = data.sellers.filter((s) => !k || s.name.toLowerCase().includes(k) || s.id.toLowerCase().includes(k));
  return `
    <div class="filter-row"><input class="filter" id="filter" type="search" placeholder="Find user by name or ID" aria-label="Find user" /></div>
    <table>
      <thead><tr><th>User</th><th>Contact</th><th>Joined</th><th>Sales / rating</th><th>Balance</th><th>Status</th><th></th></tr></thead>
      <tbody>${list.map((s) => `
        <tr>
          <td><b>@${esc(s.name)}</b><br><span class="mono small">${esc(s.id)}</span></td>
          <td>${esc(s.contact)}${s.email ? `<br><span class="small">${esc(s.email)}</span>` : ""}${s.hasPassword ? "" : `<br><span class="small">no password yet</span>`}</td>
          <td>${day(s.createdAt)}</td>
          <td>${s.sales || 0} sales${s.reviews ? `<br><span class="small">${s.positive}% of ${s.reviews}</span>` : ""}<br><span class="small">${s.listings} listing(s)</span></td>
          <td>${s.balance !== undefined ? money(s.balance) : "–"}</td>
          <td>${s.owner ? '<span class="badge owner sm">Owner</span>' : s.verified ? '<span class="badge ok sm">Verified</span>' : '<span class="badge risk sm">Risky</span>'}</td>
          <td><div class="acts">${s.owner ? '<span class="small">Site owner</span>' : `
            <button class="btn ${s.verified ? "ghost" : "sell"}" data-verify="${esc(s.id)}" data-to="${!s.verified}" type="button">${s.verified ? "Remove verification" : "Verify"}</button>
            <button class="btn danger" data-ban="${esc(s.id)}" type="button">Ban</button>`}
            <button class="btn ghost" data-reset-pw="${esc(s.id)}" data-name="${esc(s.name)}" type="button">Reset password</button>
          </div></td>
        </tr>`).join("")}</tbody>
    </table>
    ${list.length ? "" : `<p class="muted">${data.sellers.length ? "No users match." : "No users yet."}</p>`}`;
}

function listingsView() {
  if (Market.mode !== "remote") return `<p class="muted" style="margin-top:16px">Listing checks need the server.</p>`;
  const badgeFor = (s) => !s ? "" : s.owner ? '<span class="badge owner sm">Owner</span>' : s.verified ? '<span class="badge ok sm">Verified</span>' : '<span class="badge risk sm">Risky</span>';
  return `
    <p class="muted small" style="margin-top:16px">Check listings are real before buyers pay. For ⚡ instant-delivery accounts, open the stored logins and try them. Mark a listing checked to give it a “✓ Staff checked” badge, remove a login that doesn't work, or take the listing down. Unchecked listings are shown first.</p>
    <table>
      <thead><tr><th>Listing</th><th>Seller</th><th>Price / stock</th><th>Status</th><th></th></tr></thead>
      <tbody>${data.listings.map((l) => `
        <tr>
          <td><b>${esc(l.title)}</b><br><span class="small">${esc(l.game)} · ${esc(l.category)} · ${l.delivery === "instant" ? "⚡ instant" : "manual delivery"}</span>
            <details><summary class="small">Description</summary><div class="detail">${esc(l.description)}</div></details>
            ${openLogins[l.id] ? loginsBlock(l) : ""}
          </td>
          <td>@${esc(l.seller ? l.seller.name : "?")}<br>${badgeFor(l.seller)}</td>
          <td>${money(l.price)}<br><span class="small">${l.stock} in stock</span></td>
          <td>${l.checked ? `<span class="pill ok">✓ Checked</span><br><span class="small">by @${esc(l.checkedBy || "staff")} · ${day(l.checkedAt)}</span>` : `<span class="pill wait">Not checked</span>`}</td>
          <td><div class="acts">
            ${l.delivery === "instant" ? `<button class="btn ghost" data-logins="${esc(l.id)}" type="button">${openLogins[l.id] ? "Hide logins" : "🔍 View logins"}</button>` : ""}
            <button class="btn ${l.checked ? "ghost" : "sell"}" data-check="${esc(l.id)}" data-to="${!l.checked}" type="button">${l.checked ? "Uncheck" : "✓ Mark checked"}</button>
            <button class="btn danger" data-remove-listing="${esc(l.id)}" type="button">Remove listing</button>
          </div></td>
        </tr>`).join("")}</tbody>
    </table>
    ${data.listings.length ? "" : `<p class="muted">No listings for sale.</p>`}`;
}
function loginsBlock(l) {
  const list = openLogins[l.id];
  if (!list.length) return `<div class="detail">No logins left in stock.</div>`;
  return `<div class="logins">${list.map((x, i) => x.error ? `<div class="detail">Login ${i + 1}: ${esc(x.error)}</div>` : `
    <div class="login-card">
      <div class="mono small">
        <b>Login ${i + 1}</b><br>
        Username: ${esc(x.login)}<br>Password: ${esc(x.password)}
        ${x.email ? `<br>Email: ${esc(x.email)}` : ""}${x.emailPassword ? `<br>Email password: ${esc(x.emailPassword)}` : ""}
        ${x.notes ? `<br>Notes: ${esc(x.notes)}` : ""}
      </div>
      <button class="btn danger" data-bad-login="${esc(l.id)}" data-ref="${esc(x.ref)}" type="button">Remove bad login</button>
    </div>`).join("")}</div>`;
}

function ordersView() {
  if (Market.mode !== "remote") return `<p class="muted" style="margin-top:16px">Orders need the server.</p>`;
  const open = ["paid", "delivered", "disputed"];
  const list = data.orders.filter((o) => orderFilter === "all" || (orderFilter === "open" ? open.includes(o.status) : o.status === orderFilter));
  return `
    <div class="filter-row"><select id="orderFilter" aria-label="Filter orders">
      ${[["open", "Open (money held)"], ["disputed", "Disputed"], ["completed", "Completed"], ["refunded", "Refunded"], ["all", "All"]].map(([v, t]) => `<option value="${v}" ${orderFilter === v ? "selected" : ""}>${t}</option>`).join("")}
    </select></div>
    <table>
      <thead><tr><th>Order</th><th>Buyer → Seller</th><th>Amount</th><th>Status</th><th></th></tr></thead>
      <tbody>${list.map((o) => `
        <tr>
          <td><b>${esc(o.title)}</b><br><span class="small">${esc(o.game)} · ${esc(o.category)}</span><br><span class="mono small">${esc(o.id)} · ${day(o.createdAt)}</span>
            ${o.dispute ? `<div class="detail"><b>Buyer's problem:</b> ${esc(o.dispute.reason)}</div>` : ""}
            ${o.delivery ? `<details><summary class="small">Delivery details</summary><div class="detail">${esc(o.delivery)}</div></details>` : ""}
            ${o.login && !o.login.error ? `<details><summary class="small">⚡ Login given to buyer</summary><div class="detail mono">${esc(["Username: " + o.login.login, "Password: " + o.login.password, o.login.email && "Email: " + o.login.email, o.login.emailPassword && "Email password: " + o.login.emailPassword, o.login.notes && "Notes: " + o.login.notes].filter(Boolean).join("\n"))}</div></details>` : ""}
            ${(o.messages || []).length ? `<details><summary class="small">Chat (${o.messages.length})</summary><div class="detail">${o.messages.map((m) => `${esc(m.from)}: ${esc(m.text)}`).join("\n")}</div></details>` : ""}
          </td>
          <td>@${esc(o.buyer ? o.buyer.name : "?")} → @${esc(o.seller ? o.seller.name : "?")}</td>
          <td>${money(o.total)}<br><span class="small">seller gets ${money(o.sellerNet)} · ${esc(o.method)}</span></td>
          <td>${pill(o.status)}</td>
          <td><div class="acts">${open.includes(o.status) ? `
            ${o.deliveredAt ? `<span class="small">Delivered: sale is final</span>` : `<button class="btn danger" data-resolve="${esc(o.id)}" data-decision="refund" type="button">Refund buyer</button>`}
            <button class="btn sell" data-resolve="${esc(o.id)}" data-decision="release" type="button">Release to seller</button>` : ""}
          </div></td>
        </tr>`).join("")}</tbody>
    </table>
    ${list.length ? "" : `<p class="muted">No orders here.</p>`}`;
}

function payoutsView() {
  if (Market.mode !== "remote") return `<p class="muted" style="margin-top:16px">Payouts need the server.</p>`;
  return `
    <p class="muted small" style="margin-top:16px">Stripe withdrawals are transferred automatically when you approve them. For PayPal, crypto and bank transfers, send the money yourself first, then click “Mark as sent”.</p>
    <table>
      <thead><tr><th>User</th><th>Amount</th><th>Method & details</th><th>Status</th><th></th></tr></thead>
      <tbody>${data.payouts.map((p) => `
        <tr>
          <td><b>@${esc(p.user)}</b><br><span class="small">${day(p.createdAt)}</span></td>
          <td><b>${money(p.amount)}</b></td>
          <td>${esc(METHOD[p.method] || p.method)}<div class="detail mono">${esc(p.details)}</div>${p.transferId ? `<span class="small mono">${esc(p.transferId)}</span>` : ""}</td>
          <td>${pill(p.status === "paid" ? "completed" : p.status).replace("Completed", "Sent")}${p.note ? `<br><span class="small">${esc(p.note)}</span>` : ""}</td>
          <td><div class="acts">${p.status === "requested" ? `
            <button class="btn ghost" data-payout="${esc(p.id)}" data-decision="reject" type="button">Reject</button>
            <button class="btn sell" data-payout="${esc(p.id)}" data-decision="paid" type="button">${p.method === "stripe" ? "Approve & transfer" : "Mark as sent"}</button>` : ""}
          </div></td>
        </tr>`).join("")}</tbody>
    </table>
    ${data.payouts.length ? "" : `<p class="muted">No withdrawals yet.</p>`}`;
}

function depositsView() {
  if (Market.mode !== "remote") return `<p class="muted" style="margin-top:16px">Adding funds needs the server.</p>`;
  const set = data.depositSettings;
  return `
    <p class="muted small" style="margin-top:16px">People without a card send a bank transfer or crypto to the details below, then tap “I've sent it”. Check the money really arrived (match the reference code or transaction ID), then click <b>Add to balance</b> with the amount that arrived. Added funds can be spent on Vaultix but not withdrawn.</p>
    <table>
      <thead><tr><th>User</th><th>Amount</th><th>How & proof</th><th>Status</th><th></th></tr></thead>
      <tbody>${data.deposits.map((d) => `
        <tr>
          <td><b>@${esc(d.user)}</b><br><span class="small">${day(d.createdAt)}</span></td>
          <td><b>${money(d.status === "credited" ? d.credited : d.amount)}</b>${d.status === "credited" && d.credited !== d.amount ? `<br><span class="small">asked ${money(d.amount)}</span>` : ""}</td>
          <td>${d.method === "bank" ? "Bank transfer" : esc(d.network)}<div class="detail mono">Ref ${esc(d.ref)}${d.proof ? `<br>${d.method === "bank" ? "From" : "Tx"}: ${esc(d.proof)}` : ""}</div></td>
          <td>${pill(d.status)}${d.note ? `<br><span class="small">${esc(d.note)}</span>` : ""}</td>
          <td><div class="acts">${["waiting", "sent"].includes(d.status) ? `
            <button class="btn ghost" data-deposit="${esc(d.id)}" data-decision="reject" type="button">Reject</button>
            <button class="btn sell" data-deposit="${esc(d.id)}" data-decision="credit" data-amount="${d.amount}" type="button">Add to balance</button>` : ""}
          </div></td>
        </tr>`).join("")}</tbody>
    </table>
    ${data.deposits.length ? "" : `<p class="muted">No requests yet.</p>`}
    <h3 style="margin-top:28px">Where people send the money</h3>
    <p class="muted small">Leave a box empty to turn that method off. Requests already made keep the details they were given.</p>
    <form id="depositSettings" class="dform" style="max-width:640px">
      <label>Bank transfer details<textarea name="bank" rows="3" maxlength="400" placeholder="Account holder, IBAN or account number, SWIFT/BIC, bank name">${esc(set.bank)}</textarea></label>
      ${CRYPTO_NETWORKS.map((n) => `<label>${esc(n)} address<input name="crypto:${esc(n)}" maxlength="120" value="${esc(set.crypto[n] || "")}" autocomplete="off" /></label>`).join("")}
      <button class="btn sell" type="submit">Save</button>
    </form>`;
}

$("#view").addEventListener("submit", async (e) => {
  if (e.target.id !== "depositSettings") return;
  e.preventDefault();
  const f = e.target, crypto = {};
  for (const n of CRYPTO_NETWORKS) crypto[n] = f.elements[`crypto:${n}`].value;
  try {
    await Market.admin("adminSetDeposit", { bank: f.elements.bank.value, crypto });
    toast("Saved."); await load();
  } catch (err) { toast(err.message); }
});

$("#login").addEventListener("submit", (e) => {
  e.preventDefault();
  Market.setAdminKey($("#key").value);
  $("#key").value = "";
  load();
});
$("#tabs").addEventListener("click", (e) => { const b = e.target.closest("[data-tab]"); if (b) { tab = b.dataset.tab; render(); } });
$("#view").addEventListener("input", (e) => { if (e.target.id === "filter") { q = e.target.value; const pos = e.target.selectionStart; render(); const f = $("#filter"); f.focus(); f.setSelectionRange(pos, pos); } });
$("#view").addEventListener("change", (e) => { if (e.target.id === "orderFilter") { orderFilter = e.target.value; render(); } });

$("#view").addEventListener("click", async (e) => {
  const v = e.target.closest("[data-verify]"), b = e.target.closest("[data-ban]");
  const r = e.target.closest("[data-resolve]"), p = e.target.closest("[data-payout]");
  const lg = e.target.closest("[data-logins]"), ck = e.target.closest("[data-check]");
  const bl = e.target.closest("[data-bad-login]"), rl = e.target.closest("[data-remove-listing]");
  const rp = e.target.closest("[data-reset-pw]"), dp = e.target.closest("[data-deposit]");
  try {
    if (dp) {
      const d = data.deposits.find((x) => x.id === dp.dataset.deposit);
      if (dp.dataset.decision === "credit") {
        const amt = prompt(`How much arrived from @${d ? d.user : "user"}? (asked for ${money(dp.dataset.amount)}) This is added to their balance.`, Number(dp.dataset.amount).toFixed(2));
        if (amt === null) return;
        await Market.admin("depositDecision", { depositId: dp.dataset.deposit, decision: "credit", amount: Number(amt) });
        toast("Added to their balance.");
      } else {
        const note = prompt("Reason for rejecting (shown to the user):", "Payment not received");
        if (note === null) return;
        await Market.admin("depositDecision", { depositId: dp.dataset.deposit, decision: "reject", note });
        toast("Request rejected.");
      }
      return load();
    }
    if (rp) {
      if (!confirm(`Reset @${rp.dataset.name}'s password? Only do this after checking it's really them (e.g. message them on their contact). They'll be signed out everywhere.`)) return;
      const r = await Market.admin("adminResetPassword", { sellerId: rp.dataset.resetPw });
      prompt(`Temporary password for @${rp.dataset.name}. Send it to them privately and tell them to change it under Profile:`, r.tempPassword);
      return load();
    }
    if (lg) {
      const id = lg.dataset.logins;
      if (openLogins[id]) delete openLogins[id];
      else openLogins[id] = (await Market.admin("adminLogins", { listingId: id })).logins;
      return render();
    }
    if (ck) {
      await Market.admin("adminCheck", { listingId: ck.dataset.check, checked: ck.dataset.to === "true" });
      toast(ck.dataset.to === "true" ? "Marked as checked. Buyers now see “✓ Staff checked”." : "Check removed.");
      return load();
    }
    if (bl) {
      if (!confirm("Remove this login? It won't be sold, and stock goes down by one.")) return;
      const res = await Market.admin("adminRemoveLogin", { listingId: bl.dataset.badLogin, ref: bl.dataset.ref });
      openLogins[bl.dataset.badLogin] = (await Market.admin("adminLogins", { listingId: bl.dataset.badLogin })).logins;
      toast(`Login removed. ${res.stock} left in stock.`);
      return load();
    }
    if (rl) {
      if (!confirm("Take this listing down? Any unsold logins in it are deleted.")) return;
      await Market.admin("adminRemove", { listingId: rl.dataset.removeListing });
      delete openLogins[rl.dataset.removeListing];
      toast("Listing removed.");
      return load();
    }
    if (v) {
      await Market.admin("verify", { sellerId: v.dataset.verify, verified: v.dataset.to === "true" });
      toast(v.dataset.to === "true" ? "Seller verified." : "Verification removed.");
    } else if (b) {
      const s = data.sellers.find((x) => x.id === b.dataset.ban);
      if (!confirm(`Ban @${s ? s.name : "user"} and remove all their listings?`)) return;
      const res = await Market.admin("banSeller", { sellerId: b.dataset.ban });
      toast(`User banned. ${res.removedListings} listing(s) removed.`);
    } else if (r) {
      const refund = r.dataset.decision === "refund";
      if (!confirm(refund ? "Refund the buyer in full?" : "Release the money to the seller? This can't be undone.")) return;
      await Market.admin("resolve", { orderId: r.dataset.resolve, decision: r.dataset.decision });
      toast(refund ? "Buyer refunded." : "Money released to the seller.");
    } else if (p) {
      const paid = p.dataset.decision === "paid";
      const note = paid ? "" : prompt("Reason for rejecting (shown to the user):", "") ?? null;
      if (note === null) return;
      if (paid && !confirm("Confirm this withdrawal? Stripe withdrawals are transferred right away.")) return;
      await Market.admin("payoutDecision", { payoutId: p.dataset.payout, decision: p.dataset.decision, note });
      toast(paid ? "Withdrawal sent." : "Withdrawal rejected. The money is back in their balance.");
    } else return;
    await load();
  } catch (err) { toast(err.message); }
});

(async () => {
  await Market.init();
  $("#demoBar").hidden = Market.mode !== "demo";
  if (Market.mode === "demo" || Market.adminKey()) load();
  else if (Market.session()) { quiet = true; await load(); quiet = false; } // owner account: no password needed
})();
