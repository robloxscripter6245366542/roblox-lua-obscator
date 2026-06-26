import * as THREE from 'three'

const HALF_PI = Math.PI / 2

// ── Materials ─────────────────────────────────────────────────────────────────
export function makeMaterials(skinColor = '#d4956a', clothColor = '#1e3a5f') {
  const skin = new THREE.MeshPhysicalMaterial({
    color: skinColor, roughness: 0.68, metalness: 0.0,
    clearcoat: 0.06, clearcoatRoughness: 0.55,
  })
  const cloth = new THREE.MeshPhysicalMaterial({
    color: clothColor, roughness: 0.66, metalness: 0.02,
    sheen: 0.55, sheenRoughness: 0.52,
    sheenColor: new THREE.Color(clothColor).lerp(new THREE.Color('#ffffff'), 0.18),
  })
  const dark = new THREE.MeshStandardMaterial({ color: '#160800', roughness: 0.9, metalness: 0.0 })
  const eye = new THREE.MeshPhysicalMaterial({
    color: '#ffffff', emissive: '#88ccff', emissiveIntensity: 0.25,
    roughness: 0.04, metalness: 0.0, clearcoat: 1.0, clearcoatRoughness: 0.0,
  })
  const iris = new THREE.MeshPhysicalMaterial({
    color: '#2a5fa8', roughness: 0.08, metalness: 0.0, clearcoat: 1.0, clearcoatRoughness: 0.0,
  })
  const pupil = new THREE.MeshStandardMaterial({ color: '#030308', roughness: 0.2 })
  const shoe = new THREE.MeshPhysicalMaterial({
    color: '#0d0d0d', roughness: 0.38, metalness: 0.28, clearcoat: 0.3, clearcoatRoughness: 0.38,
  })
  return { skin, cloth, dark, eye, iris, pupil, shoe }
}

function mesh(geo, mat) {
  const m = new THREE.Mesh(geo, mat)
  m.castShadow = true
  m.receiveShadow = true
  return m
}

function attach(bone, geo, mat2, px = 0, py = 0, pz = 0, rx = 0, ry = 0, rz = 0, sx = 1, sy = 1, sz = 1) {
  const m = mesh(geo, mat2)
  m.position.set(px, py, pz)
  m.rotation.set(rx, ry, rz)
  m.scale.set(sx, sy, sz)
  bone.add(m)
  return m
}

// ── Finger geometry helper ─────────────────────────────────────────────────────
function addFingers(bone, skinMat, dir) {
  // dir=1 (left hand, -X outward) or dir=-1 (right hand, +X outward)
  const d = dir
  // Palm box
  attach(bone, new THREE.BoxGeometry(0.12, 0.024, 0.12), skinMat, 0.095 * d, 0, 0.005)
  // 4 fingers (index→pinky), spread in Z
  const zOff = [0.042, 0.014, -0.014, -0.042]
  zOff.forEach(z => {
    attach(bone, new THREE.CylinderGeometry(0.012, 0.011, 0.056, 7), skinMat, 0.127 * d, 0, z, 0, 0, HALF_PI)
    attach(bone, new THREE.CylinderGeometry(0.011, 0.009, 0.040, 7), skinMat, 0.173 * d, 0, z, 0, 0, HALF_PI)
    attach(bone, new THREE.SphereGeometry(0.009, 6, 5), skinMat, 0.200 * d, 0, z)
  })
  // Thumb
  const tx = 0.085 * d, ty = -0.028, tz = 0.066
  attach(bone, new THREE.CylinderGeometry(0.014, 0.012, 0.052, 7), skinMat, tx, ty, tz, HALF_PI * 0.42, 0, HALF_PI)
  attach(bone, new THREE.SphereGeometry(0.012, 6, 5), skinMat, tx, ty - 0.027, tz + 0.036)
}

// ── Skeleton ──────────────────────────────────────────────────────────────────
function makeBone(name) { const b = new THREE.Bone(); b.name = name; return b }

