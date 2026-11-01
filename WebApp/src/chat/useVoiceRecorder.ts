import { useEffect, useRef, useState } from 'react'

export function useVoiceRecorder(onDone: (file: File) => void, onDenied: () => void) {
  const [recording, setRecording] = useState(false)
  const [seconds, setSeconds] = useState(0)
  const recorder = useRef<MediaRecorder | null>(null)
  const chunks = useRef<Blob[]>([])
  const cancelled = useRef(false)
  const doneRef = useRef(onDone)
  doneRef.current = onDone

  useEffect(() => {
    if (!recording) return
    const timer = window.setInterval(() => setSeconds((s) => s + 1), 1000)
    return () => window.clearInterval(timer)
  }, [recording])

  useEffect(
    () => () => {
      cancelled.current = true
      recorder.current?.stop()
    },
    [],
  )

  const start = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      const mime = ['audio/webm;codecs=opus', 'audio/webm', 'audio/mp4', 'audio/ogg'].find((m) => MediaRecorder.isTypeSupported(m)) ?? ''
      const rec = new MediaRecorder(stream, mime ? { mimeType: mime } : undefined)
      chunks.current = []
      cancelled.current = false
      rec.ondataavailable = (e) => {
        if (e.data.size) chunks.current.push(e.data)
      }
      rec.onstop = () => {
        stream.getTracks().forEach((track) => track.stop())
        setRecording(false)
        setSeconds(0)
        if (cancelled.current || !chunks.current.length) return
        const type = rec.mimeType || 'audio/webm'
        const ext = type.includes('mp4') ? 'm4a' : type.includes('ogg') ? 'ogg' : 'webm'
        doneRef.current(new File(chunks.current, `voice-${Date.now()}.${ext}`, { type: type.split(';')[0] }))
      }
      rec.start()
      recorder.current = rec
      setRecording(true)
    } catch {
      onDenied()
    }
  }

  const stop = (cancel = false) => {
    cancelled.current = cancel
    recorder.current?.stop()
    recorder.current = null
  }

  return { recording, seconds, start, stop }
}

export const formatClock = (seconds: number) => `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`
