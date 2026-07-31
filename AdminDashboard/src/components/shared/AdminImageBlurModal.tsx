import { useEffect, useRef, useState } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { fetchAdminAssetBlob } from '../../utils/downloadAsset'

type BlurRect = {
  x: number
  y: number
  width: number
  height: number
}

type AdminImageBlurModalProps = {
  open: boolean
  imageUrl: string
  isSaving?: boolean
  onClose: () => void
  onSave: (file: File) => Promise<void>
}

function clampRect(rect: BlurRect, maxW: number, maxH: number): BlurRect {
  const x = Math.max(0, Math.min(rect.x, maxW - 1))
  const y = Math.max(0, Math.min(rect.y, maxH - 1))
  const width = Math.max(8, Math.min(rect.width, maxW - x))
  const height = Math.max(8, Math.min(rect.height, maxH - y))
  return { x, y, width, height }
}

function applyBlurRegion(
  ctx: CanvasRenderingContext2D,
  source: CanvasImageSource,
  rect: BlurRect,
  blurPx: number,
) {
  const { x, y, width, height } = rect
  const patch = document.createElement('canvas')
  patch.width = Math.max(1, Math.round(width))
  patch.height = Math.max(1, Math.round(height))
  const patchCtx = patch.getContext('2d')
  if (!patchCtx) return

  patchCtx.drawImage(source, x, y, width, height, 0, 0, patch.width, patch.height)

  const blurred = document.createElement('canvas')
  blurred.width = patch.width
  blurred.height = patch.height
  const blurredCtx = blurred.getContext('2d')
  if (!blurredCtx) return

  blurredCtx.filter = `blur(${blurPx}px)`
  blurredCtx.drawImage(patch, 0, 0)
  ctx.drawImage(blurred, x, y)
}

/**
 * Edit the already-displayed image in place (no fetch on open).
 * Only when saving: one authenticated download + upload/replace.
 */
