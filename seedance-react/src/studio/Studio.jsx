import { useEffect, useRef, useState, useCallback } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/addons/controls/OrbitControls.js'
import { buildCharacter } from './character.js'
import { CLIPS, ANIM_LIST } from './animations.js'
import Timeline from './Timeline.jsx'
import {
  X, Play, Pause, SkipBack, Video, Grid3X3, Eye, EyeOff,
  ChevronRight, ChevronDown, Palette, Move3D, RotateCcw,
  Layers, Sun, Camera, Download, Sliders
} from 'lucide-react'

// Bone tree (parent → children keys)
const BONE_TREE = {
  root: ['hips'],
  hips: ['spine', 'lThigh', 'rThigh'],
  spine: ['chest'],
  chest: ['neck', 'lShoulder', 'rShoulder'],
  neck: ['head'],
  head: [],
  lShoulder: ['lUpperArm'],
  lUpperArm: ['lForeArm'],
  lForeArm: ['lHand'],
  lHand: [],
  rShoulder: ['rUpperArm'],
  rUpperArm: ['rForeArm'],
  rForeArm: ['rHand'],
  rHand: [],
  lThigh: ['lShin'],
  lShin: ['lFoot'],
  lFoot: [],
  rThigh: ['rShin'],
  rShin: ['rFoot'],
  rFoot: [],
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
  const animFrameRef = useRef()
  const recorderRef = useRef()
  const chunksRef = useRef([])

  const [animId, setAnimId] = useState('idle')
  const [isPlaying, setIsPlaying] = useState(true)
  const [playSpeed, setPlaySpeed] = useState(1)
  const [wireframe, setWireframe] = useState(false)
  const [showGrid, setShowGrid] = useState(true)
  const [skinColor, setSkinColor] = useState('#d4956a')
  const [clothColor, setClothColor] = useState('#1e3a5f')
  const [selectedBoneKey, setSelectedBoneKey] = useState(null)
  const [poseMode, setPoseMode] = useState(false)
  const [boneRot, setBoneRot] = useState({ x: 0, y: 0, z: 0 })
  const [isRecording, setIsRecording] = useState(false)
  const [recordUrl, setRecordUrl] = useState(null)
  const [timeNorm, setTimeNorm] = useState(0)
  const [expanded, setExpanded] = useState({ root: true, hips: true, chest: true })
  const [activePanel, setActivePanel] = useState('anim') // 'anim' | 'materials' | 'pose' | 'env'
  const [envBg, setEnvBg] = useState('#0d0f1a')
  const [exposure, setExposure] = useState(1.2)
  const [keyLight, setKeyLight] = useState(2.5)
  const [ambientLight, setAmbientLight] = useState(0.4)
  const lightsRef = useRef({})

  // ── Init Three.js ──────────────────────────────────────────────
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
    scene.fog = new THREE.FogExp2('#0d0f1a', 0.04)
    sceneRef.current = scene

    const camera = new THREE.PerspectiveCamera(45, w / h, 0.05, 100)
    camera.position.set(0, 1.6, 3.5)
    cameraRef.current = camera

    const controls = new OrbitControls(camera, renderer.domElement)
    controls.target.set(0, 1.1, 0)
    controls.enableDamping = true
    controls.dampingFactor = 0.06
    controls.maxPolarAngle = Math.PI * 0.88
    controls.minDistance = 0.8
    controls.maxDistance = 14
    controlsRef.current = controls

    // Lights
    const ambient = new THREE.AmbientLight('#b0b8ff', 0.4)
    scene.add(ambient)
    lightsRef.current.ambient = ambient

    const key = new THREE.DirectionalLight('#fff8f0', 2.5)
    key.position.set(3, 6, 4)
    key.castShadow = true
    key.shadow.mapSize.set(2048, 2048)
    key.shadow.camera.near = 0.5
    key.shadow.camera.far = 20
    key.shadow.camera.left = -4
    key.shadow.camera.right = 4
    key.shadow.camera.top = 7
    key.shadow.camera.bottom = -2
    key.shadow.bias = -0.0005
    scene.add(key)
    lightsRef.current.key = key

    const fill = new THREE.DirectionalLight('#4060ff', 0.7)
    fill.position.set(-4, 3, -2)
    scene.add(fill)

    const rim = new THREE.DirectionalLight('#ff6030', 0.5)
    rim.position.set(0, 2, -5)
    scene.add(rim)

    const topLight = new THREE.HemisphereLight('#a0c0ff', '#302010', 0.3)
    scene.add(topLight)

    // Ground
    const gGeo = new THREE.CircleGeometry(5, 64)
    const gMat = new THREE.MeshStandardMaterial({ color: '#161929', roughness: 0.9, metalness: 0.05 })
    const ground = new THREE.Mesh(gGeo, gMat)
    ground.rotation.x = -Math.PI / 2
    ground.receiveShadow = true
    scene.add(ground)

    // Reflective floor ring
    const ringGeo = new THREE.RingGeometry(0, 1.2, 48)
    const ringMat = new THREE.MeshStandardMaterial({
      color: '#7C3AED', roughness: 0.15, metalness: 0.8, transparent: true, opacity: 0.18, side: THREE.DoubleSide,
    })
    const ring = new THREE.Mesh(ringGeo, ringMat)
    ring.rotation.x = -Math.PI / 2
    ring.position.y = 0.002
    scene.add(ring)

    // Grid
    const grid = new THREE.GridHelper(10, 20, '#2a2d3e', '#1e2030')
    grid.position.y = 0.002
    scene.add(grid)
    gridRef.current = grid

    // Character
    const char = buildCharacter(skinColor, clothColor)
    scene.add(char.root)
    charRef.current = char

    // Mixer
    const mixer = new THREE.AnimationMixer(char.root)
    mixerRef.current = mixer
    const action = mixer.clipAction(CLIPS['idle'])
    action.play()
    actionRef.current = action

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
      renderer.render(scene, camera)
    }
    loop()

    function onResize() {
      if (!mount) return
      const w2 = mount.clientWidth, h2 = mount.clientHeight
      camera.aspect = w2 / h2
      camera.updateProjectionMatrix()
      renderer.setSize(w2, h2)
    }
    const ro = new ResizeObserver(onResize)
    ro.observe(mount)

    return () => {
      ro.disconnect()
      cancelAnimationFrame(animFrameRef.current)
      controls.dispose()
      renderer.dispose()
      if (mount.contains(renderer.domElement)) mount.removeChild(renderer.domElement)
    }
  }, []) // eslint-disable-line

  // ── Sync wireframe ─────────────────────────────────────────────
  useEffect(() => {
    if (!charRef.current) return
    charRef.current.root.traverse(obj => {
      if (obj.isMesh && obj.material) {
        const mats = Array.isArray(obj.material) ? obj.material : [obj.material]
        mats.forEach(m => { m.wireframe = wireframe })
      }
    })
  }, [wireframe])

  // ── Sync grid visibility ────────────────────────────────────────
  useEffect(() => {
    if (gridRef.current) gridRef.current.visible = showGrid
  }, [showGrid])

  // ── Sync exposure ───────────────────────────────────────────────
  useEffect(() => {
    if (rendererRef.current) rendererRef.current.toneMappingExposure = exposure
  }, [exposure])

  // ── Sync key light ──────────────────────────────────────────────
  useEffect(() => {
    if (lightsRef.current.key) lightsRef.current.key.intensity = keyLight
  }, [keyLight])

  // ── Sync ambient light ──────────────────────────────────────────
  useEffect(() => {
    if (lightsRef.current.ambient) lightsRef.current.ambient.intensity = ambientLight
  }, [ambientLight])

  // ── Rebuild character when colors change ────────────────────────
  useEffect(() => {
    if (!charRef.current || !sceneRef.current || !mixerRef.current) return
    const scene = sceneRef.current

    // Stop old mixer
    mixerRef.current.stopAllAction()
    scene.remove(charRef.current.root)

    // Dispose old
    charRef.current.root.traverse(obj => {
      if (obj.geometry) obj.geometry.dispose()
      if (obj.material) {
        const mats = Array.isArray(obj.material) ? obj.material : [obj.material]
        mats.forEach(m => m.dispose())
      }
    })

    const char = buildCharacter(skinColor, clothColor)
    char.root.traverse(obj => { if (obj.isMesh) { obj.material.wireframe = wireframe } })
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

  // ── Switch animation ────────────────────────────────────────────
  const switchAnim = useCallback((id) => {
    if (!mixerRef.current) return
    setAnimId(id)
    mixerRef.current.stopAllAction()
    const action = mixerRef.current.clipAction(CLIPS[id])
    action.timeScale = playSpeed
    if (isPlaying) action.play()
    actionRef.current = action
  }, [isPlaying, playSpeed])

  // ── Play / pause ────────────────────────────────────────────────
  const togglePlay = useCallback(() => {
    if (!actionRef.current) return
    setIsPlaying(p => {
      const next = !p
      if (next) actionRef.current.play()
      else actionRef.current.stop()
      return next
    })
  }, [])

  // ── Reset pose ──────────────────────────────────────────────────
  const resetAnim = useCallback(() => {
    if (!actionRef.current) return
    actionRef.current.stop()
    actionRef.current.reset()
    actionRef.current.play()
    setTimeNorm(0)
  }, [])

  // ── Speed ───────────────────────────────────────────────────────
  const changeSpeed = useCallback((spd) => {
    setPlaySpeed(spd)
    if (actionRef.current) actionRef.current.timeScale = spd
  }, [])

  // ── Select bone ─────────────────────────────────────────────────
  const selectBone = useCallback((key) => {
    setSelectedBoneKey(key)
    if (!charRef.current) return
    const bone = charRef.current.bones[key]
    if (bone) {
      setBoneRot({
        x: Math.round(bone.rotation.x * DEG),
        y: Math.round(bone.rotation.y * DEG),
        z: Math.round(bone.rotation.z * DEG),
      })
    }
    setActivePanel('pose')
  }, [])

  // ── Apply pose rotation ─────────────────────────────────────────
  const applyPose = useCallback((axis, deg) => {
    setBoneRot(r => {
      const next = { ...r, [axis]: deg }
      if (charRef.current && selectedBoneKey) {
        const bone = charRef.current.bones[selectedBoneKey]
        if (bone) {
          bone.rotation.x = next.x * RAD
          bone.rotation.y = next.y * RAD
          bone.rotation.z = next.z * RAD
        }
      }
      return next
    })
  }, [selectedBoneKey])

  // ── Reset bone rotation ─────────────────────────────────────────
  const resetBone = useCallback(() => {
    if (!charRef.current || !selectedBoneKey) return
    const bone = charRef.current.bones[selectedBoneKey]
    if (bone) { bone.rotation.set(0, 0, 0) }
    setBoneRot({ x: 0, y: 0, z: 0 })
  }, [selectedBoneKey])

  // ── Scrub timeline ──────────────────────────────────────────────
  const scrubTimeline = useCallback((norm) => {
    if (!actionRef.current) return
    const dur = actionRef.current.getClip().duration
    actionRef.current.time = norm * dur
    setTimeNorm(norm)
  }, [])

  // ── Render to video ─────────────────────────────────────────────
  const startRecord = useCallback(() => {
    if (!rendererRef.current) return
    const canvas = rendererRef.current.domElement
    const stream = canvas.captureStream(30)
    const recorder = new MediaRecorder(stream, { mimeType: 'video/webm;codecs=vp9', videoBitsPerSecond: 16_000_000 })
    chunksRef.current = []
    recorder.ondataavailable = e => { if (e.data.size > 0) chunksRef.current.push(e.data) }
    recorder.onstop = () => {
      const blob = new Blob(chunksRef.current, { type: 'video/webm' })
      setRecordUrl(URL.createObjectURL(blob))
      setIsRecording(false)
    }
    recorder.start()
    recorderRef.current = recorder
    setIsRecording(true)
    setRecordUrl(null)
    setTimeout(() => { if (recorderRef.current?.state === 'recording') recorderRef.current.stop() }, 10000)
  }, [])

  const stopRecord = useCallback(() => {
    if (recorderRef.current?.state === 'recording') recorderRef.current.stop()
  }, [])

  // ── Toggle bone expand ──────────────────────────────────────────
  const toggleExpand = useCallback((key) => {
    setExpanded(e => ({ ...e, [key]: !e[key] }))
  }, [])

  // ── Bone tree renderer ──────────────────────────────────────────
  function BoneNode({ bKey, depth = 0 }) {
    const children = BONE_TREE[bKey] || []
    const hasChildren = children.length > 0
    const isExpanded = expanded[bKey]
    const isSelected = selectedBoneKey === bKey
    return (
      <div>
        <div
          className="flex items-center gap-1 py-0.5 px-2 rounded cursor-pointer select-none text-xs transition-colors"
          style={{
            paddingLeft: `${8 + depth * 12}px`,
            background: isSelected ? 'rgba(124,58,237,0.25)' : 'transparent',
            color: isSelected ? '#c4b5fd' : '#9ca3af',
          }}
          onClick={() => selectBone(bKey)}
        >
          {hasChildren
            ? <button onClick={e => { e.stopPropagation(); toggleExpand(bKey) }} className="w-4 h-4 flex items-center justify-center text-[#6b7280] flex-shrink-0">
                {isExpanded ? <ChevronDown size={10} /> : <ChevronRight size={10} />}
              </button>
            : <span className="w-4 h-4 flex-shrink-0" />
          }
          <span className="w-2 h-2 rounded-full flex-shrink-0"
            style={{ background: isSelected ? '#7C3AED' : '#374151' }} />
          <span className="ml-1 truncate">{BONE_LABELS[bKey]}</span>
        </div>
        {hasChildren && isExpanded && children.map(c => (
          <BoneNode key={c} bKey={c} depth={depth + 1} />
        ))}
      </div>
    )
  }

  const panelBtns = [
    { id: 'anim',      Icon: Layers,   label: 'Anims'  },
    { id: 'materials', Icon: Palette,  label: 'Paint'  },
    { id: 'pose',      Icon: Move3D,   label: 'Pose'   },
    { id: 'env',       Icon: Sun,      label: 'Light'  },
  ]

  return (
    <div className="fixed inset-0 z-50 flex flex-col" style={{ background: '#090b12', fontFamily: 'Inter,sans-serif' }}>

      {/* ── Top bar ─────────────────────────────────────────────── */}
      <div className="flex items-center gap-3 px-4 h-12 border-b flex-shrink-0"
        style={{ background: '#0d0f1a', borderColor: 'rgba(255,255,255,0.08)' }}>
        <button onClick={onClose}
          className="w-7 h-7 rounded-lg flex items-center justify-center text-[#9ca3af] hover:text-white hover:bg-white/10 transition-all">
          <X size={15} />
        </button>
        <div className="w-px h-5 mx-1" style={{ background: 'rgba(255,255,255,0.1)' }} />
        <div className="flex items-center gap-2">
          <div className="w-5 h-5 rounded" style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }} />
          <span className="text-sm font-bold text-white">Character Studio</span>
          <span className="text-[10px] font-black tracking-wider px-1.5 py-px rounded text-white"
            style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }}>PRO</span>
        </div>

        <div className="flex items-center gap-1 ml-4">
          {[
            { title: 'Perspective', icon: Camera },
            { title: 'Wireframe', icon: wireframe ? Eye : EyeOff, action: () => setWireframe(w => !w), active: wireframe },
            { title: 'Grid', icon: Grid3X3, action: () => setShowGrid(g => !g), active: showGrid },
          ].map(({ title, icon: Icon, action, active }) => (
            <button key={title} title={title} onClick={action}
              className="px-2.5 py-1 rounded text-xs flex items-center gap-1 transition-all"
              style={{
                color: active ? '#a78bfa' : '#6b7280',
                background: active ? 'rgba(124,58,237,0.15)' : 'transparent',
              }}>
              <Icon size={13} />
            </button>
          ))}
        </div>

        <div className="ml-auto flex items-center gap-2">
          {recordUrl && (
            <a href={recordUrl} download={`studio-render-${Date.now()}.webm`}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-emerald-300 transition-all"
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
              ? <><span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />Stop (10s)</>
              : <><Video size={12} />Render 4K</>}
          </button>
        </div>
      </div>

      {/* ── Main area ────────────────────────────────────────────── */}
      <div className="flex flex-1 overflow-hidden">

        {/* Left: Bone Hierarchy ─────────────────────────────────── */}
        <div className="w-52 flex-shrink-0 flex flex-col border-r"
          style={{ background: '#0b0d18', borderColor: 'rgba(255,255,255,0.07)' }}>
          <div className="px-3 py-2 border-b flex items-center gap-2"
            style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
            <Layers size={12} className="text-[#7C3AED]" />
            <span className="text-[11px] font-bold text-[#8b8fa8] uppercase tracking-wider">Skeleton</span>
          </div>
          <div className="flex-1 overflow-y-auto py-1 text-xs">
            <BoneNode bKey="root" depth={0} />
          </div>
          {selectedBoneKey && (
            <div className="border-t px-3 py-2" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
              <p className="text-[10px] text-[#7C3AED] font-bold uppercase tracking-wide mb-1">
                {BONE_LABELS[selectedBoneKey]}
              </p>
              <p className="text-[10px] text-[#555872]">Click "Pose" panel to edit rotations</p>
            </div>
          )}
        </div>

        {/* Center: 3D Viewport ──────────────────────────────────── */}
        <div className="flex-1 relative overflow-hidden" ref={mountRef}
          style={{ background: '#0d0f1a' }}>
          {/* Corner overlay */}
          <div className="absolute top-3 left-3 text-[10px] font-bold tracking-widest pointer-events-none"
            style={{ color: 'rgba(255,255,255,0.2)' }}>
            PERSPECTIVE · 4K ENGINE
          </div>
          <div className="absolute bottom-3 left-3 text-[10px] pointer-events-none"
            style={{ color: 'rgba(255,255,255,0.15)' }}>
            RMB drag: orbit · Scroll: zoom · MMB: pan
          </div>
        </div>

        {/* Right: Properties ────────────────────────────────────── */}
        <div className="w-60 flex-shrink-0 flex flex-col border-l"
          style={{ background: '#0b0d18', borderColor: 'rgba(255,255,255,0.07)' }}>
          {/* Panel tabs */}
          <div className="flex border-b" style={{ borderColor: 'rgba(255,255,255,0.06)' }}>
            {panelBtns.map(({ id, Icon, label }) => (
              <button key={id} onClick={() => setActivePanel(id)}
                className="flex-1 flex flex-col items-center gap-0.5 py-2 text-[9px] font-bold uppercase tracking-wide transition-all"
                style={{
                  color: activePanel === id ? '#a78bfa' : '#555872',
                  borderBottom: activePanel === id ? '2px solid #7C3AED' : '2px solid transparent',
                  background: activePanel === id ? 'rgba(124,58,237,0.08)' : 'transparent',
                }}>
                <Icon size={13} />
                {label}
              </button>
            ))}
          </div>

          <div className="flex-1 overflow-y-auto">

            {/* ── ANIMATIONS panel ──────────────────────────────── */}
            {activePanel === 'anim' && (
              <div className="p-3">
                <p className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Animation Presets</p>
                <div className="grid grid-cols-2 gap-1.5">
                  {ANIM_LIST.map(({ id, label, icon }) => (
                    <button key={id} onClick={() => switchAnim(id)}
                      className="flex flex-col items-center gap-1 py-2.5 px-1 rounded-xl text-xs font-semibold transition-all"
                      style={{
                        background: animId === id ? 'rgba(124,58,237,0.22)' : 'rgba(255,255,255,0.04)',
                        border: animId === id ? '1px solid rgba(124,58,237,0.5)' : '1px solid rgba(255,255,255,0.07)',
                        color: animId === id ? '#c4b5fd' : '#9ca3af',
                      }}>
                      <span className="text-xl leading-none">{icon}</span>
                      <span className="text-[11px]">{label}</span>
                    </button>
                  ))}
                </div>

                <p className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider mt-4 mb-2">Playback Speed</p>
                <div className="flex gap-1">
                  {[0.25, 0.5, 1, 1.5, 2].map(spd => (
                    <button key={spd} onClick={() => changeSpeed(spd)}
                      className="flex-1 py-1 rounded text-[10px] font-bold transition-all"
                      style={{
                        background: playSpeed === spd ? 'rgba(124,58,237,0.25)' : 'rgba(255,255,255,0.05)',
                        color: playSpeed === spd ? '#c4b5fd' : '#6b7280',
                        border: playSpeed === spd ? '1px solid rgba(124,58,237,0.4)' : '1px solid transparent',
                      }}>
                      {spd}x
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* ── MATERIALS / PAINT panel ───────────────────────── */}
            {activePanel === 'materials' && (
              <div className="p-3 space-y-4">
                <div>
                  <p className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Skin Color</p>
                  <div className="flex items-center gap-2">
                    <input type="color" value={skinColor} onChange={e => setSkinColor(e.target.value)}
                      className="w-10 h-10 rounded-lg cursor-pointer border-0 bg-transparent" />
                    <div className="flex-1">
                      <div className="text-xs text-white font-mono">{skinColor}</div>
                      <div className="text-[10px] text-[#555872]">Head, neck, arms, hands</div>
                    </div>
                  </div>
                  <div className="flex gap-1 mt-2 flex-wrap">
                    {['#d4956a','#f0c89a','#8b5a3c','#5c3317','#f7d9c4','#c68642','#e8b89b','#a0522d'].map(c => (
                      <button key={c} onClick={() => setSkinColor(c)}
                        className="w-6 h-6 rounded-full border-2 transition-all"
                        style={{ background: c, borderColor: skinColor === c ? '#a78bfa' : 'transparent' }} />
                    ))}
                  </div>
                </div>

                <div>
                  <p className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Cloth Color</p>
                  <div className="flex items-center gap-2">
                    <input type="color" value={clothColor} onChange={e => setClothColor(e.target.value)}
                      className="w-10 h-10 rounded-lg cursor-pointer border-0 bg-transparent" />
                    <div className="flex-1">
                      <div className="text-xs text-white font-mono">{clothColor}</div>
                      <div className="text-[10px] text-[#555872]">Torso, arms, legs</div>
                    </div>
                  </div>
                  <div className="flex gap-1 mt-2 flex-wrap">
                    {['#1e3a5f','#7C3AED','#2563EB','#dc2626','#16a34a','#ea580c','#1f2937','#854d0e'].map(c => (
                      <button key={c} onClick={() => setClothColor(c)}
                        className="w-6 h-6 rounded-full border-2 transition-all"
                        style={{ background: c, borderColor: clothColor === c ? '#a78bfa' : 'transparent' }} />
                    ))}
                  </div>
                </div>

                <div>
                  <p className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Material Presets</p>
                  <div className="grid grid-cols-2 gap-1.5">
                    {[
                      { label: 'Default', skin: '#d4956a', cloth: '#1e3a5f' },
                      { label: 'Hero',    skin: '#f0c89a', cloth: '#7C3AED' },
                      { label: 'Villain', skin: '#8b5a3c', cloth: '#1f2937' },
                      { label: 'Fire',    skin: '#d4956a', cloth: '#dc2626' },
                      { label: 'Nature',  skin: '#c68642', cloth: '#16a34a' },
                      { label: 'Ice',     skin: '#e8b89b', cloth: '#2563EB' },
                    ].map(p => (
                      <button key={p.label}
                        onClick={() => { setSkinColor(p.skin); setClothColor(p.cloth) }}
                        className="flex items-center gap-1.5 px-2 py-1.5 rounded-lg text-[11px] transition-all"
                        style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.08)', color: '#9ca3af' }}>
                        <span className="w-3 h-3 rounded-full flex-shrink-0" style={{ background: p.skin }} />
                        <span className="w-3 h-3 rounded-full flex-shrink-0" style={{ background: p.cloth }} />
                        {p.label}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* ── POSE panel ─────────────────────────────────────── */}
            {activePanel === 'pose' && (
              <div className="p-3">
                {!selectedBoneKey ? (
                  <div className="text-center py-8 text-[#555872] text-xs">
                    <Move3D size={28} className="mx-auto mb-2 opacity-30" />
                    <p>Select a bone in the Skeleton panel to pose it</p>
                  </div>
                ) : (
                  <>
                    <div className="flex items-center justify-between mb-3">
                      <p className="text-xs font-bold text-white">{BONE_LABELS[selectedBoneKey]}</p>
                      <button onClick={resetBone}
                        className="flex items-center gap-1 px-2 py-1 rounded text-[10px] text-[#9ca3af] hover:text-white transition-all"
                        style={{ background: 'rgba(255,255,255,0.06)' }}>
                        <RotateCcw size={10} /> Reset
                      </button>
                    </div>
                    {['x', 'y', 'z'].map(axis => (
                      <div key={axis} className="mb-3">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-[10px] font-bold uppercase"
                            style={{ color: axis === 'x' ? '#ef4444' : axis === 'y' ? '#22c55e' : '#3b82f6' }}>
                            {axis.toUpperCase()} Rotation
                          </span>
                          <span className="text-[10px] text-[#9ca3af] font-mono">{boneRot[axis]}°</span>
                        </div>
                        <input type="range" min="-180" max="180" step="1" value={boneRot[axis]}
                          onChange={e => applyPose(axis, Number(e.target.value))}
                          className="w-full accent-purple-500 h-1.5" />
                      </div>
                    ))}
                    <p className="text-[10px] text-[#555872] mt-4">
                      Tip: Pose edits are additive over the current animation.
                    </p>
                  </>
                )}
              </div>
            )}

            {/* ── ENVIRONMENT / LIGHTING panel ──────────────────── */}
            {activePanel === 'env' && (
              <div className="p-3 space-y-4">
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider">Exposure</span>
                    <span className="text-[10px] text-[#9ca3af] font-mono">{exposure.toFixed(1)}</span>
                  </div>
                  <input type="range" min="0.2" max="3" step="0.1" value={exposure}
                    onChange={e => setExposure(Number(e.target.value))}
                    className="w-full accent-purple-500 h-1.5" />
                </div>
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider">Key Light</span>
                    <span className="text-[10px] text-[#9ca3af] font-mono">{keyLight.toFixed(1)}</span>
                  </div>
                  <input type="range" min="0" max="6" step="0.1" value={keyLight}
                    onChange={e => setKeyLight(Number(e.target.value))}
                    className="w-full accent-yellow-400 h-1.5" />
                </div>
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider">Ambient</span>
                    <span className="text-[10px] text-[#9ca3af] font-mono">{ambientLight.toFixed(1)}</span>
                  </div>
                  <input type="range" min="0" max="2" step="0.05" value={ambientLight}
                    onChange={e => setAmbientLight(Number(e.target.value))}
                    className="w-full accent-blue-400 h-1.5" />
                </div>
                <div>
                  <p className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Background</p>
                  <div className="flex items-center gap-2">
                    <input type="color" value={envBg} onChange={e => {
                      setEnvBg(e.target.value)
                      if (sceneRef.current) sceneRef.current.background = new THREE.Color(e.target.value)
                    }}
                      className="w-10 h-10 rounded-lg cursor-pointer border-0 bg-transparent" />
                    <span className="text-xs text-white font-mono">{envBg}</span>
                  </div>
                  <div className="flex gap-1 mt-2">
                    {['#0d0f1a','#1a0533','#080808','#001a2c','#f0f0f0'].map(c => (
                      <button key={c} onClick={() => {
                        setEnvBg(c)
                        if (sceneRef.current) sceneRef.current.background = new THREE.Color(c)
                      }}
                        className="w-8 h-6 rounded border-2 transition-all"
                        style={{ background: c, borderColor: envBg === c ? '#a78bfa' : 'rgba(255,255,255,0.1)' }} />
                    ))}
                  </div>
                </div>
                <div>
                  <p className="text-[10px] font-bold text-[#8b8fa8] uppercase tracking-wider mb-2">Camera Presets</p>
                  <div className="grid grid-cols-2 gap-1.5">
                    {[
                      { label: 'Front', fn: () => { cameraRef.current.position.set(0,1.4,3.5); controlsRef.current.target.set(0,1.1,0) }},
                      { label: 'Side',  fn: () => { cameraRef.current.position.set(3.5,1.4,0); controlsRef.current.target.set(0,1.1,0) }},
                      { label: 'Top',   fn: () => { cameraRef.current.position.set(0,5,0.01); controlsRef.current.target.set(0,1.1,0) }},
                      { label: 'Close', fn: () => { cameraRef.current.position.set(0,1.7,1.5); controlsRef.current.target.set(0,1.5,0) }},
                    ].map(({ label, fn }) => (
                      <button key={label} onClick={fn}
                        className="px-2 py-1.5 rounded-lg text-[11px] transition-all text-[#9ca3af] hover:text-white"
                        style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.08)' }}>
                        {label}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ── Bottom: Playback + Timeline ──────────────────────────── */}
      <div className="flex-shrink-0 border-t"
        style={{ background: '#0d0f1a', borderColor: 'rgba(255,255,255,0.07)' }}>
        {/* Playback controls */}
        <div className="flex items-center gap-3 px-4 py-2 border-b"
          style={{ borderColor: 'rgba(255,255,255,0.05)' }}>
          <button onClick={resetAnim}
            className="w-7 h-7 rounded-lg flex items-center justify-center text-[#6b7280] hover:text-white transition-all hover:bg-white/5">
            <SkipBack size={14} />
          </button>
          <button onClick={togglePlay}
            className="w-8 h-8 rounded-xl flex items-center justify-center text-white transition-all"
            style={{ background: 'linear-gradient(135deg,#7C3AED,#2563EB)' }}>
            {isPlaying ? <Pause size={14} /> : <Play size={14} />}
          </button>
          <span className="text-xs text-[#555872] font-mono ml-1">{animId.toUpperCase()}</span>
          <span className="text-xs text-[#374151] font-mono">·</span>
          <span className="text-xs text-[#9ca3af] font-mono">{playSpeed}x</span>
          <div className="ml-auto flex items-center gap-2">
            <Sliders size={12} className="text-[#6b7280]" />
            <span className="text-[10px] text-[#555872]">{Math.round(timeNorm * 100)}%</span>
          </div>
        </div>

        {/* Timeline */}
        <Timeline
          timeNorm={timeNorm}
          clip={CLIPS[animId]}
          onScrub={scrubTimeline}
        />
      </div>
    </div>
  )
}
