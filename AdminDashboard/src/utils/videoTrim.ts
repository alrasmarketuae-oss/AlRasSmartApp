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
  video.crossOrigin = 'anonymous'

  try {
    await new Promise<void>((resolve, reject) => {
      video.onloadedmetadata = () => resolve()
      video.onerror = () => reject(new Error('Could not load video'))
    })

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
    await new Promise<void>((resolve, reject) => {
      const onSeeked = () => {
        video.removeEventListener('seeked', onSeeked)
        resolve()
      }
      video.addEventListener('seeked', onSeeked)
      window.setTimeout(() => {
        video.removeEventListener('seeked', onSeeked)
        reject(new Error('Could not seek video'))
      }, 8000)
    })

    recorder.start(250)
    await video.play()

    const trimMs = Math.max(500, (endSec - startSec) * 1000)
    await new Promise<void>((resolve) => {
      window.setTimeout(() => resolve(), trimMs + 200)
    })

    video.pause()
    if (recorder.state !== 'inactive') recorder.stop()

    const trimmedBlob = await blobPromise
    if (!trimmedBlob.size) {
      throw new Error('Trimmed video is empty')
    }

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
