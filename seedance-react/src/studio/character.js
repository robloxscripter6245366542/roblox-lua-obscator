import * as THREE from 'three'

// ── Materials ──────────────────────────────────────────────────────
export function makeMaterials(skinColor = '#d4956a', clothColor = '#1e3a5f') {
  const skin = new THREE.MeshStandardMaterial({ color: skinColor, roughness: 0.65, metalness: 0.0 })
  const cloth = new THREE.MeshStandardMaterial({ color: clothColor, roughness: 0.5, metalness: 0.05 })
  const dark = new THREE.MeshStandardMaterial({ color: '#1a0a00', roughness: 0.8, metalness: 0.0 })
  const eye = new THREE.MeshStandardMaterial({ color: '#ffffff', emissive: '#88ccff', emissiveIntensity: 0.4, roughness: 0.1 })
  const pupil = new THREE.MeshStandardMaterial({ color: '#050510', roughness: 0.3 })
  const shoe = new THREE.MeshStandardMaterial({ color: '#111111', roughness: 0.7, metalness: 0.15 })
  return { skin, cloth, dark, eye, pupil, shoe }
}

function mesh(geo, mat) {
  const m = new THREE.Mesh(geo, mat)
  m.castShadow = true
  m.receiveShadow = true
  return m
}

// ── Build skeleton bones ───────────────────────────────────────────
function makeBone(name) {
  const b = new THREE.Bone()
  b.name = name
  return b
}

export function buildSkeleton() {
  const b = {}
  // Spine chain
  b.root      = makeBone('Root')
  b.hips      = makeBone('Hips');      b.hips.position.set(0, 1.02, 0)
  b.spine     = makeBone('Spine');     b.spine.position.set(0, 0.18, 0)
  b.chest     = makeBone('Chest');     b.chest.position.set(0, 0.28, 0)
  b.neck      = makeBone('Neck');      b.neck.position.set(0, 0.3, 0)
  b.head      = makeBone('Head');      b.head.position.set(0, 0.14, 0)
  // Left arm
  b.lShoulder = makeBone('L_Shoulder'); b.lShoulder.position.set(-0.2, 0.28, 0)
  b.lUpperArm = makeBone('L_UpperArm'); b.lUpperArm.position.set(-0.18, 0, 0)
  b.lForeArm  = makeBone('L_ForeArm');  b.lForeArm.position.set(-0.28, 0, 0)
  b.lHand     = makeBone('L_Hand');     b.lHand.position.set(-0.25, 0, 0)
  // Right arm
  b.rShoulder = makeBone('R_Shoulder'); b.rShoulder.position.set(0.2, 0.28, 0)
  b.rUpperArm = makeBone('R_UpperArm'); b.rUpperArm.position.set(0.18, 0, 0)
  b.rForeArm  = makeBone('R_ForeArm');  b.rForeArm.position.set(0.28, 0, 0)
  b.rHand     = makeBone('R_Hand');     b.rHand.position.set(0.25, 0, 0)
  // Left leg
  b.lThigh    = makeBone('L_Thigh');   b.lThigh.position.set(-0.16, -0.04, 0)
  b.lShin     = makeBone('L_Shin');    b.lShin.position.set(0, -0.44, 0)
  b.lFoot     = makeBone('L_Foot');    b.lFoot.position.set(0, -0.42, 0)
  // Right leg
  b.rThigh    = makeBone('R_Thigh');   b.rThigh.position.set(0.16, -0.04, 0)
  b.rShin     = makeBone('R_Shin');    b.rShin.position.set(0, -0.44, 0)
  b.rFoot     = makeBone('R_Foot');    b.rFoot.position.set(0, -0.42, 0)

  // Hierarchy
  b.root.add(b.hips)
  b.hips.add(b.spine); b.spine.add(b.chest)
  b.chest.add(b.neck); b.neck.add(b.head)
  b.chest.add(b.lShoulder); b.lShoulder.add(b.lUpperArm); b.lUpperArm.add(b.lForeArm); b.lForeArm.add(b.lHand)
  b.chest.add(b.rShoulder); b.rShoulder.add(b.rUpperArm); b.rUpperArm.add(b.rForeArm); b.rForeArm.add(b.rHand)
  b.hips.add(b.lThigh); b.lThigh.add(b.lShin); b.lShin.add(b.lFoot)
  b.hips.add(b.rThigh); b.rThigh.add(b.rShin); b.rShin.add(b.rFoot)

  return b
}

