import * as THREE from 'three'

function quat(x, y, z) {
  return new THREE.Quaternion().setFromEuler(new THREE.Euler(
    THREE.MathUtils.degToRad(x),
    THREE.MathUtils.degToRad(y),
    THREE.MathUtils.degToRad(z)
  ))
}
const Q0 = new THREE.Quaternion()

function makeTrack(boneName, times, quats) {
  const flat = quats.flatMap(q => [q.x, q.y, q.z, q.w])
  return new THREE.QuaternionKeyframeTrack(`${boneName}.quaternion`, times, flat)
}
function makePosTrack(boneName, times, positions) {
  const flat = positions.flatMap(p => [p.x, p.y, p.z])
  return new THREE.VectorKeyframeTrack(`${boneName}.position`, times, flat)
}
const V3 = (x, y, z) => new THREE.Vector3(x, y, z)

// ── IDLE ────────────────────────────────────────────────────────────
function idleClip() {
  return new THREE.AnimationClip('idle', 3, [
    makeTrack('Chest',      [0,1.5,3], [quat(-2,0,0),  quat(2,0,0),   quat(-2,0,0)]),
    makeTrack('Head',       [0,1.5,3], [quat(3,0,0),   quat(-3,0,0),  quat(3,0,0)]),
    makeTrack('L_UpperArm', [0,1.5,3], [quat(0,0,-8),  quat(0,0,-12), quat(0,0,-8)]),
    makeTrack('R_UpperArm', [0,1.5,3], [quat(0,0,8),   quat(0,0,12),  quat(0,0,8)]),
    makePosTrack('Hips',    [0,1.5,3], [V3(0,1.02,0),  V3(0,1.01,0),  V3(0,1.02,0)]),
  ])
}

// ── WALK ────────────────────────────────────────────────────────────
function walkClip() {
  return new THREE.AnimationClip('walk', 1.0, [
    makeTrack('Hips',      [0,.5,1.0], [quat(8,0,0),    quat(-8,0,0),   quat(8,0,0)]),
    makeTrack('L_Thigh',   [0,.5,1.0], [quat(-35,0,0),  quat(30,0,0),   quat(-35,0,0)]),
    makeTrack('R_Thigh',   [0,.5,1.0], [quat(30,0,0),   quat(-35,0,0),  quat(30,0,0)]),
    makeTrack('L_Shin',    [0,.5,1.0], [quat(10,0,0),   quat(40,0,0),   quat(10,0,0)]),
    makeTrack('R_Shin',    [0,.5,1.0], [quat(40,0,0),   quat(10,0,0),   quat(40,0,0)]),
    makeTrack('L_UpperArm',[0,.5,1.0], [quat(40,0,-10), quat(-35,0,-10),quat(40,0,-10)]),
    makeTrack('R_UpperArm',[0,.5,1.0], [quat(-35,0,10), quat(40,0,10),  quat(-35,0,10)]),
    makeTrack('Spine',     [0,.5,1.0], [quat(0,5,0),    quat(0,-5,0),   quat(0,5,0)]),
  ])
}

// ── RUN ─────────────────────────────────────────────────────────────
function runClip() {
  return new THREE.AnimationClip('run', 0.6, [
    makeTrack('Hips',      [0,.3,.6], [quat(15,0,0),   quat(-5,0,0),   quat(15,0,0)]),
    makeTrack('L_Thigh',   [0,.3,.6], [quat(-65,0,0),  quat(55,0,0),   quat(-65,0,0)]),
    makeTrack('R_Thigh',   [0,.3,.6], [quat(55,0,0),   quat(-65,0,0),  quat(55,0,0)]),
    makeTrack('L_Shin',    [0,.3,.6], [quat(5,0,0),    quat(75,0,0),   quat(5,0,0)]),
    makeTrack('R_Shin',    [0,.3,.6], [quat(75,0,0),   quat(5,0,0),    quat(75,0,0)]),
    makeTrack('L_UpperArm',[0,.3,.6], [quat(75,0,-18), quat(-60,0,-18),quat(75,0,-18)]),
    makeTrack('R_UpperArm',[0,.3,.6], [quat(-60,0,18), quat(75,0,18),  quat(-60,0,18)]),
    makeTrack('L_ForeArm', [0,.3,.6], [quat(60,0,0),   quat(70,0,0),   quat(60,0,0)]),
    makeTrack('R_ForeArm', [0,.3,.6], [quat(70,0,0),   quat(60,0,0),   quat(70,0,0)]),
    makeTrack('Chest',     [0,.3,.6], [quat(10,8,0),   quat(10,-8,0),  quat(10,8,0)]),
  ])
}

