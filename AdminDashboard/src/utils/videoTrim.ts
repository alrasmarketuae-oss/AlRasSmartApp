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

/**
 * MediaRecorder WebM often reports duration as Infinity until seeked to the end.
 * Accept the blob if it loads and either has a finite duration or a seekable end.
 */
async function validateVideoBlob(blob: Blob): Promise<void> {
  if (!blob.size) {
    throw new Error('Trimmed video is empty')
  }

  // Very tiny outputs are almost always corrupt (headers only / no frames).
  if (blob.size < 1024) {
    throw new Error('Trimmed video is invalid')
  }

  const url = URL.createObjectURL(blob)
  const video = document.createElement('video')
  video.src = url
  video.muted = true
  video.playsInline = true
  video.preload = 'auto'

  try {
    await waitForEvent(video, 'loadedmetadata')

    if (Number.isFinite(video.duration) && video.duration > 0) {
      return
    }

    // Probe duration for WebM/MediaRecorder blobs that report Infinity.
    await new Promise<void>((resolve, reject) => {
      const timeout = window.setTimeout(() => {
        cleanup()
        // Blob has frames and loaded — Infinity duration is common and still uploadable.
        if (blob.size >= 8_000) {
          resolve()
          return
        }
        reject(new Error('Trimmed video is invalid'))
      }, 8000)

      const onSeeked = () => {
        const ok =
          (Number.isFinite(video.duration) && video.duration > 0) ||
          (Number.isFinite(video.currentTime) && video.currentTime > 0) ||
          blob.size >= 8_000
        cleanup()
        if (ok) resolve()
        else reject(new Error('Trimmed video is invalid'))
      }

      const cleanup = () => {
        window.clearTimeout(timeout)
        video.removeEventListener('seeked', onSeeked)
      }

      video.addEventListener('seeked', onSeeked)
      try {
        video.currentTime = 1e10
      } catch {
        cleanup()
        if (blob.size >= 8_000) resolve()
        else reject(new Error('Trimmed video is invalid'))
      }
    })
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
    if (stream.getVideoTracks().length === 0) {
      throw new Error('Video trim is not supported in this browser')
    }

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

    // Ensure a painted frame before recording starts (avoids empty WebM headers).
    try {
      await video.play()
      await new Promise<void>((resolve) => {
        requestAnimationFrame(() => requestAnimationFrame(() => resolve()))
      })
    } catch {
      throw new Error('Could not play video for trimming')
    }

    recorder.start(250)

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

      const onEnded = () => {
        cleanup()
        resolve()
      }

      const cleanup = () => {
        window.clearTimeout(timeout)
        video.removeEventListener('timeupdate', onTimeUpdate)
        video.removeEventListener('ended', onEnded)
        video.pause()
      }

      video.addEventListener('timeupdate', onTimeUpdate)
      video.addEventListener('ended', onEnded)
    })

    if (recorder.state !== 'inactive') {
      recorder.requestData()
      recorder.stop()
    }

    for (const track of stream.getTracks()) {
      track.stop()
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
