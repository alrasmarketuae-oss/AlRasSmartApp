function pickRecorderMimeType(): string {
  const candidates = [
    'video/webm;codecs=vp9',
    'video/webm;codecs=vp8',
    'video/webm',
    'video/mp4',
  ]
  for (const type of candidates) {
    if (typeof MediaRecorder !== 'undefined' && MediaRecorder.isTypeSupported(type)) {
      return type
    }
  }
  return 'video/webm'
}

function extensionForMime(mime: string): string {
  if (mime.includes('mp4')) return 'mp4'
  if (mime.includes('webm')) return 'webm'
  return 'mp4'
}

/**
 * Trim a video segment in the browser (upload trimmed file to replace the original).
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

  await new Promise<void>((resolve, reject) => {
    video.onloadedmetadata = () => resolve()
    video.onerror = () => reject(new Error('Could not load video'))
  })

  const mimeType = pickRecorderMimeType()
  const videoWithCapture = video as HTMLVideoElement & {
    captureStream?: () => MediaStream
    mozCaptureStream?: () => MediaStream
  }
  const captureStream = videoWithCapture.captureStream ?? videoWithCapture.mozCaptureStream

  if (!captureStream) {
    URL.revokeObjectURL(url)
    throw new Error('Video trim is not supported in this browser')
  }

  const stream = captureStream.call(videoWithCapture)
  const recorder = new MediaRecorder(stream, { mimeType })
  const chunks: BlobPart[] = []

  recorder.ondataavailable = (event) => {
    if (event.data.size > 0) chunks.push(event.data)
  }

  const blobPromise = new Promise<Blob>((resolve, reject) => {
    recorder.onstop = () => resolve(new Blob(chunks, { type: mimeType }))
    recorder.onerror = () => reject(new Error('Trim recording failed'))
  })

  recorder.start(200)
  video.currentTime = startSec
  await new Promise<void>((resolve) => {
    video.onseeked = () => resolve()
  })
  await video.play()

  const trimMs = (endSec - startSec) * 1000
  await new Promise<void>((resolve) => {
    window.setTimeout(() => resolve(), trimMs + 150)
  })

  video.pause()
  if (recorder.state !== 'inactive') recorder.stop()

  const trimmedBlob = await blobPromise
  URL.revokeObjectURL(url)

  const durationSeconds = Math.max(1, Math.min(180, Math.ceil(endSec - startSec)))
  const ext = extensionForMime(mimeType)
  const file = new File([trimmedBlob], `trimmed-${Date.now()}.${ext}`, { type: mimeType })
  return { file, durationSeconds }
}
