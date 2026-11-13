// Vaultix storefront — edit PRODUCTS to change what you sell.
const PRODUCTS = [
  { id: "acc-starter", cat: "Accounts", name: "Starter Account", desc: "Fresh, verified account with email access. Great for alts.", price: 4.99, icon: "👤", color: ["#3b2a8f", "#1b5b6b"], tag: "new" },
  { id: "acc-stacked", cat: "Accounts", name: "Stacked Account", desc: "High-level account with rare items and full email access.", price: 24.99, was: 34.99, icon: "💎", color: ["#5b2a8f", "#1b3f6b"], tag: "hot" },
  { id: "acc-og", cat: "Accounts", name: "OG Account (2016+)", desc: "Aged account with legacy badges and a clean history.", price: 49.99, icon: "🏆", color: ["#7a4b14", "#3b1f5b"] },
  { id: "acc-bundle", cat: "Accounts", name: "Alt Bundle ×5", desc: "Five ready-to-use alt accounts, delivered together.", price: 14.99, was: 19.99, icon: "🧩", color: ["#1f5b4b", "#2a2a8f"], tag: "sale" },
  { id: "key-week", cat: "Keys", name: "Script Hub Key — 7 days", desc: "Weekly license key for premium hub features.", price: 2.99, icon: "🔑", color: ["#2a4b8f", "#5b1b6b"] },
  { id: "key-month", cat: "Keys", name: "Script Hub Key — 30 days", desc: "Monthly key with priority updates and support.", price: 7.99, icon: "🗝️", color: ["#2a6b8f", "#3b1b6b"], tag: "hot" },
  { id: "key-life", cat: "Keys", name: "Lifetime Key", desc: "One payment, never expires. Includes all future updates.", price: 29.99, was: 44.99, icon: "♾️", color: ["#6b2a8f", "#1b6b5b"], tag: "sale" },
  { id: "item-pets", cat: "Items", name: "Rare Pet Pack", desc: "Bundle of 3 rare pets delivered by in-game trade.", price: 9.99, icon: "🐉", color: ["#8f2a4b", "#3b1b6b"] },
  { id: "item-skins", cat: "Items", name: "Legendary Skin Crate", desc: "Guaranteed legendary skin from the current season.", price: 6.49, icon: "🗡️", color: ["#8f5b2a", "#5b1b3b"], tag: "new" },
  { id: "item-coins", cat: "Items", name: "1M In-Game Coins", desc: "Fast coin delivery to your account via trade.", price: 3.99, icon: "🪙", color: ["#8f7a2a", "#3b3b1b"] },
  { id: "svc-boost", cat: "Services", name: "Rank Boost", desc: "Pro players push your rank up. Starts within 1 hour.", price: 19.99, icon: "🚀", color: ["#2a8f6b", "#1b2a6b"], tag: "hot" },
  { id: "svc-coach", cat: "Services", name: "1-on-1 Coaching (1h)", desc: "Live session with a top player to sharpen your game.", price: 14.99, icon: "🎯", color: ["#8f2a2a", "#2a1b6b"] },
];

const $ = (s) => document.querySelector(s);
const money = (n) => "$" + n.toFixed(2);
const artBg = (p) => `linear-gradient(135deg, ${p.color[0]}, ${p.color[1]})`;
const CATS = ["All", ...new Set(PRODUCTS.map((p) => p.cat))];

let activeCat = "All";
let query = "";
let cart = load();

function load() {
  try { return JSON.parse(localStorage.getItem("vaultix-cart")) || {}; } catch { return {}; }
}
function save() {
  try { localStorage.setItem("vaultix-cart", JSON.stringify(cart)); } catch {}
}

/* ---------- Catalog ---------- */
function renderFilters() {
  $("#filters").innerHTML = CATS.map(
    (c) => `<button class="chip ${c === activeCat ? "active" : ""}" data-cat="${c}" role="tab" aria-selected="${c === activeCat}">${c}</button>`
  ).join("");
}

function renderGrid() {
  const q = query.trim().toLowerCase();
  const list = PRODUCTS.filter(
    (p) => (activeCat === "All" || p.cat === activeCat) && (!q || (p.name + p.desc + p.cat).toLowerCase().includes(q))
  );
  $("#empty").hidden = list.length > 0;
  $("#grid").innerHTML = list.map((p) => `
    <article class="card">
      <div class="card-art" style="background:${artBg(p)}">
        ${p.tag ? `<span class="tag ${p.tag}">${p.tag.toUpperCase()}</span>` : ""}
        <span class="icon">${p.icon}</span>
      </div>
      <div class="card-body">
        <span class="card-cat">${p.cat}</span>
        <h3>${p.name}</h3>
        <p>${p.desc}</p>
        <span class="stock">● In stock · instant delivery</span>
        <div class="card-foot">
          <span class="price">${money(p.price)}${p.was ? `<s>${money(p.was)}</s>` : ""}</span>
          <button class="add-btn" data-add="${p.id}">Add to cart</button>
        </div>
      </div>
    </article>`).join("");
}

