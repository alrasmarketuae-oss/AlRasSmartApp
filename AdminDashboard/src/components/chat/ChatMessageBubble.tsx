import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { formatChatRelativeTime } from '../../utils/formatChatRelativeTime'
import { resolveAssetUrl } from '../../lib/assets'
import { useGetAdminProductDetailQuery } from '../../store'
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
import {
  parseAskSupplierContent,
  type AskSupplierTarget,
} from '../../utils/askSupplierPrice'

export type { AskSupplierTarget }
/** @deprecated Use AskSupplierTarget */
export type AskForPriceSupplierTarget = AskSupplierTarget

const ASK_FOR_PRICE_MARKER = /ASK_FOR_PRICE_PRODUCT:\s*([0-9a-fA-F-]{36})/i
const PRODUCT_ID_LINE = /(?:^|\n)\s*Product ID:\s*([0-9a-fA-F-]{36})/i
const ANY_UUID = /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/
const IMAGE_LINE = /(?:^|\n)\s*Image:\s*(.+)(?:\n|$)/i
const VIDEO_LINE = /(?:^|\n)\s*Video:\s*(.+)(?:\n|$)/i
const PRODUCT_NAME_LINE =
  /(?:^|\n)\s*(?:Product Name|Ø§Ø³Ù… Ø§Ù„Ù…Ù†ØªØ¬|Ø§Ø³Ù… Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†)\s*[:ï¼š]\s*(.+)(?:\n|$)/i
const PRODUCT_CODE_LINE = /(?:^|\n)\s*(?:Product Code|ÙƒÙˆØ¯ Ø§Ù„Ù…Ù†ØªØ¬)\s*[:ï¼š]\s*(.+)(?:\n|$)/i
const SUPPLIER_ID_LINE = /(?:^|\n)\s*Supplier ID:\s*([0-9a-fA-F-]{36})/i
const QUANTITY_LINE =
  /(?:^|\n)\s*(?:Quantity|Ø§Ù„ÙƒÙ…ÙŠØ©|Ø§Ù„ÙƒÙ…ÙŠÙ‡)\s*[:ï¼š]\s*(.+)(?:\n|$)/i
const CUSTOMER_PRICE_LINE =
  /(?:^|\n)\s*(?:Customer Price|Ø³Ø¹Ø± Ø§Ù„Ø¹Ù…ÙŠÙ„)\s*[:ï¼š]\s*(.+)(?:\n|$)/i
const ASK_FOR_PRICE_HINT = /ask\s*for\s*price|Ø·Ù„Ø¨\s*Ø³Ø¹Ø±|Ø§Ø·Ù„Ø¨\s*Ø§Ù„Ø³Ø¹Ø±|Ø§Ø³Ø£Ù„\s*Ø¹Ù†\s*Ø§Ù„Ø³Ø¹Ø±/i

function looksLikeVideoPath(path: string | null | undefined): boolean {
  const lower = (path ?? '').trim().toLowerCase()
  return (
    lower.endsWith('.mp4') ||
    lower.endsWith('.mov') ||
    lower.endsWith('.webm') ||
    lower.endsWith('.m4v') ||
    lower.endsWith('.avi') ||
    lower.endsWith('.mkv')
  )
}

type AskForPricePayload = {
  productId: string
  imagePath: string | null
  videoPath: string | null
  productName: string | null
  productCode: string | null
  supplierId: string | null
  quantityLabel: string | null
  customerPriceLabel: string | null
}