// ── JUMP ────────────────────────────────────────────────────────────
function jumpClip() {
  return new THREE.AnimationClip('jump', 1.4, [
    makePosTrack('Hips',   [0,.15,.5,.85,1.4], [V3(0,1.02,0),V3(0,0.75,0),V3(0,2.0,0),V3(0,0.85,0),V3(0,1.02,0)]),
    makeTrack('L_Thigh',   [0,.15,.5,.85,1.4], [Q0, quat(40,0,0), quat(-55,0,0), quat(25,0,0), Q0]),
    makeTrack('R_Thigh',   [0,.15,.5,.85,1.4], [Q0, quat(40,0,0), quat(-55,0,0), quat(25,0,0), Q0]),
    makeTrack('L_Shin',    [0,.15,.5,.85,1.4], [Q0, quat(70,0,0), quat(55,0,0),  quat(30,0,0), Q0]),
    makeTrack('R_Shin',    [0,.15,.5,.85,1.4], [Q0, quat(70,0,0), quat(55,0,0),  quat(30,0,0), Q0]),
    makeTrack('L_UpperArm',[0,.15,.5,1.4],     [quat(0,0,-8), quat(-25,0,-25), quat(-160,0,-30), quat(0,0,-8)]),
    makeTrack('R_UpperArm',[0,.15,.5,1.4],     [quat(0,0,8),  quat(-25,0,25),  quat(-160,0,30),  quat(0,0,8)]),
    makeTrack('Spine',     [0,.15,.5,1.4],     [Q0, quat(15,0,0), quat(-10,0,0), Q0]),
  ])
}

// ── WAVE ────────────────────────────────────────────────────────────
function waveClip() {
  return new THREE.AnimationClip('wave', 1.5, [
    makeTrack('R_UpperArm',[0,.5,1.0,1.5], [quat(-150,0,30), quat(-150,15,30), quat(-150,-15,30), quat(-150,0,30)]),
    makeTrack('R_ForeArm', [0,.5,1.0,1.5], [quat(0,0,0), quat(30,0,0), quat(-20,0,0), quat(0,0,0)]),
    makeTrack('Head',      [0,.75,1.5],    [quat(0,15,0), quat(0,-15,0), quat(0,15,0)]),
    makeTrack('Spine',     [0,.75,1.5],    [quat(0,10,0), quat(0,-10,0), quat(0,10,0)]),
  ])
}

// ── PUNCH ───────────────────────────────────────────────────────────
function punchClip() {
  return new THREE.AnimationClip('punch', 0.8, [
    makeTrack('R_UpperArm',[0,.2,.4,.8], [quat(0,0,8), quat(-20,0,8), quat(-85,0,5), quat(0,0,8)]),
    makeTrack('R_ForeArm', [0,.2,.4,.8], [quat(80,0,0), quat(60,0,0), quat(0,0,0), quat(80,0,0)]),
    makeTrack('L_UpperArm',[0,.4,.8],    [quat(-80,0,-20), quat(-80,0,-20), quat(-80,0,-20)]),
    makeTrack('L_ForeArm', [0,.4,.8],    [quat(90,0,0), quat(90,0,0), quat(90,0,0)]),
    makeTrack('Spine',     [0,.2,.8],    [Q0, quat(0,-25,0), Q0]),
    makeTrack('Hips',      [0,.2,.8],    [Q0, quat(0,15,0), Q0]),
  ])
}

