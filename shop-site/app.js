// Vaultix Market — storefront UI
const $ = (s) => document.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const money = (n) => "$" + Number(n).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const date = (t) => new Date(t).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });
const pctOff = (l) => (l.wasPrice > l.price ? Math.round((1 - l.price / l.wasPrice) * 100) : 0);
const badge = (s, sm) => s && s.owner
  ? `<span class="badge owner${sm ? " sm" : ""}">Owner</span>`
  : s && s.verified
  ? `<span class="badge ok${sm ? " sm" : ""}">Verified</span>`
  : `<span class="badge risk${sm ? " sm" : ""}">Risky</span>`;
const CHEVRON = `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg>`;
const PERSON = `<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>`;

const state = { owners: [], listings: [], icons: {}, cat: null, game: null, q: "", verifiedOnly: false, sort: "new", browseAll: false, me: null, wallet: null, payouts: [], fees: { pct: 0.03, fixed: 0.3, commission: 0.05 } };
const OTHER = "__other";

/* ---------- game art ----------
   1. seller's own picture (games not in games.js)
   2. official game icon (looked up by the API)
   3. coloured monogram if neither is available or an image fails to load */
function monogram(game) {
  const name = String(game || "?");
  let h = 0;
  for (const ch of name.toLowerCase()) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  const hue = h % 360;
  const words = name.trim().split(/\s+/);
  const mono = (words.length > 1 ? words[0][0] + words[1][0] : name.slice(0, 2)).toUpperCase();
  return `<span class="gtile" style="background:linear-gradient(135deg,hsl(${hue} 70% 52%),hsl(${(hue + 40) % 360} 65% 38%))">${esc(mono)}</span>`;
}
const isSteam = (game) => { const g = Market.Games.find(game); return !!(g && g.steam); };
const img = (src, cls, game) => `<img class="${cls}" src="${esc(src)}" alt="" loading="lazy" decoding="async" referrerpolicy="no-referrer" data-game="${esc(game)}" data-cls="${cls}" />`;
// Small square tile (card meta row, menus, detail header)
function gameTile(game) {
  const icon = state.icons[game];
  return icon ? img(icon, "gtile", game) : monogram(game);
}
// Big art at the top of a card
function cardArt(l) {
  const own = Market.imageUrl(l);
  if (own) return img(own, "art-cover", l.game);
  const icon = state.icons[l.game];
  if (icon) return img(icon, isSteam(l.game) ? "art-cover" : "gtile art-icon", l.game);
  return monogram(l.game).replace('class="gtile"', 'class="gtile art-icon"');
}
// Broken image -> monogram
document.addEventListener("error", (e) => {
  const el = e.target;
  if (el.tagName !== "IMG" || el.dataset.game == null) return;
  const t = document.createElement("span");
  t.innerHTML = monogram(el.dataset.game);
  const m = t.firstChild;
  if ((el.dataset.cls || "").includes("art")) m.classList.add("art-icon");
  el.replaceWith(m);
}, true);

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
    <span class="card-top">${cardArt(l)}${badge(l.seller, true)}${l.delivery === "instant" ? `<span class="instant-tag">⚡ Instant</span>` : ""}</span>
    <span class="card-body">
      <span class="card-meta">${gameTile(l.game)}<span>${esc(l.game)} · ${esc(l.category)}</span></span>
      <span class="card-title">${esc(l.title)}</span>
      <span class="card-price">
        <span class="was">${off ? money(l.wasPrice) : ""}</span>
        <span class="now${off ? " deal" : ""}"><b>${money(l.price)}</b>${off ? `<span class="off">-${off}%</span>` : ""}</span>
      </span>
      <span class="card-seller"><span class="seller-link" data-user="${esc(l.seller.id)}">@${esc(l.seller.name)}</span>${badge(l.seller, true)}</span>
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
  const who = e.target.closest("[data-user]");
  if (who) { e.stopPropagation(); openProfile(who.dataset.user); return; }
  const c = e.target.closest("[data-id]"); if (!c) return;
  const l = state.listings.find((x) => x.id === c.dataset.id); if (l) openListing(l);
});

