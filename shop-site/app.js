// Vaultix Market — public marketplace UI
const $ = (s) => document.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const money = (n) => "$" + Number(n).toFixed(2);
const date = (t) => new Date(t).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });
const badge = (s, sm) => s && s.verified
  ? `<span class="badge ok${sm ? " sm" : ""}">Verified</span>`
  : `<span class="badge risk${sm ? " sm" : ""}">Risky</span>`;

const state = { listings: [], cat: "All", q: "", verifiedOnly: false, sort: "new", me: null };

/* ---------- catalogue ---------- */
function renderTabs() {
  $("#tabs").innerHTML = ["All", ...Market.CATEGORIES].map((c) =>
    `<button class="tab" role="tab" data-cat="${c}" aria-selected="${c === state.cat}">${c}</button>`).join("");
}

function visible() {
  const q = state.q.trim().toLowerCase();
  const out = state.listings.filter((l) =>
    (state.cat === "All" || l.category === state.cat) &&
    (!state.verifiedOnly || l.seller.verified) &&
    (!q || `${l.title} ${l.description} ${l.seller.name}`.toLowerCase().includes(q)));
  if (state.sort === "low") out.sort((a, b) => a.price - b.price);
  else if (state.sort === "high") out.sort((a, b) => b.price - a.price);
  else out.sort((a, b) => b.createdAt - a.createdAt);
  return out;
}

function renderGrid() {
  const list = visible();
  const total = state.listings.length;
  const filtered = total > 0 && list.length === 0;
  $("#count").textContent = total ? `${list.length} of ${total} listing${total === 1 ? "" : "s"}` : "";
  $("#empty").hidden = list.length > 0;
  $("#emptyKicker").textContent = filtered ? "No matches" : "00 listings";
  $("#emptyTitle").textContent = filtered ? "No listings match." : "Nothing for sale yet.";
  $("#emptyText").textContent = filtered
    ? (state.verifiedOnly ? "No verified sellers have listings here yet. Try turning off “Verified sellers only”." : "Try a different search or category.")
    : "This market just opened. Be the first to post a listing.";
  $("#emptySell").hidden = filtered;
  $("#grid").innerHTML = list.map((l) => `
    <button class="item ${l.seller.verified ? "is-ok" : "is-risk"}" data-id="${esc(l.id)}" type="button">
      <span class="mono item-cat">${esc(l.category)}</span>
      <h3>${esc(l.title)}</h3>
      <p class="item-desc">${esc(l.description)}</p>
      <span class="item-foot">
        <span class="price">${money(l.price)}</span>
        <span class="seller"><span class="seller-name">@${esc(l.seller.name)}</span>${badge(l.seller, true)}</span>
      </span>
    </button>`).join("");
}

async function refresh() {
  try {
    const r = await Market.list();
    state.listings = r.listings;
  } catch (e) { toast(e.message); }
  renderGrid();
}

$("#tabs").addEventListener("click", (e) => {
  const b = e.target.closest("[data-cat]"); if (!b) return;
  state.cat = b.dataset.cat; renderTabs(); renderGrid();
});
$("#search").addEventListener("input", (e) => { state.q = e.target.value; renderGrid(); });
$("#verifiedOnly").addEventListener("change", (e) => { state.verifiedOnly = e.target.checked; renderGrid(); });
$("#sort").addEventListener("change", (e) => { state.sort = e.target.value; renderGrid(); });

/* ---------- listing detail ---------- */
$("#grid").addEventListener("click", (e) => {
  const b = e.target.closest("[data-id]"); if (!b) return;
  const l = state.listings.find((x) => x.id === b.dataset.id); if (l) openListing(l);
});

function openListing(l) {
  const s = l.seller;
  const trust = s.verified
    ? `<div class="safe"><b>Verified seller.</b> Vaultix staff checked this seller. Still only pay the way you agreed in writing.</div>`
    : `<div class="warn">
        <b>Risky: this seller is not verified.</b>
        <span>Nobody has checked who they are. If they scam you, there is no one to get your money back.</span>
        <ul>
          <li>Don't pay first with gift cards or crypto.</li>
          <li>Use a middleman or payment with buyer protection.</li>
          <li>Prefer a verified seller if one has the same item.</li>
        </ul>
      </div>`;
  $("#viewBody").innerHTML = `
    <div class="dlg-head">
      <div><p class="mono muted">${esc(l.category)} · listed ${date(l.createdAt)}</p><h2>${esc(l.title)}</h2></div>
      <button class="x" data-close aria-label="Close">×</button>
    </div>
    <p class="price">${money(l.price)}</p>
    ${trust}
    <p class="desc">${esc(l.description)}</p>
    <dl class="meta">
      <dt>Seller</dt><dd>@${esc(s.name)} ${badge(s, true)}</dd>
      <dt>Member since</dt><dd>${date(s.createdAt)}</dd>
      <dt>Listings</dt><dd>${state.listings.filter((x) => x.seller.id === s.id).length}</dd>
    </dl>
    <div id="contactSlot"><button class="btn wide" id="revealContact" type="button">${s.verified ? "Contact seller" : "I understand the risk — show contact"}</button></div>`;
  $("#revealContact").addEventListener("click", () => {
    $("#contactSlot").innerHTML = `<p class="mono muted" style="margin-bottom:6px">Contact @${esc(s.name)}</p><div class="contact">${esc(s.contact)}</div>`;
  });
  $("#viewDlg").showModal();
}