// ── DANCE ───────────────────────────────────────────────────────────
function danceClip() {
  return new THREE.AnimationClip('dance', 2.0, [
    makePosTrack('Hips', [0,.5,1,1.5,2], [V3(0,1.02,0),V3(-0.1,1.08,0),V3(0,1.02,0),V3(0.1,1.08,0),V3(0,1.02,0)]),
    makeTrack('Hips',      [0,.5,1,1.5,2], [Q0, quat(0,20,10),  Q0, quat(0,-20,-10), Q0]),
    makeTrack('L_UpperArm',[0,.5,1,1.5,2], [quat(-40,0,-30), quat(10,0,-60),  quat(-40,0,-30), quat(-90,0,-10), quat(-40,0,-30)]),
    makeTrack('R_UpperArm',[0,.5,1,1.5,2], [quat(10,0,60),   quat(-40,0,30),  quat(10,0,60),   quat(-90,0,10),  quat(10,0,60)]),
    makeTrack('L_Thigh',   [0,.5,1,1.5,2], [Q0, quat(-20,0,0), quat(20,0,0), quat(-10,0,0), Q0]),
    makeTrack('R_Thigh',   [0,.5,1,1.5,2], [Q0, quat(20,0,0),  quat(-20,0,0),quat(10,0,0),  Q0]),
    makeTrack('Spine',     [0,.5,1,1.5,2], [Q0, quat(5,15,5),  Q0, quat(5,-15,-5), Q0]),
    makeTrack('Head',      [0,.5,1,1.5,2], [Q0, quat(0,-20,8), Q0, quat(0,20,-8),  Q0]),
  ])
}

// ── CROUCH ──────────────────────────────────────────────────────────
function crouchClip() {
  return new THREE.AnimationClip('crouch', 0.6, [
    makePosTrack('Hips', [0,.3,.6], [V3(0,1.02,0),V3(0,0.6,0),V3(0,0.6,0)]),
    makeTrack('L_Thigh',   [0,.3,.6], [Q0, quat(80,0,0),  quat(80,0,0)]),
    makeTrack('R_Thigh',   [0,.3,.6], [Q0, quat(80,0,0),  quat(80,0,0)]),
    makeTrack('L_Shin',    [0,.3,.6], [Q0, quat(-80,0,0), quat(-80,0,0)]),
    makeTrack('R_Shin',    [0,.3,.6], [Q0, quat(-80,0,0), quat(-80,0,0)]),
    makeTrack('Spine',     [0,.3,.6], [Q0, quat(20,0,0),  quat(20,0,0)]),
    makeTrack('L_UpperArm',[0,.3,.6], [quat(0,0,-8),  quat(-10,0,-30), quat(-10,0,-30)]),
    makeTrack('R_UpperArm',[0,.3,.6], [quat(0,0,8),   quat(-10,0,30),  quat(-10,0,30)]),
  ])
}

// ── AIM ─────────────────────────────────────────────────────────────
function aimClip() {
  return new THREE.AnimationClip('aim', 1.5, [
    makeTrack('Hips',      [0,.75,1.5], [quat(0,-20,0),  quat(0,-20,0),  quat(0,-20,0)]),
    makeTrack('Spine',     [0,.75,1.5], [quat(5,-15,0),  quat(4,-15,0),  quat(5,-15,0)]),
    makeTrack('Chest',     [0,.75,1.5], [quat(5,0,0),    quat(4,0,0),    quat(5,0,0)]),
    makeTrack('Head',      [0,.75,1.5], [quat(-8,-20,0), quat(-8,-20,0), quat(-8,-20,0)]),
    makeTrack('R_UpperArm',[0,.75,1.5], [quat(-75,-15,15),quat(-76,-15,15),quat(-75,-15,15)]),
    makeTrack('R_ForeArm', [0,.75,1.5], [quat(-20,0,0),  quat(-20,0,0),  quat(-20,0,0)]),
    makeTrack('L_UpperArm',[0,.75,1.5], [quat(-60,0,-25),quat(-60,0,-25),quat(-60,0,-25)]),
    makeTrack('L_ForeArm', [0,.75,1.5], [quat(20,0,0),   quat(20,0,0),   quat(20,0,0)]),
    makeTrack('L_Thigh',   [0,.75,1.5], [quat(15,0,5),   quat(15,0,5),   quat(15,0,5)]),
    makeTrack('R_Thigh',   [0,.75,1.5], [quat(15,0,-5),  quat(15,0,-5),  quat(15,0,-5)]),
    makeTrack('L_Shin',    [0,.75,1.5], [quat(-8,0,0),   quat(-8,0,0),   quat(-8,0,0)]),
    makeTrack('R_Shin',    [0,.75,1.5], [quat(-8,0,0),   quat(-8,0,0),   quat(-8,0,0)]),
  ])
}

