import { useEffect, useMemo, useState } from 'react'
import { resolveAssetUrl } from '../../lib/assets'

export type GalleryMediaItem = {
  src: string
  kind: 'image' | 'video'
  id?: number
  path?: string
  isMuted?: boolean
}

type ImageGalleryProps = {
  /** @deprecated Prefer `media`. Kept for older call sites. */
  images?: string[]
  media?: GalleryMediaItem[]
  initialIndex?: number
  open: boolean
  onClose: () => void
  onMuteChange?: (item: GalleryMediaItem, muted: boolean) => void
  muteLabel?: string
  unmuteLabel?: string
  onBlur?: (item: GalleryMediaItem, index: number) => void
  onDelete?: (item: GalleryMediaItem, index: number) => void
  blurLabel?: string
  deleteLabel?: string
  canBlurCurrent?: boolean
  canDeleteCurrent?: boolean
}

function toMedia(images: string[] | undefined, media: GalleryMediaItem[] | undefined): GalleryMediaItem[] {
  if (media && media.length > 0) {
    return media.filter((item) => Boolean(item.src?.trim()))
  }
  return (images ?? [])
    .map((src) => src?.trim())
    .filter((src): src is string => Boolean(src))
    .map((src) => ({ src, kind: 'image' as const, path: src }))
}

export default function ImageGallery({
  images,
  media,
  initialIndex = 0,
  open,
  onClose,
  onMuteChange,
  muteLabel = 'Mute',
  unmuteLabel = 'Unmute',
  onBlur,
  onDelete,
  blurLabel = 'Blur',
  deleteLabel = 'Delete',
  canBlurCurrent,
  canDeleteCurrent,
}: ImageGalleryProps) {
  const items = useMemo(() => toMedia(images, media), [images, media])
  const [index, setIndex] = useState(0)
  const [localMuted, setLocalMuted] = useState(true)

  useEffect(() => {
    if (!open) return
    const next = Math.min(Math.max(initialIndex, 0), Math.max(items.length - 1, 0))
    setIndex(next)
  }, [open, initialIndex, items.length])

  useEffect(() => {
    if (!open) return
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        onClose()
        return
      }
      if (event.key === 'ArrowRight') {
        setIndex((current) => (current + 1) % Math.max(items.length, 1))
      }
      if (event.key === 'ArrowLeft') {
        setIndex(
          (current) =>
            (current - 1 + Math.max(items.length, 1)) % Math.max(items.length, 1),
        )
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [open, onClose, items.length])

  if (!open || items.length === 0) return null

  const current = items[index] ?? items[0]
  const currentUrl = resolveAssetUrl(current.src)
  const showNav = items.length > 1
  const isVideo = current.kind === 'video'
  const muted = current.isMuted ?? localMuted
  const showBlur =
    !isVideo &&
    Boolean(onBlur) &&
    (canBlurCurrent ?? typeof current.id === 'number')
  const showDelete =
    !isVideo &&
    Boolean(onDelete) &&
    (canDeleteCurrent ?? typeof current.id === 'number')

  function toggleMute() {
    const next = !muted
    if (onMuteChange) onMuteChange(current, next)
    else setLocalMuted(next)
  }

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 p-4"
      onClick={onClose}
      role="presentation"
    >
      <button
        type="button"
        className="absolute end-4 top-4 rounded-full bg-white/10 px-3 py-1 text-sm font-semibold text-white"
        onClick={onClose}
      >
        ×
      </button>

      {showNav ? (
        <button
          type="button"
          className="absolute start-3 top-1/2 z-[101] -translate-y-1/2 rounded-full bg-white/15 px-3 py-2 text-lg font-bold text-white hover:bg-white/25"
          onClick={(event) => {
            event.stopPropagation()
            setIndex((current) => (current - 1 + items.length) % items.length)
          }}
          aria-label="Previous"
        >
          ‹
        </button>
      ) : null}

      {showNav ? (
        <button
          type="button"
          className="absolute end-3 top-1/2 z-[101] -translate-y-1/2 rounded-full bg-white/15 px-3 py-2 text-lg font-bold text-white hover:bg-white/25"
          onClick={(event) => {
            event.stopPropagation()
            setIndex((current) => (current + 1) % items.length)
          }}
          aria-label="Next"
        >
          ›
        </button>
      ) : null}

      <div
        className="relative flex max-h-[90vh] max-w-[min(96vw,1200px)] flex-col items-center gap-3"
        onClick={(event) => event.stopPropagation()}
        role="presentation"
      >
        {isVideo && currentUrl ? (
          <video
            key={current.src}
            controls
            autoPlay
            playsInline
            muted={muted}
            preload="metadata"
            className="max-h-[78vh] max-w-full rounded-lg bg-black object-contain"
            src={currentUrl}
          />
        ) : currentUrl ? (
          <img
            src={currentUrl}
            alt=""
            className="max-h-[78vh] max-w-full rounded-lg object-contain"
          />
        ) : null}

        {isVideo ? (
          <button
            type="button"
            onClick={toggleMute}
            className="rounded-full bg-white/15 px-4 py-2 text-sm font-semibold text-white hover:bg-white/25"
          >
            {muted ? unmuteLabel : muteLabel}
          </button>
        ) : null}

        {!isVideo && (showBlur || showDelete) ? (
          <div className="flex flex-wrap items-center justify-center gap-2">
            {showBlur && onBlur ? (
              <button
                type="button"
                onClick={() => onBlur(current, index)}
                className="rounded-full bg-white/15 px-4 py-2 text-sm font-semibold text-white hover:bg-white/25"
              >
                {blurLabel}
              </button>
            ) : null}
            {showDelete && onDelete ? (
              <button
                type="button"
                onClick={() => onDelete(current, index)}
                className="rounded-full bg-red-500/80 px-4 py-2 text-sm font-semibold text-white hover:bg-red-500"
              >
                {deleteLabel}
              </button>
            ) : null}
          </div>
        ) : null}

        {showNav ? (
          <p className="text-xs font-semibold text-white/80">
            {index + 1} / {items.length}
          </p>
        ) : null}
      </div>
    </div>
  )
}
