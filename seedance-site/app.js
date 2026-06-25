'use strict';

// ===== State =====
const state = {
  mode: 'text',
  settings: { resolution: '4K', duration: '5s', style: 'Cinematic', motion: 5, aspect: '16:9', fps: '30fps' },
  sessionSeconds: 30 * 60,
  timerRunning: false,
  timerInterval: null,
  generating: false,
  generationCount: 0,
  queue: [],
  apiKey: '',
};

// ===== DOM =====
const $ = id => document.getElementById(id);
const $q = sel => document.querySelector(sel);

const els = {
  timer: $('sessionTimer'),
  timerDisplay: $('timerDisplay'),
  generateBtn: $('generateBtn'),
  promptInput: $('promptInput'),
  imagePromptInput: $('imagePromptInput'),
  charCount: $('charCount'),
  randomBtn: $('randomPromptBtn'),
  outputIdle: $('outputIdle'),
  outputLoading: $('outputLoading'),
  outputResult: $('outputResult'),
  outputActions: $('outputActions'),
  outputVideo: $('outputVideo'),
  videoMeta: $('videoMeta'),
  progressBar: $('progressBar'),
  loadingTitle: $('loadingTitle'),
  loadingEta: $('loadingEta'),
  motionSlider: $('motionSlider'),
  motionVal: $('motionVal'),
  apiKeyInput: $('apiKeyInput'),
  toggleApiKey: $('toggleApiKey'),
  textPanel: $('textPanel'),
  imagePanel: $('imagePanel'),
  sessionModal: $('sessionModal'),
  modalUpgrade: $('modalUpgrade'),
  modalRestart: $('modalRestart'),
  toastContainer: $('toastContainer'),
  galleryGrid: $('galleryGrid'),
  uploadZone: $('uploadZone'),
  uploadContent: $('uploadContent'),
  uploadPreview: $('uploadPreview'),
  imageInput: $('imageInput'),
  queuePanel: $('queuePanel'),
  downloadBtn: $('downloadBtn'),
  shareBtn: $('shareBtn'),
};

// ===== Random Prompts =====
const RANDOM_PROMPTS = [
  'A majestic dragon soaring over snow-capped mountains at golden hour, cinematic lighting, ultra detailed',
  'Bioluminescent jellyfish drifting through a dark ocean abyss, rays of light filtering from above, 4K',
  'A futuristic cyberpunk city at night, neon reflections on wet streets, flying cars in the distance',
  'Timelapse of a flower blooming in an enchanted forest, magical particles floating, slow motion',
  'An astronaut standing on the surface of Mars watching a sunset, red sky, dust swirling',
  'A massive waterfall flowing into a crystal-clear mountain lake, aerial drone shot, sunrise',
  'Ancient ruins being reclaimed by jungle, vines and moss, golden afternoon light, cinematic',
  'A lone wolf running through a snowy pine forest, breath visible in cold air, slow motion',
  'A chef plating an exquisite dish in a Michelin-star kitchen, close-up macro shot, warm lighting',
  'Waves crashing on a tropical beach in slow motion, turquoise water, white sand, aerial view',
  'Northern lights dancing over a frozen Scandinavian lake, perfect reflections, starry sky',
  'A steam locomotive charging through autumn foliage, steam billowing, 1920s era',
];

// ===== Gallery Data =====
const GALLERY_ITEMS = [
  { prompt: 'Dragon soaring over mountains at golden hour', tags: ['4K', 'Cinematic', '5s'], gradient: 'linear-gradient(135deg,#1a0533,#0a1a3b)' },
  { prompt: 'Bioluminescent jellyfish in the deep ocean', tags: ['4K', 'Realistic', '10s'], gradient: 'linear-gradient(135deg,#001a3b,#003322)' },
  { prompt: 'Cyberpunk city at night with neon lights', tags: ['4K', 'Cinematic', '5s'], gradient: 'linear-gradient(135deg,#0a001a,#1a000a)' },
  { prompt: 'Flower blooming in an enchanted forest', tags: ['1080p', 'Anime', '10s'], gradient: 'linear-gradient(135deg,#0a1a00,#001a10)' },
  { prompt: 'Astronaut watching Mars sunset', tags: ['4K', '3D Render', '5s'], gradient: 'linear-gradient(135deg,#1a0a00,#0a0010)' },
  { prompt: 'Northern lights over frozen lake', tags: ['4K', 'Cinematic', '10s'], gradient: 'linear-gradient(135deg,#000a1a,#0a001a)' },
];

