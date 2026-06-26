import { useEffect, useRef, useState, useCallback } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/addons/controls/OrbitControls.js'
import { buildCharacter } from './character.js'
import { CLIPS, ANIM_LIST } from './animations.js'
import { createPostFX } from './postfx.js'
import Timeline from './Timeline.jsx'
import {
  X, Play, Pause, SkipBack, Video, Grid3X3, Eye, EyeOff,
  ChevronRight, ChevronDown, Palette, Move3D, RotateCcw,
  Layers, Sun, Camera, Download, Sliders, Sparkles, Paintbrush,
  Wand2, Zap, Film
} from 'lucide-react'

const BONE_TREE = {
  root: ['hips'],
  hips: ['spine', 'lThigh', 'rThigh'],
  spine: ['chest'],
  chest: ['neck', 'lShoulder', 'rShoulder'],
  neck: ['head'], head: [],
  lShoulder: ['lUpperArm'], lUpperArm: ['lForeArm'], lForeArm: ['lHand'], lHand: [],
  rShoulder: ['rUpperArm'], rUpperArm: ['rForeArm'], rForeArm: ['rHand'], rHand: [],
  lThigh: ['lShin'], lShin: ['lFoot'], lFoot: [],
  rThigh: ['rShin'], rShin: ['rFoot'], rFoot: [],
}
const BONE_LABELS = {
  root: 'Root', hips: 'Hips', spine: 'Spine', chest: 'Chest',
  neck: 'Neck', head: 'Head',
  lShoulder: 'L Shoulder', lUpperArm: 'L Upper Arm', lForeArm: 'L Forearm', lHand: 'L Hand',
  rShoulder: 'R Shoulder', rUpperArm: 'R Upper Arm', rForeArm: 'R Forearm', rHand: 'R Hand',
  lThigh: 'L Thigh', lShin: 'L Shin', lFoot: 'L Foot',
  rThigh: 'R Thigh', rShin: 'R Shin', rFoot: 'R Foot',
}

const RAD = Math.PI / 180
const DEG = 180 / Math.PI

// ── Procedural texture generators ─────────────────────────────────────────────
function genTexture(fn, w = 256, h = 256) {
  const c = document.createElement('canvas')
  c.width = w; c.height = h
  const ctx = c.getContext('2d')
  fn(ctx, w, h)
  return new THREE.CanvasTexture(c)
}

const TEXTURE_PRESETS = [
  {
    id: 'default', label: 'Clean', icon: '✦',
    fn(ctx, w, h, color) {
      ctx.fillStyle = color; ctx.fillRect(0, 0, w, h)
    },
  },
  {
    id: 'pores', label: 'Skin', icon: '🔬',
    fn(ctx, w, h, color) {
      ctx.fillStyle = color; ctx.fillRect(0, 0, w, h)
      for (let i = 0; i < 4000; i++) {
        const x = Math.random() * w, y = Math.random() * h
        const r = Math.random() * 1.5 + 0.5
        ctx.fillStyle = `rgba(0,0,0,${Math.random() * 0.06 + 0.01})`
        ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill()
      }
    },
  },
  {
    id: 'weave', label: 'Cloth', icon: '🧵',
    fn(ctx, w, h, color) {
      ctx.fillStyle = color; ctx.fillRect(0, 0, w, h)
      for (let x = 0; x < w; x += 4)
        for (let y = 0; y < h; y += 4) {
          const v = ((x + y) % 8 < 4) ? 0.12 : -0.08
          ctx.fillStyle = `rgba(${v > 0 ? 255 : 0},${v > 0 ? 255 : 0},${v > 0 ? 255 : 0},${Math.abs(v)})`
          ctx.fillRect(x, y, 4, 4)
        }
    },
  },
  {
    id: 'metal', label: 'Armor', icon: '⚔️',
    fn(ctx, w, h) {
      ctx.fillStyle = '#3a3a3a'; ctx.fillRect(0, 0, w, h)
      const g = ctx.createLinearGradient(0, 0, 0, h)
      g.addColorStop(0, 'rgba(200,200,220,0.4)')
      g.addColorStop(0.5, 'rgba(80,80,100,0.2)')
      g.addColorStop(1, 'rgba(200,200,220,0.4)')
      ctx.fillStyle = g; ctx.fillRect(0, 0, w, h)
      for (let y = 0; y < h; y += 32) {
        ctx.fillStyle = 'rgba(0,0,0,0.2)'; ctx.fillRect(0, y, w, 2)
        ctx.fillStyle = 'rgba(255,255,255,0.06)'; ctx.fillRect(0, y + 2, w, 1)
      }
      for (let x = 0; x < w; x += 32) {
        ctx.fillStyle = 'rgba(0,0,0,0.15)'; ctx.fillRect(x, 0, 2, h)
      }
    },
  },
  {
    id: 'camo', label: 'Camo', icon: '🌿',
    fn(ctx, w, h) {
      ctx.fillStyle = '#4a5c2a'; ctx.fillRect(0, 0, w, h)
      const colors = ['#3b4a22','#2d3a18','#5a6e33','#1e2e12']
      for (let i = 0; i < 60; i++) {
        ctx.fillStyle = colors[Math.floor(Math.random() * colors.length)]
        ctx.beginPath()
        ctx.ellipse(Math.random()*w, Math.random()*h, Math.random()*30+10, Math.random()*15+5,
          Math.random()*Math.PI, 0, Math.PI*2)
        ctx.fill()
      }
    },
  },
  {
    id: 'neon', label: 'Neon', icon: '⚡',
    fn(ctx, w, h) {
      ctx.fillStyle = '#060616'; ctx.fillRect(0, 0, w, h)
      ctx.strokeStyle = '#7C3AED'; ctx.lineWidth = 1
      for (let x = 0; x < w; x += 16) {
        ctx.globalAlpha = 0.3; ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke()
      }
      for (let y = 0; y < h; y += 16) {
        ctx.globalAlpha = 0.3; ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke()
      }
      ctx.globalAlpha = 1
      ctx.strokeStyle = '#a78bfa'; ctx.lineWidth = 2
      ctx.strokeRect(2, 2, w-4, h-4)
    },
  },
]

const ANIM_CATS = ['Basic', 'Combat', 'Action', 'Emote']

