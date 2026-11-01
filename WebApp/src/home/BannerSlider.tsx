import { useQuery } from '@tanstack/react-query'
import { useCallback, useEffect, useRef, useState } from 'react'
import { useI18n } from '../i18n/I18nProvider'
import { resolveMediaUrl } from '../lib/media'
import { fetchBanners } from '../products/productsApi'
import { Icon } from '../ui/Icon'

type Slide = { id: number | string; image: string; link?: string | null }

const FALLBACK: Slide[] = [
  { id: -1, image: '/assets/images/bunner.png' },
  { id: -2, image: '/assets/images/bunner2.png' },
]

function BannerImage({ src }: { src: string }) {
  const [failed, setFailed] = useState(false)
  return (
    <img
      src={failed ? '/assets/images/bunner2.png' : src}
      onError={() => setFailed(true)}
      alt=""
      draggable={false}
      className="size-full object-cover"
    />
  )
}

/**
 * Autoplaying carousel. Phones show ~80% of a slide with neighbours peeking
 * (like the app); wider screens show 2–3 slides side by side.
 */
export function BannerSlider() {
  const { isAr } = useI18n()
  const { data, isPending, isError } = useQuery({ queryKey: ['banners'], queryFn: fetchBanners, staleTime: 10 * 60_000 })
  const trackRef = useRef<HTMLDivElement>(null)
  const [index, setIndex] = useState(0)
  const [paused, setPaused] = useState(false)

  const apiSlides: Slide[] = (data?.items ?? [])
    .slice()
    .sort((a, b) => (a.displayOrder ?? 0) - (b.displayOrder ?? 0))
    .map((b) => ({ id: b.id, image: resolveMediaUrl(b.imagePath), link: b.linkUrl }))
    .filter((s) => s.image)
  const slides = isError || (!isPending && apiSlides.length === 0) ? FALLBACK : apiSlides

  const scrollToIndex = useCallback((i: number) => {
    const track = trackRef.current
    const child = track?.children[i] as HTMLElement | undefined
    if (!track || !child) return
    const trackRect = track.getBoundingClientRect()
    const childRect = child.getBoundingClientRect()
    const offset = childRect.left - trackRect.left - (trackRect.width - childRect.width) / 2
    track.scrollBy({ left: offset, behavior: 'smooth' })
  }, [])

  useEffect(() => {
    if (paused || slides.length < 2) return
    const id = window.setInterval(() => {
      setIndex((current) => {
        const next = (current + 1) % slides.length
        scrollToIndex(next)
        return next
      })
    }, 3000)
    return () => window.clearInterval(id)
  }, [paused, slides.length, scrollToIndex])

  const onScroll = () => {
    const track = trackRef.current
    if (!track) return
    const center = track.getBoundingClientRect().left + track.clientWidth / 2
    let best = 0
    let bestDistance = Infinity
    Array.from(track.children).forEach((child, i) => {
      const rect = child.getBoundingClientRect()
      const distance = Math.abs(rect.left + rect.width / 2 - center)
      if (distance < bestDistance) {
        bestDistance = distance
        best = i
      }
    })
    setIndex(best)
  }

  if (isPending) {
    return (
      <div className="flex gap-2.5 overflow-hidden px-[10%] sm:px-6">
        <div className="shimmer h-[136px] w-full shrink-0 rounded-[18px] sm:h-[180px] sm:w-1/2 lg:h-[220px] lg:w-1/3" />
        <div className="shimmer hidden h-[180px] w-1/2 shrink-0 rounded-[18px] sm:block lg:h-[220px] lg:w-1/3" />
        <div className="shimmer hidden h-[220px] w-1/3 shrink-0 rounded-[18px] lg:block" />
      </div>
    )
  }

  const step = (dir: 1 | -1) => {
    const next = (index + dir + slides.length) % slides.length
    setIndex(next)
    scrollToIndex(next)
  }

  return (
    <div className="group relative" onMouseEnter={() => setPaused(true)} onMouseLeave={() => setPaused(false)} onTouchStart={() => setPaused(true)} onTouchEnd={() => setPaused(false)}>
      <div
        ref={trackRef}
        onScroll={onScroll}
        className="no-scrollbar flex snap-x snap-mandatory gap-2.5 overflow-x-auto scroll-smooth px-[10%] sm:gap-4 sm:px-6 2xl:px-10"
      >
        {slides.map((slide) => {
          const content = <BannerImage src={slide.image} />
          const cls = 'block h-[136px] w-[80vw] shrink-0 snap-center overflow-hidden rounded-[18px] bg-[#dfe8f5] sm:h-[180px] sm:w-[calc(50%-8px)] lg:h-[220px] lg:w-[calc(33.333%-11px)]'
          return slide.link ? (
            <a key={slide.id} href={slide.link} target="_blank" rel="noopener noreferrer" className={cls}>
              {content}
            </a>
          ) : (
            <div key={slide.id} className={cls}>
              {content}
            </div>
          )
        })}
      </div>
      {slides.length > 1 && (
        <>
          <button
            type="button"
            onClick={() => step(isAr ? 1 : -1)}
            className="absolute start-3 top-1/2 hidden size-10 -translate-y-1/2 place-items-center rounded-full bg-white/90 text-title opacity-0 shadow-md transition group-hover:opacity-100 lg:grid"
            aria-label="Previous"
          >
            <Icon name={isAr ? 'chevronRight' : 'chevronLeft'} size={22} />
          </button>
          <button
            type="button"
            onClick={() => step(isAr ? -1 : 1)}
            className="absolute end-3 top-1/2 hidden size-10 -translate-y-1/2 place-items-center rounded-full bg-white/90 text-title opacity-0 shadow-md transition group-hover:opacity-100 lg:grid"
            aria-label="Next"
          >
            <Icon name={isAr ? 'chevronLeft' : 'chevronRight'} size={22} />
          </button>
          <div className="mt-2.5 flex justify-center gap-1.5">
            {slides.map((slide, i) => (
              <button
                key={slide.id}
                type="button"
                onClick={() => {
                  setIndex(i)
                  scrollToIndex(i)
                }}
                className={`h-1.5 rounded-full transition-all ${i === index ? 'w-5 bg-brand' : 'w-1.5 bg-[#C9D6E8]'}`}
                aria-label={`Slide ${i + 1}`}
              />
            ))}
          </div>
        </>
      )}
    </div>
  )
}