/* ---------- account ---------- */
async function loadMe() {
  const sess = Market.session();
  if (!sess) { state.me = null; return renderAccountBtn(); }
  try { state.me = (await Market.me()).seller; }
  catch (e) { if (e.status === 401 || /signed in/.test(e.message)) Market.signOut(); state.me = null; }
  renderAccountBtn();
}
function renderAccountBtn() {
  $("#accountBtn").textContent = state.me ? `@${state.me.name}` : "Sign up";
}

$("#accountBtn").addEventListener("click", () => state.me ? openMe() : openJoin());
$("#sellBtn").addEventListener("click", startSell);
$("#emptySell").addEventListener("click", startSell);

let afterJoin = null;
function startSell() { state.me ? openPost() : openJoin(openPost); }
function openJoin(next) {
  afterJoin = typeof next === "function" ? next : null;
  $("#joinErr").textContent = ""; $("#joinForm").reset(); $("#joinDlg").showModal();
}

$("#joinForm").addEventListener("submit", async (e) => {
  if (e.submitter && e.submitter.value === "cancel") return;
  e.preventDefault();
  const f = e.target, btn = f.querySelector("[type=submit]");
  btn.disabled = true; $("#joinErr").textContent = "";
  try {
    state.me = await Market.register(f.elements.name.value, f.elements.contact.value);
    renderAccountBtn(); $("#joinDlg").close();
    toast("Seller account created. You're marked Risky until staff verify you.");
    if (afterJoin) afterJoin();
  } catch (err) { $("#joinErr").textContent = err.message; }
  btn.disabled = false;
});

function openPost() {
  $("#postCat").innerHTML = Market.CATEGORIES.map((c) => `<option>${c}</option>`).join("");
  $("#postErr").textContent = ""; $("#postForm").reset(); $("#postDlg").showModal();
}
$("#postForm").addEventListener("submit", async (e) => {
  if (e.submitter && e.submitter.value === "cancel") return;
  e.preventDefault();
  const f = e.target, btn = f.querySelector("[type=submit]");
  btn.disabled = true; $("#postErr").textContent = "";
  try {
    const el = f.elements;
    await Market.post({ title: el.title.value, price: el.price.value, category: el.category.value, description: el.description.value });
    $("#postDlg").close(); toast("Listing published."); await refresh();
  } catch (err) { $("#postErr").textContent = err.message; }
  btn.disabled = false;
});

function openMe() {
  const me = state.me;
  const mine = state.listings.filter((l) => l.seller.id === me.id);
  $("#meBody").innerHTML = `
    <div class="dlg-head"><h2>@${esc(me.name)}</h2><button class="x" data-close aria-label="Close">×</button></div>
    <p>Status: ${badge(me)}</p>
    ${me.verified
      ? `<div class="safe">You're verified. Buyers see a green Verified badge on all your listings.</div>`
      : `<div class="warn"><b>Your listings show as Risky.</b><span>To get verified, send the site owner your seller ID below. Once they check you, the badge turns green.</span></div>
         <p class="mono muted">Seller ID</p><div class="contact idbox">${esc(me.id)}</div>`}
    <p class="mono muted">Your listings (${mine.length})</p>
    <div class="mine">${mine.length ? mine.map((l) => `
      <div class="mine-item"><span>${esc(l.title)} · ${money(l.price)}</span><button class="btn danger" data-del="${esc(l.id)}" type="button">Delete</button></div>`).join("")
      : `<p class="muted">No listings yet.</p>`}</div>
    <div class="row"><button class="btn" id="meSell" type="button">New listing</button><button class="btn ghost" id="signOut" type="button">Sign out</button></div>
    <p class="muted" style="font-size:.82rem">Signing out on this device can't be undone — your seller login is stored only in this browser.</p>`;
  $("#meSell").addEventListener("click", () => { $("#meDlg").close(); openPost(); });
  $("#signOut").addEventListener("click", () => {
    if (!confirm("Sign out? You won't be able to sign back in to this seller account from this browser.")) return;
    Market.signOut(); state.me = null; renderAccountBtn(); $("#meDlg").close();
  });
  $("#meDlg").showModal();
}
$("#meBody").addEventListener("click", async (e) => {
  const b = e.target.closest("[data-del]"); if (!b) return;
  if (!confirm("Delete this listing?")) return;
  try { await Market.remove(b.dataset.del); await refresh(); openMe(); toast("Listing deleted."); }
  catch (err) { toast(err.message); }
});

/* ---------- dialogs: close buttons + click outside ---------- */
document.querySelectorAll("dialog").forEach((d) => {
  d.addEventListener("click", (e) => {
    if (e.target === d || e.target.closest("[data-close]")) d.close();
  });
});

/* ---------- misc ---------- */
let tt;
function toast(msg) {
  const t = $("#toast"); t.textContent = msg; t.classList.add("show");
  clearTimeout(tt); tt = setTimeout(() => t.classList.remove("show"), 2800);
}
$("#year").textContent = new Date().getFullYear();

(async () => {
  renderTabs();
  const r = await Market.init();
  state.listings = r.listings;
  $("#demoBar").hidden = Market.mode !== "demo";
  renderGrid();
  await loadMe();
})();