/* ---------- listing detail ---------- */
function openListing(l) {
  pushRecent(l.id);
  const s = l.seller, off = pctOff(l);
  const trust = s.verified
    ? `<div class="safe"><b>Verified seller.</b> Vaultix staff checked this seller. Your payment is still held until you confirm delivery.</div>`
    : `<div class="warn">
        <b>Risky — this seller is not verified.</b>
        <span>Nobody has checked who they are. Your payment is held in escrow, so report a problem before confirming if anything is wrong.</span>
      </div>`;
  $("#viewBody").innerHTML = `
    <div class="dlg-head">
      <div class="view-top">${gameTile(l.game)}<div><p class="muted">${esc(l.game)} · ${esc(l.category)}</p><h2>${esc(l.title)}</h2></div></div>
      <button class="x" data-close aria-label="Close">×</button>
    </div>
    ${Market.imageUrl(l) ? `<img class="view-pic" src="${esc(Market.imageUrl(l))}" alt="Picture of ${esc(l.title)}" />` : ""}
    <div class="view-price"><b>${money(l.price)}</b>${off ? `<s>${money(l.wasPrice)}</s><span class="off">-${off}%</span>` : ""}</div>
    ${trust}
    <p class="desc">${esc(l.description)}</p>
    <dl class="meta">
      <dt>Seller</dt><dd><button class="link-btn" data-user="${esc(s.id)}" type="button">@${esc(s.name)}</button> ${badge(s, true)}</dd>
      <dt>Rating</dt><dd>${s.reviews ? `${s.positive}% positive · ${s.reviews} review${s.reviews === 1 ? "" : "s"}` : "No reviews yet"} · ${s.sales || 0} sale${s.sales === 1 ? "" : "s"}</dd>
      <dt>Delivery</dt><dd>${l.delivery === "instant" ? "⚡ Instant: the login appears on your order page right after you pay" : "The seller delivers in your order chat"}</dd>
      <dt>In stock</dt><dd>${l.stock ?? 1}</dd>
      <dt>Listed</dt><dd>${date(l.createdAt)}</dd>
    </dl>
    ${state.me && state.me.id === s.id
      ? `<p class="muted">This is your listing.</p>`
      : `<a class="btn sell wide" href="#/checkout/${esc(l.id)}" data-close>Buy now · ${money(l.price)}</a>`}`;
  $("#viewDlg").showModal();
  if (!browsing()) render(); // refresh "Recently viewed"
}

/* ---------- account ---------- */
async function loadMe() {
  if (!Market.session()) { state.me = null; return renderAvatar(); }
  try {
    const r = await Market.me();
    state.me = r.seller; state.wallet = r.wallet || null; state.payouts = r.payouts || [];
  } catch (e) { if (e.status === 401 || /sign in|signed in/.test(e.message)) Market.signOut(); state.me = null; }
  renderAvatar();
}
function renderAvatar() {
  const a = $("#accountBtn"), me = state.me;
  a.innerHTML = me ? `${esc(me.name[0].toUpperCase())}<span class="dot ${me.owner ? "owner" : me.verified ? "ok" : "risk"}"></span>` : PERSON;
  a.setAttribute("aria-label", me ? `Your seller account @${me.name}` : "Sign up as a seller");
}

$("#accountBtn").addEventListener("click", () => (state.me ? openAccount() : openJoin()));
$("#sellBtn").addEventListener("click", startSell);
$("#emptySell").addEventListener("click", startSell);

let afterJoin = null;
function startSell() { state.me ? openPost() : openJoin(openPost); }
function openJoin(next) {
  afterJoin = typeof next === "function" ? next : null;
  $("#joinErr").textContent = ""; $("#joinForm").reset(); $("#ownerKeyRow").hidden = true; $("#joinDlg").showModal();
}
// Owner usernames are reserved: ask for the staff password when one is typed.
$("#joinForm").elements.name.addEventListener("input", (e) => {
  $("#ownerKeyRow").hidden = !state.owners.includes(e.target.value.trim().toLowerCase());
});
$("#joinForm").addEventListener("submit", async (e) => {
  if (e.submitter && e.submitter.value === "cancel") return;
  e.preventDefault();
  const f = e.target, btn = f.querySelector("[type=submit]");
  btn.disabled = true; $("#joinErr").textContent = "";
  try {
    state.me = await Market.register(f.elements.name.value, f.elements.contact.value, $("#ownerKeyRow").hidden ? "" : f.elements.ownerKey.value);
    renderAvatar(); $("#joinDlg").close();
    toast(state.me.owner ? "Welcome, owner 👑 You're verified and can open the Staff page from your account menu." : "Account created. As a seller you're marked Risky until staff verify you.");
    if (afterJoin) afterJoin();
  } catch (err) { $("#joinErr").textContent = err.message; }
  btn.disabled = false;
});

