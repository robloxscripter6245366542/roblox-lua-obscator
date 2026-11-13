// Vaultix Market — storefront UI
const $ = (s) => document.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const money = (n) => "$" + Number(n).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const date = (t) => new Date(t).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });
const pctOff = (l) => (l.wasPrice > l.price ? Math.round((1 - l.price / l.wasPrice) * 100) : 0);
const badge = (s, sm) => s && s.verified
  ? `<span class="badge ok${sm ? " sm" : ""}">Verified</span>`
  : `<span class="badge risk${sm ? " sm" : ""}">Risky</span>`;
const CHEVRON = `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg>`;
const PERSON = `<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>`;

const state = { listings: [], cat: null, game: null, q: "", verifiedOnly: false, sort: "new", browseAll: false, me: null };

/* ---------- game tiles: a coloured monogram per game (no third-party logos) ---------- */
function gameTile(game) {
  const name = String(game || "?");
  let h = 0;
  for (const ch of name.toLowerCase()) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  const hue = h % 360;
  const words = name.trim().split(/\s+/);
  const mono = (words.length > 1 ? words[0][0] + words[1][0] : name.slice(0, 2)).toUpperCase();
  return `<span class="gtile" style="background:linear-gradient(135deg,hsl(${hue} 70% 52%),hsl(${(hue + 40) % 360} 65% 38%))">${esc(mono)}</span>`;
}

/* ---------- recently viewed (per browser) ---------- */
const RECENT = "vx-recent";
const getRecent = () => { try { return JSON.parse(localStorage.getItem(RECENT)) || []; } catch { return []; } };
function pushRecent(id) {
  const r = [id, ...getRecent().filter((x) => x !== id)].slice(0, 12);
  try { localStorage.setItem(RECENT, JSON.stringify(r)); } catch {}
}

/* ---------- cards ---------- */
function card(l) {
  const off = pctOff(l);
  return `
  <button class="card" data-id="${esc(l.id)}" type="button">
    <span class="card-top">${gameTile(l.game)}${badge(l.seller, true)}</span>
    <span class="card-body">
      <span class="card-meta">${gameTile(l.game)}<span>${esc(l.game)} · ${esc(l.category)}</span></span>
      <span class="card-title">${esc(l.title)}</span>
      <span class="card-price">
        <span class="was">${off ? money(l.wasPrice) : ""}</span>
        <span class="now${off ? " deal" : ""}"><b>${money(l.price)}</b>${off ? `<span class="off">-${off}%</span>` : ""}</span>
      </span>
      <span class="card-seller"><span>@${esc(l.seller.name)}</span>${badge(l.seller, true)}</span>
    </span>
  </button>`;
}
const section = (title, items, opts = {}) => `
  <section class="sec">
    <div class="sec-head"><h2>${esc(title)}</h2>${opts.action || ""}</div>
    <div class="${opts.row ? "row" : "grid"}">${items.map(card).join("")}</div>
  </section>`;

/* ---------- filtering ---------- */
const browsing = () => !!(state.cat || state.game || state.q.trim() || state.browseAll);

function filtered() {
  const q = state.q.trim().toLowerCase();
  const out = state.listings.filter((l) =>
    (!state.cat || l.category === state.cat) &&
    (!state.game || l.game.toLowerCase() === state.game.toLowerCase()) &&
    (!state.verifiedOnly || l.seller.verified) &&
    (!q || `${l.title} ${l.game} ${l.category} ${l.description} ${l.seller.name}`.toLowerCase().includes(q)));
  const by = {
    new: (a, b) => b.createdAt - a.createdAt,
    low: (a, b) => a.price - b.price,
    high: (a, b) => b.price - a.price,
    deal: (a, b) => pctOff(b) - pctOff(a) || b.createdAt - a.createdAt,
  }[state.sort];
  return out.sort(by);
}

