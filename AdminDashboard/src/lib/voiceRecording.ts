import { resolveAssetUrl } from './assets'

const VOICE_MIME_CANDIDATES = [
  'audio/webm;codecs=opus',
  'audio/webm',
  'audio/mp4',
  'audio/aac',
  'audio/ogg;codecs=opus',
  'audio/ogg',
] as const

const IOS_VOICE_MIME_CANDIDATES = [
  'audio/mp4',
  'audio/aac',
  'audio/webm;codecs=opus',
  'audio/webm',
  'audio/ogg;codecs=opus',
  'audio/ogg',
] as const

export function isApplePlatform(): boolean {
  if (typeof navigator === 'undefined') return false

  const ua = navigator.userAgent
  if (/iPad|iPhone|iPod/.test(ua)) return true

  return navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1
}

export function pickVoiceRecorderMimeType(): string | undefined {
  if (typeof MediaRecorder === 'undefined') return undefined

  const candidates = isApplePlatform() ? IOS_VOICE_MIME_CANDIDATES : VOICE_MIME_CANDIDATES

  for (const mimeType of candidates) {
    if (MediaRecorder.isTypeSupported(mimeType)) {
      return mimeType
    }
  }

  return undefined
}

export function voiceExtensionFromMime(mimeType: string | undefined): string {
  const mime = (mimeType ?? '').toLowerCase().split(';')[0]?.trim() ?? ''

  if (mime.includes('mp4') || mime.includes('aac')) return '.m4a'
  if (mime.includes('caf')) return '.caf'
  if (mime.includes('webm')) return '.webm'
  if (mime.includes('ogg')) return '.ogg'
  if (mime.includes('wav')) return '.wav'
  if (mime.includes('mpeg') || mime.includes('mp3')) return '.mp3'
  if (mime.includes('3gp')) return '.3gp'
  if (mime.includes('amr')) return '.amr'

  return isApplePlatform() ? '.m4a' : '.webm'
}

export function voiceMimeFromPath(path: string): string | undefined {
  const ext = path.toLowerCase().split('?')[0]?.split('.').pop() ?? ''

  switch (ext) {
    case 'm4a':
    case 'aac':
    case 'mp4':
      return 'audio/mp4'
    case 'caf':
      return 'audio/x-caf'
    case 'webm':
      return 'audio/webm'
    case 'ogg':
      return 'audio/ogg'
    case 'wav':
      return 'audio/wav'
    case 'mp3':
      return 'audio/mpeg'
    case '3gp':
    case '3gpp':
      return 'audio/3gpp'
    case 'amr':
      return 'audio/amr'
    default:
      return undefined
  }
}

/** رابط تشغيل صوتي من الـ CDN (نفس مسار التخزين على R2). */
export function resolveVoiceUrl(path: string | null | undefined): string {
  if (!path?.trim()) return ''

  const trimmed = path.trim()
  if (trimmed.startsWith('blob:') || trimmed.startsWith('data:')) {
    return trimmed
  }

  // Legacy API voice stream URLs → strip to storage path then resolve via CDN.
  const chatVoiceIdx = trimmed.toLowerCase().indexOf('/chat-voice/')
  if (chatVoiceIdx >= 0) {
    return resolveAssetUrl(decodeURIComponent(trimmed.slice(chatVoiceIdx)))
  }

  return resolveAssetUrl(trimmed)
}

export function createVoiceFile(blob: Blob, mimeType: string | undefined): File {
  const type = mimeType || blob.type || (isApplePlatform() ? 'audio/mp4' : 'audio/webm')
  const extension = voiceExtensionFromMime(type)
  return new File([blob], `voice-${Date.now()}${extension}`, { type })
}
