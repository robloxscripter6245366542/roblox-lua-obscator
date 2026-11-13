// Vaultix staff page: verify / unverify / ban sellers.
const $ = (s) => document.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
let sellers = [];

function toast(msg) {
  const t = $("#toast"); t.textContent = msg; t.classList.add("show");
  clearTimeout(toast.t); toast.t = setTimeout(() => t.classList.remove("show"), 2500);
}

function render() {
  const q = $("#filter").value.trim().toLowerCase();
  const list = sellers.filter((s) => !q || s.name.toLowerCase().includes(q) || s.id.toLowerCase().includes(q));
  $("#none").hidden = list.length > 0;
  $("#none").textContent = sellers.length ? "No sellers match." : "No sellers yet.";
  $("#rows").innerHTML = list.map((s) => `
    <tr>
      <td><b>@${esc(s.name)}</b><br><span class="mono muted">${esc(s.id)}</span></td>
      <td>${esc(s.contact)}</td>
      <td>${new Date(s.createdAt).toLocaleDateString()}</td>
      <td>${s.listings}</td>
      <td>${s.verified ? '<span class="badge ok sm">Verified</span>' : '<span class="badge risk sm">Risky</span>'}</td>
      <td><div class="acts">
        <button class="btn ${s.verified ? "ghost" : ""}" data-verify="${esc(s.id)}" data-to="${!s.verified}" type="button">${s.verified ? "Remove verification" : "Verify"}</button>
        <button class="btn danger" data-ban="${esc(s.id)}" type="button">Ban</button>
      </div></td>
    </tr>`).join("");
}

async function load() {
  $("#err").textContent = "";
  try {
    sellers = (await Market.admin("adminSellers")).sellers;
    $("#table").hidden = false;
    $("#login").hidden = true;
    render();
  } catch (e) {
    $("#table").hidden = true;
    $("#login").hidden = false;
    $("#err").textContent = e.message;
    if (e.status === 401) Market.setAdminKey("");
  }
}

$("#login").addEventListener("submit", (e) => {
  e.preventDefault();
  Market.setAdminKey($("#key").value);
  $("#key").value = "";
  load();
});
$("#filter").addEventListener("input", render);

$("#rows").addEventListener("click", async (e) => {
  const v = e.target.closest("[data-verify]");
  const b = e.target.closest("[data-ban]");
  try {
    if (v) {
      await Market.admin("verify", { sellerId: v.dataset.verify, verified: v.dataset.to === "true" });
      toast(v.dataset.to === "true" ? "Seller verified." : "Verification removed.");
    } else if (b) {
      const s = sellers.find((x) => x.id === b.dataset.ban);
      if (!confirm(`Ban @${s ? s.name : "seller"} and delete all their listings?`)) return;
      const r = await Market.admin("banSeller", { sellerId: b.dataset.ban });
      toast(`Seller banned. ${r.removedListings} listing(s) removed.`);
    } else return;
    await load();
  } catch (err) { toast(err.message); }
});

(async () => {
  await Market.init();
  $("#demoBar").hidden = Market.mode !== "demo";
  if (Market.mode === "demo" || Market.adminKey()) load();
})();