function render() {
  renderCats();
  const all = state.listings;
  const browse = browsing();
  $("#filterbar").hidden = !browse;
  let html = "";

  if (browse) {
    const chips = [];
    if (state.cat) chips.push(`<span class="chip">${esc(state.cat)}<button data-clear="cat" aria-label="Remove ${esc(state.cat)} filter">×</button></span>`);
    if (state.game) chips.push(`<span class="chip">${esc(state.game)}<button data-clear="game" aria-label="Remove ${esc(state.game)} filter">×</button></span>`);
    if (state.q.trim()) chips.push(`<span class="chip">“${esc(state.q.trim())}”<button data-clear="q" aria-label="Clear search">×</button></span>`);
    $("#crumbs").innerHTML = `<button class="link-btn" data-clear="all" type="button">← Home</button>${chips.join("")}`;
    const list = filtered();
    const title = [state.game, state.cat].filter(Boolean).join(" · ") || (state.q.trim() ? "Search results" : "All listings");
    if (list.length) html = section(`${title} (${list.length})`, list);
    setEmpty(list.length === 0, all.length === 0
      ? ["Nothing for sale yet", "This market just opened. Be the first to post a listing.", true]
      : ["No listings match", state.verifiedOnly ? "No verified sellers here yet. Try turning off “Verified sellers only”." : "Try another game, category or search.", false]);
  } else {
    if (all.length) {
      const verified = all.filter((l) => l.seller.verified).slice(0, 12);
      const recent = getRecent().map((id) => all.find((l) => l.id === id)).filter(Boolean);
      const deals = all.filter((l) => pctOff(l) > 0).sort((a, b) => pctOff(b) - pctOff(a)).slice(0, 12);
      if (verified.length) html += section("From verified sellers", verified, { row: true });
      if (deals.length) html += section("Best deals", deals, { row: true });
      if (recent.length) html += section("Recently viewed", recent, { row: true });
      html += section("Latest listings", all.slice(0, 24), {
        action: all.length > 24 ? `<button class="link-btn" id="seeAll" type="button">See all ${all.length}</button>` : "",
      });
    }
    setEmpty(all.length === 0, ["Nothing for sale yet", "This market just opened. Be the first to post a listing.", true]);
  }
  $("#sections").innerHTML = html;
}

function setEmpty(show, [title, text, canSell]) {
  $("#empty").hidden = !show;
  $("#emptyTitle").textContent = title;
  $("#emptyText").textContent = text;
  $("#emptySell").hidden = !canSell;
}

/* ---------- category bar + dropdown ---------- */
function renderCats() {
  $("#cats").innerHTML = Market.CATEGORIES.map((c) =>
    `<button class="cat${state.cat === c ? " active" : ""}" data-cat="${esc(c)}" aria-haspopup="true" aria-expanded="${openCat === c}" type="button">${esc(c)}${CHEVRON}</button>`).join("");
}

let openCat = null;
function openMenu(btn) {
  const cat = btn.dataset.cat;
  if (openCat === cat) return closeMenu();
  openCat = cat;
  const inCat = state.listings.filter((l) => l.category === cat);
  const games = {};
  for (const l of inCat) games[l.game] = (games[l.game] || 0) + 1;
  const names = Object.keys(games).sort((a, b) => games[b] - games[a] || a.localeCompare(b));
  const m = $("#catMenu");
  m.innerHTML = `
    <button class="menu-all" data-pick-cat="${esc(cat)}" type="button">All ${esc(cat)} <span class="count">${inCat.length}</span></button>
    ${names.length
      ? names.map((g) => `<button data-pick-cat="${esc(cat)}" data-pick-game="${esc(g)}" type="button"><span style="display:flex;align-items:center;gap:10px">${gameTile(g)}${esc(g)}</span><span class="count">${games[g]}</span></button>`).join("")
      : `<p>No ${esc(cat.toLowerCase())} listings yet.</p>`}`;
  const r = btn.getBoundingClientRect(), top = $(".top").getBoundingClientRect();
  m.hidden = false;
  m.style.top = `${r.bottom - top.top + 4}px`;
  m.style.left = `${Math.max(16, Math.min(r.left, window.innerWidth - m.offsetWidth - 16))}px`;
  renderCats();
}
function closeMenu() {
  if (!openCat) return;
  openCat = null; $("#catMenu").hidden = true; renderCats();
}

$("#cats").addEventListener("click", (e) => {
  const b = e.target.closest("[data-cat]"); if (!b) return;
  e.stopPropagation(); // the bar re-renders, so the outside-click check below would see a detached target
  openMenu(b);
});
$("#cats").addEventListener("scroll", closeMenu);
$("#catMenu").addEventListener("click", (e) => {
  const b = e.target.closest("[data-pick-cat]"); if (!b) return;
  state.cat = b.dataset.pickCat; state.game = b.dataset.pickGame || null;
  closeMenu(); render(); window.scrollTo({ top: 0 });
});
document.addEventListener("click", (e) => { if (!e.target.closest("#catMenu, #cats")) closeMenu(); });
window.addEventListener("resize", closeMenu);