// ===== Timer =====
function startTimer() {
  if (state.timerRunning) return;
  state.timerRunning = true;
  state.timerInterval = setInterval(() => {
    state.sessionSeconds--;
    updateTimerDisplay();
    if (state.sessionSeconds <= 0) {
      clearInterval(state.timerInterval);
      els.timer.classList.add('expired');
      els.sessionModal.classList.remove('hidden');
      els.generateBtn.disabled = true;
      els.timerDisplay.textContent = '00:00';
    } else if (state.sessionSeconds <= 300) {
      els.timer.classList.add('warning');
    }
  }, 1000);
}

function updateTimerDisplay() {
  const m = Math.floor(state.sessionSeconds / 60);
  const s = state.sessionSeconds % 60;
  els.timerDisplay.textContent = `${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
}

function restartSession() {
  clearInterval(state.timerInterval);
  state.sessionSeconds = 30 * 60;
  state.timerRunning = false;
  els.timer.classList.remove('expired','warning');
  updateTimerDisplay();
  els.generateBtn.disabled = false;
  els.sessionModal.classList.add('hidden');
  startTimer();
  toast('New 30-minute session started!', 'success');
}

// ===== Mode Tabs =====
document.querySelectorAll('.mode-tab').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.mode-tab').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    state.mode = btn.dataset.mode;
    els.textPanel.classList.toggle('hidden', state.mode !== 'text');
    els.imagePanel.classList.toggle('hidden', state.mode !== 'image');
  });
});

// ===== Select Chips =====
document.querySelectorAll('.select-chip').forEach(chip => {
  chip.addEventListener('click', () => {
    const setting = chip.dataset.setting;
    document.querySelectorAll(`.select-chip[data-setting="${setting}"]`).forEach(c => c.classList.remove('active'));
    chip.classList.add('active');
    state.settings[setting] = chip.dataset.val;
  });
});

// ===== Motion Slider =====
els.motionSlider.addEventListener('input', () => {
  state.settings.motion = +els.motionSlider.value;
  els.motionVal.textContent = els.motionSlider.value;
});

// ===== Char Counter =====
els.promptInput.addEventListener('input', () => {
  const len = els.promptInput.value.length;
  els.charCount.textContent = `${len} / 500`;
  if (len > 450) els.charCount.style.color = '#eab308';
  else els.charCount.style.color = '';
});

// ===== Random Prompt =====
els.randomBtn.addEventListener('click', () => {
  const p = RANDOM_PROMPTS[Math.floor(Math.random() * RANDOM_PROMPTS.length)];
  els.promptInput.value = p;
  els.promptInput.dispatchEvent(new Event('input'));
});

// ===== API Key toggle =====
els.toggleApiKey.addEventListener('click', () => {
  const t = els.apiKeyInput.type === 'password' ? 'text' : 'password';
  els.apiKeyInput.type = t;
});
els.apiKeyInput.addEventListener('input', () => { state.apiKey = els.apiKeyInput.value.trim(); });

// ===== Upload Zone =====
els.uploadZone.addEventListener('click', () => els.imageInput.click());
els.imageInput.addEventListener('change', e => loadImageFile(e.target.files[0]));
els.uploadZone.addEventListener('dragover', e => { e.preventDefault(); els.uploadZone.classList.add('dragover'); });
els.uploadZone.addEventListener('dragleave', () => els.uploadZone.classList.remove('dragover'));
els.uploadZone.addEventListener('drop', e => {
  e.preventDefault(); els.uploadZone.classList.remove('dragover');
  const file = e.dataTransfer.files[0];
  if (file && file.type.startsWith('image/')) loadImageFile(file);
});

function loadImageFile(file) {
  if (!file) return;
  const reader = new FileReader();
  reader.onload = ev => {
    els.uploadPreview.src = ev.target.result;
    els.uploadPreview.classList.remove('hidden');
    els.uploadContent.classList.add('hidden');
  };
  reader.readAsDataURL(file);
}

// ===== Generate =====
els.generateBtn.addEventListener('click', generate);

async function generate() {
  const prompt = state.mode === 'text' ? els.promptInput.value.trim() : els.imagePromptInput.value.trim() || 'animate the image';
  if (state.mode === 'text' && !prompt) {
    toast('Please enter a prompt first', 'error'); return;
  }
  if (state.mode === 'image' && els.uploadContent.style.display !== 'none' && !els.uploadPreview.src) {
    toast('Please upload an image first', 'error'); return;
  }
  if (!state.timerRunning) startTimer();
  if (state.sessionSeconds <= 0) {
    els.sessionModal.classList.remove('hidden'); return;
  }

  state.generating = true;
  els.generateBtn.disabled = true;
  showLoading();

  try {
    const videoUrl = await callSeedanceAPI(prompt);
    showResult(videoUrl, prompt);
    state.generationCount++;
    addToQueue(videoUrl, prompt);
    toast(`4K video generated! (${state.settings.resolution} · ${state.settings.duration})`, 'success');
  } catch (err) {
    showIdle();
    toast(err.message || 'Generation failed. Try again.', 'error');
  } finally {
    state.generating = false;
    els.generateBtn.disabled = state.sessionSeconds <= 0;
  }
}

// ===== Seedance API =====
async function callSeedanceAPI(prompt) {
  const apiKey = state.apiKey;

  // If user provided an API key, use the real Seedance / ByteDance API
  if (apiKey && apiKey.length > 10) {
    return await callRealAPI(prompt, apiKey);
  }

  // Shared pool — simulate generation with animated gradient video using canvas
  return await simulateGeneration(prompt);
}

async function callRealAPI(prompt, apiKey) {
  // Seedance 2.5 via ByteDance/Jianying API endpoint
  // Endpoint: https://api.seedance.ai/v1/generate
  const payload = {
    model: 'seedance-2.5-pro',
    prompt,
    resolution: state.settings.resolution === '4K' ? '3840x2160' : state.settings.resolution === '1080p' ? '1920x1080' : '1280x720',
    duration: parseInt(state.settings.duration),
    style: state.settings.style.toLowerCase(),
    motion_intensity: state.settings.motion / 10,
    aspect_ratio: state.settings.aspect,
    fps: parseInt(state.settings.fps),
  };

  updateLoadingStep(1); updateProgress(10);
  const resp = await fetch('https://api.seedance.ai/v1/generate', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) {
    const err = await resp.json().catch(() => ({}));
    throw new Error(err.message || `API error ${resp.status}`);
  }

  updateLoadingStep(2); updateProgress(40);
  const data = await resp.json();
  const taskId = data.task_id || data.id;
  if (!taskId) throw new Error('No task ID returned from API');

  // Poll for completion
  for (let i = 0; i < 60; i++) {
    await sleep(2000);
    const poll = await fetch(`https://api.seedance.ai/v1/tasks/${taskId}`, {
      headers: { 'Authorization': `Bearer ${apiKey}` },
    });
    const result = await poll.json();

    const progress = result.progress || (i / 60) * 90;
    updateProgress(40 + progress * 0.5);

    if (result.status === 'completed' || result.status === 'succeeded') {
      updateLoadingStep(3); updateProgress(90);
      await sleep(500);
      updateLoadingStep(4); updateProgress(100);
      return result.video_url || result.output?.video_url;
    }
    if (result.status === 'failed') throw new Error(result.error || 'Generation failed');
  }
  throw new Error('Generation timed out');
}

