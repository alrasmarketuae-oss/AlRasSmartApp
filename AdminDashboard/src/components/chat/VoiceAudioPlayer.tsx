import { useCallback, useEffect, useRef, useState } from 'react'
import {
  isApplePlatform,
  resolveVoiceUrl,
  voiceMimeFromPath,
} from '../../lib/voiceRecording'

type VoiceAudioPlayerProps = {
  content: string
  localPreviewUrl?: string
  isMine?: boolean
}

type PlayerStatus = 'idle' | 'loading' | 'ready' | 'playing' | 'error'

const blobCache = new Map<string, string>()

async function loadVoiceBlob(content: string, remoteUrl: string): Promise<string> {
  const cached = blobCache.get(content)
  if (cached) {
    return cached
  }

  const response = await fetch(remoteUrl)
  if (!response.ok) {
    throw new Error('voice fetch failed')
  }

  const blob = await response.blob()
  const mime =
    blob.type && blob.type !== 'application/octet-stream'
      ? blob.type
      : voiceMimeFromPath(content) || 'audio/mp4'
  const blobUrl = URL.createObjectURL(new Blob([blob], { type: mime }))
  blobCache.set(content, blobUrl)
  return blobUrl
}

export default function VoiceAudioPlayer({
  content,
  localPreviewUrl,
  isMine = false,
}: VoiceAudioPlayerProps) {
  const audioRef = useRef<HTMLAudioElement>(null)
  const blobUrlRef = useRef<string | null>(null)
  const [status, setStatus] = useState<PlayerStatus>('idle')
  const [progress, setProgress] = useState(0)
  const useIosPlayer = isApplePlatform()
  const remoteUrl = localPreviewUrl || resolveVoiceUrl(content)

  useEffect(() => {
    if (!remoteUrl) {
      setStatus('error')
      return
    }

    if (!useIosPlayer) {
      setStatus('ready')
      return
    }

    if (localPreviewUrl) {
      blobUrlRef.current = localPreviewUrl
      setStatus('ready')
      return
    }

    let cancelled = false
    setStatus('loading')

    loadVoiceBlob(content, remoteUrl)
      .then((blobUrl) => {
        if (cancelled) return
        blobUrlRef.current = blobUrl
        setStatus('ready')
      })
      .catch(() => {
        if (!cancelled) setStatus('error')
      })

    return () => {
      cancelled = true
    }
  }, [content, localPreviewUrl, remoteUrl, useIosPlayer])

  const handlePlayPause = useCallback(async () => {
    const audio = audioRef.current
    if (!audio || status === 'loading') return

    if (status === 'playing') {
      audio.pause()
      setStatus('ready')
      return
    }

    try {
      if (useIosPlayer) {
        const src = blobUrlRef.current ?? localPreviewUrl
        if (!src) {
          setStatus('loading')
          const blobUrl = await loadVoiceBlob(content, remoteUrl)
          blobUrlRef.current = blobUrl
          audio.src = blobUrl
          setStatus('ready')
        } else {
          audio.src = src
        }
      } else {
        audio.src = remoteUrl
      }

      await audio.play()
      setStatus('playing')
    } catch {
      setStatus('error')
    }
  }, [content, localPreviewUrl, remoteUrl, status, useIosPlayer])

  const btnClass = isMine
    ? 'bg-white/25 text-white hover:bg-white/35'
    : 'bg-[#3B7FC7]/15 text-[#3B7FC7] hover:bg-[#3B7FC7]/25 dark:text-[#7eb8ff]'

  if (!useIosPlayer) {
    return (
      <audio
        controls
        preload="metadata"
        playsInline
        src={remoteUrl}
        className="max-w-full min-w-[180px]"
      />
    )
  }

  return (
    <div className="flex min-w-[180px] items-center gap-2">
      <button
        type="button"
        onClick={() => void handlePlayPause()}
        disabled={status === 'loading' || status === 'error'}
        className={`inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full transition ${btnClass} disabled:opacity-50`}
        aria-label={status === 'playing' ? 'pause' : 'play'}
      >
        {status === 'loading' ? (
          <span className="inline-block h-3 w-3 animate-spin rounded-full border-2 border-current border-t-transparent" />
        ) : status === 'playing' ? (
          <PauseIcon />
        ) : (
          <PlayIcon />
        )}
      </button>

      <div className="min-w-0 flex-1">
        <div className="h-1.5 overflow-hidden rounded-full bg-black/10 dark:bg-white/10">
          <div
            className={`h-full rounded-full transition-all ${isMine ? 'bg-white/80' : 'bg-[#3B7FC7]'}`}
            style={{
              width: `${status === 'playing' ? progress : status === 'ready' ? 35 : 0}%`,
            }}
          />
        </div>
        <p className="mt-1 text-[10px] opacity-70">
          {status === 'loading' ? 'جاري التحميل...' : status === 'error' ? 'تعذر التشغيل' : status === 'playing' ? 'تشغيل' : 'اضغط للتشغيل'}
        </p>
      </div>

      <audio
        ref={audioRef}
        playsInline
        preload="auto"
        className="hidden"
        onEnded={() => {
          setStatus('ready')
          setProgress(0)
        }}
        onPause={() => setStatus((s) => (s === 'playing' ? 'ready' : s))}
        onTimeUpdate={(event) => {
          const audio = event.currentTarget
          if (audio.duration > 0) {
            setProgress(Math.min(100, (audio.currentTime / audio.duration) * 100))
          }
        }}
      />
    </div>
  )
}

function PlayIcon() {
  return (
    <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M8 5.14v13.72a1 1 0 0 0 1.5.86l11.01-6.86a1 1 0 0 0 0-1.72L9.5 4.28A1 1 0 0 0 8 5.14Z" />
    </svg>
  )
}

function PauseIcon() {
  return (
    <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M6 5h4v14H6V5Zm8 0h4v14h-4V5Z" />
    </svg>
  )
}