// ── KICK ────────────────────────────────────────────────────────────
function kickClip() {
  return new THREE.AnimationClip('kick', 1.0, [
    makePosTrack('Hips',   [0,.2,.5,.75,1.0], [V3(0,1.02,0),V3(0,1.05,0),V3(0,1.0,0),V3(0,1.03,0),V3(0,1.02,0)]),
    makeTrack('R_Thigh',   [0,.2,.5,.75,1.0], [Q0, quat(-80,0,0), quat(-15,0,0), quat(-40,0,0), Q0]),
    makeTrack('R_Shin',    [0,.2,.5,.75,1.0], [Q0, quat(90,0,0),  quat(0,0,0),   quat(60,0,0),  Q0]),
    makeTrack('L_Thigh',   [0,.5,1.0],        [quat(15,0,0), quat(20,0,0), quat(15,0,0)]),
    makeTrack('L_Shin',    [0,.5,1.0],        [quat(5,0,0),  quat(5,0,0),  quat(5,0,0)]),
    makeTrack('Spine',     [0,.3,.5,1.0],     [Q0, quat(15,0,0), quat(20,0,0), Q0]),
    makeTrack('L_UpperArm',[0,.3,.5,1.0],     [quat(0,0,-15), quat(-30,0,-15), quat(-20,0,-20), quat(0,0,-15)]),
    makeTrack('R_UpperArm',[0,.3,.5,1.0],     [quat(0,0,8),   quat(-20,0,8),   quat(-30,0,15),  quat(0,0,8)]),
  ])
}

// ── BLOCK ───────────────────────────────────────────────────────────
function blockClip() {
  return new THREE.AnimationClip('block', 0.8, [
    makePosTrack('Hips',   [0,.25,.8], [V3(0,1.02,0),V3(0,0.84,0),V3(0,0.84,0)]),
    makeTrack('L_UpperArm',[0,.25,.8], [quat(0,0,-8),  quat(-70,0,-30), quat(-70,0,-30)]),
    makeTrack('R_UpperArm',[0,.25,.8], [quat(0,0,8),   quat(-70,0,30),  quat(-70,0,30)]),
    makeTrack('L_ForeArm', [0,.25,.8], [quat(80,0,0),  quat(85,0,0),    quat(85,0,0)]),
    makeTrack('R_ForeArm', [0,.25,.8], [quat(80,0,0),  quat(85,0,0),    quat(85,0,0)]),
    makeTrack('Head',      [0,.25,.8], [Q0, quat(-15,0,0), quat(-15,0,0)]),
    makeTrack('Spine',     [0,.25,.8], [Q0, quat(22,0,0),  quat(22,0,0)]),
    makeTrack('L_Thigh',   [0,.25,.8], [Q0, quat(25,0,5),  quat(25,0,5)]),
    makeTrack('R_Thigh',   [0,.25,.8], [Q0, quat(25,0,-5), quat(25,0,-5)]),
    makeTrack('L_Shin',    [0,.25,.8], [Q0, quat(-5,0,0),  quat(-5,0,0)]),
    makeTrack('R_Shin',    [0,.25,.8], [Q0, quat(-5,0,0),  quat(-5,0,0)]),
  ])
}