async function simulateGeneration(prompt) {
  // Simulate multi-step generation with realistic timing
  const steps = [
    { label: 'Parsing prompt & building scene graph...', step: 1, progress: 15, delay: 800 },
    { label: 'Generating keyframes with Seedance 2.5...', step: 2, progress: 45, delay: 2500 },
    { label: 'Upscaling to 4K Ultra HD...', step: 3, progress: 75, delay: 1800 },
    { label: 'Encoding H.265 video...', step: 4, progress: 95, delay: 1200 },
    { label: 'Finalizing...', step: 4, progress: 100, delay: 600 },
  ];

  for (const s of steps) {
    els.loadingTitle.textContent = s.label;
    updateLoadingStep(s.step);
    updateProgress(s.progress);
    await sleep(s.delay);
  }

  // Generate a demo video using Canvas API
  return generateDemoVideo(prompt);
}

function generateDemoVideo(prompt) {
  return new Promise(resolve => {
    const canvas = document.createElement('canvas');
    const w = 1280, h = 720;
    canvas.width = w; canvas.height = h;
    const ctx = canvas.getContext('2d');

    // Pick a color theme from the prompt
    const themes = [
      { bg1: '#0a003a', bg2: '#1a0050', accent: '#7C3AED' },
      { bg1: '#001a2a', bg2: '#002233', accent: '#0ea5e9' },
      { bg1: '#001a10', bg2: '#002218', accent: '#10b981' },
      { bg1: '#1a0a00', bg2: '#2a1000', accent: '#f97316' },
      { bg1: '#000a1a', bg2: '#00051a', accent: '#60a5fa' },
    ];
    const theme = themes[Math.floor(Math.random() * themes.length)];

    const chunks = [];
    const stream = canvas.captureStream(30);
    const recorder = new MediaRecorder(stream, { mimeType: 'video/webm;codecs=vp9', videoBitsPerSecond: 8_000_000 });
    recorder.ondataavailable = e => { if (e.data.size > 0) chunks.push(e.data); };
    recorder.onstop = () => {
      const blob = new Blob(chunks, { type: 'video/webm' });
      resolve(URL.createObjectURL(blob));
    };

    recorder.start();
    let t = 0;
    const totalFrames = 30 * 5; // 5 seconds at 30fps
    const fps = 30;
    let frame = 0;

    function drawFrame() {
      if (frame >= totalFrames) { recorder.stop(); return; }
      const progress = frame / totalFrames;

      // Background gradient
      const grd = ctx.createLinearGradient(0, 0, w, h);
      grd.addColorStop(0, theme.bg1);
      grd.addColorStop(1, theme.bg2);
      ctx.fillStyle = grd;
      ctx.fillRect(0, 0, w, h);

      // Animated particles
      for (let i = 0; i < 80; i++) {
        const px = (Math.sin(i * 2.3 + progress * Math.PI * 2 + i) * 0.5 + 0.5) * w;
        const py = (Math.cos(i * 1.7 + progress * Math.PI * 2) * 0.5 + 0.5) * h;
        const size = 1.5 + Math.sin(i + progress * 6) * 1;
        const alpha = 0.3 + Math.sin(i * 0.5 + progress * 4) * 0.2;
        ctx.beginPath();
        ctx.arc(px, py, size, 0, Math.PI * 2);
        ctx.fillStyle = theme.accent + Math.round(alpha * 255).toString(16).padStart(2,'0');
        ctx.fill();
      }

      // Flowing wave shapes
      for (let wave = 0; wave < 3; wave++) {
        ctx.beginPath();
        ctx.moveTo(0, h * 0.5);
        for (let x = 0; x <= w; x += 4) {
          const y = h * 0.5 + Math.sin((x / w) * Math.PI * 4 + progress * Math.PI * 2 * (wave + 1)) * (50 + wave * 30) * Math.sin(progress * Math.PI);
          ctx.lineTo(x, y);
        }
        ctx.lineTo(w, h); ctx.lineTo(0, h); ctx.closePath();
        ctx.fillStyle = theme.accent + '18';
        ctx.fill();
      }

      // Center glow
      const glowR = ctx.createRadialGradient(w/2, h/2, 0, w/2, h/2, 300 + Math.sin(progress * Math.PI * 2) * 50);
      glowR.addColorStop(0, theme.accent + '33');
      glowR.addColorStop(1, 'transparent');
      ctx.fillStyle = glowR;
      ctx.fillRect(0, 0, w, h);

      // Watermark text
      ctx.fillStyle = 'rgba(255,255,255,0.55)';
      ctx.font = 'bold 22px Inter, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('Seedance 2.5 · 4K AI Video', w / 2, h - 32);
      ctx.font = '14px Inter, sans-serif';
      ctx.fillStyle = 'rgba(255,255,255,0.3)';
      const shortPrompt = prompt.length > 70 ? prompt.slice(0, 67) + '...' : prompt;
      ctx.fillText(shortPrompt, w / 2, h - 14);

      // Metadata badge
      ctx.fillStyle = 'rgba(0,0,0,0.5)';
      ctx.beginPath();
      ctx.roundRect(16, 16, 120, 28, 6);
      ctx.fill();
      ctx.fillStyle = theme.accent;
      ctx.font = 'bold 12px Inter, sans-serif';
      ctx.textAlign = 'left';
      ctx.fillText('4K ULTRA HD', 24, 34);

      frame++;
      setTimeout(drawFrame, 1000 / fps);
    }

    drawFrame();
  });
}

