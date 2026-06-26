import * as THREE from 'three'

// Helper: quaternion from euler degrees
function quat(x, y, z) {
  return new THREE.Quaternion().setFromEuler(new THREE.Euler(
    THREE.MathUtils.degToRad(x),
    THREE.MathUtils.degToRad(y),
    THREE.MathUtils.degToRad(z)
  ))
}
const Q0 = new THREE.Quaternion() // identity

function makeTrack(boneName, times, quats) {
  const flat = quats.flatMap(q => [q.x, q.y, q.z, q.w])
  return new THREE.QuaternionKeyframeTrack(`${boneName}.quaternion`, times, flat)
}

function makePosTrack(boneName, times, positions) {
  const flat = positions.flatMap(p => [p.x, p.y, p.z])
  return new THREE.VectorKeyframeTrack(`${boneName}.position`, times, flat)
}

// ── IDLE ────────────────────────────────────────────────────────────
function idleClip() {
  const T = 3
  return new THREE.AnimationClip('idle', T, [
    makeTrack('Chest',     [0, 1.5, 3], [quat(-2,0,0), quat(2,0,0), quat(-2,0,0)]),
    makeTrack('Head',      [0, 1.5, 3], [quat(3,0,0),  quat(-3,0,0), quat(3,0,0)]),
    makeTrack('L_UpperArm',[0, 1.5, 3], [quat(0,0,-8), quat(0,0,-12), quat(0,0,-8)]),
    makeTrack('R_UpperArm',[0, 1.5, 3], [quat(0,0,8),  quat(0,0,12),  quat(0,0,8)]),
    makePosTrack('Hips',   [0, 1.5, 3], [
      new THREE.Vector3(0, 1.02, 0),
      new THREE.Vector3(0, 1.01, 0),
      new THREE.Vector3(0, 1.02, 0),
    ]),
  ])
}

// ── WALK ────────────────────────────────────────────────────────────
function walkClip() {
  const T = 1.0
  return new THREE.AnimationClip('walk', T, [
    makeTrack('Hips',      [0, 0.5, 1.0], [quat(8,0,0),  quat(-8,0,0), quat(8,0,0)]),
    makeTrack('L_Thigh',   [0, 0.5, 1.0], [quat(-35,0,0), quat(30,0,0), quat(-35,0,0)]),
    makeTrack('R_Thigh',   [0, 0.5, 1.0], [quat(30,0,0), quat(-35,0,0), quat(30,0,0)]),
    makeTrack('L_Shin',    [0, 0.5, 1.0], [quat(10,0,0),  quat(40,0,0), quat(10,0,0)]),
    makeTrack('R_Shin',    [0, 0.5, 1.0], [quat(40,0,0),  quat(10,0,0), quat(40,0,0)]),
    makeTrack('L_UpperArm',[0, 0.5, 1.0], [quat(40,0,-10), quat(-35,0,-10), quat(40,0,-10)]),
    makeTrack('R_UpperArm',[0, 0.5, 1.0], [quat(-35,0,10), quat(40,0,10), quat(-35,0,10)]),
    makeTrack('Spine',     [0, 0.5, 1.0], [quat(0,5,0), quat(0,-5,0), quat(0,5,0)]),
  ])
}

// ── RUN ─────────────────────────────────────────────────────────────
function runClip() {
  const T = 0.6
  return new THREE.AnimationClip('run', T, [
    makeTrack('Hips',      [0, 0.3, 0.6], [quat(15,0,0), quat(-5,0,0), quat(15,0,0)]),
    makeTrack('L_Thigh',   [0, 0.3, 0.6], [quat(-65,0,0), quat(55,0,0), quat(-65,0,0)]),
    makeTrack('R_Thigh',   [0, 0.3, 0.6], [quat(55,0,0), quat(-65,0,0), quat(55,0,0)]),
    makeTrack('L_Shin',    [0, 0.3, 0.6], [quat(5,0,0),   quat(75,0,0), quat(5,0,0)]),
    makeTrack('R_Shin',    [0, 0.3, 0.6], [quat(75,0,0),  quat(5,0,0),  quat(75,0,0)]),
    makeTrack('L_UpperArm',[0, 0.3, 0.6], [quat(75,0,-18), quat(-60,0,-18), quat(75,0,-18)]),
    makeTrack('R_UpperArm',[0, 0.3, 0.6], [quat(-60,0,18), quat(75,0,18), quat(-60,0,18)]),
    makeTrack('L_ForeArm', [0, 0.3, 0.6], [quat(60,0,0), quat(70,0,0), quat(60,0,0)]),
    makeTrack('R_ForeArm', [0, 0.3, 0.6], [quat(70,0,0), quat(60,0,0), quat(70,0,0)]),
    makeTrack('Chest',     [0, 0.3, 0.6], [quat(10,8,0), quat(10,-8,0), quat(10,8,0)]),
  ])
}

