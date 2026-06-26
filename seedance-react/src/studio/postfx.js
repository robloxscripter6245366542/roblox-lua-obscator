import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js'
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js'
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js'
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js'
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js'
import * as THREE from 'three'

// Film-grade color correction + grain + vignette
const FilmShader = {
  uniforms: {
    tDiffuse: { value: null },
    time:       { value: 0 },
    grain:      { value: 0.018 },
    vignette:   { value: 0.28 },
    saturation: { value: 1.0 },
    contrast:   { value: 1.0 },
    brightness: { value: 0.0 },
    liftR: { value: 0 }, liftG: { value: 0 }, liftB: { value: 0 },
    gammaR: { value: 1 }, gammaG: { value: 1 }, gammaB: { value: 1 },
    gainR: { value: 1 }, gainG: { value: 1 }, gainB: { value: 1 },
  },
  vertexShader: `
    varying vec2 vUv;
    void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.); }
  `,
  fragmentShader: `
    uniform sampler2D tDiffuse;
    uniform float time, grain, vignette, saturation, contrast, brightness;
    uniform float liftR,liftG,liftB,gammaR,gammaG,gammaB,gainR,gainG,gainB;
    varying vec2 vUv;

    float rnd(vec2 p) { return fract(sin(dot(p*1.7,vec2(127.1,311.7)))*43758.5453); }

    void main() {
      vec4 t = texture2D(tDiffuse, vUv);
      vec3 c = t.rgb;

      // ASC CDL color grade
      c = c * vec3(gainR,gainG,gainB);
      c = pow(max(c,0.0), vec3(1./max(gammaR,0.01), 1./max(gammaG,0.01), 1./max(gammaB,0.01)));
      c += vec3(liftR,liftG,liftB);

      // Brightness + contrast
      c += brightness;
      c = (c - 0.5) * contrast + 0.5;

      // Saturation
      float lum = dot(c, vec3(0.2126,0.7152,0.0722));
      c = mix(vec3(lum), c, saturation);

      // Film grain
      float g = rnd(vUv + fract(time * 0.07)) * grain;
      c += g - grain * 0.5;

      // Vignette
      vec2 uv2 = vUv * (1.0 - vUv.yx);
      float vig = pow(uv2.x * uv2.y * 15.0, vignette);
      c *= vig;

      gl_FragColor = vec4(clamp(c, 0.0, 1.0), t.a);
    }
  `,
}

export function createPostFX(renderer, scene, camera, w, h) {
  const composer = new EffectComposer(renderer)
  composer.addPass(new RenderPass(scene, camera))

  const bloom = new UnrealBloomPass(new THREE.Vector2(w, h), 0.32, 0.75, 0.12)
  composer.addPass(bloom)

  const film = new ShaderPass(FilmShader)
  composer.addPass(film)

  composer.addPass(new OutputPass())

  let _t = 0
  return {
    composer,
    bloom,
    film,
    render(delta) {
      _t += delta
      film.uniforms.time.value = _t
      composer.render()
    },
    resize(w2, h2) {
      composer.setSize(w2, h2)
      bloom.resolution.set(w2, h2)
    },
    setBloom(strength, radius, threshold) {
      bloom.strength = strength
      bloom.radius = radius
      bloom.threshold = threshold
    },
    setFilm(opts) {
      for (const [k, v] of Object.entries(opts)) {
        if (film.uniforms[k]) film.uniforms[k].value = v
      }
    },
  }
}
