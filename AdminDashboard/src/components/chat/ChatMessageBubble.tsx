import { useState } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { formatChatRelativeTime } from '../../utils/formatChatRelativeTime'
import { resolveAssetUrl } from '../../lib/assets'
import type { GalleryMediaItem } from '../ui/ImageGallery'
import VoiceAudioPlayer from './VoiceAudioPlayer'
import {
  formatFileSize,
  parseFileContent,
  parseImageContent,
  parseLocationContent,
  type ChatMessage,
} from '../../types/chat'
import { IconDocument, IconMapPin, IconMic } from '../icons'

type ChatMessageBubbleProps = {
  message: ChatMessage
  isMine: boolean
  onOpenMedia?: (item: GalleryMediaItem) => void
}

export default function ChatMessageBubble({
  message,
  isMine,
  onOpenMedia,
}: ChatMessageBubbleProps) {
  const { t, locale } = useAppPreferences()
  const timeLabel =
    formatChatRelativeTime(message.sentAtUtc, locale) || message.relativeTime

  return (
    <div className={`flex ${isMine ? 'justify-end' : 'justify-start'}`}>
      <div
        translate="no"
        className={`notranslate max-w-[88%] rounded-2xl px-3 py-2 shadow-sm sm:max-w-[85%] sm:px-3.5 sm:py-2.5 ${
          isMine
            ? 'chat-bubble-mine rounded-ee-md'
            : 'chat-bubble-theirs rounded-es-md'
        } ${message.deliveryStatus === 'failed' ? 'ring-2 ring-red-300/80' : ''}`}
      >
        {message.isDeleted ? (
          <p className="text-sm italic opacity-80">{t('chat.deletedMessage')}</p>
        ) : (
          <>
            {message.isForwarded ? (
              <p className={`mb-1 text-[11px] font-semibold ${isMine ? 'text-white/80' : 'text-slate-500'}`}>
                {t('chat.forwarded')}
              </p>
            ) : null}
            {message.replyToMessageId ? (
              <div
                className={`mb-1.5 rounded-lg border-s-2 px-2 py-1 text-xs ${
                  isMine
                    ? 'border-white/70 bg-white/15 text-white/90'
                    : 'border-[#3B7FC7] bg-[#3B7FC7]/10 text-slate-600 dark:text-slate-300'
                }`}
              >
                <p className="font-semibold">{t('chat.replyTo')}</p>
                <p className="notranslate line-clamp-2" translate="no">
                  {message.replyToPreview || t('chat.deletedMessage')}
                </p>
              </div>
            ) : null}
            <MessageBody
              message={message}
              isMine={isMine}
              onOpenMedia={onOpenMedia}
            />
          </>
        )}
        <div
          className={`mt-1.5 flex items-center justify-end gap-2 text-[10px] ${
            isMine ? 'opacity-80' : 'text-slate-500 dark:text-slate-400'
          }`}
        >
          <span>{timeLabel}</span>
          {message.isEdited && !message.isDeleted ? <span>· {t('chat.edited')}</span> : null}
          {isMine ? <DeliveryIndicator message={message} /> : null}
        </div>
      </div>
    </div>
  )
}

function DeliveryIndicator({ message }: { message: ChatMessage }) {
  if (message.deliveryStatus === 'sending') {
    return (
      <span className="inline-flex items-center gap-1 font-semibold opacity-90" aria-label="sending">
        <span className="inline-block h-2 w-2 animate-pulse rounded-full bg-current" />
      </span>
    )
  }

  if (message.deliveryStatus === 'failed') {
    return <span className="font-semibold text-red-200">!</span>
  }

  if (message.isSeen) {
    return <span className="font-semibold text-[#53bdeb]">✓✓</span>
  }

  if (message.isDelivered) {
    return <span className="font-semibold text-white/75">✓✓</span>
  }

  return <span className="font-semibold text-white/75">✓</span>
}

function MessageBody({ message, isMine, onOpenMedia }: ChatMessageBubbleProps) {
  switch (message.messageType) {
    case 3:
      return <ChatImageMessage message={message} onOpenMedia={onOpenMedia} />
    case 2:
      return <ChatVoiceMessage message={message} isMine={isMine} />
    case 5:
      return <ChatVideoMessage message={message} onOpenMedia={onOpenMedia} />
    case 6:
      return <ChatFileMessage message={message} isMine={isMine} />
    case 4: {
      const location = parseLocationContent(message.content)
      if (!location) {
        return (
          <p className="notranslate whitespace-pre-wrap break-words text-sm leading-relaxed" translate="no">
            {message.content}
          </p>
        )
      }
      const mapsUrl = `https://www.google.com/maps?q=${location.lat},${location.lng}`
      return (
        <a
          href={mapsUrl}
          target="_blank"
          rel="noreferrer"
          className={`inline-flex items-center gap-2 rounded-xl px-2 py-1 text-sm font-medium ${
            isMine ? 'bg-white/20' : 'bg-[#3B7FC7]/10'
          }`}
        >
          <IconMapPin className="h-4 w-4 shrink-0" />
          <span className="notranslate" translate="no">
            {location.label ?? `${location.lat.toFixed(5)}, ${location.lng.toFixed(5)}`}
          </span>
        </a>
      )
    }
    default:
      return (
        <p className="notranslate whitespace-pre-wrap break-words text-sm leading-relaxed" translate="no">
          {message.content}
        </p>
      )
  }
}

