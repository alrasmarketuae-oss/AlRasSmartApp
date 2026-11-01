import { useQuery } from '@tanstack/react-query'
import { memo, useState } from 'react'
import { Link } from 'react-router-dom'
import { useI18n } from '../i18n/I18nProvider'
import { productPath } from '../products/productLinks'
import { productImages, productTitle } from '../products/productRules'
import { fetchProduct } from '../products/productsApi'
import { Icon } from '../ui/Icon'
import { MessageType, attachmentUrl, parseAskForPrice, parseFile, parseImages, parseLocation, type ChatMessage } from './chatApi'

const timeOf = (iso: string) => new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })

function StatusTicks({ message }: { message: ChatMessage }) {
  if (message.status === 'sending') return <Icon name="clock" size={13} className="opacity-70" />
  if (message.status === 'failed') return <Icon name="info" size={13} className="text-[#FCA5A5]" />
  const double = message.isDelivered || message.isSeen
  return (
    <svg width="16" height="11" viewBox="0 0 16 11" fill="none" stroke={message.isSeen ? '#53BDEB' : 'currentColor'} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" className={message.isSeen ? '' : 'opacity-75'}>
      <path d="M1 6l3 3 6-7" />
      {double && <path d="M6 9l1 0.5L14 2" />}
    </svg>
  )
}

function AskForPriceCard({ productId, fallbackName, code, quantity, mine }: { productId: string; fallbackName: string; code: string; quantity: string; mine: boolean }) {
  const { t, isAr } = useI18n()
  const { data } = useQuery({ queryKey: ['product', productId, 'chat-card'], queryFn: () => fetchProduct(productId), staleTime: 300_000 })
  const image = data ? productImages(data)[0] : ''
  const name = data ? productTitle(data, isAr) : fallbackName
  return (
    <div className={`w-64 max-w-full overflow-hidden rounded-xl ${mine ? 'bg-white/12' : 'bg-[#F4F8FC]'}`}>
      <div className="flex gap-2.5 p-2.5">
        <div className="size-16 shrink-0 overflow-hidden rounded-lg bg-white/60">
          {image ? <img src={image} alt="" className="size-full object-cover" /> : <img src="/assets/logo/brand_mark.png" alt="" className="size-full object-contain p-2 opacity-60" />}
        </div>
        <div className="min-w-0 text-[12px] leading-snug">
          <p className={`font-extrabold ${mine ? 'text-white' : 'text-brand'}`}>{t('chatAskForPriceCard')}</p>
          <p className="line-clamp-2 font-semibold">{name}</p>
          {quantity && <p className="opacity-80">{quantity}</p>}
          {code && (
            <p className="opacity-80" dir="ltr">
              {code}
            </p>
          )}
        </div>
      </div>
      <Link
        to={data ? productPath(data) : `/product/${productId}`}
        className={`block border-t py-2 text-center text-[12px] font-bold ${mine ? 'border-white/20 text-white hover:bg-white/10' : 'border-line text-brand hover:bg-white'}`}
      >
        {t('chatOpenAd')}
      </Link>
    </div>
  )
}

function Body({ message, mine, onOpenImage }: { message: ChatMessage; mine: boolean; onOpenImage: (urls: string[], index: number) => void }) {
  const { t } = useI18n()
  if (message.isDeleted)
    return (
      <p className="flex items-center gap-1.5 text-[13px] italic opacity-75">
        <Icon name="close" size={13} />
        {t('chatDeletedMessage')}
      </p>
    )

  if (message.localFile) {
    if (message.messageType === MessageType.image) return <img src={message.localFile.url} alt="" className="max-h-64 rounded-lg opacity-70" />
    return (
      <p className="flex items-center gap-2 text-[13px]">
        <Icon name={message.messageType === MessageType.video ? 'video' : message.messageType === MessageType.voice ? 'mic' : 'doc'} size={16} />
        {message.localFile.name}
      </p>
    )
  }

  switch (message.messageType) {
    case MessageType.image: {
      const urls = parseImages(message.content).map(attachmentUrl)
      return (
        <div className={`grid gap-1 ${urls.length > 1 ? 'grid-cols-2' : ''}`}>
          {urls.map((url, i) => (
            <button key={url} type="button" onClick={() => onOpenImage(urls, i)} className="overflow-hidden rounded-lg">
              <img src={url} alt="" loading="lazy" className={`${urls.length > 1 ? 'aspect-square' : 'max-h-72'} w-full object-cover`} />
            </button>
          ))}
        </div>
      )
    }
    case MessageType.video:
      return <video src={attachmentUrl(message.content)} controls playsInline preload="metadata" className="max-h-72 w-72 max-w-full rounded-lg bg-black" />
    case MessageType.voice:
      return <audio src={attachmentUrl(message.content)} controls preload="metadata" className="h-10 w-60 max-w-full" />
    case MessageType.location: {
      const loc = parseLocation(message.content)
      if (!loc) return <p className="text-[13px]">{message.content}</p>
      return (
        <a href={`https://www.google.com/maps?q=${loc.lat},${loc.lng}`} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2.5">
          <span className={`grid size-11 place-items-center rounded-lg ${mine ? 'bg-white/15' : 'bg-[#EEF4FB] text-brand'}`}>
            <Icon name="location" size={22} />
          </span>
          <span className="text-[13px]">
            <span className="block font-bold">{loc.label || t('chatMyLocation')}</span>
            <span className="underline opacity-80">{t('chatOpenInMaps')}</span>
          </span>
        </a>
      )
    }
    case MessageType.file: {
      const file = parseFile(message.content)
      return (
        <a href={attachmentUrl(file.path)} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2.5">
          <span className={`grid size-11 shrink-0 place-items-center rounded-lg ${mine ? 'bg-white/15' : 'bg-[#FDECEC] text-[#DC2626]'}`}>
            <Icon name="doc" size={20} />
          </span>
          <span className="min-w-0 text-[13px]">
            <span className="block truncate font-bold">{file.name}</span>
            {file.size ? <span className="opacity-75">{(file.size / 1024 / 1024).toFixed(2)} MB</span> : null}
          </span>
        </a>
      )
    }
    default: {
      const ask = parseAskForPrice(message.content)
      if (ask) return <AskForPriceCard productId={ask.productId} fallbackName={ask.name} code={ask.code} quantity={ask.quantity} mine={mine} />
      return <p className="whitespace-pre-wrap break-words text-[14px] leading-relaxed">{message.content}</p>
    }
  }
}

