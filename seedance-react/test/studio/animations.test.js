import { describe, it, expect } from 'vitest'
import * as THREE from 'three'
import { CLIPS, ANIM_LIST } from '../../src/studio/animations.js'

describe('studio/animations', () => {
  it('exposes a clip for every animation listed in ANIM_LIST', () => {
    for (const anim of ANIM_LIST) {
      expect(CLIPS, `missing clip for "${anim.id}"`).toHaveProperty(anim.id)
    }
  })

  it('every ANIM_LIST entry has the required display fields', () => {
    for (const anim of ANIM_LIST) {
      expect(anim.id).toBeTypeOf('string')
      expect(anim.label).toBeTypeOf('string')
      expect(anim.icon).toBeTypeOf('string')
      expect(['Basic', 'Combat', 'Action', 'Emote']).toContain(anim.cat)
    }
  })

  it('has unique animation ids', () => {
    const ids = ANIM_LIST.map(a => a.id)
    expect(new Set(ids).size).toBe(ids.length)
  })

  it('builds valid THREE.AnimationClip instances with positive duration', () => {
    for (const [name, clip] of Object.entries(CLIPS)) {
      expect(clip, name).toBeInstanceOf(THREE.AnimationClip)
      expect(clip.name).toBe(name)
      expect(clip.duration, `${name} duration`).toBeGreaterThan(0)
      expect(clip.tracks.length, `${name} tracks`).toBeGreaterThan(0)
    }
  })

  it('produces keyframe tracks that target real bone properties', () => {
    for (const [name, clip] of Object.entries(CLIPS)) {
      for (const track of clip.tracks) {
        expect(track.name, `${name}: ${track.name}`).toMatch(/\.(quaternion|position)$/)
        // times must be monotonically non-decreasing
        for (let i = 1; i < track.times.length; i++) {
          expect(track.times[i]).toBeGreaterThanOrEqual(track.times[i - 1])
        }
      }
    }
  })
})