function parseAskForPriceContent(content: string): AskForPricePayload | null {
  const text = content?.trim() ?? ''
  if (!text) return null

  const markerMatch = text.match(ASK_FOR_PRICE_MARKER)
  const idLineMatch = text.match(PRODUCT_ID_LINE)
  const hintMatch = ASK_FOR_PRICE_HINT.test(text)
  const uuidMatch = text.match(ANY_UUID)

  const productId =
    markerMatch?.[1]?.trim() ||
    idLineMatch?.[1]?.trim() ||
    (hintMatch ? uuidMatch?.[0]?.trim() : undefined)

  if (!productId) return null

  const imageMatch = text.match(IMAGE_LINE)
  const videoMatch = text.match(VIDEO_LINE)
  const nameMatch = text.match(PRODUCT_NAME_LINE)
  const codeMatch = text.match(PRODUCT_CODE_LINE)
  const supplierMatch = text.match(SUPPLIER_ID_LINE)
  const quantityMatch = text.match(QUANTITY_LINE)
  const customerPriceMatch = text.match(CUSTOMER_PRICE_LINE)

  const rawImage = imageMatch?.[1]?.trim() || null
  let videoPath = videoMatch?.[1]?.trim() || null
  if (!videoPath && looksLikeVideoPath(rawImage)) {
    videoPath = rawImage
  }

  return {
    productId,
    imagePath: rawImage && !looksLikeVideoPath(rawImage) ? rawImage : null,
    videoPath,
    productName: nameMatch?.[1]?.trim() || null,
    productCode: codeMatch?.[1]?.trim() || null,
    supplierId: supplierMatch?.[1]?.trim() || null,
    quantityLabel: quantityMatch?.[1]?.trim() || null,
    customerPriceLabel: customerPriceMatch?.[1]?.trim() || null,
  }
}

type ChatMessageBubbleProps = {
  message: ChatMessage
  isMine: boolean
  onOpenMedia?: (item: GalleryMediaItem) => void
  onChatWithSupplier?: (target: AskSupplierTarget) => void
}

export default function ChatMessageBubble({
  message,
  isMine,
  onOpenMedia,
  onChatWithSupplier,
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
              onChatWithSupplier={onChatWithSupplier}
            />
          </>
        )}
        <div
          className={`mt-1.5 flex items-center justify-end gap-2 text-[10px] ${
            isMine ? 'opacity-80' : 'text-slate-500 dark:text-slate-400'
          }`}
        >
          <span>{timeLabel}</span>
          {message.isEdited && !message.isDeleted ? <span>Â· {t('chat.edited')}</span> : null}
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
    return <span className="font-semibold text-[#53bdeb]">âœ“âœ“</span>
  }

  if (message.isDelivered) {
    return <span className="font-semibold text-white/75">âœ“âœ“</span>
  }

  return <span className="font-semibold text-white/75">âœ“</span>
}

function MessageBody({
  message,
  isMine,
  onOpenMedia,
  onChatWithSupplier,
}: ChatMessageBubbleProps) {
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
    default: {
      const askSupplier = parseAskSupplierContent(message.content)
      if (askSupplier?.kind === 'ask') {
        return <AskSupplierPriceCard payload={askSupplier} isMine={isMine} />
      }
      if (askSupplier?.kind === 'reply') {
        return <AskSupplierReplyCard payload={askSupplier} isMine={isMine} />
      }
      const askForPrice = parseAskForPriceContent(message.content)
      if (askForPrice) {
        return (
          <AskForPriceProductCard
            payload={askForPrice}
            isMine={isMine}
            onChatWithSupplier={onChatWithSupplier}
          />
        )
      }
      return (
        <p className="notranslate whitespace-pre-wrap break-words text-sm leading-relaxed" translate="no">
          {message.content}
        </p>
      )
    }
  }
}