// ── STRAFE ──────────────────────────────────────────────────────────
function strafeClip() {
  return new THREE.AnimationClip('strafe', 1.0, [
    makePosTrack('Hips',   [0,.5,1.0], [V3(0,1.02,0),V3(0,1.0,0),V3(0,1.02,0)]),
    makeTrack('L_Thigh',   [0,.25,.5,.75,1.0], [quat(0,15,0),quat(15,0,0),quat(0,-15,0),quat(-10,0,0),quat(0,15,0)]),
    makeTrack('R_Thigh',   [0,.25,.5,.75,1.0], [quat(-10,0,0),quat(0,-15,0),quat(15,0,0),quat(15,0,0),quat(-10,0,0)]),
    makeTrack('L_Shin',    [0,.5,1.0], [quat(5,0,0), quat(20,0,0),quat(5,0,0)]),
    makeTrack('R_Shin',    [0,.5,1.0], [quat(20,0,0),quat(5,0,0), quat(20,0,0)]),
    makeTrack('Spine',     [0,.5,1.0], [quat(0,8,0), quat(0,-8,0),quat(0,8,0)]),
    makeTrack('L_UpperArm',[0,.5,1.0], [quat(-30,0,-15),quat(-20,0,-15),quat(-30,0,-15)]),
    makeTrack('R_UpperArm',[0,.5,1.0], [quat(-30,0,15), quat(-20,0,15), quat(-30,0,15)]),
  ])
}

// ── SWIM ────────────────────────────────────────────────────────────
function swimClip() {
  return new THREE.AnimationClip('swim', 2.0, [
    makeTrack('Spine',     [0,1.0,2.0], [quat(-10,0,0),  quat(-5,0,0),   quat(-10,0,0)]),
    makeTrack('Head',      [0,1.0,2.0], [quat(-5,0,0),   quat(-18,0,0),  quat(-5,0,0)]),
    makeTrack('L_UpperArm',[0,.5,1.0,1.5,2.0], [quat(-90,0,-45),quat(-45,0,-60),quat(-170,0,-30),quat(-110,0,-40),quat(-90,0,-45)]),
    makeTrack('R_UpperArm',[0,.5,1.0,1.5,2.0], [quat(-90,0,45), quat(-45,0,60), quat(-170,0,30), quat(-110,0,40), quat(-90,0,45)]),
    makeTrack('L_ForeArm', [0,.5,1.5,2.0], [quat(0,0,0), quat(-30,0,0), quat(60,0,0), quat(0,0,0)]),
    makeTrack('R_ForeArm', [0,.5,1.5,2.0], [quat(0,0,0), quat(-30,0,0), quat(60,0,0), quat(0,0,0)]),
    makeTrack('L_Thigh',   [0,1.0,2.0], [quat(-10,0,-15),quat(18,0,-10), quat(-10,0,-15)]),
    makeTrack('R_Thigh',   [0,1.0,2.0], [quat(-10,0,15), quat(18,0,10),  quat(-10,0,15)]),
    makeTrack('L_Shin',    [0,1.0,2.0], [quat(20,0,0), quat(5,0,0), quat(20,0,0)]),
    makeTrack('R_Shin',    [0,1.0,2.0], [quat(20,0,0), quat(5,0,0), quat(20,0,0)]),
  ])
}

// ── FLY ─────────────────────────────────────────────────────────────
function flyClip() {
  return new THREE.AnimationClip('fly', 2.0, [
    makePosTrack('Hips',   [0,1.0,2.0], [V3(0,1.02,0),V3(0,1.04,0),V3(0,1.02,0)]),
    makeTrack('Spine',     [0,1.0,2.0], [quat(-22,0,0),  quat(-17,0,0),  quat(-22,0,0)]),
    makeTrack('Head',      [0,1.0,2.0], [quat(-18,0,0),  quat(-14,0,0),  quat(-18,0,0)]),
    makeTrack('L_UpperArm',[0,1.0,2.0], [quat(-162,0,-18),quat(-167,0,-16),quat(-162,0,-18)]),
    makeTrack('R_UpperArm',[0,1.0,2.0], [quat(-162,0,18), quat(-167,0,16), quat(-162,0,18)]),
    makeTrack('L_ForeArm', [0,1.0,2.0], [quat(4,0,0),    quat(2,0,0),    quat(4,0,0)]),
    makeTrack('R_ForeArm', [0,1.0,2.0], [quat(4,0,0),    quat(2,0,0),    quat(4,0,0)]),
    makeTrack('L_Thigh',   [0,1.0,2.0], [quat(-5,0,-8),  quat(-3,0,-8),  quat(-5,0,-8)]),
    makeTrack('R_Thigh',   [0,1.0,2.0], [quat(-5,0,8),   quat(-3,0,8),   quat(-5,0,8)]),
    makeTrack('L_Shin',    [0,1.0,2.0], [quat(5,0,0),    quat(3,0,0),    quat(5,0,0)]),
    makeTrack('R_Shin',    [0,1.0,2.0], [quat(5,0,0),    quat(3,0,0),    quat(5,0,0)]),
  ])
}

