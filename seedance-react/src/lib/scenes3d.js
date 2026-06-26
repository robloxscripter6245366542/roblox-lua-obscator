import * as THREE from 'three'

// ── Shared helpers ────────────────────────────────────────────────
function hex(h) { return new THREE.Color(h) }
function rnd(a, b) { return a + Math.random() * (b - a) }

function addStarfield(scene, count = 3000) {
  const pos = new Float32Array(count * 3)
  for (let i = 0; i < count; i++) {
    pos[i * 3]     = rnd(-200, 200)
    pos[i * 3 + 1] = rnd(-200, 200)
    pos[i * 3 + 2] = rnd(-200, 200)
  }
  const geo = new THREE.BufferGeometry()
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3))
  scene.add(new THREE.Points(geo, new THREE.PointsMaterial({ color: 0xffffff, size: 0.3, sizeAttenuation: true })))
}

// ── Scene builders ────────────────────────────────────────────────

function buildGalaxy(scene, palette) {
  const count = 20000
  const pos = new Float32Array(count * 3)
  const col = new Float32Array(count * 3)
  const c1 = hex(palette[0]), c2 = hex(palette[1])
  const arms = 3
  for (let i = 0; i < count; i++) {
    const r = Math.pow(Math.random(), 1.4) * 12 + 0.5
    const branch = (i % arms) / arms * Math.PI * 2
    const spin = r * 1.8
    const spread = (Math.random() - 0.5) * Math.exp(-r * 0.1) * 3
    pos[i * 3]     = Math.cos(branch + spin) * r + spread
    pos[i * 3 + 1] = (Math.random() - 0.5) * 0.6 + spread * 0.2
    pos[i * 3 + 2] = Math.sin(branch + spin) * r + spread
    const mix = r / 12
    const c = c1.clone().lerp(c2, mix)
    col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b
  }
  const geo = new THREE.BufferGeometry()
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3))
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3))
  scene.add(new THREE.Points(geo, new THREE.PointsMaterial({
    size: 0.04, sizeAttenuation: true, vertexColors: true,
    blending: THREE.AdditiveBlending, depthWrite: false,
  })))
  addStarfield(scene, 1000)
}

function buildNeonCity(scene, palette) {
  const grid = new THREE.GridHelper(80, 40, hex(palette[0]), hex(palette[0]))
  grid.position.y = -3
  scene.add(grid)

  const buildingMat = new THREE.MeshStandardMaterial({ color: 0x0a0a1a, metalness: 0.9, roughness: 0.1, emissive: hex(palette[1]), emissiveIntensity: 0.05 })
  for (let i = 0; i < 60; i++) {
    const h = rnd(2, 14)
    const geo = new THREE.BoxGeometry(rnd(0.8, 2.2), h, rnd(0.8, 2.2))
    const mesh = new THREE.Mesh(geo, buildingMat.clone())
    mesh.position.set(rnd(-20, 20), h / 2 - 3, rnd(-20, 20))
    scene.add(mesh)
    // Window glow strips
    const lineGeo = new THREE.BoxGeometry(rnd(0.8, 2.2) + 0.05, 0.05, rnd(0.8, 2.2) + 0.05)
    const lineMat = new THREE.MeshBasicMaterial({ color: hex(palette[i % 3]), transparent: true, opacity: 0.9 })
    for (let w = 0; w < Math.floor(h / 1.5); w++) {
      const line = new THREE.Mesh(lineGeo, lineMat)
      line.position.set(mesh.position.x, -3 + w * 1.5 + 0.5, mesh.position.z)
      scene.add(line)
    }
  }
  scene.add(new THREE.AmbientLight(0x050510, 1))
  const spot = new THREE.PointLight(hex(palette[0]), 3, 30)
  spot.position.set(0, 5, 0)
  scene.add(spot)
}

function buildAbstract(scene, palette) {
  const group = new THREE.Group()
  const shapes = [
    new THREE.TorusKnotGeometry(3, 0.8, 200, 16),
    new THREE.IcosahedronGeometry(2.5, 2),
    new THREE.OctahedronGeometry(3, 0),
  ]
  shapes.forEach((geo, i) => {
    const mat = new THREE.MeshStandardMaterial({
      color: hex(palette[i % palette.length]),
      metalness: 0.95, roughness: 0.05,
      emissive: hex(palette[i % palette.length]), emissiveIntensity: 0.3,
      wireframe: i === 2,
    })
    const mesh = new THREE.Mesh(geo, mat)
    mesh.visible = i === 0
    mesh.userData.shapeIndex = i
    group.add(mesh)
  })
  group.userData.shapes = shapes
  scene.add(group)
  scene.add(new THREE.AmbientLight(0xffffff, 0.3))
  const lights = palette.map((c, i) => {
    const l = new THREE.PointLight(hex(c), 4, 20)
    l.position.set(Math.cos(i / palette.length * Math.PI * 2) * 8, Math.sin(i * 1.1) * 4, Math.sin(i / palette.length * Math.PI * 2) * 8)
    scene.add(l)
    return l
  })
  scene.userData.lights = lights
  scene.userData.group = group
}