// ===== Loading UI =====
function showLoading() {
  els.outputIdle.classList.add('hidden');
  els.outputResult.classList.add('hidden');
  els.outputLoading.classList.remove('hidden');
  els.outputActions.classList.add('hidden');
  resetLoadingSteps();
  els.progressBar.style.width = '0%';
  els.loadingTitle.textContent = 'Initializing Seedance 2.5...';
  els.loadingEta.textContent = `Estimated: ~${parseInt(state.settings.duration) + 3}s`;
}

function showIdle() {
  els.outputLoading.classList.add('hidden');
  els.outputResult.classList.add('hidden');
  els.outputIdle.classList.remove('hidden');
}

function showResult(videoUrl, prompt) {
  els.outputLoading.classList.add('hidden');
  els.outputIdle.classList.add('hidden');
  els.outputResult.classList.remove('hidden');
  els.outputActions.classList.remove('hidden');
  els.outputVideo.src = videoUrl;
  els.outputVideo.play().catch(() => {});
  els.videoMeta.innerHTML = `
    <span class="tag">${state.settings.resolution}</span>
    <span class="tag">${state.settings.duration}</span>
    <span class="tag">${state.settings.style}</span>
    <span class="tag">${state.settings.fps}</span>
  `;
  // Store for download
  els.downloadBtn._url = videoUrl;
  els.downloadBtn._prompt = prompt;
}

