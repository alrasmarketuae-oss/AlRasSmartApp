import { useEffect, useRef, useState } from 'react'

const FRAME_COUNT = 11
/** User must scroll through this track to finish every frame before page content. */
const SCROLL_SVH = 240

function frameSrc(index) {
  const n = String(Math.min(FRAME_COUNT, Math.max(1, index + 1))).padStart(3, '0')
  return `/hero/frames/frame-${n}.jpg`
}

const FRAMES = Array.from({ length: FRAME_COUNT }, (_, i) => frameSrc(i))

/**
 * Scroll-driven intro. Every frame is decoded before the animation starts and
 * stays mounted, so switching frames is an opacity toggle with no black gap.
 */
export default function HeroScrollFrames({ lang }) {
  const isAr = lang === 'ar'
  const sectionRef = useRef(null)
  const stickyRef = useRef(null)
  const barRef = useRef(null)
  const layersRef = useRef(/** @type {(HTMLImageElement | null)[]} */ ([]))
  const frameIndexRef = useRef(0)
  const rafRef = useRef(0)
  const [ready, setReady] = useState(false)

  useEffect(() => {
    let cancelled = false

    Promise.all(FRAMES.map(decodeImage)).then(() => {
      if (!cancelled) setReady(true)
    })

    return () => {
      cancelled = true
    }
  }, [])

  useEffect(() => {
    const section = sectionRef.current
    if (!section || !ready) return undefined

    const paint = (index) => {
      layersRef.current.forEach((layer, i) => {
        if (layer) layer.style.opacity = i === index ? '1' : '0'
      })
    }

    // Hold on frame 0 until the user actually scrolls.
    paint(0)
    frameIndexRef.current = 0
    if (barRef.current) barRef.current.style.transform = 'scaleX(0)'

    const onScroll = () => {
      if (rafRef.current) return
      rafRef.current = window.requestAnimationFrame(() => {
        rafRef.current = 0
        const stickyHeight = stickyRef.current?.offsetHeight ?? window.innerHeight
        const total = Math.max(1, section.offsetHeight - stickyHeight)
        const raw = -section.getBoundingClientRect().top / total
        // Ignore tiny scroll jitter at the top so frame 0 stays stable on first render.
        const p = raw < 0.02 ? 0 : Math.min(1, Math.max(0, raw))
        const idx = Math.min(FRAME_COUNT - 1, Math.round(p * (FRAME_COUNT - 1)))

        if (idx !== frameIndexRef.current) {
          frameIndexRef.current = idx
          paint(idx)
        }
        if (barRef.current) {
          barRef.current.style.transform = `scaleX(${p})`
        }
      })
    }

    window.addEventListener('scroll', onScroll, { passive: true })
    window.addEventListener('resize', onScroll, { passive: true })
    return () => {
      window.removeEventListener('scroll', onScroll)
      window.removeEventListener('resize', onScroll)
      if (rafRef.current) window.cancelAnimationFrame(rafRef.current)
    }
  }, [ready])

  return (
    <section
      ref={sectionRef}
      className="relative bg-black"
      style={{ height: `${SCROLL_SVH}svh` }}
      aria-label={isAr ? 'مقدمة بالتمرير' : 'Scroll intro'}
    >
      <div ref={stickyRef} className="sticky top-0 h-[100svh] w-full overflow-hidden bg-black">
        {FRAMES.map((src, i) => (
          <img
            key={src}
            ref={(el) => {
              layersRef.current[i] = el
            }}
            src={src}
            alt=""
            width={720}
            height={406}
            decoding="async"
            fetchPriority={i === 0 ? 'high' : 'low'}
            draggable={false}
            style={{ opacity: i === 0 ? 1 : 0 }}
            className="absolute inset-0 h-full w-full select-none object-cover"
          />
        ))}

        <div
          className={`pointer-events-none absolute inset-0 z-20 flex items-center justify-center bg-black transition-opacity duration-500 ${
            ready ? 'opacity-0' : 'opacity-100'
          }`}
        >
          <span className="h-8 w-8 animate-spin rounded-full border-2 border-white/25 border-t-white/90" />
        </div>

        <div
          className={`pointer-events-none absolute inset-x-0 bottom-6 z-10 flex flex-col items-center gap-2 transition-opacity duration-500 ${
            ready ? 'opacity-100' : 'opacity-0'
          }`}
        >
          <div className="h-1 w-28 overflow-hidden rounded-full bg-white/25">
            <div
              ref={barRef}
              className="h-full w-full origin-left scale-x-0 rounded-full bg-white/90 will-change-transform"
            />
          </div>
          <span className="text-[11px] font-semibold tracking-wide text-white/75">
            {isAr ? 'اسحب للأسفل' : 'Scroll'}
          </span>
        </div>
      </div>
    </section>
  )
}

function decodeImage(src) {
  return new Promise((resolve) => {
    const img = new Image()
    img.decoding = 'async'
    const done = () => resolve(img)
    img.onload = () => (img.decode ? img.decode().then(done, done) : done())
    img.onerror = done
    img.src = src
  })
}