// ── FALL ────────────────────────────────────────────────────────────
function fallClip() {
  return new THREE.AnimationClip('fall', 1.2, [
    makePosTrack('Hips',   [0,.5,1.2], [V3(0,1.02,0),V3(0,1.55,0),V3(0,1.55,0)]),
    makeTrack('Spine',     [0,.5,1.2], [Q0, quat(-22,0,0), quat(-20,0,0)]),
    makeTrack('Head',      [0,.5,1.2], [Q0, quat(18,0,0),  quat(15,0,0)]),
    makeTrack('L_UpperArm',[0,.5,1.2], [quat(-50,0,-40), quat(-80,0,-50), quat(-80,0,-50)]),
    makeTrack('R_UpperArm',[0,.5,1.2], [quat(-50,0,40),  quat(-80,0,50),  quat(-80,0,50)]),
    makeTrack('L_ForeArm', [0,.5,1.2], [quat(20,0,0), quat(40,0,0), quat(40,0,0)]),
    makeTrack('R_ForeArm', [0,.5,1.2], [quat(20,0,0), quat(40,0,0), quat(40,0,0)]),
    makeTrack('L_Thigh',   [0,.5,1.2], [quat(30,0,-10), quat(20,0,-10), quat(20,0,-10)]),
    makeTrack('R_Thigh',   [0,.5,1.2], [quat(30,0,10),  quat(20,0,10),  quat(20,0,10)]),
    makeTrack('L_Shin',    [0,.5,1.2], [quat(-20,0,0),quat(-30,0,0),quat(-30,0,0)]),
    makeTrack('R_Shin',    [0,.5,1.2], [quat(-20,0,0),quat(-30,0,0),quat(-30,0,0)]),
  ])
}

// ── EMOTE ───────────────────────────────────────────────────────────
function emoteClip() {
  return new THREE.AnimationClip('emote', 2.0, [
    makePosTrack('Hips', [0,.5,1,1.5,2], [V3(0,1.0,0),V3(0,1.07,0),V3(0,1.0,0),V3(0,1.07,0),V3(0,1.0,0)]),
    makeTrack('L_UpperArm',[0,.25,.5,.75,1,1.25,1.5,1.75,2],
      [quat(-160,0,-30),quat(-160,12,-30),quat(-160,-12,-30),quat(-160,12,-30),quat(-160,-12,-30),quat(-160,12,-30),quat(-160,-12,-30),quat(-160,12,-30),quat(-160,0,-30)]),
    makeTrack('R_UpperArm',[0,.25,.5,.75,1,1.25,1.5,1.75,2],
      [quat(-160,0,30),quat(-160,-12,30),quat(-160,12,30),quat(-160,-12,30),quat(-160,12,30),quat(-160,-12,30),quat(-160,12,30),quat(-160,-12,30),quat(-160,0,30)]),
    makeTrack('L_ForeArm', [0,1,2], [quat(25,0,0),quat(35,0,0),quat(25,0,0)]),
    makeTrack('R_ForeArm', [0,1,2], [quat(25,0,0),quat(35,0,0),quat(25,0,0)]),
    makeTrack('Head',      [0,.5,1,1.5,2], [quat(10,18,0),quat(10,-18,0),quat(10,18,0),quat(10,-18,0),quat(10,18,0)]),
    makeTrack('Spine',     [0,.5,1,1.5,2], [quat(-5,8,0), quat(-5,-8,0), quat(-5,8,0), quat(-5,-8,0), quat(-5,8,0)]),
    makeTrack('L_Thigh',   [0,.5,1,1.5,2], [Q0,quat(-8,0,0),Q0,quat(-8,0,0),Q0]),
    makeTrack('R_Thigh',   [0,.5,1,1.5,2], [Q0,quat(-8,0,0),Q0,quat(-8,0,0),Q0]),
  ])
}