function buildCrystal(scene, palette) {
  const group = new THREE.Group()
  for (let i = 0; i < 18; i++) {
    const h = rnd(1.5, 5)
    const geo = new THREE.ConeGeometry(rnd(0.3, 0.8), h, 6)
    const mat = new THREE.MeshPhysicalMaterial({
      color: hex(palette[i % palette.length]),
      metalness: 0.1, roughness: 0.0, transmission: 0.8,
      thickness: 1.5, emissive: hex(palette[i % palette.length]), emissiveIntensity: 0.2,
    })
    const mesh = new THREE.Mesh(geo, mat)
    const angle = (i / 18) * Math.PI * 2
    const r = rnd(2, 6)
    mesh.position.set(Math.cos(angle) * r, -h / 2 + rnd(-0.5, 1), Math.sin(angle) * r)
    mesh.rotation.z = rnd(-0.3, 0.3)
    mesh.rotation.x = rnd(-0.2, 0.2)
    group.add(mesh)
  }
  scene.add(group)
  scene.userData.group = group
  scene.add(new THREE.AmbientLight(0xffffff, 0.5))
  palette.forEach((c, i) => {
    const l = new THREE.PointLight(hex(c), 5, 15)
    l.position.set(Math.cos(i * 2.1) * 5, 3, Math.sin(i * 2.1) * 5)
    scene.add(l)
  })
}

function buildNebula(scene, palette) {
  addStarfield(scene, 4000)
  for (let i = 0; i < 8; i++) {
    const geo = new THREE.SphereGeometry(rnd(3, 8), 16, 16)
    const mat = new THREE.MeshBasicMaterial({
      color: hex(palette[i % palette.length]),
      transparent: true, opacity: rnd(0.04, 0.12),
      blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.BackSide,
    })
    const mesh = new THREE.Mesh(geo, mat)
    mesh.position.set(rnd(-10, 10), rnd(-5, 5), rnd(-10, 10))
    scene.add(mesh)
  }
  // Dense particle cloud
  const count = 12000
  const pos = new Float32Array(count * 3)
  const col = new Float32Array(count * 3)
  for (let i = 0; i < count; i++) {
    const r = rnd(0, 15)
    const theta = Math.random() * Math.PI * 2
    const phi = Math.acos(2 * Math.random() - 1)
    pos[i * 3]     = r * Math.sin(phi) * Math.cos(theta)
    pos[i * 3 + 1] = r * Math.sin(phi) * Math.sin(theta)
    pos[i * 3 + 2] = r * Math.cos(phi)
    const c = hex(palette[i % palette.length])
    col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b
  }
  const geo2 = new THREE.BufferGeometry()
  geo2.setAttribute('position', new THREE.BufferAttribute(pos, 3))
  geo2.setAttribute('color', new THREE.BufferAttribute(col, 3))
  scene.add(new THREE.Points(geo2, new THREE.PointsMaterial({
    size: 0.06, vertexColors: true, blending: THREE.AdditiveBlending, depthWrite: false, sizeAttenuation: true,
  })))
}

function buildSpace(scene, palette) {
  addStarfield(scene, 5000)
  const planet = new THREE.Mesh(
    new THREE.SphereGeometry(4, 64, 64),
    new THREE.MeshPhongMaterial({ color: hex(palette[0]), emissive: hex(palette[1]), emissiveIntensity: 0.15, shininess: 80 })
  )
  planet.position.set(3, 0, -5)
  scene.add(planet)
  // Rings
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(5.5, 8, 64),
    new THREE.MeshBasicMaterial({ color: hex(palette[2] || palette[0]), side: THREE.DoubleSide, transparent: true, opacity: 0.4 })
  )
  ring.rotation.x = Math.PI / 2.5
  ring.position.copy(planet.position)
  scene.add(ring)
  const sun = new THREE.PointLight(0xffffff, 3, 100)
  sun.position.set(-15, 8, 10)
  scene.add(sun)
  scene.add(new THREE.AmbientLight(hex(palette[1]), 0.15))
  scene.userData.planet = planet
  scene.userData.ring = ring
}

function buildTerrain(scene, palette) {
  const size = 60, segs = 80
  const geo = new THREE.PlaneGeometry(size, size, segs, segs)
  const pos = geo.attributes.position
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), z = pos.getY(i)
    const y = Math.sin(x * 0.15) * 3 + Math.cos(z * 0.12) * 2.5
           + Math.sin(x * 0.4 + z * 0.3) * 1.2 + (Math.random() - 0.5) * 0.4
    pos.setZ(i, y)
  }
  geo.computeVertexNormals()
  const mat = new THREE.MeshStandardMaterial({
    color: hex(palette[1]), roughness: 0.85, metalness: 0.0,
    wireframe: false,
  })
  const terrain = new THREE.Mesh(geo, mat)
  terrain.rotation.x = -Math.PI / 2
  terrain.position.y = -2
  scene.add(terrain)
  const fog = new THREE.FogExp2(hex(palette[0]), 0.03)
  scene.fog = fog
  scene.background = hex(palette[0])
  const sun = new THREE.DirectionalLight(0xfff5e0, 2)
  sun.position.set(10, 20, 10)
  scene.add(sun)
  scene.add(new THREE.AmbientLight(hex(palette[2] || '#4499ff'), 0.6))
}