function mediaSource(path: string, message: ChatMessage): string {
  if (path.startsWith('blob:')) {
    return path
  }

  if (message.localPreviewUrl && path === message.content) {
    return message.localPreviewUrl
  }

  return resolveAssetUrl(path)
}

export function getChatGalleryItems(message: ChatMessage): GalleryMediaItem[] {
  if (message.isDeleted) return []
  if (message.messageType === 3) {
    const imagePaths = parseImageContent(message.content)
    const displayPaths = imagePaths.length > 0 ? imagePaths : [message.content]
    return displayPaths.map((path, index) => ({
      src: mediaSource(path, message),
      kind: 'image' as const,
      path: `${message.messageId}:${index}`,
    }))
  }
  if (message.messageType === 5) {
    return [
      {
        src: mediaSource(message.content, message),
        kind: 'video',
        path: `${message.messageId}:0`,
      },
    ]
  }
  return []
}

function ChatImageMessage({
  message,
  onOpenMedia,
}: {
  message: ChatMessage
  onOpenMedia?: (item: GalleryMediaItem) => void
}) {
  const items = getChatGalleryItems(message)

  if (items.length === 1) {
    return <ChatSingleImage item={items[0]} onOpenMedia={onOpenMedia} />
  }

  return (
    <div className="grid grid-cols-2 gap-1">
      {items.map((item) => (
        <ChatSingleImage
          key={item.path}
          item={item}
          compact
          onOpenMedia={onOpenMedia}
        />
      ))}
    </div>
  )
}

function ChatSingleImage({
  item,
  compact = false,
  onOpenMedia,
}: {
  item: GalleryMediaItem
  compact?: boolean
  onOpenMedia?: (item: GalleryMediaItem) => void
}) {
  const [loaded, setLoaded] = useState(false)
  const [failed, setFailed] = useState(false)
  const url = item.src

  return (
    <button
      type="button"
      title="Preview"
      onClick={() => onOpenMedia?.(item)}
      className="relative block overflow-hidden rounded-xl cursor-zoom-in"
    >
      {!loaded && !failed ? (
        <div className={`flex items-center justify-center bg-black/10 text-xs opacity-70 ${compact ? 'h-28 min-w-[120px]' : 'h-40 min-w-[180px]'}`}>
          ...
        </div>
      ) : null}
      {failed ? (
        <div className={`flex items-center justify-center bg-black/10 text-xs opacity-70 ${compact ? 'h-28 min-w-[120px]' : 'h-40 min-w-[180px]'}`}>
          !
        </div>
      ) : (
        <img
          src={url}
          alt=""
          className={`object-cover transition-opacity ${compact ? 'max-h-40' : 'max-h-64'} ${loaded ? 'opacity-100' : 'opacity-0'}`}
          onLoad={() => setLoaded(true)}
          onError={() => setFailed(true)}
        />
      )}
    </button>
  )
}

function ChatVoiceMessage({ message, isMine }: { message: ChatMessage; isMine: boolean }) {
  return (
    <div className="flex items-center gap-2">
      <IconMic className={`h-4 w-4 shrink-0 ${isMine ? 'opacity-90' : 'text-[#3B7FC7] dark:text-[#7eb8ff]'}`} />
      <VoiceAudioPlayer
        content={message.content}
        localPreviewUrl={message.localPreviewUrl}
        isMine={isMine}
      />
    </div>
  )
}

function ChatFileMessage({ message, isMine }: { message: ChatMessage; isMine: boolean }) {
  const file = parseFileContent(message.content)

  if (!file) {
    return (
      <p className="notranslate whitespace-pre-wrap break-words text-sm leading-relaxed" translate="no">
        {message.content}
      </p>
    )
  }

  const sizeLabel = formatFileSize(file.size)
  // Still uploading: no storage path yet, so render the name without a link.
  const href = file.path ? resolveAssetUrl(file.path) : null

  const body = (
    <>
      <span
        className={`inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full ${
          isMine ? 'bg-white/20' : 'bg-[#3B7FC7]/10 text-[#3B7FC7] dark:text-[#7eb8ff]'
        }`}
      >
        <IconDocument className="h-5 w-5" />
      </span>
      <span className="min-w-0">
        <span className="notranslate block truncate text-sm font-medium" translate="no">
          {file.name}
        </span>
        {sizeLabel ? <span className="block text-[11px] opacity-70">{sizeLabel}</span> : null}
      </span>
    </>
  )

  if (!href) {
    return <div className="flex items-center gap-2 py-0.5">{body}</div>
  }

  return (
    <a
      href={href}
      target="_blank"
      rel="noreferrer"
      download={file.name}
      className={`flex items-center gap-2 rounded-xl px-2 py-1.5 transition ${
        isMine ? 'hover:bg-white/10' : 'hover:bg-[#3B7FC7]/10'
      }`}
    >
      {body}
    </a>
  )
}

function ChatVideoMessage({
  message,
  onOpenMedia,
}: {
  message: ChatMessage
  onOpenMedia?: (item: GalleryMediaItem) => void
}) {
  const item = getChatGalleryItems(message)[0]
  if (!item) return null
  return (
    <button
      type="button"
      title="Preview"
      onClick={() => onOpenMedia?.(item)}
      className="relative block w-full max-w-xs overflow-hidden rounded-xl bg-black cursor-zoom-in"
    >
      <video
        src={item.src}
        muted
        playsInline
        preload="metadata"
        className="pointer-events-none max-h-64 w-full object-contain"
      />
      <span className="pointer-events-none absolute inset-0 flex items-center justify-center bg-black/30 text-3xl text-white">
        ▶
      </span>
    </button>
  )
}
