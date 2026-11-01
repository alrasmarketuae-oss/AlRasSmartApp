import { useCallback, useEffect, useRef, useState, type PointerEvent } from 'react'
import { createPortal } from 'react-dom'
import { useI18n } from '../../i18n/I18nProvider'
import { Icon } from '../../ui/Icon'
import type { MediaItem } from '../productRules'
import { VideoFrame } from '../VideoFrame'

export function HeroThumbnail({ media, soldOut, onOpen, className = '' }: { media: MediaItem[]; soldOut: boolean; onOpen: (index: number) => void; className?: string }) {
  const { t } = useI18n()
  const first = media.find((m) => m.kind === 'image') ?? media[0]
  const hasVideo = media.some((m) => m.kind === 'video')
  return (
    <button
      type="button"
      onClick={() => media.length && onOpen(first ? media.indexOf(first) : 0)}
      className={`relative shrink-0 overflow-hidden rounded-[14px] border border-line bg-[#F2F5F9] ${className}`}
    >
      {!first ? (
        <img src="/assets/images/bunner2.png" alt="" className="size-full object-cover" />
      ) : first.kind === 'image' ? (
        <img src={first.url} alt="" className="size-full object-cover" />
      ) : (
        <VideoFrame src={first.url} className="size-full object-cover" fallback={<img src="/assets/images/bunner2.png" alt="" className="size-full object-cover" />} />
      )}
      {hasVideo && (
        <span className="absolute inset-0 grid place-items-center">
          <span className="grid size-10 place-items-center rounded-full bg-black/45 text-white">
            <Icon name="play" size={18} />
          </span>
        </span>
      )}
      {media.length > 0 && (
        <span className="absolute bottom-1.5 start-1.5 rounded-md bg-black/60 px-1.5 py-0.5 text-[10px] font-semibold text-white sm:text-xs">
          {t('photosCount', { count: media.length })}
        </span>
      )}
      {soldOut && (
        <span className="pointer-events-none absolute inset-0 grid place-items-center bg-white/25">
          <img src="/assets/images/sold_out_stamp.png" alt="" className="w-4/5 -rotate-12" />
        </span>
      )}
    </button>
  )
}

/** Fullscreen preview: looping list, i/N counter, keyboard + swipe, wheel/double-click zoom for images. */
export function MediaPreview({ media, index, onClose }: { media: MediaItem[]; index: number; onClose: () => void }) {
  const [current, setCurrent] = useState(index)
  const [zoom, setZoom] = useState(1)
  const [offset, setOffset] = useState({ x: 0, y: 0 })
  const drag = useRef<{ x: number; y: number; ox: number; oy: number; moved: boolean } | null>(null)
  const count = media.length
  const item = media[current]

  const go = useCallback(
    (delta: number) => {
      if (count < 2) return
      setCurrent((c) => (c + delta + count) % count)
      setZoom(1)
      setOffset({ x: 0, y: 0 })
    },
    [count],
  )

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
      if (e.key === 'ArrowRight') go(1)
      if (e.key === 'ArrowLeft') go(-1)
    }
    const overflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    window.addEventListener('keydown', onKey)
    return () => {
      document.body.style.overflow = overflow
      window.removeEventListener('keydown', onKey)
    }
  }, [go, onClose])

  if (!item) return null

  const onPointerDown = (e: PointerEvent) => {
    drag.current = { x: e.clientX, y: e.clientY, ox: offset.x, oy: offset.y, moved: false }
  }
  const onPointerMove = (e: PointerEvent) => {
    const d = drag.current
    if (!d) return
    const dx = e.clientX - d.x
    const dy = e.clientY - d.y
    if (Math.abs(dx) + Math.abs(dy) > 6) d.moved = true
    if (zoom > 1) setOffset({ x: d.ox + dx, y: d.oy + dy })
  }
  const onPointerUp = (e: PointerEvent) => {
    const d = drag.current
    drag.current = null
    if (!d || zoom > 1 || item.kind === 'video') return
    const dx = e.clientX - d.x
    const dy = e.clientY - d.y
    if (dy > 120 && Math.abs(dy) > Math.abs(dx)) onClose()
    else if (Math.abs(dx) > 60) go(dx < 0 ? 1 : -1)
  }

  return createPortal(
    <div dir="ltr" className="fixed inset-0 z-[90] flex select-none flex-col bg-black text-white" role="dialog" aria-modal="true">
      <div className="flex h-14 shrink-0 items-center justify-between px-3">
        <button type="button" onClick={onClose} aria-label="Close" className="grid size-10 place-items-center rounded-full hover:bg-white/10">
          <Icon name="close" size={24} />
        </button>
        {count > 1 && (
          <span className="rounded-full bg-white/15 px-3 py-1 text-sm font-semibold">
            {current + 1}/{count}
          </span>
        )}
      </div>
      <div
        className="relative flex min-h-0 flex-1 items-center justify-center overflow-hidden"
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onWheel={(e) => {
          if (item.kind !== 'image') return
          const next = Math.min(4, Math.max(1, zoom - e.deltaY * 0.002))
          setZoom(next)
          if (next === 1) setOffset({ x: 0, y: 0 })
        }}
        style={{ touchAction: zoom > 1 ? 'none' : 'pan-y' }}
      >
        {item.kind === 'image' ? (
          <img
            key={item.url}
            src={item.url}
            alt=""
            draggable={false}
            onDoubleClick={() => {
              setZoom((z) => (z > 1 ? 1 : 2.5))
              setOffset({ x: 0, y: 0 })
            }}
            className="max-h-full max-w-full object-contain transition-transform duration-75"
            style={{ transform: `translate(${offset.x}px, ${offset.y}px) scale(${zoom})`, cursor: zoom > 1 ? 'grab' : 'zoom-in' }}
          />
        ) : (
          <video key={item.url} src={item.url} autoPlay loop playsInline controls muted={item.muted} className="max-h-full max-w-full" />
        )}
        {count > 1 && (
          <>
            <button type="button" onClick={() => go(-1)} aria-label="Previous" className="absolute left-2 top-1/2 grid size-11 -translate-y-1/2 place-items-center rounded-full bg-white/15 hover:bg-white/25">
              <Icon name="chevronLeft" size={26} />
            </button>
            <button type="button" onClick={() => go(1)} aria-label="Next" className="absolute right-2 top-1/2 grid size-11 -translate-y-1/2 place-items-center rounded-full bg-white/15 hover:bg-white/25">
              <Icon name="chevronRight" size={26} />
            </button>
          </>
        )}
      </div>
      {count > 1 && (
        <div className="no-scrollbar flex shrink-0 justify-center gap-2 overflow-x-auto p-3">
          {media.map((m, i) => (
            <button
              key={`${m.url}-${i}`}
              type="button"
              onClick={() => {
                setCurrent(i)
                setZoom(1)
                setOffset({ x: 0, y: 0 })
              }}
              className={`relative size-14 shrink-0 overflow-hidden rounded-lg border-2 ${i === current ? 'border-white' : 'border-transparent opacity-60'}`}
            >
              {m.kind === 'image' ? (
                <img src={m.url} alt="" className="size-full object-cover" />
              ) : (
                <span className="relative grid size-full place-items-center bg-white/10">
                  <VideoFrame src={m.url} className="absolute inset-0 size-full object-cover" />
                  <Icon name="play" size={18} className="relative drop-shadow" />
                </span>
              )}
            </button>
          ))}
        </div>
      )}
    </div>,
    document.body,
  )
}
