import { apiUrl } from '../config/api.js'
import { getAuthToken } from '../lib/authStorage'
import type { ChatUploadImagesResult, ChatUploadResult } from '../types/chat'

type ChatPresignResponse = {
  uploadUrl?: string
  UploadUrl?: string
  path?: string
  Path?: string
  contentType?: string
  ContentType?: string
}

type MessageType = 2 | 3 | 5 | 6

function extensionFromFile(file: File): string {
  const fromName = file.name.includes('.')
    ? `.${file.name.split('.').pop()!.toLowerCase()}`
    : ''
  if (fromName.length > 1) return fromName

  const mime = (file.type || '').toLowerCase()
  if (mime.includes('jpeg') || mime.includes('jpg')) return '.jpg'
  if (mime.includes('png')) return '.png'
  if (mime.includes('webm')) return '.webm'
  if (mime.includes('mp4')) return '.mp4'
  if (mime.includes('quicktime')) return '.mov'
  if (mime.includes('mpeg') || mime.includes('mp3')) return '.mp3'
  if (mime.includes('ogg')) return '.ogg'
  if (mime.includes('wav')) return '.wav'
  if (mime.includes('aac') || mime.includes('m4a')) return '.m4a'
  return ''
}

function defaultContentType(messageType: MessageType, file: File): string {
  if (file.type) return file.type
  return messageType === 3
    ? 'image/jpeg'
    : messageType === 5
      ? 'video/mp4'
      : messageType === 2
        ? 'audio/mp4'
        : 'application/octet-stream'
}

function serializeImagePaths(paths: string[]): string {
  const normalized = paths.map((p) => p.trim()).filter(Boolean)
  if (normalized.length === 0) {
    throw new Error('At least one image path is required.')
  }
  if (normalized.length === 1) return normalized[0]
  return JSON.stringify({ images: normalized })
}

async function readJson(response: Response): Promise<Record<string, unknown>> {
  const data: unknown = await response.json().catch(() => ({}))
  return data && typeof data === 'object' ? (data as Record<string, unknown>) : {}
}

function authHeaders(): HeadersInit {
  const token = getAuthToken()
  return token ? { Authorization: `Bearer ${token}` } : {}
}

async function multipartUpload(
  file: File,
  messageType: MessageType,
): Promise<ChatUploadResult> {
  const form = new FormData()
  form.append('File', file)
  form.append('MessageType', String(messageType))

  const response = await fetch(apiUrl('/api/Chat/upload'), {
    method: 'POST',
    headers: authHeaders(),
    body: form,
  })
  const data = await readJson(response)
  if (!response.ok) {
    throw new Error(String(data.message ?? 'تعذر رفع الملف.'))
  }
  return data as unknown as ChatUploadResult
}

async function multipartUploadImages(files: File[]): Promise<ChatUploadImagesResult> {
  const form = new FormData()
  files.forEach((file) => form.append('Files', file))

  const response = await fetch(apiUrl('/api/Chat/upload-images'), {
    method: 'POST',
    headers: authHeaders(),
    body: form,
  })
  const data = await readJson(response)
  if (!response.ok) {
    throw new Error(String(data.message ?? 'تعذر رفع الصور.'))
  }

  return {
    paths: (data.paths as string[] | undefined) ?? [],
    content: String(data.content ?? ''),
    messageType: 3,
  }
}

async function requestPresign(
  messageType: MessageType,
  file: File,
): Promise<ChatPresignResponse | null> {
  const extension = extensionFromFile(file)
  let url = ''
  let body: Record<string, string> = {}

  switch (messageType) {
    case 3:
      url = apiUrl('/api/Chat/presign/image')
      body = {}
      break
    case 5:
      url = apiUrl('/api/Chat/presign/video')
      body = { extension }
      break
    case 2:
      url = apiUrl('/api/Chat/presign/voice')
      body = { extension }
      break
    case 6:
      url = apiUrl('/api/Chat/presign/file')
      body = { fileName: file.name }
      break
    default:
      return null
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      ...authHeaders(),
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  })

  if (response.status === 503 || response.status === 404) {
    return null
  }

  const data = await readJson(response)
  if (!response.ok) {
    throw new Error(String(data.message ?? `Chat presign failed (${response.status})`))
  }

  return data as ChatPresignResponse
}

async function putToR2(uploadUrl: string, file: File, contentType: string): Promise<void> {
  const response = await fetch(uploadUrl, {
    method: 'PUT',
    headers: { 'Content-Type': contentType },
    body: file,
  })
  if (!response.ok) {
    throw new Error(`Chat direct upload failed (${response.status})`)
  }
}

async function confirmUpload(
  path: string,
  messageType: MessageType,
  file: File,
): Promise<ChatUploadResult> {
  const response = await fetch(apiUrl('/api/Chat/confirm-upload'), {
    method: 'POST',
    headers: {
      ...authHeaders(),
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      path,
      messageType,
      fileName: messageType === 6 ? file.name : undefined,
      sizeBytes: messageType === 6 ? file.size : undefined,
    }),
  })
  const data = await readJson(response)
  if (!response.ok) {
    throw new Error(String(data.message ?? `Chat upload confirm failed (${response.status})`))
  }
  return data as unknown as ChatUploadResult
}

/** Presign → PUT R2 → confirm. Falls back to multipart when R2 presign is unavailable. */
export async function uploadChatMediaDirect(
  file: File,
  messageType: MessageType,
): Promise<ChatUploadResult> {
  try {
    const presign = await requestPresign(messageType, file)
    if (!presign) {
      return multipartUpload(file, messageType)
    }

    const uploadUrl = presign.uploadUrl ?? presign.UploadUrl
    const path = presign.path ?? presign.Path
    const contentType =
      presign.contentType ??
      presign.ContentType ??
      defaultContentType(messageType, file)

    if (!uploadUrl || !path) {
      return multipartUpload(file, messageType)
    }

    await putToR2(uploadUrl, file, contentType)
    return confirmUpload(path, messageType, file)
  } catch (error) {
    // Soft-fallback for transient R2 issues; keep chat usable.
    if (error instanceof Error && /presign|direct upload|503|404/i.test(error.message)) {
      return multipartUpload(file, messageType)
    }
    throw error
  }
}

export async function uploadChatImagesDirect(files: File[]): Promise<ChatUploadImagesResult> {
  if (files.length === 0) {
    throw new Error('At least one image file is required.')
  }

  try {
    const paths: string[] = []
    for (const file of files) {
      const result = await uploadChatMediaDirect(file, 3)
      const path = result.content?.trim()
      if (!path) {
        throw new Error('Chat image upload returned empty path.')
      }
      paths.push(path)
    }

    return {
      paths,
      content: serializeImagePaths(paths),
      messageType: 3,
    }
  } catch {
    return multipartUploadImages(files)
  }
}