export default function AdminImageBlurModal({
  open,
  imageUrl,
  isSaving = false,
  onClose,
  onSave,
}: AdminImageBlurModalProps) {
  const { t } = useAppPreferences()
  const frameRef = useRef<HTMLDivElement>(null)
  const imgRef = useRef<HTMLImageElement>(null)
  const [regions, setRegions] = useState<BlurRect[]>([])
  const [draft, setDraft] = useState<BlurRect | null>(null)
  const [dragStart, setDragStart] = useState<{ x: number; y: number } | null>(null)
  const [imgReady, setImgReady] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isExporting, setIsExporting] = useState(false)

  useEffect(() => {
    if (!open) return
    setRegions([])
    setDraft(null)
    setDragStart(null)
    setError(null)
    setImgReady(false)
    setIsExporting(false)
  }, [open, imageUrl])

  if (!open) return null

  function pointInImage(event: React.MouseEvent) {
    const img = imgRef.current
    if (!img) return { x: 0, y: 0, maxW: 0, maxH: 0 }
    const bounds = img.getBoundingClientRect()
    return {
      x: Math.max(0, Math.min(event.clientX - bounds.left, bounds.width)),
      y: Math.max(0, Math.min(event.clientY - bounds.top, bounds.height)),
      maxW: bounds.width,
      maxH: bounds.height,
    }
  }

  function handleMouseDown(event: React.MouseEvent) {
    if (isSaving || isExporting || !imgReady) return
    event.preventDefault()
    const point = pointInImage(event)
    setDragStart({ x: point.x, y: point.y })
    setDraft({ x: point.x, y: point.y, width: 0, height: 0 })
  }

  function handleMouseMove(event: React.MouseEvent) {
    if (!dragStart || isSaving || isExporting) return
    const point = pointInImage(event)
    setDraft(
      clampRect(
        {
          x: Math.min(dragStart.x, point.x),
          y: Math.min(dragStart.y, point.y),
          width: Math.abs(point.x - dragStart.x),
          height: Math.abs(point.y - dragStart.y),
        },
        point.maxW,
        point.maxH,
      ),
    )
  }

  function handleMouseUp() {
    if (!draft || draft.width < 12 || draft.height < 12) {
      setDraft(null)
      setDragStart(null)
      return
    }
    setRegions((prev) => [...prev, draft])
    setDraft(null)
    setDragStart(null)
  }

  async function handleSave() {
    const img = imgRef.current
    if (!img || regions.length === 0) return

    setIsExporting(true)
    setError(null)

    try {
      const displayW = img.getBoundingClientRect().width
      const displayH = img.getBoundingClientRect().height
      if (displayW <= 0 || displayH <= 0) {
        throw new Error('invalid display size')
      }

      // One request only at save time — then replace the current image.
      const sourceBlob = await fetchAdminAssetBlob(imageUrl)
      const bitmap = await createImageBitmap(sourceBlob)

      const exportCanvas = document.createElement('canvas')
      exportCanvas.width = bitmap.width
      exportCanvas.height = bitmap.height
      const exportCtx = exportCanvas.getContext('2d')
      if (!exportCtx) throw new Error('no canvas')

      exportCtx.drawImage(bitmap, 0, 0)
      const scaleX = bitmap.width / displayW
      const scaleY = bitmap.height / displayH

      for (const rect of regions) {
        applyBlurRegion(
          exportCtx,
          bitmap,
          {
            x: rect.x * scaleX,
            y: rect.y * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY,
          },
          28,
        )
      }

      bitmap.close()

      const blob = await new Promise<Blob | null>((resolve) => {
        exportCanvas.toBlob((value) => resolve(value), 'image/jpeg', 0.92)
      })
      if (!blob) throw new Error('toBlob failed')

      const file = new File([blob], `blurred-${Date.now()}.jpg`, { type: 'image/jpeg' })
      await onSave(file)
    } catch {
      setError(t('ads.blurSaveError'))
    } finally {
      setIsExporting(false)
    }
  }

  const busy = isSaving || isExporting

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
      <div className="admin-card flex max-h-[95vh] w-full max-w-4xl flex-col overflow-hidden rounded-2xl shadow-xl">
        <div className="admin-border flex items-center justify-between border-b px-4 py-3">
          <h3 className="admin-text text-sm font-bold">{t('ads.blurImageTitle')}</h3>
          <button
            type="button"
            onClick={onClose}
            disabled={busy}
            className="admin-text-muted text-xl leading-none disabled:opacity-50"
          >
            ×
          </button>
        </div>

        <p className="admin-text-muted px-4 py-2 text-xs">{t('ads.blurImageHint')}</p>

        <div className="flex-1 overflow-auto px-4 pb-2">
          <div
            ref={frameRef}
            className="relative mx-auto inline-block max-w-full select-none"
            onMouseDown={handleMouseDown}
            onMouseMove={handleMouseMove}
            onMouseUp={handleMouseUp}
            onMouseLeave={handleMouseUp}
          >
            <img
              ref={imgRef}
              src={imageUrl}
              alt=""
              draggable={false}
              className="block max-h-[70vh] max-w-full rounded-lg object-contain"
              onLoad={() => setImgReady(true)}
              onError={() => setError(t('ads.blurImageLoadError'))}
            />

            {!imgReady && !error ? (
              <div className="absolute inset-0 flex items-center justify-center rounded-lg bg-slate-100/80">
                <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
              </div>
            ) : null}

            {/* Selection overlays on the current image — no server round-trips */}
            {regions.map((rect, index) => (
              <div
                key={`region-${index}`}
                className="pointer-events-none absolute overflow-hidden rounded-sm ring-2 ring-sky-500/80"
                style={{
                  left: rect.x,
                  top: rect.y,
                  width: rect.width,
                  height: rect.height,
                  backdropFilter: 'blur(20px)',
                  WebkitBackdropFilter: 'blur(20px)',
                  background: 'rgba(255,255,255,0.2)',
                }}
              />
            ))}
            {draft ? (
              <div
                className="pointer-events-none absolute border-2 border-dashed border-blue-500 bg-blue-500/10"
                style={{
                  left: draft.x,
                  top: draft.y,
                  width: draft.width,
                  height: draft.height,
                }}
              />
            ) : null}
          </div>

          {error ? <p className="mt-3 text-center text-sm text-red-600">{error}</p> : null}
        </div>

        <div className="admin-border flex flex-wrap items-center justify-end gap-2 border-t px-4 py-3">
          <button
            type="button"
            disabled={busy || regions.length === 0}
            onClick={() => setRegions((prev) => prev.slice(0, -1))}
            className="admin-border rounded-lg border px-3 py-2 text-xs font-semibold disabled:opacity-50"
          >
            {t('ads.blurUndo')}
          </button>
          <button
            type="button"
            disabled={busy}
            onClick={onClose}
            className="admin-border rounded-lg border px-3 py-2 text-xs font-semibold"
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            disabled={busy || regions.length === 0 || !imgReady || Boolean(error)}
            onClick={() => void handleSave()}
            className="keep-white rounded-lg bg-[#3B7FC7] px-4 py-2 text-xs font-semibold text-white disabled:opacity-50"
          >
            {busy ? '…' : t('ads.blurSave')}
          </button>
        </div>
      </div>
    </div>
  )
}
