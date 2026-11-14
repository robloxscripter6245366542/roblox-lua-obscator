// Vaultix staff page: verify sellers, settle disputed orders, approve withdrawals.
const $ = (s) => document.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const money = (n) => "$" + Number(n || 0).toFixed(2);
const day = (t) => (t ? new Date(t).toLocaleDateString() : "");
const PILL = {
  pending: ["Awaiting payment", "wait"], paid: ["Paid", "info"], delivered: ["Delivered", "info"], completed: ["Completed", "ok"],
  disputed: ["Disputed", "risk"], refunded: ["Refunded", "muted"], cancelled: ["Cancelled", "muted"],
  requested: ["Requested", "wait"], rejected: ["Rejected", "muted"],
};
const pill = (s) => { const [t, k] = PILL[s] || [s, "muted"]; return `<span class="pill ${k}">${esc(t)}</span>`; };
const METHOD = { stripe: "Bank / card (Stripe)", paypal: "PayPal", crypto: "Crypto", bank: "Bank transfer" };

const data = { sellers: [], orders: [], payouts: [] };
let tab = "sellers", orderFilter = "open", q = "";

function toast(msg) {
  const t = $("#toast"); t.textContent = msg; t.classList.add("show");
  clearTimeout(toast.t); toast.t = setTimeout(() => t.classList.remove("show"), 2800);
}

async function load() {
  $("#err").textContent = "";
  try {
    data.sellers = (await Market.admin("adminSellers")).sellers;
    if (Market.mode === "remote") {
      data.orders = (await Market.admin("adminOrders")).orders;
      data.payouts = (await Market.admin("adminPayouts")).payouts;
    }
    $("#app").hidden = false;
    $("#login").hidden = true;
    render();
  } catch (e) {
    $("#app").hidden = true; $("#login").hidden = false;
    $("#err").textContent = e.message;
    if (e.status === 401) Market.setAdminKey("");
  }
}

function render() {
  const disputes = data.orders.filter((o) => o.status === "disputed").length;
  const requests = data.payouts.filter((p) => p.status === "requested").length;
  $("#tabs").innerHTML = [["sellers", "Sellers", 0], ["orders", "Orders", disputes], ["payouts", "Payouts", requests]]
    .map(([k, t, n]) => `<button role="tab" data-tab="${k}" aria-selected="${tab === k}" type="button">${t}${n ? `<span class="count">${n}</span>` : ""}</button>`).join("");
  $("#view").innerHTML = tab === "sellers" ? sellersView() : tab === "orders" ? ordersView() : payoutsView();
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
          <td>${esc(s.contact)}</td>
          <td>${day(s.createdAt)}</td>
          <td>${s.sales || 0} sales${s.reviews ? `<br><span class="small">${s.positive}% of ${s.reviews}</span>` : ""}<br><span class="small">${s.listings} listing(s)</span></td>
          <td>${s.balance !== undefined ? money(s.balance) : "–"}</td>
          <td>${s.verified ? '<span class="badge ok sm">Verified</span>' : '<span class="badge risk sm">Risky</span>'}</td>
          <td><div class="acts">
            <button class="btn ${s.verified ? "ghost" : "sell"}" data-verify="${esc(s.id)}" data-to="${!s.verified}" type="button">${s.verified ? "Remove verification" : "Verify"}</button>
            <button class="btn danger" data-ban="${esc(s.id)}" type="button">Ban</button>
          </div></td>
        </tr>`).join("")}</tbody>
    </table>
    ${list.length ? "" : `<p class="muted">${data.sellers.length ? "No users match." : "No users yet."}</p>`}`;
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
            <button class="btn danger" data-resolve="${esc(o.id)}" data-decision="refund" type="button">Refund buyer</button>
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
  try {
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
})();