function AskForPriceProductCard({
  payload,
  isMine,
  onChatWithSupplier,
}: {
  payload: AskForPricePayload
  isMine: boolean
  onChatWithSupplier?: (target: AskSupplierTarget) => void
}) {
  const { t } = useAppPreferences()
  const { data: product, isLoading, isError } = useGetAdminProductDetailQuery(
    { productId: payload.productId },
    { skip: !payload.productId },
  )

  const title = useMemo(() => {
    return (
      product?.name?.trim() ||
      payload.productName?.trim() ||
      t('chat.askForPriceTitle')
    )
  }, [payload.productName, product?.name, t])

  const code = payload.productCode?.trim() || null

  const quantityLabel = useMemo(() => {
    if (payload.quantityLabel?.trim()) return payload.quantityLabel.trim()
    if (!product) return null
    const qty = product.quantity
    const unit = product.unitName?.trim()
    if (qty == null && !unit) return null
    return [qty != null ? String(qty) : null, unit].filter(Boolean).join(' ')
  }, [payload.quantityLabel, product])

  const customerPrice =
    product?.customerPriceFormatted?.trim() ||
    (product?.customerPriceUsd != null ? String(product.customerPriceUsd) : null) ||
    payload.customerPriceLabel?.trim() ||
    null
  const supplierPrice = product?.priceFormatted?.trim() || null

  const imageUrl = useMemo(() => {
    const path =
      product?.primaryImagePath?.trim() ||
      product?.imagePaths?.find((p) => p?.trim() && !looksLikeVideoPath(p))?.trim() ||
      payload.imagePath?.trim() ||
      null
    return path ? resolveAssetUrl(path) : null
  }, [payload.imagePath, product?.imagePaths, product?.primaryImagePath])

  const videoUrl = useMemo(() => {
    if (imageUrl) return null
    const path =
      product?.videoPath?.trim() ||
      product?.videoPaths?.find((p) => p?.trim())?.trim() ||
      payload.videoPath?.trim() ||
      null
    return path ? resolveAssetUrl(path) : null
  }, [imageUrl, payload.videoPath, product?.videoPath, product?.videoPaths])

  const supplierUserId =
    payload.supplierId?.trim() || product?.ownerId?.trim() || null
  const supplierDisplayName =
    product?.ownerCompanyName?.trim() ||
    product?.ownerName?.trim() ||
    t('chat.supplierChat')

  const href = `/ads/${payload.productId}`

  function handleAskSupplier() {
    if (!supplierUserId || !onChatWithSupplier) return
    const imagePath =
      product?.primaryImagePath?.trim() ||
      product?.imagePaths?.find((p) => p?.trim() && !looksLikeVideoPath(p))?.trim() ||
      payload.imagePath?.trim() ||
      null
    onChatWithSupplier({
      supplierUserId,
      displayName: supplierDisplayName,
      avatarUrl: null,
      productId: payload.productId,
      productName: product?.name?.trim() || payload.productName,
      productCode: payload.productCode,
      unitName: product?.unitName?.trim() || null,
      quantityLabel,
      supplierPriceFormatted: product?.priceFormatted?.trim() || null,
      supplierPriceUsd: product?.priceUsd ?? null,
      imagePath,
    })
  }

  return (
    <div
      className={`overflow-hidden rounded-xl border text-start ${
        isMine
          ? 'border-white/35 bg-white/15'
          : 'border-slate-200 bg-white dark:border-slate-600 dark:bg-slate-900'
      }`}
    >
      <div className="flex gap-2.5 p-2 sm:gap-3 sm:p-2.5">
        <div
          className={`relative h-24 w-24 shrink-0 overflow-hidden rounded-lg sm:h-28 sm:w-28 ${
            isMine ? 'bg-white/20' : 'bg-slate-100 dark:bg-slate-800'
          }`}
        >
          {imageUrl ? (
            <img src={imageUrl} alt="" className="h-full w-full object-cover" />
          ) : videoUrl ? (
            <div className="flex h-full w-full items-center justify-center text-xs font-semibold opacity-80">
              â–¶
            </div>
          ) : (
            <div className="flex h-full w-full items-center justify-center text-xs opacity-50">â€”</div>
          )}
        </div>
        <div className="min-w-0 flex-1">
          <p
            className={`text-[10px] font-bold uppercase tracking-wide ${
              isMine ? 'text-white/70' : 'text-slate-500'
            }`}
          >
            {t('chat.askForPriceTitle')}
          </p>
          <p
            className={`notranslate mt-0.5 line-clamp-2 text-sm font-bold leading-snug ${
              isMine ? 'text-white' : 'text-slate-900 dark:text-white'
            }`}
            translate="no"
          >
            {isError ? t('chat.askForPriceOpenAd') : title}
          </p>
          {quantityLabel ? (
            <p
              className={`notranslate mt-0.5 truncate text-[11px] ${
                isMine ? 'text-white/65' : 'text-slate-500 dark:text-slate-400'
              }`}
              translate="no"
            >
              {quantityLabel}
            </p>
          ) : null}
          {code ? (
            <p
              className={`notranslate mt-0.5 truncate text-[11px] ${
                isMine ? 'text-white/65' : 'text-slate-500 dark:text-slate-400'
              }`}
              translate="no"
            >
              {code}
            </p>
          ) : null}
          <div className="mt-1.5 space-y-0.5">
            {customerPrice ? (
              <p
                className={`notranslate text-sm font-bold ${
                  isMine ? 'text-[#7dffa8]' : 'text-[#619d51]'
                }`}
                translate="no"
              >
                <span className={`me-1 text-[10px] font-semibold uppercase tracking-wide ${
                  isMine ? 'text-white/70' : 'text-slate-500'
                }`}>
                  {t('chat.customerPrice')}
                </span>
                {customerPrice}
              </p>
            ) : isLoading ? (
              <p className={`text-[11px] ${isMine ? 'text-white/60' : 'text-slate-400'}`}>
                {t('chat.askForPriceLoading')}
              </p>
            ) : null}
            {supplierPrice ? (
              <p
                className={`notranslate text-[11px] ${
                  isMine ? 'text-white/65' : 'text-slate-500 dark:text-slate-400'
                }`}
                translate="no"
              >
                {t('chat.supplierPrice')}: {supplierPrice}
              </p>
            ) : null}
          </div>
        </div>
      </div>
      <div
        className={`flex flex-wrap gap-1.5 border-t px-2 py-2 sm:px-2.5 ${
          isMine ? 'border-white/20' : 'border-slate-100 dark:border-slate-700'
        }`}
      >
        <Link
          to={href}
          className={`inline-flex items-center rounded-lg px-2.5 py-1.5 text-[11px] font-semibold transition ${
            isMine
              ? 'bg-white/20 text-white hover:bg-white/30'
              : 'bg-[#3B7FC7]/10 text-[#3B7FC7] hover:bg-[#3B7FC7]/20'
          }`}
        >
          {isError ? title : t('chat.askForPriceOpenAd')}
        </Link>
        {supplierUserId && onChatWithSupplier ? (
          <button
            type="button"
            onClick={handleAskSupplier}
            disabled={isLoading && !supplierPrice}
            className={`inline-flex items-center rounded-lg px-2.5 py-1.5 text-[11px] font-semibold transition ${
              isMine
                ? 'bg-[#619d51]/90 text-white hover:bg-[#619d51]'
                : 'bg-[#619d51] text-white hover:bg-[#528544]'
            } disabled:cursor-not-allowed disabled:opacity-60`}
          >
            {t('chat.askSupplier')}
          </button>
        ) : null}
      </div>
    </div>
  )
}

