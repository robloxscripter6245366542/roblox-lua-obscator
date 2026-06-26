import * as THREE from 'three'

const PI = Math.PI
const HALF_PI = PI / 2

// ── Materials ─────────────────────────────────────────────────────────────────
export function makeMaterials(skinColor = '#e8b896', clothColor = '#1a2f50') {
  const skinC = new THREE.Color(skinColor)
  const skin = new THREE.MeshPhysicalMaterial({
    color: skinColor, roughness: 0.62, metalness: 0.0,
    clearcoat: 0.18, clearcoatRoughness: 0.38,
    emissive: skinC.clone().multiplyScalar(0.12), emissiveIntensity: 0.8,
  })
  const cloth = new THREE.MeshPhysicalMaterial({
    color: clothColor, roughness: 0.58, metalness: 0.04,
    sheen: 0.7, sheenRoughness: 0.48,
    sheenColor: new THREE.Color(clothColor).lerp(new THREE.Color('#ffffff'), 0.28),
  })
  const dark = new THREE.MeshStandardMaterial({ color: '#0a0600', roughness: 0.92 })
  const hair = new THREE.MeshPhysicalMaterial({
    color: '#120800', roughness: 0.5, metalness: 0.0,
    clearcoat: 0.35, clearcoatRoughness: 0.28,
  })
  const eye = new THREE.MeshPhysicalMaterial({
    color: '#f4f8ff', roughness: 0.02, metalness: 0.0,
    clearcoat: 1.0, clearcoatRoughness: 0.0,
    emissive: '#d0e8ff', emissiveIntensity: 0.15,
  })
  const iris = new THREE.MeshPhysicalMaterial({
    color: '#3a7ae8', roughness: 0.04, metalness: 0.0,
    clearcoat: 1.0, clearcoatRoughness: 0.0,
    emissive: '#1a40a0', emissiveIntensity: 0.2,
  })
  const pupil = new THREE.MeshStandardMaterial({ color: '#010104', roughness: 0.08 })
  const eyeHL = new THREE.MeshBasicMaterial({ color: '#ffffff' })
  const shoe = new THREE.MeshPhysicalMaterial({
    color: '#080a0c', roughness: 0.3, metalness: 0.35,
    clearcoat: 0.5, clearcoatRoughness: 0.25,
  })
  const shoeSole = new THREE.MeshPhysicalMaterial({ color: '#f0f0ec', roughness: 0.75, metalness: 0.0 })
  const accent = new THREE.MeshPhysicalMaterial({ color: '#cc2222', roughness: 0.55, metalness: 0.1 })
  const white = new THREE.MeshPhysicalMaterial({ color: '#e8eaf0', roughness: 0.65, metalness: 0.0 })
  const lip = new THREE.MeshPhysicalMaterial({
    color: new THREE.Color(skinColor).lerp(new THREE.Color('#c06060'), 0.4),
    roughness: 0.5, metalness: 0.0, clearcoat: 0.2,
  })
  return { skin, cloth, dark, hair, eye, iris, pupil, eyeHL, shoe, shoeSole, accent, white, lip }
}

function mesh(geo, mat) {
  const m = new THREE.Mesh(geo, mat)
  m.castShadow = true; m.receiveShadow = true
  return m
}

function attach(bone, geo, mat2, px = 0, py = 0, pz = 0, rx = 0, ry = 0, rz = 0, sx = 1, sy = 1, sz = 1) {
  const m = mesh(geo, mat2)
  m.position.set(px, py, pz)
  m.rotation.set(rx, ry, rz)
  m.scale.set(sx, sy, sz)
  bone.add(m); return m
}