type Props = {
  message: ChatMessage
  mine: boolean
  onReply: (m: ChatMessage) => void
  onDelete: (m: ChatMessage, scope: 'me' | 'everyone') => void
  onRetry: (m: ChatMessage) => void
  onOpenImage: (urls: string[], index: number) => void
}

function ChatBubbleImpl({ message, mine, onReply, onDelete, onRetry, onOpenImage }: Props) {
  const { t } = useI18n()
  const [menu, setMenu] = useState(false)
  const canAct = !message.status && !message.isDeleted

  return (
    <div className={`group flex ${mine ? 'justify-end' : 'justify-start'}`}>
      <div className={`relative flex max-w-[82%] items-end gap-1 sm:max-w-[70%] ${mine ? 'flex-row-reverse' : ''}`}>
        <div
          onContextMenu={(e) => {
            if (!canAct) return
            e.preventDefault()
            setMenu(true)
          }}
          onDoubleClick={() => canAct && onReply(message)}
          className={`rounded-2xl px-3 py-2 shadow-[0_1px_2px_rgba(15,23,42,0.08)] ${
            mine ? 'rounded-ee-md bg-gradient-to-br from-[#2F6AAD] to-[#3A7DC5] text-white' : 'rounded-es-md border border-line bg-white text-title'
          }`}
        >
          {message.isForwarded && (
            <p className="mb-1 flex items-center gap-1 text-[11px] italic opacity-75">
              <Icon name="arrowForward" size={12} />
              {t('chatForwarded')}
            </p>
          )}
          {!mine && message.supportAgentName && <p className="mb-0.5 text-[11px] font-bold text-[#3A7DC5]">{message.supportAgentName}</p>}
          {message.replyToPreview && (
            <div className={`mb-1.5 rounded-lg border-s-[3px] px-2 py-1 text-[12px] ${mine ? 'border-white/70 bg-white/12' : 'border-brand bg-[#F4F8FC]'}`}>
              <p className="font-bold opacity-80">{t('chatReplyTo')}</p>
              <p className="line-clamp-2 opacity-90">{message.replyToPreview}</p>
            </div>
          )}
          <Body message={message} mine={mine} onOpenImage={onOpenImage} />
          <div className={`mt-1 flex items-center justify-end gap-1 text-[10.5px] ${mine ? 'text-white/80' : 'text-subtitle'}`} dir="ltr">
            {message.isEdited && <span>✎</span>}
            <span>{timeOf(message.sentAtUtc)}</span>
            {mine && <StatusTicks message={message} />}
          </div>
        </div>
        {canAct && (
          <button
            type="button"
            onClick={() => setMenu((v) => !v)}
            aria-label="More"
            className="grid size-7 shrink-0 place-items-center rounded-full text-subtitle opacity-0 transition hover:bg-black/5 group-hover:opacity-100 max-sm:opacity-60"
          >
            <Icon name="more" size={16} strokeWidth={3} />
          </button>
        )}
        {menu && (
          <>
            <button type="button" aria-label="Close" className="fixed inset-0 z-40 cursor-default" onClick={() => setMenu(false)} />
            <div className={`absolute bottom-full z-50 mb-1 min-w-44 overflow-hidden rounded-xl border border-line bg-white py-1 text-[13px] text-title shadow-xl ${mine ? 'end-0' : 'start-0'}`}>
              {[
                { label: t('chatReply'), icon: 'chat' as const, run: () => onReply(message) },
                ...(message.messageType === MessageType.text ? [{ label: t('chatCopy'), icon: 'copy' as const, run: () => void navigator.clipboard?.writeText(message.content) }] : []),
                { label: t('chatDeleteForMe'), icon: 'trash' as const, run: () => onDelete(message, 'me') },
                ...(mine ? [{ label: t('chatDeleteForEveryone'), icon: 'trash' as const, run: () => onDelete(message, 'everyone'), danger: true }] : []),
              ].map((item) => (
                <button
                  key={item.label}
                  type="button"
                  onClick={() => {
                    setMenu(false)
                    item.run()
                  }}
                  className={`flex w-full items-center gap-2.5 px-3.5 py-2 text-start hover:bg-[#F4F8FC] ${'danger' in item && item.danger ? 'text-[#DC2626]' : ''}`}
                >
                  <Icon name={item.icon} size={16} />
                  {item.label}
                </button>
              ))}
            </div>
          </>
        )}
      </div>
      {message.status === 'failed' && (
        <button type="button" onClick={() => onRetry(message)} className="ms-2 self-center text-[11px] font-semibold text-[#DC2626] hover:underline">
          {t('chatFailedTapRetry')}
        </button>
      )}
    </div>
  )
}

export const ChatBubble = memo(ChatBubbleImpl)