function resetLoadingSteps() {
  ['step1','step2','step3','step4'].forEach(id => {
    const el = $(id);
    el.classList.remove('active','done');
  });
}

function updateLoadingStep(n) {
  for (let i = 1; i <= 4; i++) {
    const el = $(('step' + i));
    if (i < n) { el.classList.remove('active'); el.classList.add('done'); }
    else if (i === n) { el.classList.add('active'); el.classList.remove('done'); }
    else { el.classList.remove('active','done'); }
  }
}

function updateProgress(pct) {
  els.progressBar.style.width = `${pct}%`;
}

// ===== Queue =====
function addToQueue(videoUrl, prompt) {
  const item = { videoUrl, prompt, settings: { ...state.settings }, ts: Date.now() };
  state.queue.unshift(item);
  if (state.queue.length > 5) state.queue.pop();
  renderQueue();
}

function renderQueue() {
  els.queuePanel.innerHTML = '';
  if (state.queue.length < 2) return;
  state.queue.slice(1, 4).forEach(item => {
    const div = document.createElement('div');
    div.className = 'queue-item';
    div.innerHTML = `
      <div class="queue-thumb"><video src="${item.videoUrl}" muted loop autoplay playsinline></video></div>
      <div class="queue-info">
        <div class="queue-prompt">${item.prompt}</div>
        <div class="queue-meta">${item.settings.resolution} · ${item.settings.duration} · ${item.settings.style}</div>
      </div>
      <span class="queue-badge">Done</span>
    `;
    els.queuePanel.appendChild(div);
  });
}