// ── Fingers ──────────────────────────────────────────────────────────────────
function addFingers(bone, skinMat, dir) {
  const d = dir
  attach(bone, new THREE.BoxGeometry(0.11, 0.022, 0.10), skinMat, 0.088 * d, 0, 0.003)
  const zOff = [0.038, 0.013, -0.013, -0.038]
  zOff.forEach((z, i) => {
    const len = i === 3 ? 0.044 : i === 0 ? 0.060 : 0.054
    attach(bone, new THREE.CylinderGeometry(0.011, 0.010, len, 7), skinMat, 0.118 * d, 0, z, 0, 0, HALF_PI)
    attach(bone, new THREE.CylinderGeometry(0.010, 0.008, len * 0.7, 7), skinMat, (0.118 + len * 0.5 + len * 0.35) * d, 0, z, 0, 0, HALF_PI)
    attach(bone, new THREE.SphereGeometry(0.008, 6, 5), skinMat, (0.118 + len * 0.5 + len * 0.7 + 0.012) * d, 0, z)
  })
  const tx = 0.080 * d, ty = -0.026, tz = 0.060
  attach(bone, new THREE.CylinderGeometry(0.013, 0.011, 0.048, 7), skinMat, tx, ty, tz, HALF_PI * 0.4, 0, HALF_PI)
  attach(bone, new THREE.SphereGeometry(0.011, 6, 5), skinMat, tx, ty - 0.025, tz + 0.030)
}

// ── Face builder ──────────────────────────────────────────────────────────────
function buildFace(headBone, mat) {
  const hz = 0.165 // forward offset from head bone to face surface

  // Eyes – bigger, more expressive
  ;[-1, 1].forEach(side => {
    const ex = 0.073 * side, ey = 0.20, ez = hz - 0.01
    // Sclera (white of eye)
    attach(headBone, new THREE.SphereGeometry(0.050, 18, 14), mat.eye, ex, ey, ez + 0.006)
    // Iris
    attach(headBone, new THREE.CylinderGeometry(0.032, 0.032, 0.007, 20), mat.iris, ex, ey, ez + 0.046, HALF_PI, 0, 0)
    // Pupil
    attach(headBone, new THREE.CylinderGeometry(0.019, 0.019, 0.008, 14), mat.pupil, ex, ey, ez + 0.050, HALF_PI, 0, 0)
    // Specular highlight
    attach(headBone, new THREE.SphereGeometry(0.008, 6, 5), mat.eyeHL, ex + 0.010 * side, ey + 0.010, ez + 0.052)
    // Eyelash line (thin dark crescent above eye)
    attach(headBone, new THREE.BoxGeometry(0.082, 0.010, 0.007), mat.dark, ex, ey + 0.038, ez + 0.022)
  })

  // Eyebrows – thick, personality
  ;[-1, 1].forEach(side => {
    attach(headBone, new THREE.BoxGeometry(0.078, 0.020, 0.012), mat.dark,
      0.074 * side, 0.285, hz, 0, 0, -0.12 * side)
  })

  // Nose
  attach(headBone, new THREE.CylinderGeometry(0.012, 0.020, 0.058, 10), mat.skin, 0, 0.135, hz - 0.01)
  attach(headBone, new THREE.SphereGeometry(0.024, 12, 10), mat.skin, 0, 0.105, hz + 0.012, 0, 0, 0, 1.25, 0.82, 1.0)
  ;[-1, 1].forEach(side => {
    attach(headBone, new THREE.SphereGeometry(0.014, 8, 7), mat.skin, 0.025 * side, 0.098, hz + 0.005, 0, 0, 0, 0.6, 0.5, 0.4)
  })

  // Lips
  // Philtrum dip (upper lip bow)
  attach(headBone, new THREE.SphereGeometry(0.038, 12, 8), mat.lip, 0, 0.060, hz + 0.005, 0, 0, 0, 1.15, 0.45, 0.55)
  // Lower lip (fuller)
  attach(headBone, new THREE.SphereGeometry(0.044, 12, 8), mat.lip, 0, 0.030, hz + 0.010, 0, 0, 0, 1.2, 0.55, 0.65)
  // Mouth line
  attach(headBone, new THREE.BoxGeometry(0.068, 0.007, 0.005), mat.dark, 0, 0.048, hz + 0.016)

  // Chin dimple hint
  attach(headBone, new THREE.SphereGeometry(0.055, 10, 8), mat.skin, 0, -0.018, hz - 0.005, 0, 0, 0, 0.7, 0.4, 0.5)

  // Ears
  ;[-1, 1].forEach(side => {
    const ex = 0.165 * side
    attach(headBone, new THREE.SphereGeometry(0.042, 12, 10), mat.skin, ex, 0.155, 0.01, 0, 0, 0, 0.38, 1.08, 0.28)
    // Ear canal
    attach(headBone, new THREE.SphereGeometry(0.012, 8, 6), mat.dark, ex + 0.003 * side, 0.155, 0.008, 0, 0, 0, 0.3, 0.6, 0.3)
  })
}