let picData = null;
function resetPic() {
  picData = null;
  $("#picInput").value = "";
  $("#picPreview").hidden = true; $("#picPreview").removeAttribute("src");
  $("#picHint").hidden = false;
}
function toggleOther() {
  const other = $("#postGame").value === OTHER;
  $("#otherGame").hidden = !other;
  $("#postForm").elements.gameOther.required = other;
}
/* ---------- instant delivery logins ---------- */
let instantTouched = false;
function loginRow() {
  const d = document.createElement("div");
  d.className = "login-row";
  d.innerHTML = `
    <div class="login-row-head"><b class="small">Account <span class="n"></span></b><button type="button" class="x sm" data-remove-login aria-label="Remove this account">×</button></div>
    <div class="two">
      <input data-f="login" maxlength="120" placeholder="Username / login *" autocomplete="off" />
      <input data-f="password" maxlength="200" placeholder="Password *" autocomplete="new-password" />
      <input data-f="email" maxlength="120" placeholder="Email (optional)" autocomplete="off" />
      <input data-f="emailPassword" maxlength="200" placeholder="Email password (optional)" autocomplete="new-password" />
    </div>
    <input data-f="notes" maxlength="300" placeholder="Notes for the buyer (optional), e.g. recovery codes, 2FA info" autocomplete="off" />`;
  return d;
}
function renumberLogins() {
  const rows = [...document.querySelectorAll("#loginRows .login-row")];
  rows.forEach((r, i) => { r.querySelector(".n").textContent = i + 1; r.querySelector("[data-remove-login]").hidden = rows.length === 1; });
}
function setInstant(on) {
  $("#instantOn").checked = on;
  $("#loginRows").hidden = $("#addLogin").hidden = $("#loginNote").hidden = !on;
  $("#stockLabel").hidden = on;
  if (on && !$("#loginRows").children.length) { $("#loginRows").append(loginRow()); renumberLogins(); }
}
$("#instantOn").addEventListener("change", (e) => { instantTouched = true; setInstant(e.target.checked); });
$("#addLogin").addEventListener("click", () => {
  if ($("#loginRows").children.length >= 50) return toast("Up to 50 accounts per listing.");
  $("#loginRows").append(loginRow()); renumberLogins();
  $("#loginRows").lastElementChild.querySelector("input").focus();
});
$("#loginRows").addEventListener("click", (e) => {
  const b = e.target.closest("[data-remove-login]"); if (!b) return;
  b.closest(".login-row").remove(); renumberLogins();
});
$("#postCat").addEventListener("change", (e) => { if (!instantTouched) setInstant(e.target.value === "Accounts"); });
function collectLogins() {
  return [...document.querySelectorAll("#loginRows .login-row")].map((r) => {
    const o = {}; r.querySelectorAll("[data-f]").forEach((i) => (o[i.dataset.f] = i.value.trim())); return o;
  }).filter((o) => Object.values(o).some(Boolean));
}