export function buildSkeleton() {
  const b = {}
  b.root  = makeBone('Root')
  b.hips  = makeBone('Hips');  b.hips.position.set(0, 1.02, 0)
  b.spine = makeBone('Spine'); b.spine.position.set(0, 0.18, 0)
  b.chest = makeBone('Chest'); b.chest.position.set(0, 0.3, 0)
  b.neck  = makeBone('Neck');  b.neck.position.set(0, 0.32, 0)
  b.head  = makeBone('Head');  b.head.position.set(0, 0.14, 0)

  b.lShoulder = makeBone('L_Shoulder'); b.lShoulder.position.set(-0.2, 0.28, 0)
  b.lUpperArm = makeBone('L_UpperArm'); b.lUpperArm.position.set(-0.18, 0, 0)
  b.lForeArm  = makeBone('L_ForeArm');  b.lForeArm.position.set(-0.28, 0, 0)
  b.lHand     = makeBone('L_Hand');     b.lHand.position.set(-0.25, 0, 0)

  b.rShoulder = makeBone('R_Shoulder'); b.rShoulder.position.set(0.2, 0.28, 0)
  b.rUpperArm = makeBone('R_UpperArm'); b.rUpperArm.position.set(0.18, 0, 0)
  b.rForeArm  = makeBone('R_ForeArm');  b.rForeArm.position.set(0.28, 0, 0)
  b.rHand     = makeBone('R_Hand');     b.rHand.position.set(0.25, 0, 0)

  b.lThigh = makeBone('L_Thigh'); b.lThigh.position.set(-0.16, -0.04, 0)
  b.lShin  = makeBone('L_Shin');  b.lShin.position.set(0, -0.44, 0)
  b.lFoot  = makeBone('L_Foot');  b.lFoot.position.set(0, -0.42, 0)

  b.rThigh = makeBone('R_Thigh'); b.rThigh.position.set(0.16, -0.04, 0)
  b.rShin  = makeBone('R_Shin');  b.rShin.position.set(0, -0.44, 0)
  b.rFoot  = makeBone('R_Foot');  b.rFoot.position.set(0, -0.42, 0)

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
  const root = new THREE.Group()
  root.name = 'CharacterRoot'
  const bones = buildSkeleton()
  root.add(bones.root)

  // Head
  attach(bones.head, new THREE.SphereGeometry(0.2, 28, 22), mat.skin, 0, 0.18, 0)
  // Hair cap (upper hemisphere)
  attach(bones.head, new THREE.SphereGeometry(0.207, 22, 18, 0, Math.PI * 2, 0, Math.PI * 0.52), mat.dark, 0, 0.18, 0)
  // Ear L/R (scaled sphere)
  attach(bones.head, new THREE.SphereGeometry(0.038, 8, 6), mat.skin, -0.2, 0.14, 0.0, 0, 0, 0, 0.4, 1.2, 0.3)
  attach(bones.head, new THREE.SphereGeometry(0.038, 8, 6), mat.skin,  0.2, 0.14, 0.0, 0, 0, 0, 0.4, 1.2, 0.3)
  // Eyebrows
  attach(bones.head, new THREE.BoxGeometry(0.068, 0.013, 0.008), mat.dark, -0.072, 0.29, 0.172)
  attach(bones.head, new THREE.BoxGeometry(0.068, 0.013, 0.008), mat.dark,  0.072, 0.29, 0.172)
  // Eyes – sclera
  attach(bones.head, new THREE.SphereGeometry(0.042, 12, 10), mat.eye, -0.073, 0.2, 0.169)
  attach(bones.head, new THREE.SphereGeometry(0.042, 12, 10), mat.eye,  0.073, 0.2, 0.169)
  // Iris
  attach(bones.head, new THREE.CylinderGeometry(0.022, 0.022, 0.004, 12), mat.iris, -0.073, 0.2, 0.208, HALF_PI, 0, 0)
  attach(bones.head, new THREE.CylinderGeometry(0.022, 0.022, 0.004, 12), mat.iris,  0.073, 0.2, 0.208, HALF_PI, 0, 0)
  // Pupils
  attach(bones.head, new THREE.SphereGeometry(0.015, 8, 7), mat.pupil, -0.073, 0.2, 0.207)
  attach(bones.head, new THREE.SphereGeometry(0.015, 8, 7), mat.pupil,  0.073, 0.2, 0.207)
  // Nose
  attach(bones.head, new THREE.ConeGeometry(0.022, 0.04, 7), mat.skin, 0, 0.13, 0.2, -HALF_PI, 0, 0)
  // Lower lip hint
  attach(bones.head, new THREE.SphereGeometry(0.03, 8, 6), mat.skin, 0, 0.065, 0.192, 0, 0, 0, 1.4, 0.55, 0.35)

  // Neck
  attach(bones.neck, new THREE.CylinderGeometry(0.075, 0.085, 0.14, 14), mat.skin, 0, 0.07, 0)

  // Torso
  attach(bones.chest, new THREE.CylinderGeometry(0.26, 0.21, 0.34, 18), mat.cloth, 0, 0.17, 0)
  attach(bones.spine, new THREE.CylinderGeometry(0.21, 0.23, 0.22, 16), mat.cloth, 0, 0.1, 0)
  attach(bones.hips, new THREE.CylinderGeometry(0.23, 0.21, 0.2, 16), mat.cloth, 0, -0.025, 0)
  // Collarbone hints
  attach(bones.chest, new THREE.CylinderGeometry(0.024, 0.017, 0.18, 8), mat.cloth, -0.09, 0.295, 0.022, 0, 0, HALF_PI)
  attach(bones.chest, new THREE.CylinderGeometry(0.024, 0.017, 0.18, 8), mat.cloth,  0.09, 0.295, 0.022, 0, 0, HALF_PI)

  // Shoulders
  attach(bones.lShoulder, new THREE.SphereGeometry(0.13, 14, 12), mat.cloth, -0.1, 0, 0)
  attach(bones.rShoulder, new THREE.SphereGeometry(0.13, 14, 12), mat.cloth,  0.1, 0, 0)

  // Upper arms
  attach(bones.lUpperArm, new THREE.CylinderGeometry(0.085, 0.075, 0.3, 12), mat.cloth, -0.15, 0, 0, 0, 0, HALF_PI)
  attach(bones.rUpperArm, new THREE.CylinderGeometry(0.085, 0.075, 0.3, 12), mat.cloth,  0.15, 0, 0, 0, 0, HALF_PI)
  // Elbow joints
  attach(bones.lForeArm, new THREE.SphereGeometry(0.068, 10, 9), mat.cloth, 0, 0, 0)
  attach(bones.rForeArm, new THREE.SphereGeometry(0.068, 10, 9), mat.cloth, 0, 0, 0)
  // Forearms
  attach(bones.lForeArm, new THREE.CylinderGeometry(0.068, 0.056, 0.27, 12), mat.skin, -0.135, 0, 0, 0, 0, HALF_PI)
  attach(bones.rForeArm, new THREE.CylinderGeometry(0.068, 0.056, 0.27, 12), mat.skin,  0.135, 0, 0, 0, 0, HALF_PI)
  // Wrists
  attach(bones.lHand, new THREE.SphereGeometry(0.052, 10, 9), mat.skin, 0, 0, 0)
  attach(bones.rHand, new THREE.SphereGeometry(0.052, 10, 9), mat.skin, 0, 0, 0)
  // Fingers
  addFingers(bones.lHand, mat.skin, 1)
  addFingers(bones.rHand, mat.skin, -1)

  // Thighs
  attach(bones.lThigh, new THREE.CylinderGeometry(0.13, 0.105, 0.46, 14), mat.cloth, 0, -0.23, 0)
  attach(bones.rThigh, new THREE.CylinderGeometry(0.13, 0.105, 0.46, 14), mat.cloth, 0, -0.23, 0)
  // Knee joints
  attach(bones.lShin, new THREE.SphereGeometry(0.095, 12, 10), mat.cloth, 0, 0.01, 0)
  attach(bones.rShin, new THREE.SphereGeometry(0.095, 12, 10), mat.cloth, 0, 0.01, 0)
  // Shins
  attach(bones.lShin, new THREE.CylinderGeometry(0.092, 0.072, 0.42, 12), mat.cloth, 0, -0.21, 0)
  attach(bones.rShin, new THREE.CylinderGeometry(0.092, 0.072, 0.42, 12), mat.cloth, 0, -0.21, 0)
  // Ankles + feet
  attach(bones.lFoot, new THREE.SphereGeometry(0.072, 10, 8), mat.shoe, 0, 0, 0)
  attach(bones.rFoot, new THREE.SphereGeometry(0.072, 10, 8), mat.shoe, 0, 0, 0)
  attach(bones.lFoot, new THREE.BoxGeometry(0.11, 0.068, 0.24), mat.shoe, 0, -0.038, 0.05)
  attach(bones.rFoot, new THREE.BoxGeometry(0.11, 0.068, 0.24), mat.shoe, 0, -0.038, 0.05)
  // Toe caps
  attach(bones.lFoot, new THREE.SphereGeometry(0.06, 10, 7), mat.shoe, 0, -0.038, 0.155, 0, 0, 0, 0.9, 0.7, 1)
  attach(bones.rFoot, new THREE.SphereGeometry(0.06, 10, 7), mat.shoe, 0, -0.038, 0.155, 0, 0, 0, 0.9, 0.7, 1)

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
