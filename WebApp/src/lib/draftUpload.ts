import { api, ApiError } from './api'

type Presign = { uploadUrl?: string; UploadUrl?: string; path?: string; Path?: string; contentType?: string; ContentType?: string }

const MAX_IMAGE_SIDE = 1920

export const isVideoFile = (file: File) => file.type.startsWith('video/') || /\.(mp4|mov|webm|m4v|avi|mkv)$/i.test(file.name)

/** The image presign is always signed for `image/jpeg`, so every picture is re-encoded before the PUT. */
export async function toJpeg(file: File, quality = 0.82): Promise<Blob> {
  const bitmap = await createImageBitmap(file).catch(() => null)
  if (!bitmap) return file
  const scale = Math.min(1, MAX_IMAGE_SIDE / Math.max(bitmap.width, bitmap.height))
  const canvas = document.createElement('canvas')
  canvas.width = Math.round(bitmap.width * scale)
  canvas.height = Math.round(bitmap.height * scale)
  const ctx = canvas.getContext('2d')
  if (!ctx) return file
  ctx.fillStyle = '#fff'
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  ctx.drawImage(bitmap, 0, 0, canvas.width, canvas.height)
  bitmap.close()
  return new Promise((resolve) => canvas.toBlob((blob) => resolve(blob ?? file), 'image/jpeg', quality))
}

async function presignAndPut(endpoint: string, body: unknown, blob: Blob, fallbackType: string) {
  const presign = await api.post<Presign>(endpoint, body)
  const uploadUrl = presign.uploadUrl ?? presign.UploadUrl
  const path = presign.path ?? presign.Path
  if (!uploadUrl || !path) throw new ApiError('Upload could not be prepared', 0, presign)
  const put = await fetch(uploadUrl, { method: 'PUT', body: blob, headers: { 'Content-Type': presign.contentType ?? presign.ContentType ?? fallbackType } })
  if (!put.ok) throw new ApiError(`Upload failed (${put.status})`, put.status, null)
  return path
}

/** Uploads to the product draft area and returns the draft path used by create-ad and the AI plan mode. */
export async function uploadDraftImage(file: File) {
  return presignAndPut('/ProductAssets/draft/images/presign', {}, await toJpeg(file), 'image/jpeg')
}

export async function uploadDraftVideo(file: File) {
  const contentType = file.type || 'video/mp4'
  return presignAndPut('/ProductAssets/draft/videos/presign', { fileName: file.name, contentType }, file, contentType)
}

export function videoDurationSeconds(file: File): Promise<number> {
  return new Promise((resolve) => {
    const url = URL.createObjectURL(file)
    const video = document.createElement('video')
    video.preload = 'metadata'
    const done = (value: number) => {
      URL.revokeObjectURL(url)
      resolve(value)
    }
    video.onloadedmetadata = () => done(Number.isFinite(video.duration) ? Math.round(video.duration) : 0)
    video.onerror = () => done(0)
    video.src = url
  })
}