function openPost() {
  $("#postCat").innerHTML = Market.CATEGORIES.map((c) => `<option>${esc(c)}</option>`).join("");
  const G = Market.Games.GAMES;
  const group = (label, list) => `<optgroup label="${label}">${list.map((g) => `<option>${esc(g.name)}</option>`).join("")}</optgroup>`;
  $("#postGame").innerHTML = `<option value="" disabled selected>Choose a game</option>`
    + group("Roblox", G.filter((g) => g.roblox || g.name === "Roblox"))
    + group("Mobile & cross-platform", G.filter((g) => g.apple && g.name !== "Roblox" && g.name !== "Steam"))
    + group("PC", G.filter((g) => g.steam || g.name === "Steam"))
    + `<option value="${OTHER}">Other game (not listed)…</option>`;
  $("#postErr").textContent = "";
  $("#postForm").reset();
  resetPic();
  if (state.cat) $("#postCat").value = state.cat;
  instantTouched = false;
  $("#loginRows").innerHTML = "";
  setInstant($("#postCat").value === "Accounts");
  if (state.game) {
    const known = Market.Games.find(state.game);
    $("#postGame").value = known ? known.name : OTHER;
    if (!known) $("#postForm").elements.gameOther.value = state.game;
  }
  toggleOther();
  $("#postDlg").showModal();
}
$("#postGame").addEventListener("change", toggleOther);

// Shrink the picture in the browser (max 640px, JPEG) so uploads stay small.
$("#picInput").addEventListener("change", async (e) => {
  const file = e.target.files && e.target.files[0];
  if (!file) return;
  $("#postErr").textContent = "";
  if (!/^image\/(png|jpeg|webp)$/.test(file.type)) { resetPic(); $("#postErr").textContent = "Use a PNG, JPG or WebP picture."; return; }
  try {
    const bmp = await createImageBitmap(file);
    const scale = Math.min(1, 640 / Math.max(bmp.width, bmp.height));
    const c = document.createElement("canvas");
    c.width = Math.round(bmp.width * scale); c.height = Math.round(bmp.height * scale);
    c.getContext("2d").drawImage(bmp, 0, 0, c.width, c.height);
    let q = 0.85, url = c.toDataURL("image/jpeg", q);
    while (url.length > 260000 && q > 0.4) { q -= 0.1; url = c.toDataURL("image/jpeg", q); } // ~190 KB of bytes
    if (url.length > 270000) throw new Error("too big");
    picData = url;
    $("#picPreview").src = url; $("#picPreview").hidden = false; $("#picHint").hidden = true;
  } catch { resetPic(); $("#postErr").textContent = "Couldn't read that picture. Try another one."; }
});
$("#postForm").addEventListener("submit", async (e) => {
  if (e.submitter && e.submitter.value === "cancel") return;
  e.preventDefault();
  const el = e.target.elements, btn = e.target.querySelector("[type=submit]");
  btn.disabled = true; $("#postErr").textContent = "";
  try {
    const other = el.game.value === OTHER;
    if (!el.game.value) throw new Error("Choose a game");
    if (other && !picData) throw new Error("Add a picture for your game");
    const instant = $("#instantOn").checked;
    const logins = instant ? collectLogins() : undefined;
    if (instant && !logins.length) throw new Error("Add at least one account login, or turn off instant delivery.");
    if (instant && logins.some((x) => !x.login || !x.password)) throw new Error("Each account needs a username and a password.");
    await Market.post({
      delivery: instant ? "instant" : "manual", logins,
      game: other ? el.gameOther.value : el.game.value, image: other ? picData : undefined,
      category: el.category.value, title: el.title.value,
      price: el.price.value, wasPrice: el.wasPrice.value, stock: el.stock.value, description: el.description.value,
    });
    $("#postDlg").close(); toast("Listing published."); await refresh();
  } catch (err) { $("#postErr").textContent = err.message; }
  btn.disabled = false;
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
  try { const r = await Market.list(); state.listings = r.listings; if (r.fees) state.fees = r.fees; if (r.owners) state.owners = r.owners; } catch (e) { toast(e.message); }
  render();
}

$("#footPay").innerHTML = ["visa", "mastercard", "americanexpress", "discover", "applepay", "googlepay"].map(payLogo).join("");

(async () => {
  renderAvatar(); render();
  const first = await Market.init();
  state.listings = first.listings; if (first.fees) state.fees = first.fees; if (first.owners) state.owners = first.owners;
  $("#demoBar").hidden = Market.mode !== "demo";
  render();
  Market.icons().then((icons) => { state.icons = icons; render(); rerenderPage(); });
  await loadMe();
  startRouter(); // account.js
})();