$("#filters").addEventListener("click", (e) => {
  const b = e.target.closest("[data-cat]");
  if (!b) return;
  activeCat = b.dataset.cat;
  renderFilters();
  renderGrid();
});
$("#search").addEventListener("input", (e) => { query = e.target.value; renderGrid(); });
$("#grid").addEventListener("click", (e) => {
  const b = e.target.closest("[data-add]");
  if (b) addToCart(b.dataset.add);
});

/* ---------- Cart ---------- */
function addToCart(id) {
  cart[id] = (cart[id] || 0) + 1;
  save();
  renderCart();
  const p = PRODUCTS.find((x) => x.id === id);
  toast(`Added ${p.name} to cart`);
  const badge = $("#cartCount");
  badge.classList.remove("bump"); void badge.offsetWidth; badge.classList.add("bump");
}

function changeQty(id, d) {
  cart[id] = (cart[id] || 0) + d;
  if (cart[id] <= 0) delete cart[id];
  save();
  renderCart();
}

function cartTotal() {
  return Object.entries(cart).reduce((s, [id, q]) => {
    const p = PRODUCTS.find((x) => x.id === id);
    return p ? s + p.price * q : s;
  }, 0);
}

function renderCart() {
  const entries = Object.entries(cart).filter(([id]) => PRODUCTS.some((p) => p.id === id));
  const count = entries.reduce((s, [, q]) => s + q, 0);
  $("#cartCount").textContent = count;
  $("#subtotal").textContent = money(cartTotal());
  $("#checkoutBtn").disabled = count === 0;
  $("#checkoutBtn").style.opacity = count ? 1 : 0.5;
  $("#cartItems").innerHTML = entries.length
    ? entries.map(([id, q]) => {
        const p = PRODUCTS.find((x) => x.id === id);
        return `<div class="cart-item">
          <div class="ci-art" style="background:${artBg(p)}">${p.icon}</div>
          <div class="ci-info"><b>${p.name}</b><small>${money(p.price)} each</small></div>
          <div class="qty">
            <button data-dec="${id}" aria-label="Decrease">−</button>
            <span>${q}</span>
            <button data-inc="${id}" aria-label="Increase">+</button>
          </div>
        </div>`;
      }).join("")
    : `<div class="cart-empty"><div>🛒</div>Your cart is empty</div>`;
}

$("#cartItems").addEventListener("click", (e) => {
  const inc = e.target.closest("[data-inc]");
  const dec = e.target.closest("[data-dec]");
  if (inc) changeQty(inc.dataset.inc, 1);
  if (dec) changeQty(dec.dataset.dec, -1);
});

function openCart(open) {
  $("#drawer").classList.toggle("open", open);
  $("#drawer").setAttribute("aria-hidden", String(!open));
  $("#overlay").hidden = !open;
}
$("#cartBtn").addEventListener("click", () => openCart(true));
$("#closeCart").addEventListener("click", () => openCart(false));
$("#overlay").addEventListener("click", () => openCart(false));

/* ---------- Checkout (demo — connect Stripe/PayPal/Sellix here) ---------- */
function openModal(open) {
  $("#modal").hidden = !open;
  if (open) {
    $("#checkoutForm").hidden = false;
    $("#checkoutDone").hidden = true;
    $("#modalTotal").textContent = `Total: ${money(cartTotal())}`;
  }
}
$("#checkoutBtn").addEventListener("click", () => { if (cartTotal() > 0) { openCart(false); openModal(true); } });
$("#closeModal").addEventListener("click", () => openModal(false));
$("#modal").addEventListener("click", (e) => { if (e.target.id === "modal") openModal(false); });
$("#payForm").addEventListener("submit", (e) => {
  e.preventDefault();
  $("#orderId").textContent = "#" + Math.floor(10000 + Math.random() * 89999);
  $("#checkoutForm").hidden = true;
  $("#checkoutDone").hidden = false;
  cart = {};
  save();
  renderCart();
  e.target.reset();
});
$("#doneBtn").addEventListener("click", () => openModal(false));

document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") { openCart(false); openModal(false); }
});

/* ---------- Misc ---------- */
let toastTimer;
function toast(msg) {
  const t = $("#toast");
  t.textContent = msg;
  t.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.classList.remove("show"), 2000);
}

$("#menuBtn").addEventListener("click", () => $("#navLinks").classList.toggle("open"));
$("#navLinks").addEventListener("click", (e) => { if (e.target.tagName === "A") $("#navLinks").classList.remove("open"); });
$("#newsletter").addEventListener("submit", (e) => { e.preventDefault(); e.target.reset(); toast("Subscribed! Check your inbox for 10% off."); });
$("#year").textContent = new Date().getFullYear();

renderFilters();
renderGrid();
renderCart();