function buildOcean(scene, palette) {
  const geo = new THREE.PlaneGeometry(60, 60, 80, 80)
  const mat = new THREE.MeshPhongMaterial({
    color: hex(palette[0]), emissive: hex(palette[1]), emissiveIntensity: 0.1,
    shininess: 120, transparent: true, opacity: 0.92, side: THREE.DoubleSide,
  })
  const ocean = new THREE.Mesh(geo, mat)
  ocean.rotation.x = -Math.PI / 2
  ocean.position.y = -1
  scene.add(ocean)
  scene.userData.ocean = ocean
  scene.userData.oceanGeo = geo
  scene.add(new THREE.AmbientLight(0x88ccff, 0.4))
  const sun = new THREE.DirectionalLight(0xffffff, 2)
  sun.position.set(15, 20, 10)
  scene.add(sun)
  scene.fog = new THREE.FogExp2(hex(palette[2] || '#001133'), 0.02)
  scene.background = hex(palette[2] || '#001133')
}

// ── Scene type map ─────────────────────────────────────────────────
const BUILDERS = {
  galaxy: buildGalaxy, neon_city: buildNeonCity, abstract: buildAbstract,
  crystal: buildCrystal, nebula: buildNebula, space: buildSpace,
  terrain: buildTerrain, ocean: buildOcean,
}

// ── Main animator ──────────────────────────────────────────────────
export function createSceneRenderer(canvas, w, h) {
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true })
  renderer.setSize(w, h)
  renderer.setPixelRatio(1)
  renderer.outputColorSpace = THREE.SRGBColorSpace

  const camera = new THREE.PerspectiveCamera(60, w / h, 0.1, 1000)
  camera.position.set(0, 3, 16)

  return { renderer, camera }
}

export function buildScene(type, palette) {
  const scene = new THREE.Scene()
  ;(BUILDERS[type] || buildAbstract)(scene, palette)
  return scene
}

export function animateScene(renderer, scene, camera, type, plan, elapsed) {
  const { speed = 1, camera: camMode = 'orbit', intensity = 0.8 } = plan
  const t = elapsed * speed

  // Camera motion
  if (camMode === 'orbit') {
    camera.position.x = Math.sin(t * 0.3) * 14
    camera.position.z = Math.cos(t * 0.3) * 14
    camera.position.y = 3 + Math.sin(t * 0.15) * 2
    camera.lookAt(0, 0, 0)
  } else if (camMode === 'zoom_in') {
    camera.position.z = Math.max(4, 18 - t * 2.5)
    camera.lookAt(0, 0, 0)
  } else if (camMode === 'fly_through') {
    camera.position.set(Math.sin(t * 0.4) * 8, Math.cos(t * 0.25) * 4, 10 - t * 1.5)
    camera.lookAt(0, 0, 0)
  } else if (camMode === 'pan_left') {
    camera.position.x = -t * 2 + 8
    camera.position.y = 3
    camera.position.z = 14
    camera.lookAt(0, 0, 0)
  } else if (camMode === 'rise') {
    camera.position.y = 3 + t * 1.5
    camera.position.z = 16 - t * 0.5
    camera.lookAt(0, 0, 0)
  }

  // Scene-specific animations
  if (type === 'galaxy' || type === 'nebula') {
    scene.rotation.y = t * 0.08
  }
  if (type === 'abstract') {
    const g = scene.userData.group
    if (g) { g.rotation.y = t * 0.6; g.rotation.x = t * 0.3; g.rotation.z = t * 0.15 }
    scene.userData.lights?.forEach((l, i) => {
      l.position.x = Math.cos(t * 0.5 + i * 2.1) * 8
      l.position.z = Math.sin(t * 0.5 + i * 2.1) * 8
    })
    // Cycle shapes
    if (g) {
      const si = Math.floor(t * 0.3) % g.children.length
      g.children.forEach((c, i) => { c.visible = i === si })
    }
  }
  if (type === 'crystal') {
    const g = scene.userData.group
    if (g) { g.rotation.y = t * 0.25; g.rotation.x = Math.sin(t * 0.15) * 0.1 }
  }
  if (type === 'space') {
    if (scene.userData.planet) scene.userData.planet.rotation.y = t * 0.15
    if (scene.userData.ring) scene.userData.ring.rotation.z = t * 0.05
  }
  if (type === 'ocean') {
    const geo = scene.userData.oceanGeo
    if (geo) {
      const pos = geo.attributes.position
      for (let i = 0; i < pos.count; i++) {
        const x = pos.getX(i), z = pos.getY(i)
        pos.setZ(i, Math.sin(x * 0.3 + t * 1.5) * 0.4 + Math.cos(z * 0.4 + t * 1.2) * 0.3)
      }
      pos.needsUpdate = true
      geo.computeVertexNormals()
    }
  }

  renderer.render(scene, camera)
}