$("#crumbs").addEventListener("click", (e) => {
  const b = e.target.closest("[data-clear]"); if (!b) return;
  const k = b.dataset.clear;
  if (k === "all") { state.cat = state.game = null; state.q = ""; state.browseAll = false; $("#search").value = ""; }
  else if (k === "q") { state.q = ""; $("#search").value = ""; }
  else state[k] = null;
  render();
});
$("#search").addEventListener("input", (e) => { state.q = e.target.value; render(); });
$("#verifiedOnly").addEventListener("change", (e) => { state.verifiedOnly = e.target.checked; render(); });
$("#sort").addEventListener("change", (e) => { state.sort = e.target.value; render(); });
$("#sections").addEventListener("click", (e) => {
  if (e.target.closest("#seeAll")) { state.browseAll = true; render(); window.scrollTo({ top: 0 }); return; }
  const c = e.target.closest("[data-id]"); if (!c) return;
  const l = state.listings.find((x) => x.id === c.dataset.id); if (l) openListing(l);
});

/* ---------- listing detail ---------- */
function openListing(l) {
  pushRecent(l.id);
  const s = l.seller, off = pctOff(l);
  const trust = s.verified
    ? `<div class="safe"><b>Verified seller.</b> Vaultix staff checked this seller. Still only pay the way you agreed in writing.</div>`
    : `<div class="warn">
        <b>Risky — this seller is not verified.</b>
        <span>Nobody has checked who they are. If they scam you, there's no one to get your money back.</span>
        <ul><li>Don't pay first with gift cards or crypto.</li><li>Use a middleman or a payment method with buyer protection.</li><li>Prefer a verified seller if one has the same item.</li></ul>
      </div>`;
  $("#viewBody").innerHTML = `
    <div class="dlg-head">
      <div class="view-top">${gameTile(l.game)}<div><p class="muted">${esc(l.game)} · ${esc(l.category)}</p><h2>${esc(l.title)}</h2></div></div>
      <button class="x" data-close aria-label="Close">×</button>
    </div>
    <div class="view-price"><b>${money(l.price)}</b>${off ? `<s>${money(l.wasPrice)}</s><span class="off">-${off}%</span>` : ""}</div>
    ${trust}
    <p class="desc">${esc(l.description)}</p>
    <dl class="meta">
      <dt>Seller</dt><dd>@${esc(s.name)} ${badge(s, true)}</dd>
      <dt>Member since</dt><dd>${date(s.createdAt)}</dd>
      <dt>Active listings</dt><dd>${state.listings.filter((x) => x.seller.id === s.id).length}</dd>
      <dt>Listed</dt><dd>${date(l.createdAt)}</dd>
    </dl>
    <div id="contactSlot"><button class="btn ${s.verified ? "sell" : "danger"} wide" id="revealContact" type="button">${s.verified ? "Contact seller" : "I understand the risk — show contact"}</button></div>`;
  $("#revealContact").addEventListener("click", () => {
    $("#contactSlot").innerHTML = `<p class="muted" style="margin-bottom:6px">Contact @${esc(s.name)}</p><div class="contact">${esc(s.contact)}</div>`;
  });
  $("#viewDlg").showModal();
  if (!browsing()) render(); // refresh "Recently viewed"
}

/* ---------- account ---------- */
async function loadMe() {
  if (!Market.session()) { state.me = null; return renderAvatar(); }
  try { state.me = (await Market.me()).seller; }
  catch (e) { if (e.status === 401 || /signed in/.test(e.message)) Market.signOut(); state.me = null; }
  renderAvatar();
}
function renderAvatar() {
  const a = $("#accountBtn"), me = state.me;
  a.innerHTML = me ? `${esc(me.name[0].toUpperCase())}<span class="dot ${me.verified ? "ok" : "risk"}"></span>` : PERSON;
  a.setAttribute("aria-label", me ? `Your seller account @${me.name}` : "Sign up as a seller");
}

$("#accountBtn").addEventListener("click", () => (state.me ? openMe() : openJoin()));
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
    renderAvatar(); $("#joinDlg").close();
    toast("Seller account created. You're marked Risky until staff verify you.");
    if (afterJoin) afterJoin();
  } catch (err) { $("#joinErr").textContent = err.message; }
  btn.disabled = false;
});

