import { useEffect, useRef, useState } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { fetchAdminAssetBlob } from '../../utils/downloadAsset'
import { getRtkErrorMessage } from '../../utils/rtkError'
import { trimVideoToFile } from '../../utils/videoTrim'

type AdminVideoTrimModalProps = {
  open: boolean
  videoUrl: string
  isSaving?: boolean
  onClose: () => void
  onSave: (file: File, durationSeconds: number) => Promise<void>
}

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60)
  const s = Math.floor(seconds % 60)
  return `${m}:${String(s).padStart(2, '0')}`
}

export default function AdminVideoTrimModal({
  open,
  videoUrl,
  isSaving = false,
  onClose,
  onSave,
}: AdminVideoTrimModalProps) {
  const { t } = useAppPreferences()
  const videoRef = useRef<HTMLVideoElement>(null)
  const [duration, setDuration] = useState(0)
  const [startSec, setStartSec] = useState(0)
  const [clipLength, setClipLength] = useState(30)
  const [ready, setReady] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isExporting, setIsExporting] = useState(false)

  const endSec = Math.min(duration || clipLength, startSec + clipLength)
  const trimDuration = Math.max(0, endSec - startSec)

  useEffect(() => {
    if (!open) return
    setDuration(0)
    setStartSec(0)
    setClipLength(30)
    setReady(false)
    setError(null)
    setIsExporting(false)
  }, [open, videoUrl])

  if (!open) return null

  function handleLoadedMetadata() {
    const video = videoRef.current
    if (!video || !Number.isFinite(video.duration) || video.duration <= 0) {
      setError(t('ads.trimVideoLoadError'))
      return
    }
    const d = video.duration
    setDuration(d)
    setStartSec(0)
    setClipLength(Math.min(30, Math.max(1, Math.floor(d))))
    setReady(true)
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
    if (!ready || trimDuration < 0.5) return
    setIsExporting(true)
    setError(null)
    try {
      const blob = await fetchAdminAssetBlob(videoUrl)
      const { file, durationSeconds } = await trimVideoToFile(blob, startSec, endSec)
      await onSave(file, durationSeconds)
    } catch (err) {
      setError(getRtkErrorMessage(err as never, t('ads.trimVideoSaveError')))
    } finally {
      setIsExporting(false)
    }
  }

  const busy = isSaving || isExporting

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
          <video
            ref={videoRef}
            src={videoUrl}
            controls
            preload="metadata"
            className="mx-auto block max-h-[42vh] w-full rounded-lg bg-black"
            onLoadedMetadata={handleLoadedMetadata}
            onError={() => setError(t('ads.trimVideoLoadError'))}
          />

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
