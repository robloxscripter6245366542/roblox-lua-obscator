// Vaultix data layer.
// Uses the server API (/api/market) when it is deployed. If it isn't reachable,
// it falls back to DEMO mode: everything is saved in this browser only.
const Market = (() => {
  const API = window.VAULTIX_API || "/api/market";
  const CATEGORIES = ["Currency", "Accounts", "Top ups", "Items", "Boosting", "Gift cards"];
  const Games = window.VAULTIX_GAMES; // from games.js
  const K = { sellers: "vx-demo-sellers", listings: "vx-demo-listings", session: "vx-session", admin: "vx-admin-key" };
  let mode = "remote";

  const read = (k, d) => { try { const v = JSON.parse(localStorage.getItem(k)); return v ?? d; } catch { return d; } };
  const write = (k, v) => { try { v == null ? localStorage.removeItem(k) : localStorage.setItem(k, JSON.stringify(v)); } catch {} };
  const fail = (m) => { throw new Error(m); };
  const rid = (p) => p + Math.random().toString(16).slice(2, 14);
  const pub = (s) => s && { id: s.id, name: s.name, contact: s.contact, verified: !!s.verified, createdAt: s.createdAt };
  const text = (v, name, min, max) => {
    const s = typeof v === "string" ? v.trim() : "";
    if (s.length < min || s.length > max) fail(`${name} must be ${min}-${max} characters`);
    return s;
  };

  // ---------- demo (browser-only) backend ----------
  const demo = {
    list() {
      const sellers = read(K.sellers, {}), listings = Object.values(read(K.listings, {}));
      return {
        listings: listings.filter((l) => sellers[l.sellerId])
          .map((l) => ({ ...l, seller: pub(sellers[l.sellerId]) }))
          .sort((a, b) => b.createdAt - a.createdAt),
      };
    },
    register(b) {
      const name = text(b.name, "Name", 3, 24);
      if (!/^[A-Za-z0-9_.-]+$/.test(name)) fail("Name can only use letters, numbers, _ . -");
      const contact = text(b.contact, "Contact", 3, 80);
      const sellers = read(K.sellers, {});
      if (Object.values(sellers).some((s) => s.name.toLowerCase() === name.toLowerCase())) fail("That name is taken");
      const token = rid("t");
      const s = { id: rid("s_"), name, contact, verified: false, createdAt: Date.now(), token };
      sellers[s.id] = s; write(K.sellers, sellers);
      return { seller: pub(s), token };
    },
    auth(b) {
      const s = read(K.sellers, {})[b.sellerId];
      if (!s || s.token !== b.token) fail("Not signed in as this seller");
      return s;
    },
    me(b) { return { seller: pub(demo.auth(b)) }; },
    post(b) {
      const s = demo.auth(b);
      const price = Math.round(Number(b.price) * 100) / 100;
      if (!(price > 0 && price <= 10000)) fail("Price must be between 0.01 and 10000");
      if (!CATEGORIES.includes(b.category)) fail("Pick a category");
      const was = Math.round(Number(b.wasPrice) * 100) / 100;
      const known = Games.find(b.game);
      const image = known ? null : b.image;
      if (!known && !/^data:image\/(jpeg|png|webp);base64,/.test(image || "")) fail("Add a picture for games that are not in the list");
      const l = {
        id: rid("l_"), sellerId: s.id,
        game: known ? known.name : text(b.game, "Game", 2, 30),
        hasImage: !!image, image: image || null,
        title: text(b.title, "Title", 3, 70),
        description: text(b.description, "Description", 10, 1000),
        price, wasPrice: was > price && was <= 100000 ? was : null,
        category: b.category, createdAt: Date.now(),
        delivery: b.delivery === "instant" ? "instant" : "manual",
        stock: b.delivery === "instant" ? (b.logins || []).length || 1 : Math.max(1, Math.floor(Number(b.stock) || 1)),
      };
      const all = read(K.listings, {}); all[l.id] = l; write(K.listings, all);
      return { listing: { ...l, seller: pub(s) } };
    },
    remove(b) {
      const s = demo.auth(b), all = read(K.listings, {});
      if (!all[b.listingId] || all[b.listingId].sellerId !== s.id) fail("Listing not found");
      delete all[b.listingId]; write(K.listings, all); return { ok: true };
    },
    profile(b) {
      const u = read(K.sellers, {})[b.id];
      if (!u) fail("User not found");
      return { user: pub(u), listings: demo.list().listings.filter((l) => l.sellerId === u.id), reviews: [] };
    },
    adminSellers() {
      const listings = Object.values(read(K.listings, {}));
      return {
        sellers: Object.values(read(K.sellers, {}))
          .map((s) => ({ ...pub(s), listings: listings.filter((l) => l.sellerId === s.id).length }))
          .sort((a, b) => b.createdAt - a.createdAt),
      };
    },
    verify(b) {
      const sellers = read(K.sellers, {}), s = sellers[b.sellerId];
      if (!s) fail("Seller not found");
      s.verified = !!b.verified; write(K.sellers, sellers); return { seller: pub(s) };
    },
    banSeller(b) {
      const sellers = read(K.sellers, {}), all = read(K.listings, {});
      let n = 0;
      for (const id in all) if (all[id].sellerId === b.sellerId) { delete all[id]; n++; }
      delete sellers[b.sellerId]; write(K.sellers, sellers); write(K.listings, all);
      return { ok: true, removedListings: n };
    },
    adminRemove(b) { const all = read(K.listings, {}); delete all[b.listingId]; write(K.listings, all); return { ok: true }; },
  };

  // ---------- remote backend ----------
  async function remote(action, body = {}) {
    const isGet = action === "list" || action === "icons" || action === "profile";
    const qs = action === "profile" ? `&id=${encodeURIComponent(body.id || "")}` : "";
    const r = await fetch(isGet ? `${API}?action=${action}${qs}` : API, isGet ? {} : {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ action, ...body }),
    });
    const j = await r.json().catch(() => ({ error: "Bad server response" }));
    if (!r.ok) throw Object.assign(new Error(j.error || "Request failed"), { status: r.status });
    return j;
  }

  const NEEDS_SERVER = "Buying, wallets and payouts need the server. Run “node shop-site/dev-server.js” on your computer, or deploy the site.";
  async function call(action, body = {}) {
    if (mode === "demo") {
      if (!demo[action]) fail(NEEDS_SERVER);
      return demo[action](body);
    }
    return remote(action, body);
  }

  // Decide mode once at startup.
  async function init() {
    try {
      const j = await remote("list");
      mode = "remote";
      return j;
    } catch (e) {
      // Network error, no API deployed (404) or storage not configured (503) -> demo mode
      mode = "demo";
      return demo.list();
    }
  }

  // ---------- session ----------
  const session = () => read(K.session, null);
  const withSession = (b = {}) => { const s = session() || {}; return { ...b, sellerId: s.sellerId, token: s.token }; };

  return {
    CATEGORIES,
    Games,
    init,
    // Icon per catalogue game: { [name]: url }. Falls back to just the fixed Steam images.
    async icons() {
      if (mode === "remote") {
        try { return (await remote("icons")).icons || {}; } catch {}
      }
      const out = {};
      for (const g of Games.GAMES) if (g.steam) out[g.name] = Games.steamIcon(g.steam);
      return out;
    },
    // URL of a seller-uploaded picture
    imageUrl: (l) => (l.image ? l.image : l.hasImage && mode === "remote" ? `${API}?action=image&id=${encodeURIComponent(l.id)}` : null),
    get mode() { return mode; },
    list: () => call("list"),
    session,
    signOut: () => write(K.session, null),
    async register(name, contact, email, password, adminKey) {
      const r = await call("register", { name, contact, email, password, adminKey: adminKey || undefined });
      write(K.session, { sellerId: r.seller.id, token: r.token, name: r.seller.name });
      return r.seller;
    },
    async login(login, password) {
      const r = await call("login", { login, password });
      write(K.session, { sellerId: r.seller.id, token: r.token, name: r.seller.name });
      return r.seller;
    },
    // Forgot password: the server emails a reset link (emailOff when the site has no email set up;
    // demo accounts only live in this browser, so there's nothing to email).
    forgotPassword: (login) => (mode === "remote" ? call("forgotPassword", { login }) : Promise.resolve({ emailOff: true })),
    // New password from an emailed link; signs this device in.
    async resetPassword(userId, resetToken, password) {
      const r = await call("resetPassword", { userId, resetToken, password });
      write(K.session, { sellerId: r.seller.id, token: r.token, name: r.seller.name });
      return r.seller;
    },
    // Ends this device's sign-in on the server too (ignored if the server can't be reached).
    async logout() {
      if (mode === "remote" && session()) await call("logout", withSession()).catch(() => {});
      write(K.session, null);
    },
    setLogin: (data) => call("setLogin", withSession(data)),
    get canPay() { return mode === "remote"; },
    NEEDS_SERVER,
    me: () => call("me", withSession()),
    post: (data) => call("post", withSession(data)),
    remove: (listingId) => call("remove", withSession({ listingId })),
    profile: (id) => call("profile", { id }),
    updateProfile: (data) => call("updateProfile", withSession(data)),
    // buying & orders
    checkout: (listingId, method, extra = {}) => call("checkout", withSession({ listingId, method, ...extra })),
    // saved cards (stored by Stripe; we only see brand + last 4)
    cards: () => call("cards", withSession()),
    addCard: () => call("addCard", withSession()),
    removeCard: (paymentMethod) => call("removeCard", withSession({ paymentMethod })),
    myOrders: () => call("myOrders", withSession()),
    order: (orderId) => call("order", withSession({ orderId })),
    orderAction: (action, orderId, data = {}) => call(action, withSession({ orderId, ...data })),
    // wallet
    stripeConnect: () => call("stripeConnect", withSession()),
    // add funds (bank transfer / crypto, checked by staff; spend-only)
    deposits: () => call("deposits", withSession()),
    depositCreate: (amount, method) => call("depositCreate", withSession({ amount, method })),
    depositSent: (depositId, proof) => call("depositSent", withSession({ depositId, proof })),
    depositCancel: (depositId) => call("depositCancel", withSession({ depositId })),
    stripeStatus: () => call("stripeStatus", withSession()),
    payout: (data) => call("payout", withSession(data)),
    // admin
    adminKey: () => read(K.admin, ""),
    setAdminKey: (k) => write(K.admin, k || null),
    // Staff actions: signed-in owner account, or the admin key typed on the Staff page.
    admin: (action, body = {}) => {
      const s = session() || {};
      return call(action, { ...body, adminKey: read(K.admin, "") || undefined, ownerId: s.sellerId, ownerToken: s.token });
    },
  };
})();