export default function Studio({ onClose }) {
  const mountRef = useRef()
  const rendererRef = useRef()
  const sceneRef = useRef()
  const cameraRef = useRef()
  const controlsRef = useRef()
  const mixerRef = useRef()
  const actionRef = useRef()
  const clockRef = useRef(new THREE.Clock())
  const charRef = useRef(null)
  const gridRef = useRef()
  const fxRef = useRef()
  const animFrameRef = useRef()
  const recorderRef = useRef()
  const chunksRef = useRef([])
  const lightsRef = useRef({})
  const paintCtxRef = useRef()
  const paintTexRef = useRef()
  const paintActiveRef = useRef(false)

  // State
  const [animId, setAnimId] = useState('idle')
  const [animCat, setAnimCat] = useState('Basic')
  const [isPlaying, setIsPlaying] = useState(true)
  const [playSpeed, setPlaySpeed] = useState(1)
  const [wireframe, setWireframe] = useState(false)
  const [showGrid, setShowGrid] = useState(true)
  const [skinColor, setSkinColor] = useState('#d4956a')
  const [clothColor, setClothColor] = useState('#1e3a5f')
  const [selectedBoneKey, setSelectedBoneKey] = useState(null)
  const [boneRot, setBoneRot] = useState({ x: 0, y: 0, z: 0 })
  const [isRecording, setIsRecording] = useState(false)
  const [recordUrl, setRecordUrl] = useState(null)
  const [timeNorm, setTimeNorm] = useState(0)
  const [expanded, setExpanded] = useState({ root: true, hips: true, chest: true })
  const [activePanel, setActivePanel] = useState('anim')
  const [envBg, setEnvBg] = useState('#0d0f1a')
  const [exposure, setExposure] = useState(1.2)
  const [keyLightInt, setKeyLightInt] = useState(2.5)
  const [ambientInt, setAmbientInt] = useState(0.4)
  const [bloomStrength, setBloomStrength] = useState(0.32)
  const [bloomRadius, setBloomRadius] = useState(0.75)
  const [bloomThreshold, setBloomThreshold] = useState(0.12)
  const [filmGrain, setFilmGrain] = useState(0.018)
  const [vigInt, setVigInt] = useState(0.28)
  const [saturation, setSaturation] = useState(1.0)
  const [contrast, setContrast] = useState(1.0)
  const [paintColor, setPaintColor] = useState('#ff8844')
  const [brushSize, setBrushSize] = useState(12)
  const [paintLayer, setPaintLayer] = useState('skin')
  const [activeTexPreset, setActiveTexPreset] = useState('default')
  const [graphMode, setGraphMode] = useState(false)
  const graphCanvasRef = useRef()

  // ── Init Three.js ────────────────────────────────────────────────
  useEffect(() => {
    const mount = mountRef.current
    if (!mount) return
    const w = mount.clientWidth || 800
    const h = mount.clientHeight || 600

    const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true })
    renderer.setSize(w, h)
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
    renderer.toneMapping = THREE.ACESFilmicToneMapping
    renderer.toneMappingExposure = 1.2
    renderer.outputColorSpace = THREE.SRGBColorSpace
    mount.appendChild(renderer.domElement)
    rendererRef.current = renderer

    const scene = new THREE.Scene()
    scene.background = new THREE.Color('#0d0f1a')
    scene.fog = new THREE.FogExp2('#0d0f1a', 0.035)
    sceneRef.current = scene

    const camera = new THREE.PerspectiveCamera(45, w / h, 0.05, 100)
    camera.position.set(0, 1.6, 3.5)
    cameraRef.current = camera

    const controls = new OrbitControls(camera, renderer.domElement)
    controls.target.set(0, 1.1, 0)
    controls.enableDamping = true
    controls.dampingFactor = 0.06
    controls.maxPolarAngle = Math.PI * 0.88
    controls.minDistance = 0.6
    controls.maxDistance = 14
    controlsRef.current = controls

    // 3-point cinematic lighting
    const ambient = new THREE.AmbientLight('#c8d0f0', 0.32)
    scene.add(ambient)
    lightsRef.current.ambient = ambient

    // Key light – warm, high front-left
    const key = new THREE.DirectionalLight('#fff5e0', 3.2)
    key.position.set(3.5, 9, 5)
    key.castShadow = true
    key.shadow.mapSize.set(2048, 2048)
    key.shadow.camera.near = 0.5; key.shadow.camera.far = 22
    key.shadow.camera.left = -4; key.shadow.camera.right = 4
    key.shadow.camera.top = 8; key.shadow.camera.bottom = -2
    key.shadow.bias = -0.0004
    scene.add(key)
    lightsRef.current.key = key

    // Fill light – cool blue-grey from right
    const fill = new THREE.DirectionalLight('#b8d0ff', 1.2)
    fill.position.set(-4, 5, 3)
    scene.add(fill)

    // Rim light – clean white from behind-above
    const rim = new THREE.DirectionalLight('#e8f0ff', 1.0)
    rim.position.set(0, 7, -5)
    scene.add(rim)

    // Hemisphere sky/ground bounce
    scene.add(new THREE.HemisphereLight('#a0b8e8', '#3a2e22', 0.38))

    // Ground
    const gMesh = new THREE.Mesh(new THREE.CircleGeometry(6, 64), new THREE.MeshStandardMaterial({ color: '#12151f', roughness: 0.88, metalness: 0.06 }))
    gMesh.rotation.x = -Math.PI / 2; gMesh.receiveShadow = true; scene.add(gMesh)
    // Subtle glow ring (very transparent)
    const ring = new THREE.Mesh(new THREE.RingGeometry(0.6, 1.3, 64), new THREE.MeshStandardMaterial({ color: '#7C3AED', roughness: 0.2, metalness: 0.9, transparent: true, opacity: 0.06, side: THREE.DoubleSide }))
    ring.rotation.x = -Math.PI / 2; ring.position.y = 0.002; scene.add(ring)

    const grid = new THREE.GridHelper(10, 20, '#2a2d3e', '#1e2030')
    grid.position.y = 0.002; scene.add(grid); gridRef.current = grid

    // Character
    const char = buildCharacter('#d4956a', '#1e3a5f')
    scene.add(char.root); charRef.current = char
    const mixer = new THREE.AnimationMixer(char.root)
    mixerRef.current = mixer
    const action = mixer.clipAction(CLIPS['idle'])
    action.play(); actionRef.current = action

    // Post FX
    const fx = createPostFX(renderer, scene, camera, w, h)
    fxRef.current = fx

    // Paint canvas (virtual, used as texture source)
    const pCanvas = document.createElement('canvas')
    pCanvas.width = 256; pCanvas.height = 256
    const pCtx = pCanvas.getContext('2d')
    pCtx.fillStyle = '#d4956a'; pCtx.fillRect(0, 0, 256, 256)
    paintCtxRef.current = { canvas: pCanvas, ctx: pCtx }
    paintTexRef.current = new THREE.CanvasTexture(pCanvas)

    // Render loop
    function loop() {
      animFrameRef.current = requestAnimationFrame(loop)
      const delta = clockRef.current.getDelta()
      controls.update()
      if (mixerRef.current) {
        mixerRef.current.update(delta)
        if (actionRef.current) {
          const dur = actionRef.current.getClip().duration
          setTimeNorm((actionRef.current.time % dur) / dur)
        }
      }
      if (fxRef.current) fxRef.current.render(delta)
      else renderer.render(scene, camera)
    }
    loop()

    const ro = new ResizeObserver(() => {
      const w2 = mount.clientWidth, h2 = mount.clientHeight
      camera.aspect = w2 / h2
      camera.updateProjectionMatrix()
      renderer.setSize(w2, h2)
      fxRef.current?.resize(w2, h2)
    })
    ro.observe(mount)

    return () => {
      ro.disconnect()
      cancelAnimationFrame(animFrameRef.current)
      controls.dispose()
      renderer.dispose()
      if (mount.contains(renderer.domElement)) mount.removeChild(renderer.domElement)
    }
  }, []) // eslint-disable-line

  // ── Sync options ────────────────────────────────────────────────
  useEffect(() => {
    if (!charRef.current) return
    charRef.current.root.traverse(obj => {
      if (obj.isMesh && obj.material) {
        const mats = Array.isArray(obj.material) ? obj.material : [obj.material]
        mats.forEach(m => { m.wireframe = wireframe })
      }
    })
  }, [wireframe])

  useEffect(() => { if (gridRef.current) gridRef.current.visible = showGrid }, [showGrid])
  useEffect(() => { if (rendererRef.current) rendererRef.current.toneMappingExposure = exposure }, [exposure])
  useEffect(() => { if (lightsRef.current.key) lightsRef.current.key.intensity = keyLightInt }, [keyLightInt])
  useEffect(() => { if (lightsRef.current.ambient) lightsRef.current.ambient.intensity = ambientInt }, [ambientInt])
  useEffect(() => { fxRef.current?.setBloom(bloomStrength, bloomRadius, bloomThreshold) }, [bloomStrength, bloomRadius, bloomThreshold])
  useEffect(() => { fxRef.current?.setFilm({ grain: filmGrain, vignette: vigInt, saturation, contrast }) }, [filmGrain, vigInt, saturation, contrast])

  // ── Rebuild character on color change ────────────────────────────
  useEffect(() => {
    if (!charRef.current || !sceneRef.current || !mixerRef.current) return
    const scene = sceneRef.current
    mixerRef.current.stopAllAction()
    scene.remove(charRef.current.root)
    charRef.current.root.traverse(obj => {
      if (obj.geometry) obj.geometry.dispose()
      if (obj.material) {
        const mats = Array.isArray(obj.material) ? obj.material : [obj.material]
        mats.forEach(m => m.dispose())
      }
    })
    const char = buildCharacter(skinColor, clothColor)
    char.root.traverse(obj => { if (obj.isMesh) obj.material.wireframe = wireframe })
    scene.add(char.root)
    charRef.current = char
    const mixer = new THREE.AnimationMixer(char.root)
    mixerRef.current = mixer
    const action = mixer.clipAction(CLIPS[animId])
    action.timeScale = playSpeed
    if (isPlaying) action.play()
    actionRef.current = action
    setSelectedBoneKey(null)
  }, [skinColor, clothColor]) // eslint-disable-line

  // ── Animation controls ───────────────────────────────────────────
  const switchAnim = useCallback((id) => {
    if (!mixerRef.current) return
    setAnimId(id)
    mixerRef.current.stopAllAction()
    const action = mixerRef.current.clipAction(CLIPS[id])
    action.timeScale = playSpeed
    if (isPlaying) action.play()
    actionRef.current = action
  }, [isPlaying, playSpeed])

  const togglePlay = useCallback(() => {
    if (!actionRef.current) return
    setIsPlaying(p => {
      if (!p) actionRef.current.play(); else actionRef.current.stop()
      return !p
    })
  }, [])

  const resetAnim = useCallback(() => {
    if (!actionRef.current) return
    actionRef.current.stop(); actionRef.current.reset(); actionRef.current.play()
    setTimeNorm(0)
  }, [])

  const changeSpeed = useCallback((spd) => {
    setPlaySpeed(spd)
    if (actionRef.current) actionRef.current.timeScale = spd
  }, [])

  const scrubTimeline = useCallback((norm) => {
    if (!actionRef.current) return
    actionRef.current.time = norm * actionRef.current.getClip().duration
    setTimeNorm(norm)
  }, [])

  // ── Bone pose ────────────────────────────────────────────────────
  const selectBone = useCallback((key) => {
    setSelectedBoneKey(key)
    if (charRef.current) {
      const bone = charRef.current.bones[key]
      if (bone) setBoneRot({ x: Math.round(bone.rotation.x * DEG), y: Math.round(bone.rotation.y * DEG), z: Math.round(bone.rotation.z * DEG) })
    }
    setActivePanel('pose')
  }, [])

  const applyPose = useCallback((axis, deg) => {
    setBoneRot(r => {
      const next = { ...r, [axis]: deg }
      if (charRef.current && selectedBoneKey) {
        const bone = charRef.current.bones[selectedBoneKey]
        if (bone) { bone.rotation.x = next.x * RAD; bone.rotation.y = next.y * RAD; bone.rotation.z = next.z * RAD }
      }
      return next
    })
  }, [selectedBoneKey])

  const resetBone = useCallback(() => {
    if (!charRef.current || !selectedBoneKey) return
    charRef.current.bones[selectedBoneKey]?.rotation.set(0, 0, 0)
    setBoneRot({ x: 0, y: 0, z: 0 })
  }, [selectedBoneKey])

  // ── Texture paint ────────────────────────────────────────────────
  const applyTexturePreset = useCallback((preset, layer, color) => {
    const { canvas, ctx } = paintCtxRef.current
    const baseColor = layer === 'skin' ? color || skinColor : color || clothColor
    preset.fn(ctx, 256, 256, baseColor)
    paintTexRef.current.needsUpdate = true
    if (charRef.current) {
      const mat = charRef.current.materials[layer]
      if (mat) { mat.map = paintTexRef.current; mat.needsUpdate = true }
    }
    setActiveTexPreset(preset.id)
  }, [skinColor, clothColor])

  const clearTexture = useCallback((layer) => {
    if (!charRef.current) return
    const mat = charRef.current.materials[layer]
    if (mat) { mat.map = null; mat.needsUpdate = true }
    setActiveTexPreset('default')
  }, [])

  // ── Paint brush (on mini canvas) ─────────────────────────────────
  const handlePaint = useCallback((e) => {
    if (!paintActiveRef.current) return
    const canvas = e.currentTarget
    const rect = canvas.getBoundingClientRect()
    const x = (e.clientX - rect.left) / rect.width * 256
    const y = (e.clientY - rect.top) / rect.height * 256
    const ctx = paintCtxRef.current.ctx
    ctx.fillStyle = paintColor
    ctx.beginPath(); ctx.arc(x, y, brushSize, 0, Math.PI * 2); ctx.fill()
    // Sync paint canvas display
    const disp = canvas.getContext('2d')
    disp.clearRect(0, 0, canvas.width, canvas.height)
    disp.drawImage(paintCtxRef.current.canvas, 0, 0, canvas.width, canvas.height)
    paintTexRef.current.needsUpdate = true
    if (charRef.current) {
      const mat = charRef.current.materials[paintLayer]
      if (mat) { mat.map = paintTexRef.current; mat.needsUpdate = true }
    }
  }, [paintColor, brushSize, paintLayer])

  // ── Record ───────────────────────────────────────────────────────
  const startRecord = useCallback(() => {
    if (!rendererRef.current) return
    const stream = rendererRef.current.domElement.captureStream(30)
    const rec = new MediaRecorder(stream, { mimeType: 'video/webm;codecs=vp9', videoBitsPerSecond: 16_000_000 })
    chunksRef.current = []
    rec.ondataavailable = e => { if (e.data.size > 0) chunksRef.current.push(e.data) }
    rec.onstop = () => {
      setRecordUrl(URL.createObjectURL(new Blob(chunksRef.current, { type: 'video/webm' })))
      setIsRecording(false)
    }
    rec.start(); recorderRef.current = rec; setIsRecording(true); setRecordUrl(null)
    setTimeout(() => recorderRef.current?.state === 'recording' && recorderRef.current.stop(), 10000)
  }, [])

  const stopRecord = useCallback(() => { recorderRef.current?.state === 'recording' && recorderRef.current.stop() }, [])

  // ── Graph editor ─────────────────────────────────────────────────
  useEffect(() => {
    if (!graphMode || !graphCanvasRef.current) return
    const canvas = graphCanvasRef.current
    const ctx = canvas.getContext('2d')
    const W = canvas.width, H = canvas.height
    ctx.fillStyle = '#0b0d18'; ctx.fillRect(0, 0, W, H)

    const clip = CLIPS[animId]
    if (!clip) return
    const dur = clip.duration

    // Grid
    ctx.strokeStyle = 'rgba(255,255,255,0.08)'; ctx.lineWidth = 1
    for (let x = 0; x <= 10; x++) { ctx.beginPath(); ctx.moveTo(x / 10 * W, 0); ctx.lineTo(x / 10 * W, H); ctx.stroke() }
    for (let y = 0; y <= 6; y++) { ctx.beginPath(); ctx.moveTo(0, y / 6 * H); ctx.lineTo(W, y / 6 * H); ctx.stroke() }

    // Axis labels
    ctx.fillStyle = 'rgba(255,255,255,0.3)'; ctx.font = '9px monospace'
    for (let x = 0; x <= 4; x++) ctx.fillText(`${(x / 4 * dur).toFixed(1)}s`, x / 4 * W + 2, H - 3)

    const colors = ['#ef4444', '#22c55e', '#3b82f6', '#f59e0b', '#a78bfa', '#ec4899', '#14b8a6', '#fb923c']
    const rotTracks = clip.tracks.filter(t => t.name.includes('quaternion'))

    rotTracks.slice(0, 8).forEach((track, ci) => {
      const times = Array.from(track.times)
      const values = Array.from(track.values)
      ctx.strokeStyle = colors[ci % colors.length]; ctx.lineWidth = 1.5
      ctx.beginPath()
      times.forEach((t, i) => {
        const q = new THREE.Quaternion(values[i * 4], values[i * 4 + 1], values[i * 4 + 2], values[i * 4 + 3])
        const e = new THREE.Euler().setFromQuaternion(q)
        const val = e.x * 57.3 // X rotation in degrees
        const px = (t / dur) * W
        const py = H / 2 - (val / 180) * (H * 0.45)
        i === 0 ? ctx.moveTo(px, py) : ctx.lineTo(px, py)
      })
      ctx.stroke()

      // Keyframe dots
      times.forEach((t, i) => {
        const q = new THREE.Quaternion(values[i * 4], values[i * 4 + 1], values[i * 4 + 2], values[i * 4 + 3])
        const e = new THREE.Euler().setFromQuaternion(q)
        const val = e.x * 57.3
        const px = (t / dur) * W
        const py = H / 2 - (val / 180) * (H * 0.45)
        ctx.fillStyle = colors[ci % colors.length]
        ctx.beginPath(); ctx.arc(px, py, 3, 0, Math.PI * 2); ctx.fill()
      })

      // Legend
      ctx.fillStyle = colors[ci % colors.length]
      ctx.fillText(track.name.split('.')[0], 4, 14 + ci * 12)
    })

    // Playhead
    ctx.strokeStyle = '#a78bfa'; ctx.lineWidth = 1.5; ctx.setLineDash([3, 3])
    ctx.beginPath(); ctx.moveTo(timeNorm * W, 0); ctx.lineTo(timeNorm * W, H); ctx.stroke()
    ctx.setLineDash([])
  }, [graphMode, animId, timeNorm])

  // ── Bone tree ────────────────────────────────────────────────────
  function BoneNode({ bKey, depth = 0 }) {
    const children = BONE_TREE[bKey] || []
    const isExpanded = expanded[bKey]
    const isSelected = selectedBoneKey === bKey
    return (
      <div>
        <div className="flex items-center gap-1 py-[3px] px-2 rounded cursor-pointer select-none text-xs transition-colors"
          style={{ paddingLeft: `${8 + depth * 12}px`, background: isSelected ? 'rgba(124,58,237,0.25)' : 'transparent', color: isSelected ? '#c4b5fd' : '#9ca3af' }}
          onClick={() => selectBone(bKey)}>
          {children.length > 0
            ? <button onClick={e => { e.stopPropagation(); setExpanded(ex => ({ ...ex, [bKey]: !ex[bKey] })) }} className="w-4 h-4 flex items-center justify-center text-[#6b7280] flex-shrink-0">
                {isExpanded ? <ChevronDown size={10} /> : <ChevronRight size={10} />}
              </button>
            : <span className="w-4 h-4 flex-shrink-0" />}
          <span className="w-2 h-2 rounded-full flex-shrink-0" style={{ background: isSelected ? '#7C3AED' : '#374151' }} />
          <span className="ml-1 truncate text-[11px]">{BONE_LABELS[bKey]}</span>
        </div>
        {children.length > 0 && isExpanded && children.map(c => <BoneNode key={c} bKey={c} depth={depth + 1} />)}
      </div>
    )
  }

  const PANELS = [
    { id: 'anim',      Icon: Layers,     label: 'Anims'  },
    { id: 'paint',     Icon: Paintbrush, label: 'Paint'  },
    { id: 'pose',      Icon: Move3D,     label: 'Pose'   },
    { id: 'fx',        Icon: Sparkles,   label: 'FX'     },
    { id: 'light',     Icon: Sun,        label: 'Light'  },
  ]

  return (
    <div className="fixed inset-0 z-50 flex flex-col" style={{ background: '#090b12', fontFamily: 'Inter,sans-serif' }}>

      {/* ── Top bar ─────────────────────────────────────────────── */}
      <div className="flex items-center gap-3 px-4 h-12 border-b flex-shrink-0"
        style={{ background: '#0d0f1a', borderColor: 'rgba(255,255,255,0.08)' }}>
        <button onClick={onClose} className="w-7 h-7 rounded-lg flex items-center justify-center text-[#9ca3af] hover:text-white hover:bg-white/10 transition-all">
          <X size={15} />
        </button>
        <div className="w-px h-5 mx-1" style={{ background: 'rgba(255,255,255,0.1)' }} />
        <div className="flex items-center gap-2">
          <div className="w-5 h-5 rounded" style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }} />
          <span className="text-sm font-bold text-white">Character Studio</span>
          <span className="text-[10px] font-black tracking-wider px-1.5 py-px rounded text-white"
            style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }}>MOVIE</span>
        </div>

        <div className="flex items-center gap-0.5 ml-4">
          {[
            { title: 'Wireframe', icon: wireframe ? Eye : EyeOff, action: () => setWireframe(w => !w), active: wireframe },
            { title: 'Grid', icon: Grid3X3, action: () => setShowGrid(g => !g), active: showGrid },
            { title: 'Graph Editor', icon: Film, action: () => setGraphMode(g => !g), active: graphMode },
          ].map(({ title, icon: Icon, action, active }) => (
            <button key={title} title={title} onClick={action}
              className="px-2.5 py-1.5 rounded text-xs flex items-center gap-1 transition-all"
              style={{ color: active ? '#a78bfa' : '#6b7280', background: active ? 'rgba(124,58,237,0.15)' : 'transparent' }}>
              <Icon size={13} />
              <span className="text-[10px] hidden md:inline">{title}</span>
            </button>
          ))}
        </div>

        {/* Camera presets (compact) */}
        <div className="hidden lg:flex items-center gap-1 ml-1 border-l pl-3" style={{ borderColor: 'rgba(255,255,255,0.08)' }}>
          {[['F', [0,1.4,3.5]], ['S', [3.5,1.4,0]], ['T', [0,5,0.01]], ['C', [0,1.7,1.4]]].map(([k, p]) => (
            <button key={k} onClick={() => { cameraRef.current.position.set(...p); controlsRef.current.target.set(0,1.1,0) }}
              className="w-6 h-6 rounded text-[10px] font-bold text-[#6b7280] hover:text-white hover:bg-white/8 transition-all"
              style={{ background: 'rgba(255,255,255,0.04)' }}>{k}</button>
          ))}
        </div>

        <div className="ml-auto flex items-center gap-2">
          {recordUrl && (
            <a href={recordUrl} download={`studio-4k-${Date.now()}.webm`}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-emerald-300"
              style={{ background: 'rgba(16,185,129,0.12)', border: '1px solid rgba(16,185,129,0.25)' }}>
              <Download size={12} /> Download
            </a>
          )}
          <button onClick={isRecording ? stopRecord : startRecord}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all"
            style={{
              background: isRecording ? 'rgba(239,68,68,0.15)' : 'rgba(124,58,237,0.15)',
              border: isRecording ? '1px solid rgba(239,68,68,0.35)' : '1px solid rgba(124,58,237,0.35)',
              color: isRecording ? '#f87171' : '#a78bfa',
            }}>
            {isRecording
              ? <><span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />Stop</>
              : <><Video size={12} />Render 4K</>}
          </button>
        </div>
      </div>

      {/* ── Main area ─────────────────────────────────────────────── */}
      <div className="flex flex-1 overflow-hidden">

        {/* Left: Skeleton ─────────────────────────────────────────── */}
        <div className="w-48 flex-shrink-0 flex flex-col border-r" style={{ background: '#0b0d18', borderColor: 'rgba(255,255,255,0.07)' }}>
          <div className="px-3 py-2 border-b flex items-center gap-2" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
            <Layers size={11} className="text-[#7C3AED]" />
            <span className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider">Skeleton</span>
            <span className="ml-auto text-[9px] text-[#555872]">19 bones</span>
          </div>
          <div className="flex-1 overflow-y-auto py-1">
            <BoneNode bKey="root" depth={0} />
          </div>
          {selectedBoneKey && (
            <div className="border-t px-3 py-2" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
              <p className="text-[9px] text-[#7C3AED] font-bold uppercase tracking-wide mb-1">{BONE_LABELS[selectedBoneKey]}</p>
              <p className="text-[9px] text-[#555872]">Click Pose tab → rotate</p>
            </div>
          )}
        </div>

        {/* Center: 3D Viewport ──────────────────────────────────── */}
        <div className="flex-1 relative overflow-hidden" ref={mountRef} style={{ background: '#0d0f1a' }}>
          <div className="absolute top-3 left-3 text-[9px] font-bold tracking-widest pointer-events-none" style={{ color: 'rgba(255,255,255,0.18)' }}>
            PERSPECTIVE · ACES · PBR
          </div>
          <div className="absolute bottom-3 right-3 text-[9px] pointer-events-none text-right" style={{ color: 'rgba(255,255,255,0.15)' }}>
            RMB: orbit · Scroll: zoom · MMB: pan
          </div>
          {/* Bloom indicator */}
          {bloomStrength > 0.1 && (
            <div className="absolute top-3 right-3 flex items-center gap-1 px-2 py-1 rounded text-[9px] pointer-events-none"
              style={{ background: 'rgba(124,58,237,0.15)', border: '1px solid rgba(124,58,237,0.2)', color: '#a78bfa' }}>
              <Zap size={9} /> BLOOM ON
            </div>
          )}
        </div>

        {/* Right: Properties ───────────────────────────────────── */}
        <div className="w-64 flex-shrink-0 flex flex-col border-l" style={{ background: '#0b0d18', borderColor: 'rgba(255,255,255,0.07)' }}>
          {/* Tabs */}
          <div className="flex border-b" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
            {PANELS.map(({ id, Icon, label }) => (
              <button key={id} onClick={() => setActivePanel(id)}
                className="flex-1 flex flex-col items-center gap-0.5 py-2 text-[8px] font-bold uppercase tracking-wide transition-all"
                style={{ color: activePanel === id ? '#a78bfa' : '#555872', borderBottom: activePanel === id ? '2px solid #7C3AED' : '2px solid transparent', background: activePanel === id ? 'rgba(124,58,237,0.08)' : 'transparent' }}>
                <Icon size={12} />{label}
              </button>
            ))}
          </div>

          <div className="flex-1 overflow-y-auto">

            {/* ── ANIMATIONS ────────────────────────────────────── */}
            {activePanel === 'anim' && (
              <div className="p-3">
                {/* Category filter */}
                <div className="flex gap-1 mb-3 flex-wrap">
                  {ANIM_CATS.map(cat => (
                    <button key={cat} onClick={() => setAnimCat(cat)}
                      className="px-2 py-0.5 rounded text-[9px] font-bold transition-all"
                      style={{ background: animCat === cat ? 'rgba(124,58,237,0.25)' : 'rgba(255,255,255,0.05)', color: animCat === cat ? '#c4b5fd' : '#6b7280', border: animCat === cat ? '1px solid rgba(124,58,237,0.4)' : '1px solid transparent' }}>
                      {cat}
                    </button>
                  ))}
                </div>
                <div className="grid grid-cols-2 gap-1.5">
                  {ANIM_LIST.filter(a => a.cat === animCat).map(({ id, label, icon }) => (
                    <button key={id} onClick={() => switchAnim(id)}
                      className="flex flex-col items-center gap-1 py-2.5 px-1 rounded-xl text-xs font-semibold transition-all"
                      style={{ background: animId === id ? 'rgba(124,58,237,0.22)' : 'rgba(255,255,255,0.04)', border: animId === id ? '1px solid rgba(124,58,237,0.5)' : '1px solid rgba(255,255,255,0.07)', color: animId === id ? '#c4b5fd' : '#9ca3af' }}>
                      <span className="text-lg leading-none">{icon}</span>
                      <span className="text-[10px]">{label}</span>
                    </button>
                  ))}
                </div>
                <div className="mt-3">
                  <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-1.5">Speed</p>
                  <div className="flex gap-1">
                    {[0.25, 0.5, 1, 1.5, 2].map(spd => (
                      <button key={spd} onClick={() => changeSpeed(spd)}
                        className="flex-1 py-1 rounded text-[9px] font-bold transition-all"
                        style={{ background: playSpeed === spd ? 'rgba(124,58,237,0.25)' : 'rgba(255,255,255,0.05)', color: playSpeed === spd ? '#c4b5fd' : '#6b7280', border: playSpeed === spd ? '1px solid rgba(124,58,237,0.4)' : '1px solid transparent' }}>
                        {spd}×
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* ── PAINT / MATERIALS ─────────────────────────────── */}
            {activePanel === 'paint' && (
              <div className="p-3 space-y-4">
                {/* Layer toggle */}
                <div>
                  <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-1.5">Paint Layer</p>
                  <div className="flex gap-1">
                    {['skin', 'cloth'].map(l => (
                      <button key={l} onClick={() => setPaintLayer(l)}
                        className="flex-1 py-1 rounded text-[10px] font-bold capitalize transition-all"
                        style={{ background: paintLayer === l ? 'rgba(124,58,237,0.25)' : 'rgba(255,255,255,0.05)', color: paintLayer === l ? '#c4b5fd' : '#6b7280', border: paintLayer === l ? '1px solid rgba(124,58,237,0.4)' : '1px solid transparent' }}>
                        {l}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Base colors */}
                <div className="flex gap-3">
                  <div>
                    <p className="text-[9px] text-[#8b8fa8] uppercase tracking-wider mb-1">Skin</p>
                    <input type="color" value={skinColor} onChange={e => setSkinColor(e.target.value)} className="w-10 h-10 rounded-lg cursor-pointer border-0 bg-transparent" />
                  </div>
                  <div>
                    <p className="text-[9px] text-[#8b8fa8] uppercase tracking-wider mb-1">Cloth</p>
                    <input type="color" value={clothColor} onChange={e => setClothColor(e.target.value)} className="w-10 h-10 rounded-lg cursor-pointer border-0 bg-transparent" />
                  </div>
                </div>

                {/* Skin swatches */}
                <div>
                  <p className="text-[9px] text-[#6b7280] mb-1">Skin tones</p>
                  <div className="flex gap-1 flex-wrap">
                    {['#f7d9c4','#f0c89a','#d4956a','#c68642','#8b5a3c','#5c3317','#3d1c0c','#a0522d'].map(c => (
                      <button key={c} onClick={() => setSkinColor(c)} className="w-5 h-5 rounded-full border-2 transition-all" style={{ background: c, borderColor: skinColor === c ? '#a78bfa' : 'transparent' }} />
                    ))}
                  </div>
                  <p className="text-[9px] text-[#6b7280] mt-2 mb-1">Cloth colors</p>
                  <div className="flex gap-1 flex-wrap">
                    {['#1e3a5f','#7C3AED','#2563EB','#dc2626','#16a34a','#ea580c','#1f2937','#854d0e','#831843','#064e3b'].map(c => (
                      <button key={c} onClick={() => setClothColor(c)} className="w-5 h-5 rounded-full border-2 transition-all" style={{ background: c, borderColor: clothColor === c ? '#a78bfa' : 'transparent' }} />
                    ))}
                  </div>
                </div>

                {/* Texture presets */}
                <div>
                  <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Texture Presets</p>
                  <div className="grid grid-cols-3 gap-1.5">
                    {TEXTURE_PRESETS.map(preset => (
                      <button key={preset.id}
                        onClick={() => applyTexturePreset(preset, paintLayer, paintLayer === 'skin' ? skinColor : clothColor)}
                        className="flex flex-col items-center gap-1 py-2 px-1 rounded-lg transition-all text-[10px]"
                        style={{ background: activeTexPreset === preset.id ? 'rgba(124,58,237,0.22)' : 'rgba(255,255,255,0.04)', border: activeTexPreset === preset.id ? '1px solid rgba(124,58,237,0.5)' : '1px solid rgba(255,255,255,0.07)', color: activeTexPreset === preset.id ? '#c4b5fd' : '#9ca3af' }}>
                        <span className="text-base leading-none">{preset.icon}</span>
                        <span>{preset.label}</span>
                      </button>
                    ))}
                  </div>
                  <button onClick={() => clearTexture(paintLayer)} className="w-full mt-2 py-1 rounded text-[10px] text-[#9ca3af] hover:text-white transition-all" style={{ background: 'rgba(255,255,255,0.05)' }}>
                    Clear Texture
                  </button>
                </div>

                {/* Brush paint */}
                <div>
                  <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Brush Paint</p>
                  <div className="flex items-center gap-2 mb-2">
                    <input type="color" value={paintColor} onChange={e => setPaintColor(e.target.value)} className="w-8 h-8 rounded cursor-pointer border-0 bg-transparent" />
                    <div className="flex-1">
                      <div className="flex justify-between text-[9px] text-[#6b7280] mb-0.5"><span>Brush</span><span>{brushSize}px</span></div>
                      <input type="range" min="2" max="40" value={brushSize} onChange={e => setBrushSize(Number(e.target.value))} className="w-full accent-purple-500 h-1" />
                    </div>
                  </div>
                  <canvas
                    width={220} height={110}
                    className="w-full rounded-lg cursor-crosshair"
                    style={{ background: paintLayer === 'skin' ? skinColor : clothColor, border: '1px solid rgba(255,255,255,0.08)', display: 'block', imageRendering: 'pixelated' }}
                    onMouseDown={e => { paintActiveRef.current = true; handlePaint(e) }}
                    onMouseMove={handlePaint}
                    onMouseUp={() => { paintActiveRef.current = false }}
                    onMouseLeave={() => { paintActiveRef.current = false }}
                  />
                  <p className="text-[9px] text-[#555872] mt-1">Paint on canvas → applies to character mesh</p>
                </div>

                {/* Material presets */}
                <div>
                  <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Character Presets</p>
                  <div className="grid grid-cols-2 gap-1.5">
                    {[
                      { l: 'Default', s: '#d4956a', c: '#1e3a5f' },
                      { l: 'Hero',    s: '#f0c89a', c: '#7C3AED' },
                      { l: 'Villain', s: '#8b5a3c', c: '#1f2937' },
                      { l: 'Soldier', s: '#c68642', c: '#4a5c2a' },
                      { l: 'Mage',    s: '#e8b89b', c: '#831843' },
                      { l: 'Cyborg',  s: '#b0a090', c: '#374151' },
                    ].map(p => (
                      <button key={p.l} onClick={() => { setSkinColor(p.s); setClothColor(p.c) }}
                        className="flex items-center gap-1.5 px-2 py-1.5 rounded-lg text-[10px] transition-all"
                        style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.08)', color: '#9ca3af' }}>
                        <span className="w-3 h-3 rounded-full flex-shrink-0" style={{ background: p.s }} />
                        <span className="w-3 h-3 rounded-full flex-shrink-0" style={{ background: p.c }} />
                        {p.l}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* ── POSE ──────────────────────────────────────────── */}
            {activePanel === 'pose' && (
              <div className="p-3">
                {!selectedBoneKey ? (
                  <div className="text-center py-8 text-[#555872] text-xs">
                    <Move3D size={26} className="mx-auto mb-2 opacity-30" />
                    <p>Select a bone in<br />the Skeleton panel</p>
                  </div>
                ) : (
                  <>
                    <div className="flex items-center justify-between mb-3">
                      <p className="text-xs font-bold text-white">{BONE_LABELS[selectedBoneKey]}</p>
                      <button onClick={resetBone} className="flex items-center gap-1 px-2 py-1 rounded text-[10px] text-[#9ca3af] hover:text-white transition-all" style={{ background: 'rgba(255,255,255,0.06)' }}>
                        <RotateCcw size={10} /> Reset
                      </button>
                    </div>
                    {['x', 'y', 'z'].map(axis => (
                      <div key={axis} className="mb-3">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-[10px] font-bold uppercase" style={{ color: axis === 'x' ? '#ef4444' : axis === 'y' ? '#22c55e' : '#3b82f6' }}>{axis.toUpperCase()} Rotate</span>
                          <span className="text-[10px] text-[#9ca3af] font-mono">{boneRot[axis]}°</span>
                        </div>
                        <input type="range" min="-180" max="180" step="1" value={boneRot[axis]}
                          onChange={e => applyPose(axis, Number(e.target.value))}
                          className="w-full h-1.5"
                          style={{ accentColor: axis === 'x' ? '#ef4444' : axis === 'y' ? '#22c55e' : '#3b82f6' }} />
                      </div>
                    ))}
                    <div className="mt-3 p-2 rounded-lg" style={{ background: 'rgba(124,58,237,0.08)', border: '1px solid rgba(124,58,237,0.15)' }}>
                      <p className="text-[9px] text-[#a78bfa] font-bold mb-1.5">FK Pose Additive</p>
                      <p className="text-[9px] text-[#555872]">Rotation is added on top of the playing animation. Use Reset to clear.</p>
                    </div>
                  </>
                )}
              </div>
            )}

            {/* ── POST FX ───────────────────────────────────────── */}
            {activePanel === 'fx' && (
              <div className="p-3 space-y-4">
                <div>
                  <div className="flex items-center gap-1.5 mb-2">
                    <Zap size={11} className="text-yellow-400" />
                    <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider">Bloom</p>
                  </div>
                  {[
                    { label: 'Strength', val: bloomStrength, set: setBloomStrength, min: 0, max: 3, step: 0.05 },
                    { label: 'Radius',   val: bloomRadius,   set: setBloomRadius,   min: 0, max: 2, step: 0.05 },
                    { label: 'Threshold',val: bloomThreshold,set: setBloomThreshold,min: 0, max: 1, step: 0.01 },
                  ].map(({ label, val, set, min, max, step }) => (
                    <div key={label} className="mb-2">
                      <div className="flex justify-between text-[9px] mb-0.5"><span className="text-[#9ca3af]">{label}</span><span className="text-[#6b7280] font-mono">{val.toFixed(2)}</span></div>
                      <input type="range" min={min} max={max} step={step} value={val} onChange={e => set(Number(e.target.value))} className="w-full accent-yellow-400 h-1" />
                    </div>
                  ))}
                </div>

                <div>
                  <div className="flex items-center gap-1.5 mb-2">
                    <Sparkles size={11} className="text-purple-400" />
                    <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider">Color Grade</p>
                  </div>
                  {[
                    { label: 'Saturation', val: saturation, set: setSaturation, min: 0, max: 3, step: 0.05, color: '#22c55e' },
                    { label: 'Contrast',   val: contrast,   set: setContrast,   min: 0.5, max: 2.5, step: 0.05, color: '#3b82f6' },
                  ].map(({ label, val, set, min, max, step, color }) => (
                    <div key={label} className="mb-2">
                      <div className="flex justify-between text-[9px] mb-0.5"><span className="text-[#9ca3af]">{label}</span><span className="font-mono" style={{ color, fontSize: 9 }}>{val.toFixed(2)}</span></div>
                      <input type="range" min={min} max={max} step={step} value={val} onChange={e => set(Number(e.target.value))} className="w-full h-1" style={{ accentColor: color }} />
                    </div>
                  ))}
                </div>

                <div>
                  <div className="flex items-center gap-1.5 mb-2">
                    <Film size={11} className="text-pink-400" />
                    <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider">Film Look</p>
                  </div>
                  {[
                    { label: 'Film Grain', val: filmGrain, set: setFilmGrain, min: 0, max: 0.12, step: 0.002, color: '#f59e0b' },
                    { label: 'Vignette',   val: vigInt,    set: setVigInt,   min: 0.05, max: 1, step: 0.01, color: '#ec4899' },
                  ].map(({ label, val, set, min, max, step, color }) => (
                    <div key={label} className="mb-2">
                      <div className="flex justify-between text-[9px] mb-0.5"><span className="text-[#9ca3af]">{label}</span><span className="font-mono" style={{ color, fontSize: 9 }}>{val.toFixed(3)}</span></div>
                      <input type="range" min={min} max={max} step={step} value={val} onChange={e => set(Number(e.target.value))} className="w-full h-1" style={{ accentColor: color }} />
                    </div>
                  ))}
                </div>

                {/* FX Presets */}
                <div>
                  <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">LUT Presets</p>
                  <div className="grid grid-cols-2 gap-1.5">
                    {[
                      { l: 'Cinematic', bloom: [0.35,0.8,0.12], film: { saturation:1.1,contrast:1.15,grain:0.015,vignette:0.28 } },
                      { l: 'Vivid',     bloom: [0.5,1.0,0.08],  film: { saturation:1.4,contrast:1.1,grain:0.008,vignette:0.2 } },
                      { l: 'Noir',      bloom: [0.2,0.6,0.2],   film: { saturation:0.1,contrast:1.4,grain:0.04,vignette:0.45 } },
                      { l: 'Neon',      bloom: [0.8,1.5,0.05],  film: { saturation:1.8,contrast:1.2,grain:0.02,vignette:0.35 } },
                      { l: 'Flat',      bloom: [0.1,0.5,0.3],   film: { saturation:0.85,contrast:0.9,grain:0.005,vignette:0.1 } },
                      { l: 'Horror',    bloom: [0.25,0.7,0.15],  film: { saturation:0.3,contrast:1.5,grain:0.06,vignette:0.55 } },
                    ].map(p => (
                      <button key={p.l} onClick={() => {
                        setBloomStrength(p.bloom[0]); setBloomRadius(p.bloom[1]); setBloomThreshold(p.bloom[2])
                        setSaturation(p.film.saturation); setContrast(p.film.contrast)
                        setFilmGrain(p.film.grain); setVigInt(p.film.vignette)
                      }}
                        className="px-2 py-1.5 rounded-lg text-[10px] text-center transition-all"
                        style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.08)', color: '#9ca3af' }}>
                        {p.l}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* ── LIGHTING ──────────────────────────────────────── */}
            {activePanel === 'light' && (
              <div className="p-3 space-y-4">
                {[
                  { label: 'Exposure',  val: exposure,    set: setExposure,    min: 0.2, max: 3, step: 0.05, color: '#f59e0b' },
                  { label: 'Key Light', val: keyLightInt, set: setKeyLightInt, min: 0,   max: 6, step: 0.1,  color: '#fde68a' },
                  { label: 'Ambient',   val: ambientInt,  set: setAmbientInt,  min: 0,   max: 2, step: 0.05, color: '#93c5fd' },
                ].map(({ label, val, set, min, max, step, color }) => (
                  <div key={label}>
                    <div className="flex justify-between text-[9px] mb-1"><span className="text-[#9ca3af] font-bold uppercase tracking-wide">{label}</span><span className="font-mono" style={{ color, fontSize: 9 }}>{val.toFixed(2)}</span></div>
                    <input type="range" min={min} max={max} step={step} value={val} onChange={e => set(Number(e.target.value))} className="w-full h-1" style={{ accentColor: color }} />
                  </div>
                ))}

                <div>
                  <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Background</p>
                  <div className="flex items-center gap-2">
                    <input type="color" value={envBg} onChange={e => { setEnvBg(e.target.value); if (sceneRef.current) sceneRef.current.background = new THREE.Color(e.target.value) }}
                      className="w-10 h-10 rounded-lg cursor-pointer border-0 bg-transparent" />
                    <span className="text-xs font-mono text-white">{envBg}</span>
                  </div>
                  <div className="flex gap-1 mt-2">
                    {['#0d0f1a','#1a0533','#080808','#001a2c','#0a1a0a','#f0f0f0'].map(c => (
                      <button key={c} onClick={() => { setEnvBg(c); if (sceneRef.current) sceneRef.current.background = new THREE.Color(c) }}
                        className="w-8 h-6 rounded border-2 transition-all"
                        style={{ background: c, borderColor: envBg === c ? '#a78bfa' : 'rgba(255,255,255,0.1)' }} />
                    ))}
                  </div>
                </div>

                <div>
                  <p className="text-[9px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Light Presets</p>
                  <div className="grid grid-cols-2 gap-1.5">
                    {[
                      { l: 'Studio',   e:1.2, k:2.5, a:0.4 },
                      { l: 'Dawn',     e:1.4, k:3.0, a:0.25 },
                      { l: 'Night',    e:0.6, k:1.2, a:0.15 },
                      { l: 'Overcast', e:1.0, k:1.5, a:1.2 },
                    ].map(p => (
                      <button key={p.l} onClick={() => { setExposure(p.e); setKeyLightInt(p.k); setAmbientInt(p.a) }}
                        className="px-2 py-1.5 rounded-lg text-[10px] transition-all"
                        style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.08)', color: '#9ca3af' }}>
                        {p.l}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ── Bottom bar ─────────────────────────────────────────────── */}
      <div className="flex-shrink-0 border-t" style={{ background: '#0d0f1a', borderColor: 'rgba(255,255,255,0.07)' }}>
        {/* Playback row */}
        <div className="flex items-center gap-3 px-4 py-1.5 border-b" style={{ borderColor: 'rgba(255,255,255,0.05)' }}>
          <button onClick={resetAnim} className="w-7 h-7 rounded-lg flex items-center justify-center text-[#6b7280] hover:text-white transition-all hover:bg-white/5">
            <SkipBack size={13} />
          </button>
          <button onClick={togglePlay}
            className="w-8 h-8 rounded-xl flex items-center justify-center text-white transition-all"
            style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }}>
            {isPlaying ? <Pause size={13} /> : <Play size={13} />}
          </button>
          <div className="flex items-center gap-1.5">
            <span className="text-[10px] text-[#555872] font-mono">{animId.replace('_', ' ').toUpperCase()}</span>
            <span className="text-[10px] text-[#374151]">·</span>
            <span className="text-[10px] text-[#9ca3af] font-mono">{playSpeed}×</span>
            <span className="text-[10px] text-[#374151]">·</span>
            <span className="text-[10px] text-[#9ca3af] font-mono">{CLIPS[animId]?.duration.toFixed(1)}s</span>
          </div>
          <div className="ml-auto text-[10px] font-mono text-[#555872]">{Math.round(timeNorm * 100)}%</div>
        </div>

        {/* Timeline or Graph editor */}
        {graphMode ? (
          <div className="px-4 py-2">
            <p className="text-[9px] font-bold text-[#7C3AED] uppercase tracking-wider mb-1.5">
              F-Curve Graph Editor — {animId} — Quaternion X-axis traces
            </p>
            <canvas ref={graphCanvasRef} width={900} height={90}
              className="w-full rounded-lg"
              style={{ background: '#0b0d18', border: '1px solid rgba(255,255,255,0.07)', display: 'block' }} />
          </div>
        ) : (
          <Timeline timeNorm={timeNorm} clip={CLIPS[animId]} onScrub={scrubTimeline} />
        )}
      </div>
    </div>
  )
}