// ── JUMP ────────────────────────────────────────────────────────────
function jumpClip() {
  const T = 1.4
  return new THREE.AnimationClip('jump', T, [
    makePosTrack('Hips', [0, 0.15, 0.5, 0.85, 1.4], [
      new THREE.Vector3(0, 1.02, 0), new THREE.Vector3(0, 0.75, 0),
      new THREE.Vector3(0, 2.0, 0),  new THREE.Vector3(0, 0.85, 0),
      new THREE.Vector3(0, 1.02, 0),
    ]),
    makeTrack('L_Thigh', [0, 0.15, 0.5, 0.85, 1.4], [quat(0,0,0), quat(40,0,0), quat(-55,0,0), quat(25,0,0), quat(0,0,0)]),
    makeTrack('R_Thigh', [0, 0.15, 0.5, 0.85, 1.4], [quat(0,0,0), quat(40,0,0), quat(-55,0,0), quat(25,0,0), quat(0,0,0)]),
    makeTrack('L_Shin',  [0, 0.15, 0.5, 0.85, 1.4], [quat(0,0,0), quat(70,0,0), quat(55,0,0),  quat(30,0,0), quat(0,0,0)]),
    makeTrack('R_Shin',  [0, 0.15, 0.5, 0.85, 1.4], [quat(0,0,0), quat(70,0,0), quat(55,0,0),  quat(30,0,0), quat(0,0,0)]),
    makeTrack('L_UpperArm',[0, 0.15, 0.5, 1.4], [quat(0,0,-8), quat(-25,0,-25), quat(-160,0,-30), quat(0,0,-8)]),
    makeTrack('R_UpperArm',[0, 0.15, 0.5, 1.4], [quat(0,0,8),  quat(-25,0,25),  quat(-160,0,30),  quat(0,0,8)]),
    makeTrack('Spine',   [0, 0.15, 0.5, 1.4], [Q0, quat(15,0,0), quat(-10,0,0), Q0]),
  ])
}

// ── WAVE ────────────────────────────────────────────────────────────
function waveClip() {
  const T = 1.5
  return new THREE.AnimationClip('wave', T, [
    makeTrack('R_UpperArm',[0, 0.5, 1.0, 1.5], [quat(-150,0,30), quat(-150,15,30), quat(-150,-15,30), quat(-150,0,30)]),
    makeTrack('R_ForeArm', [0, 0.5, 1.0, 1.5], [quat(0,0,0), quat(30,0,0), quat(-20,0,0), quat(0,0,0)]),
    makeTrack('Head',      [0, 0.75, 1.5],      [quat(0,15,0), quat(0,-15,0), quat(0,15,0)]),
    makeTrack('Spine',     [0, 0.75, 1.5],      [quat(0,10,0), quat(0,-10,0), quat(0,10,0)]),
  ])
}

// ── PUNCH ───────────────────────────────────────────────────────────
function punchClip() {
  const T = 0.8
  return new THREE.AnimationClip('punch', T, [
    makeTrack('R_UpperArm',[0, 0.2, 0.4, 0.8], [quat(0,0,8), quat(-20,0,8), quat(-85,0,5), quat(0,0,8)]),
    makeTrack('R_ForeArm', [0, 0.2, 0.4, 0.8], [quat(80,0,0), quat(60,0,0), quat(0,0,0), quat(80,0,0)]),
    makeTrack('L_UpperArm',[0, 0.4, 0.8],       [quat(-80,0,-20), quat(-80,0,-20), quat(-80,0,-20)]),
    makeTrack('L_ForeArm', [0, 0.4, 0.8],       [quat(90,0,0), quat(90,0,0), quat(90,0,0)]),
    makeTrack('Spine',     [0, 0.2, 0.8],       [Q0, quat(0,-25,0), Q0]),
    makeTrack('Hips',      [0, 0.2, 0.8],       [Q0, quat(0,15,0), Q0]),
  ])
}