function openPost() {
  $("#postCat").innerHTML = Market.CATEGORIES.map((c) => `<option${c === state.cat ? " selected" : ""}>${esc(c)}</option>`).join("");
  const games = [...new Set([...Market.GAMES, ...state.listings.map((l) => l.game)])].sort();
  $("#gameList").innerHTML = games.map((g) => `<option value="${esc(g)}"></option>`).join("");
  $("#postErr").textContent = "";
  $("#postForm").reset();
  if (state.cat) $("#postCat").value = state.cat;
  if (state.game) $("#postForm").elements.game.value = state.game;
  $("#postDlg").showModal();
}
$("#postForm").addEventListener("submit", async (e) => {
  if (e.submitter && e.submitter.value === "cancel") return;
  e.preventDefault();
  const el = e.target.elements, btn = e.target.querySelector("[type=submit]");
  btn.disabled = true; $("#postErr").textContent = "";
  try {
    await Market.post({
      game: el.game.value, category: el.category.value, title: el.title.value,
      price: el.price.value, wasPrice: el.wasPrice.value, description: el.description.value,
    });
    $("#postDlg").close(); toast("Listing published."); await refresh();
  } catch (err) { $("#postErr").textContent = err.message; }
  btn.disabled = false;
});

function openMe() {
  const me = state.me, mine = state.listings.filter((l) => l.seller.id === me.id);
  $("#meBody").innerHTML = `
    <div class="dlg-head"><h2>@${esc(me.name)}</h2><button class="x" data-close aria-label="Close">×</button></div>
    <p>Status: ${badge(me)}</p>
    ${me.verified
      ? `<div class="safe"><b>You're verified.</b> Buyers see a green Verified badge on all your listings.</div>`
      : `<div class="warn"><b>Your listings show as Risky.</b><span>To get verified, send the site owner your seller ID below. Once they check you, your badge turns green.</span></div>
         <p class="muted">Seller ID</p><div class="contact" style="user-select:all">${esc(me.id)}</div>`}
    <p class="muted">Your listings (${mine.length})</p>
    <div class="mine">${mine.length ? mine.map((l) => `
      <div class="mine-item"><span>${esc(l.game)} · ${esc(l.title)} · ${money(l.price)}</span><button class="btn danger" data-del="${esc(l.id)}" type="button">Delete</button></div>`).join("")
      : `<p class="muted">No listings yet.</p>`}</div>
    <div class="btnrow"><button class="btn sell" id="meSell" type="button">New listing</button><button class="btn ghost" id="signOut" type="button">Sign out</button></div>
    <p class="muted" style="font-size:.82rem">Your seller login is saved only in this browser. If you sign out, you can't sign back in to this account.</p>`;
  $("#meSell").addEventListener("click", () => { $("#meDlg").close(); openPost(); });
  $("#signOut").addEventListener("click", () => {
    if (!confirm("Sign out? You won't be able to sign back in to this seller account.")) return;
    Market.signOut(); state.me = null; renderAvatar(); $("#meDlg").close();
  });
  $("#meDlg").showModal();
}
$("#meBody").addEventListener("click", async (e) => {
  const b = e.target.closest("[data-del]"); if (!b) return;
  if (!confirm("Delete this listing?")) return;
  try { await Market.remove(b.dataset.del); await refresh(); openMe(); toast("Listing deleted."); }
  catch (err) { toast(err.message); }
});

/* ---------- dialogs ---------- */
document.querySelectorAll("dialog").forEach((d) => d.addEventListener("click", (e) => {
  if (e.target === d || e.target.closest("[data-close]")) d.close();
}));
document.addEventListener("keydown", (e) => { if (e.key === "Escape") closeMenu(); });

/* ---------- misc ---------- */
let tt;
function toast(msg) {
  const t = $("#toast"); t.textContent = msg; t.classList.add("show");
  clearTimeout(tt); tt = setTimeout(() => t.classList.remove("show"), 2800);
}
async function refresh() {
  try { state.listings = (await Market.list()).listings; } catch (e) { toast(e.message); }
  render();
}

(async () => {
  renderAvatar(); render();
  state.listings = (await Market.init()).listings;
  $("#demoBar").hidden = Market.mode !== "demo";
  render();
  await loadMe();
})();
