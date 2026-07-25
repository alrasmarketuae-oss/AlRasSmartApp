import { useEffect, useState } from 'react'
import { resolveAssetUrl } from '../../lib/assets'

type ImageGalleryProps = {
  images: string[]
  initialIndex?: number
  open: boolean
  onClose: () => void
}

export default function ImageGallery({
  images,
  initialIndex = 0,
  open,
  onClose,
}: ImageGalleryProps) {
  const validImages = images.filter((path) => Boolean(path?.trim()))
  const [index, setIndex] = useState(0)

  useEffect(() => {
    if (!open) return
    const next = Math.min(
      Math.max(initialIndex, 0),
      Math.max(validImages.length - 1, 0),
    )
    setIndex(next)
  }, [open, initialIndex, validImages.length])

  useEffect(() => {
    if (!open) return
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        onClose()
        return
      }
      if (event.key === 'ArrowRight') {
        setIndex((current) => (current + 1) % Math.max(validImages.length, 1))
      }
      if (event.key === 'ArrowLeft') {
        setIndex((current) =>
          (current - 1 + Math.max(validImages.length, 1)) %
          Math.max(validImages.length, 1),
        )
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [open, onClose, validImages.length])

  if (!open || validImages.length === 0) return null

  const current = validImages[index] ?? validImages[0]
  const showNav = validImages.length > 1

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
            setIndex(
              (current) =>
                (current - 1 + validImages.length) % validImages.length,
            )
          }}
          aria-label="Previous image"
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
            setIndex((current) => (current + 1) % validImages.length)
          }}
          aria-label="Next image"
        >
          ›
        </button>
      ) : null}

      <div
        className="flex max-h-[90vh] max-w-[min(96vw,1200px)] flex-col items-center gap-2"
        onClick={(event) => event.stopPropagation()}
        role="presentation"
      >
        <img
          src={resolveAssetUrl(current)}
          alt=""
          className="max-h-[84vh] max-w-full rounded-lg object-contain"
        />
        {showNav ? (
          <p className="text-xs font-semibold text-white/80">
            {index + 1} / {validImages.length}
          </p>
        ) : null}
      </div>
    </div>
  )
}