function AskSupplierPriceCard({
  payload,
  isMine,
}: {
  payload: Extract<ReturnType<typeof parseAskSupplierContent>, { kind: 'ask' }>
  isMine: boolean
}) {
  const { t } = useAppPreferences()
  const { data: product, isLoading } = useGetAdminProductDetailQuery(
    { productId: payload!.productId },
    { skip: !payload?.productId },
  )

  if (!payload) return null

  const title =
    product?.name?.trim() || payload.productName?.trim() || t('chat.askSupplierTitle')
  const unit = product?.unitName?.trim() || payload.unitName?.trim() || null
  const code = payload.productCode?.trim() || null
  const quantityLabel =
    payload.quantityLabel?.trim() ||
    (product
      ? [product.quantity != null ? String(product.quantity) : null, product.unitName?.trim()]
          .filter(Boolean)
          .join(' ') || null
      : null)

  // Dashboard always shows customer-facing (after commission) price.
  const customerPrice =
    product?.customerPriceFormatted?.trim() ||
    (product?.customerPriceUsd != null ? String(product.customerPriceUsd) : null) ||
    null

  const imagePath =
    product?.primaryImagePath?.trim() ||
    product?.imagePaths?.find((p) => p?.trim() && !looksLikeVideoPath(p))?.trim() ||
    payload.imagePath?.trim() ||
    null
  const imageUrl = imagePath ? resolveAssetUrl(imagePath) : null
  const href = `/ads/${payload.productId}`

  return (
    <div
      className={`overflow-hidden rounded-xl border text-start ${
        isMine
          ? 'border-white/35 bg-white/15'
          : 'border-slate-200 bg-white dark:border-slate-600 dark:bg-slate-900'
      }`}
    >
      <div className="flex gap-2.5 p-2 sm:gap-3 sm:p-2.5">
        <div
          className={`relative h-20 w-20 shrink-0 overflow-hidden rounded-lg ${
            isMine ? 'bg-white/20' : 'bg-slate-100 dark:bg-slate-800'
          }`}
        >
          {imageUrl ? (
            <img src={imageUrl} alt="" className="h-full w-full object-cover" />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-xs opacity-50">â€”</div>
          )}
        </div>
        <div className="min-w-0 flex-1">
          <p
            className={`text-[10px] font-bold uppercase tracking-wide ${
              isMine ? 'text-white/70' : 'text-slate-500'
            }`}
          >
            {t('chat.askSupplierTitle')}
          </p>
          <p
            className={`notranslate mt-0.5 line-clamp-2 text-sm font-bold leading-snug ${
              isMine ? 'text-white' : 'text-slate-900 dark:text-white'
            }`}
            translate="no"
          >
            {title}
          </p>
          {quantityLabel ? (
            <p
              className={`notranslate mt-0.5 truncate text-[11px] ${
                isMine ? 'text-white/65' : 'text-slate-500'
              }`}
              translate="no"
            >
              {quantityLabel}
            </p>
          ) : null}
          {code ? (
            <p
              className={`notranslate truncate text-[11px] ${
                isMine ? 'text-white/65' : 'text-slate-500'
              }`}
              translate="no"
            >
              {code}
            </p>
          ) : null}
          <p
            className={`mt-1.5 text-[11px] leading-snug ${
              isMine ? 'text-white/85' : 'text-slate-600 dark:text-slate-300'
            }`}
          >
            {unit
              ? t('chat.askSupplierQuestionWithUnit', { unit })
              : t('chat.askSupplierQuestion')}
          </p>
          <div className="mt-1">
            {customerPrice ? (
              <p
                className={`notranslate text-sm font-bold ${
                  isMine ? 'text-[#7dffa8]' : 'text-[#619d51]'
                }`}
                translate="no"
              >
                <span
                  className={`me-1 text-[10px] font-semibold uppercase tracking-wide ${
                    isMine ? 'text-white/70' : 'text-slate-500'
                  }`}
                >
                  {t('chat.customerPrice')}
                </span>
                {customerPrice}
                {unit ? (
                  <span className={`ms-1 text-[10px] font-medium ${isMine ? 'text-white/60' : 'text-slate-400'}`}>
                    / {unit}
                  </span>
                ) : null}
              </p>
            ) : isLoading ? (
              <p className={`text-[11px] ${isMine ? 'text-white/60' : 'text-slate-400'}`}>
                {t('chat.askForPriceLoading')}
              </p>
            ) : null}
          </div>
        </div>
      </div>
      <div
        className={`border-t px-2 py-2 sm:px-2.5 ${
          isMine ? 'border-white/20' : 'border-slate-100 dark:border-slate-700'
        }`}
      >
        <Link
          to={href}
          className={`inline-flex items-center rounded-lg px-2.5 py-1.5 text-[11px] font-semibold transition ${
            isMine
              ? 'bg-white/20 text-white hover:bg-white/30'
              : 'bg-[#3B7FC7]/10 text-[#3B7FC7] hover:bg-[#3B7FC7]/20'
          }`}
        >
          {t('chat.askForPriceOpenAd')}
        </Link>
      </div>
    </div>
  )
}