// ── CROUCH WALK ─────────────────────────────────────────────────────
function crouchWalkClip() {
  return new THREE.AnimationClip('crouch_walk', 1.0, [
    makePosTrack('Hips',   [0,.5,1.0], [V3(0,0.62,0),V3(0,0.58,0),V3(0,0.62,0)]),
    makeTrack('Spine',     [0,.5,1.0], [quat(25,5,0),  quat(25,-5,0),  quat(25,5,0)]),
    makeTrack('L_Thigh',   [0,.5,1.0], [quat(60,0,0),  quat(90,0,0),   quat(60,0,0)]),
    makeTrack('R_Thigh',   [0,.5,1.0], [quat(90,0,0),  quat(60,0,0),   quat(90,0,0)]),
    makeTrack('L_Shin',    [0,.5,1.0], [quat(-55,0,0), quat(-80,0,0),  quat(-55,0,0)]),
    makeTrack('R_Shin',    [0,.5,1.0], [quat(-80,0,0), quat(-55,0,0),  quat(-80,0,0)]),
    makeTrack('L_UpperArm',[0,.5,1.0], [quat(30,0,-15),quat(-20,0,-15),quat(30,0,-15)]),
    makeTrack('R_UpperArm',[0,.5,1.0], [quat(-20,0,15),quat(30,0,15),  quat(-20,0,15)]),
  ])
}

export const CLIPS = {
  idle:        idleClip(),
  walk:        walkClip(),
  run:         runClip(),
  jump:        jumpClip(),
  wave:        waveClip(),
  punch:       punchClip(),
  dance:       danceClip(),
  crouch:      crouchClip(),
  aim:         aimClip(),
  kick:        kickClip(),
  block:       blockClip(),
  strafe:      strafeClip(),
  swim:        swimClip(),
  fly:         flyClip(),
  fall:        fallClip(),
  emote:       emoteClip(),
  crouch_walk: crouchWalkClip(),
}

export const ANIM_LIST = [
  { id: 'idle',        label: 'Idle',         icon: '🧍', cat: 'Basic'   },
  { id: 'walk',        label: 'Walk',          icon: '🚶', cat: 'Basic'   },
  { id: 'run',         label: 'Run',           icon: '🏃', cat: 'Basic'   },
  { id: 'jump',        label: 'Jump',          icon: '🦘', cat: 'Basic'   },
  { id: 'crouch',      label: 'Crouch',        icon: '🫛', cat: 'Basic'   },
  { id: 'crouch_walk', label: 'Crouch Walk',   icon: '🐾', cat: 'Basic'   },
  { id: 'strafe',      label: 'Strafe',        icon: '↔️', cat: 'Combat'  },
  { id: 'aim',         label: 'Aim',           icon: '🎯', cat: 'Combat'  },
  { id: 'punch',       label: 'Punch',         icon: '👊', cat: 'Combat'  },
  { id: 'kick',        label: 'Kick',          icon: '🦵', cat: 'Combat'  },
  { id: 'block',       label: 'Block',         icon: '🛡️', cat: 'Combat'  },
  { id: 'fall',        label: 'Fall',          icon: '🍂', cat: 'Action'  },
  { id: 'swim',        label: 'Swim',          icon: '🏊', cat: 'Action'  },
  { id: 'fly',         label: 'Fly',           icon: '🦅', cat: 'Action'  },
  { id: 'wave',        label: 'Wave',          icon: '👋', cat: 'Emote'   },
  { id: 'dance',       label: 'Dance',         icon: '💃', cat: 'Emote'   },
  { id: 'emote',       label: 'Celebrate',     icon: '🎉', cat: 'Emote'   },
]
