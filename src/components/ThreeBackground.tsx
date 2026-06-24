import { useEffect, useRef } from 'react'
import * as THREE from 'three'

export default function ThreeBackground() {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return

    const scene = new THREE.Scene()
    const cam = new THREE.PerspectiveCamera(70, innerWidth / innerHeight, 1, 3000)
    const renderer = new THREE.WebGLRenderer({ canvas, alpha: true, antialias: true })
    renderer.setSize(innerWidth, innerHeight)
    renderer.setPixelRatio(Math.min(devicePixelRatio, 2))
    cam.position.z = 400

    // Stars
    const N = 5000
    const pos = new Float32Array(N * 3)
    const col = new Float32Array(N * 3)
    for (let i = 0; i < N; i++) {
      const i3 = i * 3
      pos[i3] = (Math.random() - .5) * 3000
      pos[i3 + 1] = (Math.random() - .5) * 3000
      pos[i3 + 2] = (Math.random() - .5) * 3000
      const t = Math.random()
      col[i3] = t * .5; col[i3 + 1] = (1 - t) * .8; col[i3 + 2] = 1
    }
    const sg = new THREE.BufferGeometry()
    sg.setAttribute('position', new THREE.BufferAttribute(pos, 3))
    sg.setAttribute('color', new THREE.BufferAttribute(col, 3))
    scene.add(new THREE.Points(sg, new THREE.PointsMaterial({ size: 1.2, vertexColors: true, transparent: true, opacity: .7 })))

    // Floating wireframe shapes
    const shapes: THREE.Mesh[] = []
    ;([
      [new THREE.IcosahedronGeometry(30, 0), 0x7c3aed, -180, 90, -350],
      [new THREE.OctahedronGeometry(24, 0), 0x06b6d4, 220, -120, -420],
      [new THREE.TetrahedronGeometry(34, 0), 0xec4899, -230, -160, -480],
      [new THREE.IcosahedronGeometry(20, 0), 0x10b981, 300, 80, -300],
      [new THREE.TorusGeometry(22, 6, 4, 6), 0xf59e0b, -80, -200, -380],
    ] as [THREE.BufferGeometry, number, number, number, number][]).forEach(([geo, color, x, y, z]) => {
      const m = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({ color, wireframe: true, transparent: true, opacity: .1 }))
      m.position.set(x, y, z)
      scene.add(m)
      shapes.push(m)
    })

    let mx = 0, my = 0, tx = 0, ty = 0, t = 0
    const onMouse = (e: MouseEvent) => { mx = (e.clientX / innerWidth - .5) * 80; my = -(e.clientY / innerHeight - .5) * 80 }
    const onResize = () => { cam.aspect = innerWidth / innerHeight; cam.updateProjectionMatrix(); renderer.setSize(innerWidth, innerHeight) }
    window.addEventListener('mousemove', onMouse)
    window.addEventListener('resize', onResize)

    let raf: number
    const loop = () => {
      raf = requestAnimationFrame(loop)
      t += .004; tx += (mx - tx) * .025; ty += (my - ty) * .025
      cam.position.x = tx * .25; cam.position.y = ty * .25; cam.lookAt(0, 0, 0)
      shapes.forEach((s, i) => { s.rotation.x = t * (.15 + i * .04); s.rotation.y = t * (.22 + i * .03) })
      scene.rotation.y = t * .012
      renderer.render(scene, cam)
    }
    loop()

    return () => {
      cancelAnimationFrame(raf)
      window.removeEventListener('mousemove', onMouse)
      window.removeEventListener('resize', onResize)
      renderer.dispose()
    }
  }, [])

  return <canvas ref={canvasRef} style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none' }} />
}
