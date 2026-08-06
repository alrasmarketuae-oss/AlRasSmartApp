function pickRecorderMimeType(): string {
  const candidates = ['video/webm;codecs=vp8', 'video/webm', 'video/mp4']
  for (const type of candidates) {
    if (typeof MediaRecorder !== 'undefined' && MediaRecorder.isTypeSupported(type)) {
      return type
    }
  }
  return 'video/webm'
}

function containerMime(mime: string): string {
  if (mime.includes('mp4')) return 'video/mp4'
  return 'video/webm'
}

function extensionForMime(mime: string): string {
  return mime.includes('mp4') ? 'mp4' : 'webm'
}

function waitForEvent(target: HTMLVideoElement, event: keyof HTMLMediaElementEventMap): Promise<void> {
  return new Promise((resolve, reject) => {
    const onSuccess = () => {
      cleanup()
      resolve()
    }
    const onFailure = () => {
      cleanup()
      reject(new Error('Could not load video'))
    }
    const cleanup = () => {
      target.removeEventListener(event, onSuccess)
      target.removeEventListener('error', onFailure)
    }
    target.addEventListener(event, onSuccess, { once: true })
    target.addEventListener('error', onFailure, { once: true })
  })
}

function waitForSeek(video: HTMLVideoElement): Promise<void> {
  return new Promise((resolve, reject) => {
    const timeout = window.setTimeout(() => {
      cleanup()
      reject(new Error('Could not seek video'))
    }, 10000)

    const onSeeked = () => {
      cleanup()
      resolve()
    }

    const cleanup = () => {
      window.clearTimeout(timeout)
      video.removeEventListener('seeked', onSeeked)
    }

    video.addEventListener('seeked', onSeeked)
  })
}

async function validateVideoBlob(blob: Blob): Promise<void> {
  if (!blob.size) {
    throw new Error('Trimmed video is empty')
  }

  const url = URL.createObjectURL(blob)
  const video = document.createElement('video')
  video.src = url
  video.muted = true
  video.preload = 'auto'

  try {
    await waitForEvent(video, 'loadedmetadata')
    if (!Number.isFinite(video.duration) || video.duration <= 0) {
      throw new Error('Trimmed video is invalid')
    }
  } finally {
    URL.revokeObjectURL(url)
  }
}

/**
 * Trim a video segment in the browser and return a File ready for upload.
 */
export async function trimVideoToFile(
  sourceBlob: Blob,
  startSec: number,
  endSec: number,
): Promise<{ file: File; durationSeconds: number }> {
  if (endSec <= startSec) {
    throw new Error('Invalid trim range')
  }

  const url = URL.createObjectURL(sourceBlob)
  const video = document.createElement('video')
  video.src = url
  video.muted = true
  video.playsInline = true
  video.preload = 'auto'

  try {
    await waitForEvent(video, 'loadedmetadata')
    await waitForEvent(video, 'canplay')

    const recorderMime = pickRecorderMimeType()
    const fileMime = containerMime(recorderMime)
    const videoWithCapture = video as HTMLVideoElement & {
      captureStream?: (frameRate?: number) => MediaStream
      mozCaptureStream?: (frameRate?: number) => MediaStream
    }
    const captureStream =
      videoWithCapture.captureStream ?? videoWithCapture.mozCaptureStream

    if (!captureStream) {
      throw new Error('Video trim is not supported in this browser')
    }

    const stream = captureStream.call(videoWithCapture, 30)
    const recorder = new MediaRecorder(stream, {
      mimeType: recorderMime,
      videoBitsPerSecond: 2_500_000,
    })
    const chunks: BlobPart[] = []

    recorder.ondataavailable = (event) => {
      if (event.data.size > 0) chunks.push(event.data)
    }

    const blobPromise = new Promise<Blob>((resolve, reject) => {
      recorder.onstop = () => resolve(new Blob(chunks, { type: fileMime }))
      recorder.onerror = () => reject(new Error('Trim recording failed'))
    })

    video.currentTime = Math.max(0, startSec)
    await waitForSeek(video)

    recorder.start(100)
    await video.play()

    await new Promise<void>((resolve, reject) => {
      const trimMs = Math.max(500, (endSec - startSec) * 1000)
      const timeout = window.setTimeout(() => {
        cleanup()
        reject(new Error('Trim timed out'))
      }, trimMs + 15000)

      const onTimeUpdate = () => {
        if (video.currentTime >= endSec - 0.05) {
          cleanup()
          resolve()
        }
      }

      const cleanup = () => {
        window.clearTimeout(timeout)
        video.removeEventListener('timeupdate', onTimeUpdate)
        video.pause()
      }

      video.addEventListener('timeupdate', onTimeUpdate)
    })

    if (recorder.state !== 'inactive') {
      recorder.requestData()
      recorder.stop()
    }

    const trimmedBlob = await blobPromise
    await validateVideoBlob(trimmedBlob)

    const durationSeconds = Math.max(1, Math.min(180, Math.round(endSec - startSec)))
    const ext = extensionForMime(fileMime)
    const file = new File([trimmedBlob], `trimmed-${Date.now()}.${ext}`, {
      type: fileMime,
    })
    return { file, durationSeconds }
  } finally {
    URL.revokeObjectURL(url)
  }
}
