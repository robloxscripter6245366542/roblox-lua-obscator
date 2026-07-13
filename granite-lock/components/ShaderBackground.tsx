'use client';
import { useEffect, useRef } from 'react';
import * as THREE from 'three';

/**
 * Full-screen WebGL emerald "granite" background: flowing domain-warped fBm noise
 * lit as a deep-green fluid, with a soft vignette. One fullscreen triangle, one
 * fragment shader — cheap, 60fps, and it degrades gracefully (a CSS gradient
 * shows underneath if WebGL is unavailable).
 */
const FRAG = /* glsl */ `
precision highp float;
uniform vec2  uRes;
uniform float uTime;
uniform vec2  uPointer;

// hash / value-noise / fbm
float hash(vec2 p){ p = fract(p * vec2(123.34, 345.45)); p += dot(p, p + 34.345); return fract(p.x * p.y); }
float noise(vec2 p){
  vec2 i = floor(p), f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash(i), b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0)), d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p){
  float v = 0.0, a = 0.5;
  mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
  for (int i = 0; i < 5; i++){ v += a * noise(p); p = m * p; a *= 0.5; }
  return v;
}

void main(){
  vec2 uv = (gl_FragCoord.xy - 0.5 * uRes) / uRes.y;
  float t = uTime * 0.045;

  // domain warp for a slow fluid feel
  vec2 q = vec2(fbm(uv * 1.6 + t), fbm(uv * 1.6 - t + 4.3));
  vec2 r = vec2(fbm(uv * 1.6 + q * 1.4 + t * 1.3), fbm(uv * 1.6 + q * 1.4 - t));
  float f = fbm(uv * 1.7 + r * 1.5);

  // pointer-reactive emerald bloom
  vec2 pp = (uPointer - 0.5) * vec2(uRes.x / uRes.y, 1.0);
  float glow = 0.16 / (0.14 + dot(uv - pp, uv - pp) * 3.2);

  vec3 deep  = vec3(0.023, 0.055, 0.043);   // granite green-black
  vec3 mid   = vec3(0.031, 0.30, 0.21);     // emerald
  vec3 bright= vec3(0.43, 0.90, 0.68);      // mint highlight
  vec3 col = mix(deep, mid, smoothstep(0.25, 0.85, f + 0.15 * r.x));
  col = mix(col, bright, smoothstep(0.68, 1.02, f) * 0.55);
  col += bright * glow * 0.10;

  // vignette
  float d = length(uv * vec2(0.9, 1.05));
  col *= smoothstep(1.35, 0.25, d);
  col = pow(col, vec3(0.86)); // gentle lift

  gl_FragColor = vec4(col, 1.0);
}
`;

const VERT = /* glsl */ `
void main(){ gl_Position = vec4(position, 1.0); }
`;

export default function ShaderBackground() {
  const ref = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    let renderer: THREE.WebGLRenderer;
    try {
      renderer = new THREE.WebGLRenderer({ canvas, antialias: false, alpha: false, powerPreference: 'high-performance' });
    } catch {
      return; // no WebGL — CSS gradient underneath remains
    }
    const dpr = Math.min(window.devicePixelRatio || 1, 1.75);
    renderer.setPixelRatio(dpr);

    const scene = new THREE.Scene();
    const camera = new THREE.Camera();
    const uniforms = {
      uRes: { value: new THREE.Vector2(1, 1) },
      uTime: { value: 0 },
      uPointer: { value: new THREE.Vector2(0.5, 0.5) },
    };
    const geo = new THREE.PlaneGeometry(2, 2);
    const mat = new THREE.ShaderMaterial({ vertexShader: VERT, fragmentShader: FRAG, uniforms });
    scene.add(new THREE.Mesh(geo, mat));

    const resize = () => {
      const w = window.innerWidth, h = window.innerHeight;
      renderer.setSize(w, h, false);
      uniforms.uRes.value.set(w * dpr, h * dpr);
    };
    resize();
    window.addEventListener('resize', resize);

    const onMove = (e: PointerEvent) => {
      uniforms.uPointer.value.set(e.clientX / window.innerWidth, 1 - e.clientY / window.innerHeight);
    };
    window.addEventListener('pointermove', onMove, { passive: true });

    let raf = 0;
    const start = performance.now();
    let running = true;
    const onVis = () => { running = document.visibilityState === 'visible'; if (running) loop(); };
    document.addEventListener('visibilitychange', onVis);

    const loop = () => {
      if (!running) return;
      uniforms.uTime.value = (performance.now() - start) / 1000;
      renderer.render(scene, camera);
      raf = requestAnimationFrame(loop);
    };
    loop();

    return () => {
      running = false;
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', resize);
      window.removeEventListener('pointermove', onMove);
      document.removeEventListener('visibilitychange', onVis);
      geo.dispose(); mat.dispose(); renderer.dispose();
    };
  }, []);

  return (
    <canvas
      ref={ref}
      aria-hidden="true"
      className="fixed inset-0 -z-10 h-full w-full"
      style={{ background: 'radial-gradient(1200px 600px at 15% -10%, #0f7a5333, transparent), radial-gradient(1000px 600px at 100% 110%, #0b5a4833, transparent), #080a09' }}
    />
  );
}