// ── Body mesh parts parented to bones ────────────────────────────
export function buildCharacter(skinColor, clothColor) {
  const mat = makeMaterials(skinColor, clothColor)
  const root = new THREE.Group()
  root.name = 'CharacterRoot'

  const bones = buildSkeleton()
  root.add(bones.root)

  function attach(bone, geo, mat2, px = 0, py = 0, pz = 0, rx = 0, ry = 0, rz = 0) {
    const m = mesh(geo, mat2)
    m.position.set(px, py, pz)
    m.rotation.set(rx, ry, rz)
    bone.add(m)
    return m
  }

  // Head
  attach(bones.head, new THREE.SphereGeometry(0.2, 24, 20), mat.skin, 0, 0.18, 0)
  // Hair
  attach(bones.head, new THREE.SphereGeometry(0.205, 20, 16, 0, Math.PI * 2, 0, Math.PI * 0.55), mat.dark, 0, 0.18, 0)
  // Eyes
  attach(bones.head, new THREE.SphereGeometry(0.04, 10, 10), mat.eye, -0.07, 0.2, 0.17)
  attach(bones.head, new THREE.SphereGeometry(0.04, 10, 10), mat.eye, 0.07, 0.2, 0.17)
  attach(bones.head, new THREE.SphereGeometry(0.022, 8, 8), mat.pupil, -0.07, 0.2, 0.185)
  attach(bones.head, new THREE.SphereGeometry(0.022, 8, 8), mat.pupil, 0.07, 0.2, 0.185)
  // Neck
  attach(bones.neck, new THREE.CylinderGeometry(0.07, 0.08, 0.14, 12), mat.skin, 0, 0.07, 0)
  // Torso (chest + belly)
  attach(bones.chest, new THREE.CylinderGeometry(0.24, 0.2, 0.32, 16), mat.cloth, 0, 0.16, 0)
  attach(bones.spine, new THREE.CylinderGeometry(0.2, 0.22, 0.2, 16), mat.cloth, 0, 0.1, 0)
  // Pelvis
  attach(bones.hips, new THREE.CylinderGeometry(0.22, 0.2, 0.18, 16), mat.cloth, 0, -0.02, 0)
  // Shoulders (epaulettes)
  attach(bones.lShoulder, new THREE.SphereGeometry(0.12, 12, 12), mat.cloth, -0.1, 0, 0)
  attach(bones.rShoulder, new THREE.SphereGeometry(0.12, 12, 12), mat.cloth, 0.1, 0, 0)
  // Upper arms
  attach(bones.lUpperArm, new THREE.CylinderGeometry(0.08, 0.07, 0.28, 10), mat.cloth, -0.14, 0, 0, 0, 0, Math.PI / 2)
  attach(bones.rUpperArm, new THREE.CylinderGeometry(0.08, 0.07, 0.28, 10), mat.cloth, 0.14, 0, 0, 0, 0, Math.PI / 2)
  // Forearms
  attach(bones.lForeArm, new THREE.CylinderGeometry(0.065, 0.055, 0.26, 10), mat.skin, -0.13, 0, 0, 0, 0, Math.PI / 2)
  attach(bones.rForeArm, new THREE.CylinderGeometry(0.065, 0.055, 0.26, 10), mat.skin, 0.13, 0, 0, 0, 0, Math.PI / 2)
  // Hands
  attach(bones.lHand, new THREE.SphereGeometry(0.065, 10, 10), mat.skin, -0.065, 0, 0)
  attach(bones.rHand, new THREE.SphereGeometry(0.065, 10, 10), mat.skin, 0.065, 0, 0)
  // Thighs
  attach(bones.lThigh, new THREE.CylinderGeometry(0.12, 0.1, 0.44, 12), mat.cloth, 0, -0.22, 0)
  attach(bones.rThigh, new THREE.CylinderGeometry(0.12, 0.1, 0.44, 12), mat.cloth, 0, -0.22, 0)
  // Shins
  attach(bones.lShin, new THREE.CylinderGeometry(0.09, 0.07, 0.4, 12), mat.cloth, 0, -0.2, 0)
  attach(bones.rShin, new THREE.CylinderGeometry(0.09, 0.07, 0.4, 12), mat.cloth, 0, -0.2, 0)
  // Feet
  attach(bones.lFoot, new THREE.BoxGeometry(0.1, 0.07, 0.22), mat.shoe, 0, -0.04, 0.04)
  attach(bones.rFoot, new THREE.BoxGeometry(0.1, 0.07, 0.22), mat.shoe, 0, -0.04, 0.04)

  // Knee joints
  attach(bones.lShin, new THREE.SphereGeometry(0.09, 10, 10), mat.cloth, 0, 0.01, 0)
  attach(bones.rShin, new THREE.SphereGeometry(0.09, 10, 10), mat.cloth, 0, 0.01, 0)
  // Elbow joints
  attach(bones.lForeArm, new THREE.SphereGeometry(0.065, 8, 8), mat.cloth, 0, 0, 0)
  attach(bones.rForeArm, new THREE.SphereGeometry(0.065, 8, 8), mat.cloth, 0, 0, 0)

  const boneList = Object.entries(bones).filter(([k]) => k !== 'root').map(([name, bone]) => ({ name: bone.name, key: name, bone }))

  return { root, bones, boneList, materials: mat }
}

export const BONE_DISPLAY_NAMES = {
  hips: 'Hips', spine: 'Spine', chest: 'Chest', neck: 'Neck', head: 'Head',
  lShoulder: 'L Shoulder', lUpperArm: 'L Upper Arm', lForeArm: 'L Forearm', lHand: 'L Hand',
  rShoulder: 'R Shoulder', rUpperArm: 'R Upper Arm', rForeArm: 'R Forearm', rHand: 'R Hand',
  lThigh: 'L Thigh', lShin: 'L Shin', lFoot: 'L Foot',
  rThigh: 'R Thigh', rShin: 'R Shin', rFoot: 'R Foot',
}