function AskSupplierReplyCard({
  payload,
  isMine,
}: {
  payload: Extract<ReturnType<typeof parseAskSupplierContent>, { kind: 'reply' }>
  isMine: boolean
}) {
  const { t } = useAppPreferences()
  const { data: product, isLoading } = useGetAdminProductDetailQuery(
    { productId: payload!.productId },
    { skip: !payload?.productId, refetchOnMountOrArgChange: true },
  )

  if (!payload) return null

  const title =
    product?.name?.trim() || t('chat.askSupplierTitle')
  const unit = product?.unitName?.trim() || payload.unitName?.trim() || null
  const customerPrice =
    product?.customerPriceFormatted?.trim() ||
    (product?.customerPriceUsd != null ? String(product.customerPriceUsd) : null) ||
    payload.customerPriceLabel?.trim() ||
    null
      <Link
        to={`/ads/${payload.productId}`}
        className={`mt-2 inline-flex items-center rounded-lg px-2.5 py-1.5 text-[11px] font-semibold transition ${
          isMine
            ? 'bg-white/20 text-white hover:bg-white/30'
            : 'bg-[#3B7FC7]/10 text-[#3B7FC7] hover:bg-[#3B7FC7]/20'
        }`}
      >
        {t('chat.askForPriceOpenAd')}
      </Link>
    </div>
  )
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
        â–¶
      </span>
    </button>
  )
}