// ── DANCE ───────────────────────────────────────────────────────────
function danceClip() {
  const T = 2.0
  return new THREE.AnimationClip('dance', T, [
    makePosTrack('Hips', [0,0.5,1.0,1.5,2.0], [
      new THREE.Vector3(0,1.02,0), new THREE.Vector3(-0.1,1.08,0),
      new THREE.Vector3(0,1.02,0), new THREE.Vector3(0.1,1.08,0),
      new THREE.Vector3(0,1.02,0),
    ]),
    makeTrack('Hips',      [0,0.5,1.0,1.5,2.0], [Q0, quat(0,20,10), Q0, quat(0,-20,-10), Q0]),
    makeTrack('L_UpperArm',[0,0.5,1.0,1.5,2.0], [quat(-40,0,-30), quat(10,0,-60), quat(-40,0,-30), quat(-90,0,-10), quat(-40,0,-30)]),
    makeTrack('R_UpperArm',[0,0.5,1.0,1.5,2.0], [quat(10,0,60), quat(-40,0,30), quat(10,0,60), quat(-90,0,10), quat(10,0,60)]),
    makeTrack('L_Thigh',   [0,0.5,1.0,1.5,2.0], [quat(0,0,0), quat(-20,0,0), quat(20,0,0), quat(-10,0,0), quat(0,0,0)]),
    makeTrack('R_Thigh',   [0,0.5,1.0,1.5,2.0], [quat(0,0,0), quat(20,0,0), quat(-20,0,0), quat(10,0,0), quat(0,0,0)]),
    makeTrack('Spine',     [0,0.5,1.0,1.5,2.0], [Q0, quat(5,15,5), Q0, quat(5,-15,-5), Q0]),
    makeTrack('Head',      [0,0.5,1.0,1.5,2.0], [Q0, quat(0,-20,8), Q0, quat(0,20,-8), Q0]),
  ])
}

// ── CROUCH ──────────────────────────────────────────────────────────
function crouchClip() {
  const T = 0.6
  return new THREE.AnimationClip('crouch', T, [
    makePosTrack('Hips', [0, 0.3, 0.6], [
      new THREE.Vector3(0,1.02,0), new THREE.Vector3(0,0.6,0), new THREE.Vector3(0,0.6,0),
    ]),
    makeTrack('L_Thigh', [0, 0.3, 0.6], [Q0, quat(80,0,0),  quat(80,0,0)]),
    makeTrack('R_Thigh', [0, 0.3, 0.6], [Q0, quat(80,0,0),  quat(80,0,0)]),
    makeTrack('L_Shin',  [0, 0.3, 0.6], [Q0, quat(-80,0,0), quat(-80,0,0)]),
    makeTrack('R_Shin',  [0, 0.3, 0.6], [Q0, quat(-80,0,0), quat(-80,0,0)]),
    makeTrack('Spine',   [0, 0.3, 0.6], [Q0, quat(20,0,0),  quat(20,0,0)]),
    makeTrack('L_UpperArm',[0,0.3,0.6], [quat(0,0,-8), quat(-10,0,-30), quat(-10,0,-30)]),
    makeTrack('R_UpperArm',[0,0.3,0.6], [quat(0,0, 8), quat(-10,0, 30), quat(-10,0, 30)]),
  ])
}

export const CLIPS = {
  idle:   idleClip(),
  walk:   walkClip(),
  run:    runClip(),
  jump:   jumpClip(),
  wave:   waveClip(),
  punch:  punchClip(),
  dance:  danceClip(),
  crouch: crouchClip(),
}

export const ANIM_LIST = [
  { id: 'idle',   label: 'Idle',        icon: '🧍' },
  { id: 'walk',   label: 'Walk',        icon: '🚶' },
  { id: 'run',    label: 'Run',         icon: '🏃' },
  { id: 'jump',   label: 'Jump',        icon: '🦘' },
  { id: 'wave',   label: 'Wave',        icon: '👋' },
  { id: 'punch',  label: 'Punch',       icon: '👊' },
  { id: 'dance',  label: 'Dance',       icon: '💃' },
  { id: 'crouch', label: 'Crouch',      icon: '🫷' },
]
