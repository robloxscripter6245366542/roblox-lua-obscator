import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";

const mount = document.getElementById("viewport");
const hudRenderer = document.getElementById("hud-renderer");
const hudTris = document.getElementById("hud-tris");
const wireBtn = document.getElementById("toggle-wire");
const spinBtn = document.getElementById("toggle-spin");

const scene = new THREE.Scene();
scene.background = null;

const camera = new THREE.PerspectiveCamera(
  45,
  mount.clientWidth / mount.clientHeight,
  0.1,
  100
);
camera.position.set(0, 1.1, 4.2);

const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(mount.clientWidth, mount.clientHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
mount.appendChild(renderer.domElement);

hudRenderer.textContent = renderer.capabilities.isWebGL2 ? "WebGL2" : "WebGL";

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.minDistance = 2;
controls.maxDistance = 8;

// Key + fill + rim lighting so the mesh reads like a real product render.
scene.add(new THREE.AmbientLight(0x404050, 1.2));
const key = new THREE.DirectionalLight(0xffffff, 2.2);
key.position.set(3, 4, 2);
scene.add(key);
const rim = new THREE.DirectionalLight(0x5eead4, 1.4);
rim.position.set(-3, -1, -3);
scene.add(rim);

// Stand-in for a glTF/GLB asset produced by the mesh_process pipeline
// (trimesh decimation -> glTF export -> Draco compression).
const geometry = new THREE.TorusKnotGeometry(0.9, 0.32, 220, 32);
const material = new THREE.MeshStandardMaterial({
  color: 0x5eead4,
  metalness: 0.35,
  roughness: 0.25,
  flatShading: false,
});
const mesh = new THREE.Mesh(geometry, material);
scene.add(mesh);

hudTris.textContent = (geometry.index ? geometry.index.count / 3 : geometry.attributes.position.count / 3).toLocaleString();

let wireframe = false;
wireBtn.addEventListener("click", () => {
  wireframe = !wireframe;
  material.wireframe = wireframe;
  wireBtn.textContent = wireframe ? "Show solid" : "Toggle wireframe";
});

let spinning = true;
spinBtn.addEventListener("click", () => {
  spinning = !spinning;
  spinBtn.textContent = spinning ? "Pause spin" : "Resume spin";
});

function onResize() {
  const w = mount.clientWidth;
  const h = mount.clientHeight;
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  renderer.setSize(w, h);
}
window.addEventListener("resize", onResize);

const clock = new THREE.Clock();
function animate() {
  requestAnimationFrame(animate);
  const dt = clock.getDelta();
  if (spinning) mesh.rotation.y += dt * 0.35;
  controls.update();
  renderer.render(scene, camera);
}
animate();

// --- Text-to-3D generation panel -------------------------------------
// Talks to the FastAPI backend's /api/v1/generate/text-to-3d job endpoint.
// Same-origin by default; override by setting window.RENDER3D_API_BASE
// before this script runs if the API is hosted elsewhere.
const API_BASE = window.RENDER3D_API_BASE || "/api/v1";

const genForm = document.getElementById("generate-form");
const genPrompt = document.getElementById("generate-prompt");
const genStyle = document.getElementById("generate-style");
const genStatus = document.getElementById("generate-status");

function setGenStatus(text, kind) {
  genStatus.textContent = text;
  genStatus.className = "generate-status" + (kind ? ` ${kind}` : "");
}

async function pollJob(jobId, { intervalMs = 2000, timeoutMs = 5 * 60 * 1000 } = {}) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const res = await fetch(`${API_BASE}/jobs/${jobId}`);
    if (!res.ok) throw new Error(`status check failed (${res.status})`);
    const job = await res.json();
    if (job.status === "succeeded" || job.status === "failed") return job;
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  throw new Error("timed out waiting for generation job");
}

genForm?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const prompt = genPrompt.value.trim();
  if (!prompt) return;

  setGenStatus("Submitting job…");
  try {
    const res = await fetch(`${API_BASE}/generate/text-to-3d`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt, style: genStyle.value, target_format: "glb" }),
    });
    if (!res.ok) throw new Error(`request failed (${res.status})`);
    const job = await res.json();

    setGenStatus(`Job ${job.id.slice(0, 8)} queued — waiting on the configured 3D provider…`);
    const finished = await pollJob(job.id);

    if (finished.status === "succeeded") {
      setGenStatus(`Done — asset stored at ${finished.result_asset_key}`, "success");
    } else {
      setGenStatus(finished.error || "Generation failed.", "error");
    }
  } catch (err) {
    setGenStatus(
      `${err.message}. This panel needs the backend running with TEXT23D_API_URL / TEXT23D_API_KEY set to a real text-to-3D provider.`,
      "error"
    );
  }
});