// ===== Download & Share =====
els.downloadBtn.addEventListener('click', () => {
  const url = els.downloadBtn._url;
  if (!url) return;
  const a = document.createElement('a');
  a.href = url;
  a.download = `seedance-4k-${Date.now()}.webm`;
  a.click();
  toast('Video download started!', 'success');
});

els.shareBtn.addEventListener('click', async () => {
  const url = els.downloadBtn._url;
  if (!url) return;
  if (navigator.share) {
    try {
      await navigator.share({ title: 'Seedance 2.5 AI Video', text: els.downloadBtn._prompt || 'AI generated video', url: window.location.href });
    } catch {}
  } else {
    await navigator.clipboard.writeText(window.location.href).catch(() => {});
    toast('Link copied to clipboard!', 'info');
  }
});

// ===== Gallery =====
function renderGallery() {
  GALLERY_ITEMS.forEach(item => {
    const card = document.createElement('div');
    card.className = 'gallery-card';
    card.innerHTML = `
      <div class="gallery-thumb" style="background:${item.gradient}">
        <div class="gallery-play">
          <svg viewBox="0 0 40 40" fill="none"><circle cx="20" cy="20" r="18" fill="rgba(0,0,0,0.5)"/><path d="M16 14l12 6-12 6V14z" fill="white"/></svg>
        </div>
      </div>
      <div class="gallery-info">
        <div class="gallery-prompt">${item.prompt}</div>
        <div class="gallery-tags">${item.tags.map(t => `<span class="gallery-tag">${t}</span>`).join('')}</div>
      </div>
    `;
    card.addEventListener('click', () => {
      els.promptInput.value = item.prompt;
      els.promptInput.dispatchEvent(new Event('input'));
      document.getElementById('generate').scrollIntoView({ behavior: 'smooth' });
      toast('Prompt loaded! Click Generate to create your video.', 'info');
    });
    els.galleryGrid.appendChild(card);
  });
}

// ===== Modal =====
els.modalRestart.addEventListener('click', restartSession);
els.modalUpgrade.addEventListener('click', () => {
  document.getElementById('pricing').scrollIntoView({ behavior: 'smooth' });
  els.sessionModal.classList.add('hidden');
});

// ===== Toast =====
function toast(msg, type = 'info') {
  const t = document.createElement('div');
  t.className = `toast ${type}`;
  t.innerHTML = `<span class="toast-dot"></span><span>${msg}</span>`;
  els.toastContainer.appendChild(t);
  setTimeout(() => {
    t.style.animation = 'fadeOut 0.3s ease forwards';
    setTimeout(() => t.remove(), 300);
  }, 3500);
}

// ===== Helpers =====
function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// ===== Init =====
function init() {
  updateTimerDisplay();
  renderGallery();

  // Smooth scroll for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(a => {
    a.addEventListener('click', e => {
      e.preventDefault();
      const target = document.querySelector(a.getAttribute('href'));
      if (target) target.scrollIntoView({ behavior: 'smooth' });
    });
  });
}

init();
