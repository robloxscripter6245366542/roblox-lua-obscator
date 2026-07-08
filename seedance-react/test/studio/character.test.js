import { describe, it, expect } from 'vitest'
import * as THREE from 'three'
import { buildSkeleton, makeMaterials, BONE_DISPLAY_NAMES } from '../../src/studio/character.js'

describe('studio/character', () => {
  describe('buildSkeleton', () => {
    const bones = buildSkeleton()

    it('creates the full named bone set', () => {
      const expected = [
        'root', 'hips', 'spine', 'chest', 'neck', 'head',
        'lShoulder', 'lUpperArm', 'lForeArm', 'lHand',
        'rShoulder', 'rUpperArm', 'rForeArm', 'rHand',
        'lThigh', 'lShin', 'lFoot', 'rThigh', 'rShin', 'rFoot',
      ]
      for (const key of expected) {
        expect(bones[key], key).toBeInstanceOf(THREE.Bone)
      }
    })

    it('parents the hierarchy under root (hips -> spine -> chest -> neck -> head)', () => {
      expect(bones.root.children).toContain(bones.hips)
      expect(bones.hips.children).toContain(bones.spine)
      expect(bones.spine.children).toContain(bones.chest)
      expect(bones.chest.children).toContain(bones.neck)
      expect(bones.neck.children).toContain(bones.head)
    })

    it('attaches both arm chains to the chest', () => {
      expect(bones.chest.children).toContain(bones.lShoulder)
      expect(bones.chest.children).toContain(bones.rShoulder)
      expect(bones.lShoulder.children).toContain(bones.lUpperArm)
      expect(bones.lUpperArm.children).toContain(bones.lForeArm)
      expect(bones.lForeArm.children).toContain(bones.lHand)
    })

    it('attaches both leg chains to the hips', () => {
      expect(bones.hips.children).toContain(bones.lThigh)
      expect(bones.hips.children).toContain(bones.rThigh)
      expect(bones.lThigh.children).toContain(bones.lShin)
      expect(bones.lShin.children).toContain(bones.lFoot)
    })

    it('mirrors left/right limb positions on the X axis', () => {
      expect(bones.lShoulder.position.x).toBeCloseTo(-bones.rShoulder.position.x)
      expect(bones.lThigh.position.x).toBeCloseTo(-bones.rThigh.position.x)
    })
  })

  describe('makeMaterials', () => {
    it('returns the full material palette', () => {
      const mats = makeMaterials()
      const keys = ['skin', 'cloth', 'dark', 'hair', 'eye', 'iris', 'pupil', 'eyeHL', 'shoe', 'shoeSole', 'accent', 'white', 'lip']
      for (const k of keys) {
        expect(mats[k], k).toBeInstanceOf(THREE.Material)
      }
    })

    it('applies the provided skin and cloth colors', () => {
      const mats = makeMaterials('#ff0000', '#00ff00')
      expect(mats.skin.color.getHexString()).toBe('ff0000')
      expect(mats.cloth.color.getHexString()).toBe('00ff00')
    })
  })

  it('BONE_DISPLAY_NAMES covers every non-root skeleton bone', () => {
    const bones = buildSkeleton()
    const skeletonKeys = Object.keys(bones).filter(k => k !== 'root')
    for (const key of skeletonKeys) {
      expect(BONE_DISPLAY_NAMES, key).toHaveProperty(key)
    }
  })
})
