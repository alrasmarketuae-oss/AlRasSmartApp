import { useEffect, useRef, useState } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { fetchAdminAssetBlob } from '../../utils/downloadAsset'
import { getRtkErrorMessage } from '../../utils/rtkError'
import { trimVideoToFile } from '../../utils/videoTrim'

type AdminVideoTrimModalProps = {
  open: boolean
  videoPath: string
  knownDurationSeconds?: number | null
  isSaving?: boolean
  onClose: () => void
  onSave: (file: File, durationSeconds: number) => Promise<void>
}

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60)
  const s = Math.floor(seconds % 60)
  return `${m}:${String(s).padStart(2, '0')}`
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

export default function AdminVideoTrimModal({
  open,
  videoPath,
  knownDurationSeconds = null,
  isSaving = false,
  onClose,
  onSave,
}: AdminVideoTrimModalProps) {
  const { t } = useAppPreferences()
  const videoRef = useRef<HTMLVideoElement>(null)
  const sourceBlobRef = useRef<Blob | null>(null)
  const previewUrlRef = useRef<string | null>(null)
  const loadTokenRef = useRef(0)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [isLoadingSource, setIsLoadingSource] = useState(false)
  const [duration, setDuration] = useState(0)
  const [startSec, setStartSec] = useState(0)
  const [clipLength, setClipLength] = useState(30)
  const [ready, setReady] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isExporting, setIsExporting] = useState(false)

  const endSec = Math.min(duration || clipLength, startSec + clipLength)
  const trimDuration = Math.max(0, endSec - startSec)

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
      setClipLength(30)
      setReady(false)
      setError(null)
      setIsExporting(false)
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

  if (!open) return null

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

      setDuration(d)
      setStartSec(0)
      setClipLength(Math.min(30, Math.max(1, Math.floor(d))))
      setReady(true)
      setError(null)
    } catch {
      setError(t('ads.trimVideoLoadError'))
      setReady(false)
    }
  }

  function handleStartChange(value: number) {
    const maxStart = Math.max(0, duration - 0.5)
    const next = Math.max(0, Math.min(value, maxStart))
    setStartSec(next)
    const maxLen = Math.min(180, duration - next)
    if (clipLength > maxLen) setClipLength(Math.max(0.5, maxLen))
    const video = videoRef.current
    if (video) video.currentTime = next
  }

  function handleLengthChange(value: number) {
    const maxLen = Math.min(180, Math.max(0.5, duration - startSec))
    setClipLength(Math.max(0.5, Math.min(value, maxLen)))
  }

  async function handleSave() {
    const blob = sourceBlobRef.current
    if (!ready || !blob || trimDuration < 0.5) return
    setIsExporting(true)
    setError(null)
    try {
      const { file, durationSeconds } = await trimVideoToFile(blob, startSec, endSec)
      await onSave(file, durationSeconds)
    } catch (err) {
      setError(getRtkErrorMessage(err as never, t('ads.trimVideoSaveError')))
    } finally {
      setIsExporting(false)
    }
  }

  const busy = isSaving || isExporting || isLoadingSource

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4">
      <div className="admin-card flex max-h-[95vh] w-full max-w-xl flex-col overflow-hidden rounded-2xl shadow-xl">
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
              onLoadedMetadata={() => void handleVideoReady()}
              onDurationChange={() => {
                if (!ready) void handleVideoReady()
              }}
            />
          ) : null}

          {ready ? (
            <div className="mt-4 space-y-4">
              <div>
                <div className="mb-1 flex justify-between text-xs font-semibold">
                  <span className="admin-text-muted">{t('ads.trimVideoStart')}</span>
                  <span className="admin-text">{formatTime(startSec)}</span>
                </div>
                <input
                  type="range"
                  min={0}
                  max={Math.max(0.5, duration - 0.5)}
                  step={0.1}
                  value={startSec}
                  disabled={busy}
                  onChange={(e) => handleStartChange(Number(e.target.value))}
                  className="w-full accent-[#3B7FC7]"
                />
              </div>

              <div>
                <div className="mb-1 flex justify-between text-xs font-semibold">
                  <span className="admin-text-muted">{t('ads.trimVideoLength')}</span>
                  <span className="admin-text">{trimDuration.toFixed(1)}s</span>
                </div>
                <input
                  type="range"
                  min={0.5}
                  max={Math.min(180, Math.max(0.5, duration - startSec))}
                  step={0.5}
                  value={clipLength}
                  disabled={busy}
                  onChange={(e) => handleLengthChange(Number(e.target.value))}
                  className="w-full accent-[#3B7FC7]"
                />
              </div>

              <p className="admin-text text-center text-sm font-bold">
                {formatTime(startSec)} → {formatTime(endSec)}
              </p>
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
            disabled={busy || !ready || trimDuration < 0.5}
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
