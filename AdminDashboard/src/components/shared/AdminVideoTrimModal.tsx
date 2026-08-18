import { useEffect, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { fetchAdminAssetBlob } from '../../utils/downloadAsset'
import { getRtkErrorMessage } from '../../utils/rtkError'

type TrimVideoRange = {
  startSec: number
  endSec: number
  durationSeconds: number
}

type AdminVideoTrimModalProps = {
  open: boolean
  videoPath: string
  knownDurationSeconds?: number | null
  isSaving?: boolean
  onClose: () => void
  onQueued?: () => void
  onFailed?: (message: string) => void
  onSave: (range: TrimVideoRange) => Promise<void>
}

const MIN_CLIP_SEC = 0.5
const MAX_CLIP_SEC = 180
const HANDLE_PX = 28
const FILMSTRIP_FRAMES = 12

function formatTime(seconds: number): string {
  const total = Math.max(0, seconds)
  const m = Math.floor(total / 60)
  const s = Math.floor(total % 60)
  return `${m}:${String(s).padStart(2, '0')}`
}

function waitForSeek(video: HTMLVideoElement): Promise<void> {
  return new Promise((resolve) => {
    const done = () => {
      video.removeEventListener('seeked', done)
      resolve()
    }
    video.addEventListener('seeked', done)
  })
}

async function probeVideoDuration(
  video: HTMLVideoElement,
  fallbackSeconds?: number | null,
): Promise<number> {
  if (
    Number.isFinite(video.duration) &&
    video.duration > 0 &&
    video.duration !== Number.POSITIVE_INFINITY
  ) {
    return video.duration
  }

  if (fallbackSeconds != null && fallbackSeconds > 0) {
    return fallbackSeconds
  }

  return new Promise((resolve, reject) => {
    const timeout = window.setTimeout(() => {
      cleanup()
      if (fallbackSeconds != null && fallbackSeconds > 0) {
        resolve(fallbackSeconds)
        return
      }
      reject(new Error('Could not load video'))
    }, 15000)

    const onDurationChange = () => {
      if (
        Number.isFinite(video.duration) &&
        video.duration > 0 &&
        video.duration !== Number.POSITIVE_INFINITY
      ) {
        cleanup()
        resolve(video.duration)
      }
    }

    const onSeeked = () => {
      if (Number.isFinite(video.currentTime) && video.currentTime > 0) {
        const duration = video.currentTime
        cleanup()
        video.pause()
        video.currentTime = 0
        resolve(duration)
      }
    }

    const cleanup = () => {
      window.clearTimeout(timeout)
      video.removeEventListener('durationchange', onDurationChange)
      video.removeEventListener('seeked', onSeeked)
    }

    video.addEventListener('durationchange', onDurationChange)
    video.addEventListener('seeked', onSeeked)
    video.currentTime = 1e10
  })
}

async function captureFilmstripFrames(
  src: string,
  durationSec: number,
  isCancelled: () => boolean,
): Promise<string[]> {
  const video = document.createElement('video')
  video.muted = true
  video.playsInline = true
  video.preload = 'auto'
  video.src = src

  await new Promise<void>((resolve, reject) => {
    const timeout = window.setTimeout(() => reject(new Error('filmstrip')), 12000)
    video.onloadeddata = () => {
      window.clearTimeout(timeout)
      resolve()
    }
    video.onerror = () => {
      window.clearTimeout(timeout)
      reject(new Error('filmstrip'))
    }
  })

  if (isCancelled()) return []

  const w = 72
  const h = 56
  const canvas = document.createElement('canvas')
  canvas.width = w
  canvas.height = h
  const ctx = canvas.getContext('2d')
  if (!ctx) return []

  const frames: string[] = []
  for (let i = 0; i < FILMSTRIP_FRAMES; i += 1) {
    if (isCancelled()) return []
    const t = (i / Math.max(1, FILMSTRIP_FRAMES - 1)) * Math.max(0, durationSec - 0.08)
    video.currentTime = t
    await waitForSeek(video)
    ctx.drawImage(video, 0, 0, w, h)
    frames.push(canvas.toDataURL('image/jpeg', 0.55))
  }

  video.src = ''
  video.load()
  return frames
}

type DragKind = 'start' | 'end' | 'window'

export default function AdminVideoTrimModal({
  open,
  videoPath,
  knownDurationSeconds = null,
  isSaving = false,
  onClose,
  onQueued,
  onFailed,
  onSave,
}: AdminVideoTrimModalProps) {
  const { t } = useAppPreferences()
  const videoRef = useRef<HTMLVideoElement>(null)
  const trackRef = useRef<HTMLDivElement>(null)
  const sourceBlobRef = useRef<Blob | null>(null)
  const previewUrlRef = useRef<string | null>(null)
  const loadTokenRef = useRef(0)
  const exportStartedRef = useRef(false)
  const rangeRef = useRef({ start: 0, end: 30 })
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [isLoadingSource, setIsLoadingSource] = useState(false)
  const [duration, setDuration] = useState(0)
  const [startSec, setStartSec] = useState(0)
  const [endSec, setEndSec] = useState(30)
  const [playhead, setPlayhead] = useState(0)
  const [frames, setFrames] = useState<string[]>([])
  const [ready, setReady] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isExporting, setIsExporting] = useState(false)

  const trimDuration = Math.max(0, endSec - startSec)

  useEffect(() => {
    rangeRef.current = { start: startSec, end: endSec }
  }, [startSec, endSec])

  useEffect(() => {
    if (!open || !videoPath.trim()) return

    const loadToken = ++loadTokenRef.current
    let cancelled = false

    function revokePreviewUrl() {
      if (previewUrlRef.current) {
        URL.revokeObjectURL(previewUrlRef.current)
        previewUrlRef.current = null
      }
    }

    async function loadSource() {
      setDuration(0)
      setStartSec(0)
      setEndSec(30)
      setPlayhead(0)
      setFrames([])
      setReady(false)
      setError(null)
      setIsExporting(false)
      exportStartedRef.current = false
      setIsLoadingSource(true)
      revokePreviewUrl()
      sourceBlobRef.current = null
      setPreviewUrl(null)

      try {
        const blob = await fetchAdminAssetBlob(videoPath)
        if (cancelled || loadToken !== loadTokenRef.current) return

        sourceBlobRef.current = blob
        const objectUrl = URL.createObjectURL(blob)
        previewUrlRef.current = objectUrl
        setPreviewUrl(objectUrl)
      } catch {
        if (!cancelled && loadToken === loadTokenRef.current) {
          setError(t('ads.trimVideoLoadError'))
        }
      } finally {
        if (!cancelled && loadToken === loadTokenRef.current) {
          setIsLoadingSource(false)
        }
      }
    }

    void loadSource()

    return () => {
      cancelled = true
      sourceBlobRef.current = null
      revokePreviewUrl()
      setPreviewUrl(null)
    }
  }, [open, videoPath, t])

  useEffect(() => {
    if (!open || !ready || !previewUrl || duration <= 0) return
    let cancelled = false

    void captureFilmstripFrames(previewUrl, duration, () => cancelled)
      .then((next) => {
        if (!cancelled) setFrames(next)
      })
      .catch(() => {
        if (!cancelled) setFrames([])
      })

    return () => {
      cancelled = true
    }
  }, [open, ready, previewUrl, duration])

  if (!open) return null

  const busy = isSaving || isExporting || isLoadingSource

  function applyRange(nextStart: number, nextEnd: number, seekTo?: 'start' | 'end' | number) {
    let start = nextStart
    let end = nextEnd
    if (end - start < MIN_CLIP_SEC) {
      end = start + MIN_CLIP_SEC
    }
    if (end - start > MAX_CLIP_SEC) {
      end = start + MAX_CLIP_SEC
    }
    start = Math.max(0, start)
    end = Math.min(duration, end)
    if (end - start < MIN_CLIP_SEC) {
      start = Math.max(0, end - MIN_CLIP_SEC)
    }
    setStartSec(start)
    setEndSec(end)

    const video = videoRef.current
    if (!video || seekTo == null) return
    const time = seekTo === 'start' ? start : seekTo === 'end' ? end : seekTo
    video.currentTime = Math.min(Math.max(time, start), end)
    setPlayhead(video.currentTime)
  }

  function timeAtClientX(clientX: number): number {
    const el = trackRef.current
    if (!el || duration <= 0) return 0
    const rect = el.getBoundingClientRect()
    const ratio = (clientX - rect.left) / Math.max(1, rect.width)
    return Math.max(0, Math.min(duration, ratio * duration))
  }

  function beginDrag(kind: DragKind, event: ReactPointerEvent<HTMLElement>) {
    if (busy || !ready) return
    event.preventDefault()
    event.stopPropagation()

    const originX = event.clientX
    const origin = { ...rangeRef.current }
    const video = videoRef.current
    video?.pause()

    const onMove = (ev: PointerEvent) => {
      const { start: origStart, end: origEnd } = origin
      if (kind === 'start') {
        const maxStart = origEnd - MIN_CLIP_SEC
        let start = Math.min(maxStart, timeAtClientX(ev.clientX))
        start = Math.max(0, start)
        if (origEnd - start > MAX_CLIP_SEC) start = origEnd - MAX_CLIP_SEC
        applyRange(start, origEnd, 'start')
        return
      }
      if (kind === 'end') {
        let end = Math.max(origStart + MIN_CLIP_SEC, timeAtClientX(ev.clientX))
        end = Math.min(duration, end)
        if (end - origStart > MAX_CLIP_SEC) end = origStart + MAX_CLIP_SEC
        applyRange(origStart, end, 'end')
        return
      }
      const span = origEnd - origStart
      const delta = timeAtClientX(ev.clientX) - timeAtClientX(originX)
      let start = origStart + delta
      start = Math.max(0, Math.min(duration - span, start))
      applyRange(start, start + span, start)
    }

    const onUp = () => {
      window.removeEventListener('pointermove', onMove)
      window.removeEventListener('pointerup', onUp)
      window.removeEventListener('pointercancel', onUp)
    }

    window.addEventListener('pointermove', onMove)
    window.addEventListener('pointerup', onUp)
    window.addEventListener('pointercancel', onUp)
  }

  async function handleVideoReady() {
    const video = videoRef.current
    if (!video) return

    try {
      const d = await probeVideoDuration(video, knownDurationSeconds)
      if (!Number.isFinite(d) || d <= 0) {
        setError(t('ads.trimVideoLoadError'))
        setReady(false)
        return
      }

      const nextEnd = Math.min(MAX_CLIP_SEC, Math.min(30, Math.max(MIN_CLIP_SEC, d)))
      setDuration(d)
      setStartSec(0)
      setEndSec(nextEnd)
      setPlayhead(0)
      setReady(true)
      setError(null)
    } catch {
      setError(t('ads.trimVideoLoadError'))
      setReady(false)
    }
  }

  async function handleSave() {
    if (!ready || trimDuration < MIN_CLIP_SEC || exportStartedRef.current) return

    exportStartedRef.current = true
    setError(null)

    const start = startSec
    const end = endSec
    const durationSeconds = Math.max(1, Math.min(180, Math.round(end - start)))
    const save = onSave
    const failed = onFailed

    onQueued?.()
    onClose()

    void (async () => {
      try {
        await save({ startSec: start, endSec: end, durationSeconds })
      } catch (err) {
        failed?.(getRtkErrorMessage(err as never, t('ads.trimVideoSaveError')))
      }
    })()
  }

  const startPct = duration > 0 ? (startSec / duration) * 100 : 0
  const endPct = duration > 0 ? (endSec / duration) * 100 : 100
  const playPct = duration > 0 ? (playhead / duration) * 100 : 0

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
      <div className="admin-card flex max-h-[95vh] w-full max-w-2xl flex-col overflow-hidden rounded-2xl shadow-xl">
        <div className="admin-border flex items-center justify-between border-b px-4 py-3">
          <h3 className="admin-text text-sm font-bold">{t('ads.trimVideoTitle')}</h3>
          <button
            type="button"
            onClick={onClose}
            disabled={busy}
            className="admin-text-muted text-xl leading-none disabled:opacity-50"
          >
            ×
          </button>
        </div>

        <p className="admin-text-muted px-4 py-2 text-xs">{t('ads.trimVideoHint')}</p>

        <div className="flex-1 overflow-auto px-4 pb-2">
          {isLoadingSource ? (
            <div className="flex min-h-[200px] items-center justify-center">
              <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
            </div>
          ) : previewUrl ? (
            <video
              key={previewUrl}
              ref={videoRef}
              src={previewUrl}
              controls
              preload="auto"
              className="mx-auto block max-h-[42vh] w-full rounded-lg bg-black"
              onLoadedMetadata={() => {
                if (!ready) void handleVideoReady()
              }}
              onDurationChange={() => {
                if (!ready) void handleVideoReady()
              }}
              onTimeUpdate={() => {
                const video = videoRef.current
                if (!video) return
                if (!video.paused && video.currentTime >= endSec - 0.05) {
                  video.currentTime = startSec
                }
                setPlayhead(video.currentTime)
              }}
            />
          ) : null}

          {ready && duration > 0 ? (
            <div className="mt-4 space-y-2 px-7">
              <div className="flex justify-between text-[11px] font-semibold">
                <span className="admin-text">{formatTime(startSec)}</span>
                <span className="admin-text-muted">
                  {t('ads.trimVideoDuration', { seconds: trimDuration.toFixed(1) })}
                </span>
                <span className="admin-text">{formatTime(endSec)}</span>
              </div>

              <div
                ref={trackRef}
                dir="ltr"
                className="relative h-14 select-none overflow-visible rounded-lg bg-zinc-900"
                style={{ touchAction: 'none' }}
              >
                <div className="absolute inset-0 flex overflow-hidden rounded-lg">
                  {frames.length > 0
                    ? frames.map((src, index) => (
                        <img
                          key={`${src.slice(-24)}-${index}`}
                          src={src}
                          alt=""
                          draggable={false}
                          className="h-full flex-1 object-cover"
                        />
                      ))
                    : (
                      <div className="h-full w-full bg-[linear-gradient(90deg,#3f3f46_12px,transparent_12px)] bg-[length:24px_100%] opacity-40" />
                    )}
                </div>

                <div
                  className="pointer-events-none absolute inset-y-0 left-0 bg-black/65"
                  style={{ width: `${startPct}%` }}
                />
                <div
                  className="pointer-events-none absolute inset-y-0 right-0 bg-black/65"
                  style={{ width: `${Math.max(0, 100 - endPct)}%` }}
                />

                <div
                  className="absolute inset-y-0 cursor-grab active:cursor-grabbing"
                  style={{
                    left: `${startPct}%`,
                    width: `${Math.max(2, endPct - startPct)}%`,
                  }}
                  onPointerDown={(event) => beginDrag('window', event)}
                />

                <div
                  className="pointer-events-none absolute inset-y-0 rounded-sm border-[3px] border-[#F5C400]"
                  style={{
                    left: `${startPct}%`,
                    width: `${Math.max(2, endPct - startPct)}%`,
                  }}
                />

                <div
                  className="pointer-events-none absolute top-0 z-10 h-full w-0.5 bg-white shadow"
                  style={{ left: `${playPct}%` }}
                />

                <button
                  type="button"
                  aria-label={t('ads.trimVideoStart')}
                  disabled={busy}
                  className="absolute top-[-4px] z-20 flex h-[calc(100%+8px)] items-center justify-center rounded-l-md bg-[#F5C400] disabled:opacity-50"
                  style={{
                    left: `${startPct}%`,
                    width: HANDLE_PX,
                    transform: 'translateX(-100%)',
                    touchAction: 'none',
                  }}
                  onPointerDown={(event) => beginDrag('start', event)}
                >
                  <span className="flex gap-[3px]">
                    <span className="h-6 w-[2px] rounded-full bg-black/70" />
                    <span className="h-6 w-[2px] rounded-full bg-black/70" />
                  </span>
                </button>

                <button
                  type="button"
                  aria-label={t('ads.trimVideoEnd')}
                  disabled={busy}
                  className="absolute top-[-4px] z-20 flex h-[calc(100%+8px)] items-center justify-center rounded-r-md bg-[#F5C400] disabled:opacity-50"
                  style={{
                    left: `${endPct}%`,
                    width: HANDLE_PX,
                    transform: 'translateX(0)',
                    touchAction: 'none',
                  }}
                  onPointerDown={(event) => beginDrag('end', event)}
                >
                  <span className="flex gap-[3px]">
                    <span className="h-6 w-[2px] rounded-full bg-black/70" />
                    <span className="h-6 w-[2px] rounded-full bg-black/70" />
                  </span>
                </button>
              </div>
            </div>
          ) : null}

          {error ? <p className="mt-3 text-center text-sm text-red-600">{error}</p> : null}
        </div>

        <div className="admin-border flex flex-wrap items-center justify-end gap-2 border-t px-4 py-3">
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
            disabled={busy || !ready || trimDuration < MIN_CLIP_SEC}
            onClick={() => void handleSave()}
            className="keep-white rounded-lg bg-[#3B7FC7] px-4 py-2 text-xs font-semibold text-white disabled:opacity-50"
          >
            {busy ? '…' : t('ads.trimVideoSave')}
          </button>
        </div>
      </div>
    </div>
  )
}