// ── Hair builder ──────────────────────────────────────────────────────────────
function buildHair(headBone, mat) {
  // Main cap – full coverage
  attach(headBone, new THREE.SphereGeometry(0.175, 26, 20, 0, PI * 2, 0, PI * 0.62), mat.hair, 0, 0.195, 0, 0, 0, 0, 1.02, 1.0, 1.0)
  // Back neck hair
  attach(headBone, new THREE.SphereGeometry(0.16, 16, 12, 0, PI * 2, PI * 0.55, PI * 0.25), mat.hair, 0, 0.175, -0.03)
  // Fringe / bangs
  attach(headBone, new THREE.BoxGeometry(0.28, 0.028, 0.06), mat.hair, 0, 0.318, 0.138)
  attach(headBone, new THREE.SphereGeometry(0.10, 14, 10), mat.hair, -0.055, 0.30, 0.145, 0, 0, 0, 1.0, 0.35, 0.7)
  attach(headBone, new THREE.SphereGeometry(0.10, 14, 10), mat.hair,  0.055, 0.30, 0.145, 0, 0, 0, 1.0, 0.35, 0.7)
  // Side hair coverage
  ;[-1, 1].forEach(side => {
    attach(headBone, new THREE.SphereGeometry(0.105, 14, 10), mat.hair, 0.16 * side, 0.22, -0.02, 0, 0, 0, 0.48, 0.75, 0.55)
  })
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
function makeBone(name) { const b = new THREE.Bone(); b.name = name; return b }

export function buildSkeleton() {
  const b = {}
  b.root  = makeBone('Root')
  b.hips  = makeBone('Hips');  b.hips.position.set(0, 1.02, 0)
  b.spine = makeBone('Spine'); b.spine.position.set(0, 0.16, 0)
  b.chest = makeBone('Chest'); b.chest.position.set(0, 0.28, 0)
  b.neck  = makeBone('Neck');  b.neck.position.set(0, 0.30, 0)
  b.head  = makeBone('Head');  b.head.position.set(0, 0.13, 0)

  b.lShoulder = makeBone('L_Shoulder'); b.lShoulder.position.set(-0.22, 0.26, 0)
  b.lUpperArm = makeBone('L_UpperArm'); b.lUpperArm.position.set(-0.20, 0, 0)
  b.lForeArm  = makeBone('L_ForeArm');  b.lForeArm.position.set(-0.26, 0, 0)
  b.lHand     = makeBone('L_Hand');     b.lHand.position.set(-0.24, 0, 0)

  b.rShoulder = makeBone('R_Shoulder'); b.rShoulder.position.set(0.22, 0.26, 0)
  b.rUpperArm = makeBone('R_UpperArm'); b.rUpperArm.position.set(0.20, 0, 0)
  b.rForeArm  = makeBone('R_ForeArm');  b.rForeArm.position.set(0.26, 0, 0)
  b.rHand     = makeBone('R_Hand');     b.rHand.position.set(0.24, 0, 0)

  b.lThigh = makeBone('L_Thigh'); b.lThigh.position.set(-0.14, -0.04, 0)
  b.lShin  = makeBone('L_Shin');  b.lShin.position.set(0, -0.44, 0)
  b.lFoot  = makeBone('L_Foot');  b.lFoot.position.set(0, -0.40, 0)

  b.rThigh = makeBone('R_Thigh'); b.rThigh.position.set(0.14, -0.04, 0)
  b.rShin  = makeBone('R_Shin');  b.rShin.position.set(0, -0.44, 0)
  b.rFoot  = makeBone('R_Foot');  b.rFoot.position.set(0, -0.40, 0)

  b.root.add(b.hips)
  b.hips.add(b.spine); b.spine.add(b.chest)
  b.chest.add(b.neck); b.neck.add(b.head)
  b.chest.add(b.lShoulder); b.lShoulder.add(b.lUpperArm); b.lUpperArm.add(b.lForeArm); b.lForeArm.add(b.lHand)
  b.chest.add(b.rShoulder); b.rShoulder.add(b.rUpperArm); b.rUpperArm.add(b.rForeArm); b.rForeArm.add(b.rHand)
  b.hips.add(b.lThigh); b.lThigh.add(b.lShin); b.lShin.add(b.lFoot)
  b.hips.add(b.rThigh); b.rThigh.add(b.rShin); b.rShin.add(b.rFoot)
  return b
}

// ── Full character ─────────────────────────────────────────────────────────────
export function buildCharacter(skinColor, clothColor) {
  const mat = makeMaterials(skinColor, clothColor)
  const root = new THREE.Group(); root.name = 'CharacterRoot'
  const bones = buildSkeleton()
  root.add(bones.root)

  // ── HEAD ──────────────────────────────────────────────
  // Skull – slightly oval
  attach(bones.head, new THREE.SphereGeometry(0.165, 32, 26), mat.skin, 0, 0.185, 0, 0, 0, 0, 0.96, 1.02, 0.94)
  buildFace(bones.head, mat)
  buildHair(bones.head, mat)

  // ── NECK ──────────────────────────────────────────────
  attach(bones.neck, new THREE.CylinderGeometry(0.076, 0.092, 0.13, 16), mat.skin, 0, 0.065, 0)

  // ── TORSO – organic LatheGeometry ─────────────────────
  // Shirt body using LatheGeometry (profile from bottom to top)
  const torsoPoints = [
    new THREE.Vector2(0.19, 0.00),  // lower hip
    new THREE.Vector2(0.21, 0.08),  // hip flare
    new THREE.Vector2(0.19, 0.18),  // waist (narrowest)
    new THREE.Vector2(0.22, 0.28),  // lower chest
    new THREE.Vector2(0.27, 0.38),  // chest (widest)
    new THREE.Vector2(0.25, 0.46),  // upper chest
    new THREE.Vector2(0.20, 0.50),  // shoulder base
  ]
  const torsoGeo = new THREE.LatheGeometry(torsoPoints, 28)
  const torsoMesh = mesh(torsoGeo, mat.cloth)
  torsoMesh.position.set(0, -0.02, 0)
  bones.hips.add(torsoMesh)

  // Collar/neckline
  attach(bones.chest, new THREE.CylinderGeometry(0.092, 0.098, 0.045, 18), mat.cloth, 0, 0.275, 0)
  // Belt
  attach(bones.hips, new THREE.CylinderGeometry(0.202, 0.202, 0.028, 28), mat.dark, 0, 0.078, 0)
  // Belt buckle (front center)
  attach(bones.hips, new THREE.BoxGeometry(0.038, 0.026, 0.012), mat.accent, 0, 0.078, 0.198)

  // Shoulder pads (rounded)
  ;[-1, 1].forEach(side => {
    const bone = side < 0 ? bones.lShoulder : bones.rShoulder
    attach(bone, new THREE.SphereGeometry(0.118, 16, 12), mat.cloth, 0.092 * side, 0.015, 0)
  })

  // ── ARMS ─────────────────────────────────────────────
  // Upper arm (slightly tapered)
  attach(bones.lUpperArm, new THREE.CylinderGeometry(0.080, 0.068, 0.28, 14), mat.cloth, -0.14, 0, 0, 0, 0, HALF_PI)
  attach(bones.rUpperArm, new THREE.CylinderGeometry(0.080, 0.068, 0.28, 14), mat.cloth,  0.14, 0, 0, 0, 0, HALF_PI)
  // Elbow joints
  attach(bones.lForeArm, new THREE.SphereGeometry(0.060, 12, 10), mat.cloth, 0, 0, 0)
  attach(bones.rForeArm, new THREE.SphereGeometry(0.060, 12, 10), mat.cloth, 0, 0, 0)
  // Forearms (skin showing)
  attach(bones.lForeArm, new THREE.CylinderGeometry(0.062, 0.050, 0.25, 14), mat.skin, -0.125, 0, 0, 0, 0, HALF_PI)
  attach(bones.rForeArm, new THREE.CylinderGeometry(0.062, 0.050, 0.25, 14), mat.skin,  0.125, 0, 0, 0, 0, HALF_PI)
  // Shirt sleeve cuffs
  attach(bones.lForeArm, new THREE.CylinderGeometry(0.064, 0.064, 0.025, 14), mat.cloth, -0.004, 0, 0, 0, 0, HALF_PI)
  attach(bones.rForeArm, new THREE.CylinderGeometry(0.064, 0.064, 0.025, 14), mat.cloth,  0.004, 0, 0, 0, 0, HALF_PI)
  // Wrists
  attach(bones.lHand, new THREE.SphereGeometry(0.048, 12, 10), mat.skin, 0, 0, 0)
  attach(bones.rHand, new THREE.SphereGeometry(0.048, 12, 10), mat.skin, 0, 0, 0)
  addFingers(bones.lHand, mat.skin, 1)
  addFingers(bones.rHand, mat.skin, -1)

  // ── LEGS ──────────────────────────────────────────────
  // Thighs
  const thighPts = [
    new THREE.Vector2(0.120, 0.00),
    new THREE.Vector2(0.115, 0.12),
    new THREE.Vector2(0.108, 0.24),
    new THREE.Vector2(0.100, 0.40),
    new THREE.Vector2(0.092, 0.46),
  ]
  ;[bones.lThigh, bones.rThigh].forEach(bone => {
    const thighGeo = new THREE.LatheGeometry(thighPts, 18)
    const t = mesh(thighGeo, mat.cloth)
    t.position.set(0, -0.01, 0); t.rotation.x = PI
    bone.add(t)
  })
  // Knee caps
  attach(bones.lShin, new THREE.SphereGeometry(0.082, 14, 12), mat.cloth, 0, 0.01, 0)
  attach(bones.rShin, new THREE.SphereGeometry(0.082, 14, 12), mat.cloth, 0, 0.01, 0)
  // Shins (tapered)
  attach(bones.lShin, new THREE.CylinderGeometry(0.080, 0.060, 0.40, 14), mat.cloth, 0, -0.21, 0)
  attach(bones.rShin, new THREE.CylinderGeometry(0.080, 0.060, 0.40, 14), mat.cloth, 0, -0.21, 0)
  // Pant cuffs at ankle
  attach(bones.lShin, new THREE.CylinderGeometry(0.063, 0.063, 0.022, 14), mat.cloth, 0, -0.41, 0)
  attach(bones.rShin, new THREE.CylinderGeometry(0.063, 0.063, 0.022, 14), mat.cloth, 0, -0.41, 0)

  // ── SHOES (sneaker style) ─────────────────────────────
  ;[bones.lFoot, bones.rFoot].forEach(bone => {
    // Ankle sphere
    attach(bone, new THREE.SphereGeometry(0.062, 12, 10), mat.shoe, 0, 0.01, 0)
    // Shoe upper
    attach(bone, new THREE.BoxGeometry(0.115, 0.065, 0.215), mat.shoe, 0, -0.028, 0.045, 0, 0, 0, 1, 1, 1)
    // Sole (white, slightly wider)
    attach(bone, new THREE.BoxGeometry(0.125, 0.022, 0.228), mat.shoeSole, 0, -0.068, 0.045)
    // Toe cap (rounded)
    attach(bone, new THREE.SphereGeometry(0.062, 12, 9), mat.shoe, 0, -0.028, 0.148, 0, 0, 0, 0.88, 0.65, 0.82)
    // Accent stripe on side
    attach(bone, new THREE.BoxGeometry(0.008, 0.032, 0.15), mat.accent, 0.062, -0.030, 0.040)
    // Tongue
    attach(bone, new THREE.BoxGeometry(0.068, 0.010, 0.060), mat.white, 0, -0.005, 0.058)
  })

  const boneList = Object.entries(bones)
    .filter(([k]) => k !== 'root')
    .map(([, bone]) => ({ name: bone.name, bone }))

  return { root, bones, boneList, materials: mat }
}

export const BONE_DISPLAY_NAMES = {
  hips: 'Hips', spine: 'Spine', chest: 'Chest', neck: 'Neck', head: 'Head',
  lShoulder: 'L Shoulder', lUpperArm: 'L Upper Arm', lForeArm: 'L Forearm', lHand: 'L Hand',
  rShoulder: 'R Shoulder', rUpperArm: 'R Upper Arm', rForeArm: 'R Forearm', rHand: 'R Hand',
  lThigh: 'L Thigh', lShin: 'L Shin', lFoot: 'L Foot',
  rThigh: 'R Thigh', rShin: 'R Shin', rFoot: 'R Foot',
}
