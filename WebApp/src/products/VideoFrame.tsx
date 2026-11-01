import { useEffect, useRef, useState, type ReactNode } from 'react'

/** Poster for video-only listings: loads the video metadata once visible and shows an early frame. */
export function VideoFrame({ src, className = '', fallback = null }: { src: string; className?: string; fallback?: ReactNode }) {
  const ref = useRef<HTMLVideoElement>(null)
  const [visible, setVisible] = useState(false)
  const [failed, setFailed] = useState(false)

  useEffect(() => {
    const el = ref.current
    if (!el || visible) return
    if (typeof IntersectionObserver === 'undefined') {
      setVisible(true)
      return
    }
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) {
          setVisible(true)
          observer.disconnect()
        }
      },
      { rootMargin: '300px' },
    )
    observer.observe(el)
    return () => observer.disconnect()
  }, [visible])

  if (failed) return <>{fallback}</>

  return (
    <video
      ref={ref}
      src={visible ? `${src}#t=0.5` : undefined}
      muted
      playsInline
      preload="metadata"
      disablePictureInPicture
      tabIndex={-1}
      aria-hidden="true"
      onLoadedMetadata={(e) => {
        const v = e.currentTarget
        if (v.currentTime < 0.1 && Number.isFinite(v.duration) && v.duration > 0) v.currentTime = Math.min(0.5, v.duration / 2)
      }}
      onError={() => setFailed(true)}
      className={`pointer-events-none ${className}`}
    />
  )
}
