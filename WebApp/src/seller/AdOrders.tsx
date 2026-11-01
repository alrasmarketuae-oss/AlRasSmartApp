import { useEffect, useState, type ReactNode } from 'react'
import { useI18n } from '../i18n/I18nProvider'
import type { StringKey } from '../i18n/strings'
import { resolveMediaUrl } from '../lib/media'
import { CurrencyMark } from '../products/ProductCard'
import {
  categoryLabel,
  discountPercent,
  displayUnit,
  formatAmount,
  hasMainCategory,
  isDiscountActive,
  isOfferProduct,
  isRequestProduct,
  isSoldOut,
  localized,
  packagingDisplay,
  priceTypeLabel,
  productMedia,
  productTitle,
  quantityWithUnit,
  relativeTime,
  shippingFacts,
  unitName,
  type MediaItem,
} from '../products/productRules'
import { VideoFrame } from '../products/VideoFrame'
import { Icon } from '../ui/Icon'
import { adTypeLabel, isHybridCategoryRetail, isRejectedWithReason, statusCanonical } from './listingRules'
import { UnitPrice, ViewsBadge } from './MyAdCard'
import type { AdOrder, MyListing } from './sellerApi'

type T = (key: StringKey, vars?: Record<string, string | number>) => string

/** `OrderStatusStyle.forStatusId`. */
export function orderStatusStyle(statusId: number) {
  const map: Record<number, [string, string]> = {
    1: ['#1565C0', '#E3F2FD'],
    2: ['#6A1B9A', '#F3E5F5'],
    3: ['#00796B', '#E0F2F1'],
    4: ['#E65100', '#FFF3E0'],
    5: ['#2E7D32', '#E8F5E9'],
    6: ['#C62828', '#FFEBEE'],
    7: ['#2E7D32', '#E8F5E9'],
    8: ['#3949AB', '#E8EAF6'],
    9: ['#EF6C00', '#FFF8E1'],
    10: ['#AD1457', '#FCE4EC'],
    11: ['#6A1B9A', '#F3E5F5'],
  }
  const [fg, bg] = map[statusId] ?? ['#3A7DC5', '#E0F1FF']
  return { fg, bg }
}

const AWAITING_SELLER_APPROVAL = 11

/** `DecisionMakerOrderStatusLabels.remap`: third-person seller labels → first person. */
function remapLabel(label: string, statusId: number, t: T) {
  if (!label || label === '—') return label
  const lower = label.toLowerCase()
  if (statusId === AWAITING_SELLER_APPROVAL || lower.includes('awaiting seller approval') || label.includes('بانتظار موافقة البائع') || lower.includes('awaiting advertiser approval') || label.includes('بانتظار موافقة المعلن'))
    return t('awaitingYourApproval')
  if (lower.includes('accepted by the seller') || lower.includes('accepted by seller') || label.includes('تم قبول الطلب من البائع')) return t('youAcceptedTheOrder')
  if (lower.includes('order rejected') || label === 'تم رفض الطلب') return t('youRejectedTheOrder')
  if (lower.includes('accepted by the requester') || lower.includes('accepted by requester') || label.includes('قبول من قبل الطالب')) return t('youAcceptedTheOffer')
  if (lower.includes('rejected by the advertiser') || lower.includes('rejected by advertiser') || label.includes('رفض من قبل المعلن')) return t('youRejectedTheOffer')
  return label
}

export function decisionMakerStatus(statusName: string, statusAr: string, statusId: number, isAr: boolean, t: T) {
  const primary = (isAr ? statusAr : statusName).trim()
  const secondary = (isAr ? statusName : statusAr).trim()
  const candidates = [primary, secondary].filter((c, i, all) => c && all.indexOf(c) === i)
  if (!candidates.length) return remapLabel('', statusId, t)
  for (const candidate of candidates) {
    const remapped = remapLabel(candidate, statusId, t)
    if (remapped !== candidate) return remapped
  }
  return candidates[0]
}

function InfoRow({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="flex items-start gap-3 text-sm leading-normal text-[#333333]/80">
      <span className="shrink-0">{label}</span>
      <span className="min-w-0 flex-1 text-end [overflow-wrap:anywhere]">{value}</span>
    </div>
  )
}

function FieldBlock({ label, value, small }: { label: string; value: string; small?: boolean }) {
  return (
    <div className="min-w-0 flex-1">
      <p className="text-sm text-black/80">{label}</p>
      <p className={`mt-3 font-extrabold text-black [overflow-wrap:anywhere] ${small ? 'text-[13px]' : 'text-sm'}`}>{value}</p>
    </div>
  )
}

function MediaStrip({ items, soldOut }: { items: MediaItem[]; soldOut: boolean }) {
  const [index, setIndex] = useState(0)
  const current = items[Math.min(index, items.length - 1)]
  if (!current) return null
  return (
    <div>
      <div className="relative aspect-[16/10] overflow-hidden rounded-lg bg-[#F3F4F6]">
        {current.kind === 'image' ? (
          <img src={current.url} alt="" className="size-full object-cover" />
        ) : (
          <video src={current.url} controls playsInline muted={current.muted} className="size-full bg-black object-contain" />
        )}
        {soldOut && <img src="/assets/images/sold_out_stamp.png" alt="" className="pointer-events-none absolute start-3 top-3 w-24 opacity-90" />}
        {items.length > 1 && (
          <span className="absolute bottom-2 end-2 rounded-full bg-black/55 px-2 py-0.5 text-[11px] font-semibold text-white" dir="ltr">
            {index + 1}/{items.length}
          </span>
        )}
      </div>
      {items.length > 1 && (
        <div className="mt-2 flex gap-2 overflow-x-auto pb-1">
          {items.map((item, i) => (
            <button
              key={item.url}
              type="button"
              onClick={() => setIndex(i)}
              className={`relative size-14 shrink-0 overflow-hidden rounded-md border-2 ${i === index ? 'border-brand' : 'border-transparent'}`}
            >
              {item.kind === 'image' ? <img src={item.url} alt="" className="size-full object-cover" /> : <VideoFrame src={item.url} className="size-full object-cover" />}
              {item.kind === 'video' && (
                <span className="absolute inset-0 grid place-items-center text-white">
                  <Icon name="play" size={14} />
                </span>
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

function receiptDate(p: MyListing) {
  const raw = String(p.shippingDuration ?? '').trim()
  if (!raw) return ''
  const date = new Date(raw)
  if (/\d{4}-\d{2}-\d{2}/.test(raw) && !Number.isNaN(date.getTime())) {
    return `${date.getFullYear()}/${String(date.getMonth() + 1).padStart(2, '0')}/${String(date.getDate()).padStart(2, '0')}`
  }
  return raw.includes('/') || raw.includes('-') ? raw : ''
}

/** Collapsible "Ad details" card (`AdRequestOrderInfoCard`). */
export function AdInfoCard({ product, preferRetail, preferCategory, showBothChannels }: { product: MyListing; preferRetail: boolean; preferCategory: boolean; showBothChannels: boolean }) {
  const { t, isAr } = useI18n()
  const [expanded, setExpanded] = useState(false)
  const title = productTitle(product, isAr)
  const name = title ? title.charAt(0).toUpperCase() + title.slice(1) : t('product')

  const showBoth = isHybridCategoryRetail(product) && showBothChannels
  const media = productMedia(product)
  const images = media.filter((m) => m.kind === 'image')
  const videos = media.filter((m) => m.kind === 'video')
  const soldOut = isSoldOut(product, preferRetail)
  const status = localized(product.statusNameAr, product.status, statusCanonical(product), isAr) || '—'
  const typeLabel = adTypeLabel(product, t, preferRetail, preferCategory)
  const priceType = priceTypeLabel(product, t)
  const category = categoryLabel(product, isAr)
  const specifications = localized(product.descriptionAr, product.descriptionEn, product.description, isAr)
  const wholesaleQty = quantityWithUnit(product, isAr, false)
  const retailQty = product.hasRetailPricing ? quantityWithUnit(product, isAr, true) : ''
  const quantity = showBoth ? '' : quantityWithUnit(product, isAr, preferRetail)
  const packaging = packagingDisplay(product, isAr)
  const wholesaleUnit = unitName(product, isAr, false)
  const retailUnit = product.hasRetailPricing ? unitName(product, isAr, true) : ''
  const facts = shippingFacts(product, isAr)
  const isBooking = product.productTypeId === 2
  const route = [facts.origin, facts.destination].filter(Boolean).join(' → ')
  const deliveryAddress = facts.arrivalPort && facts.destination ? `${facts.arrivalPort}, ${facts.destination}` : facts.destination || facts.arrivalPort || facts.routeSummary
  const receipt = receiptDate(product)
  const showDiscount = isOfferProduct(product) && isDiscountActive(product)
  const discount = String(product.discountPercentage ?? '').trim() || String(discountPercent(product))
  const showRequestFulfillment = hasMainCategory(product) || isRequestProduct(product) || isOfferProduct(product) || !!priceType

  return (
    <section className="overflow-hidden rounded-lg border border-[#D0D5DD] bg-white">
      <button type="button" onClick={() => setExpanded((v) => !v)} className="flex w-full items-center gap-3 px-4 py-3.5 text-start">
        <span className="grid size-[34px] shrink-0 place-items-center rounded-lg bg-[#E8F4FD] text-[#1E6BB8]">
          <Icon name="receipt" size={18} />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block text-[15px] font-bold text-[#333333]">{t('adDetails')}</span>
          <span className="mt-0.5 block truncate text-xs text-[#667085]">{name}</span>
        </span>
        <Icon name="chevronDown" size={24} className={`shrink-0 text-[#667085] transition-transform duration-200 ${expanded ? 'rotate-180' : ''}`} />
      </button>

      {expanded && (
        <div className="border-t border-[#EAECF0] p-4">
          {media.length > 0 && (
            <div className="mb-4 space-y-2.5">
              {images.length > 0 && <MediaStrip items={images} soldOut={soldOut} />}
              {videos.length > 0 && <MediaStrip items={videos} soldOut={soldOut} />}
            </div>
          )}
          <div className="space-y-3">
            <InfoRow label={t('adStatusLabel')} value={status} />
            <InfoRow label={t('adTypeLabel')} value={typeLabel} />
            {showRequestFulfillment && <InfoRow label={t('requestFulfillment')} value={priceType || '—'} />}
            {category && <InfoRow label={t('category')} value={category} />}
            <ViewsBadge count={product.viewsCount ?? 0} />
            {product.createdAt && <InfoRow label={t('adPostedDateTime')} value={relativeTime(product.createdAt, t)} />}
          </div>

          {showBoth ? (
            <div className="mt-4 space-y-3">
              <div>
                <p className="text-sm text-black/80">{t('adWholesalePrice')}</p>
                <div className="mt-2">
                  <UnitPrice product={product} preferRetail={false} className="text-lg" />
                </div>
              </div>
              {product.hasRetailPricing && (
                <div>
                  <p className="text-sm text-black/80">{t('adRetailPrice')}</p>
                  <div className="mt-2">
                    <UnitPrice product={product} preferRetail className="text-lg" />
                  </div>
                </div>
              )}
            </div>
          ) : (
            <div className="mt-4">
              <p className="text-sm text-black/80">{t('price')}</p>
              <div className="mt-2">
                <UnitPrice product={product} preferRetail={preferRetail} className="text-lg" />
              </div>
            </div>
          )}

          {showDiscount && (
            <div className="mt-3">
              <InfoRow label={t('adDiscountLabel')} value={`${discount}%`} />
            </div>
          )}

          {specifications && (
            <div className="mt-6">
              <FieldBlock label={isRequestProduct(product) ? t('requiredSpecifications') : t('specifications')} value={specifications} small />
            </div>
          )}

          {showBoth && (wholesaleQty || retailQty) ? (
            <div className="mt-6 space-y-3">
              {wholesaleQty && <FieldBlock label={t('adWholesaleQuantity')} value={wholesaleQty} />}
              {wholesaleUnit && <FieldBlock label={t('adWholesaleUnit')} value={wholesaleUnit} />}
              {retailQty && <FieldBlock label={t('adRetailQuantity')} value={retailQty} />}
              {retailUnit && <FieldBlock label={t('adRetailUnit')} value={retailUnit} />}
              {packaging && <FieldBlock label={t('adPackingLabel')} value={packaging} />}
            </div>
          ) : (
            (quantity || packaging) && (
              <div className="mt-6 flex gap-4">
                {quantity && <FieldBlock label={t('quantity')} value={quantity} />}
                {packaging && <FieldBlock label={t('adPackingLabel')} value={packaging} />}
              </div>
            )
          )}

          <div className="mt-4 space-y-3">
            {isBooking ? (
              <>
                {facts.origin && <InfoRow label={t('countryOfOrigin')} value={facts.origin} />}
                {facts.loadingPort && <InfoRow label={t('loadingPort')} value={facts.loadingPort} />}
                {facts.destination && <InfoRow label={t('destinationCountry')} value={facts.destination} />}
                {facts.arrivalPort && <InfoRow label={t('destinationPort')} value={facts.arrivalPort} />}
              </>
            ) : (
              <>
                {route && <InfoRow label={t('adShippingRoute')} value={route} />}
                {deliveryAddress && <InfoRow label={t('deliveryAddress')} value={deliveryAddress} />}
              </>
            )}
            {receipt && <InfoRow label={t('requestedReceiptDate')} value={receipt} />}
            {facts.notes && <InfoRow label={t('additionalNotes')} value={facts.notes} />}
            {isRejectedWithReason(product) && <InfoRow label={t('rejectionReason')} value={product.supplierNotes?.trim()} />}
          </div>
        </div>
      )}
    </section>
  )
}

const VIDEO_PATH = /\.(mp4|mov|webm|m4v|avi|mkv)(\?|$)/i

function OfferThumb({ path, className }: { path: string; className: string }) {
  const url = resolveMediaUrl(path)
  const fallback = (
    <span className="grid size-full place-items-center text-[#9CA3AF]">
      <Icon name="image" size={22} />
    </span>
  )
  return (
    <span className={`relative block shrink-0 overflow-hidden bg-[#F3F4F6] ${className}`}>
      {!url ? fallback : VIDEO_PATH.test(path) ? (
        <>
          <VideoFrame src={url} className="size-full object-cover" fallback={fallback} />
          <span className="absolute inset-0 grid place-items-center text-white">
            <Icon name="play" size={16} />
          </span>
        </>
      ) : (
        <img src={url} alt="" loading="lazy" className="size-full object-cover" />
      )}
    </span>
  )
}

function Metric({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="min-w-0 flex-1">
      <p className="text-sm text-title/80">{label}</p>
      <div className="mt-3 text-sm text-title">{children}</div>
    </div>
  )
}

function OfferPrice({ amount, currency, bold }: { amount: number; currency: string; bold?: boolean }) {
  return (
    <span dir="ltr" className={`inline-flex items-center gap-1 ${bold ? 'font-bold' : 'font-semibold'}`}>
      {formatAmount(amount)}
      <CurrencyMark currency={currency} size={16} />
    </span>
  )
}

function SendingText({ label }: { label: string }) {
  const [phase, setPhase] = useState(0)
  useEffect(() => {
    const id = window.setInterval(() => setPhase((p) => (p + 1) % 3), 300)
    return () => window.clearInterval(id)
  }, [])
  return (
    <>
      {label}
      {'.'.repeat(phase + 1)}
    </>
  )
}

const isRequestOffer = (o: AdOrder) => {
  if (o.productTypeId === 4) return true
  const type = o.productTypeNameEn.toLowerCase()
  return type.includes('request') || type.includes('inquiry')
}

function offerCurrency(o: AdOrder) {
  const code = o.currency.trim().toUpperCase()
  if (code) return code === 'AED' || code === 'DHS' || code === 'DIRHAM' ? 'AED' : code === 'USD' || code === '$' ? 'USD' : code
  const formatted = (o.unitPriceFormatted || o.totalPriceFormatted).toUpperCase()
  return formatted.includes('USD') || formatted.startsWith('$') ? 'USD' : 'AED'
}

const numberFrom = (formatted: string) => Number(formatted.replace(/[^0-9.]/g, '')) || 0

export type OfferAction = 'accept' | 'reject'

/** One incoming order / offer on an ad (`RequestOfferCard`). */
export function RequestOfferCard(props: {
  offer: AdOrder
  requestAd: boolean
  pending: OfferAction | null
  onAccept: () => void
  onReject: () => void
  onCancel: () => void
  onTrack: () => void
}) {
  const { offer, pending } = props
  const { t, isAr } = useI18n()
  const name = localized(offer.productNameAr, offer.productNameEn, offer.productName, isAr)
  const status = decisionMakerStatus(offer.statusName, offer.statusAr, offer.statusId, isAr, t)
  const colors = orderStatusStyle(offer.statusId)
  const time = relativeTime(offer.createdAt, t)
  const unit = localized(offer.unitNameAr, offer.unitNameEn, '', isAr)
  const quantity = offer.quantity > 0 ? [formatAmount(offer.quantity), unit ? displayUnit(unit, offer.quantity, isAr) : ''].filter(Boolean).join(' ') : ''
  const delivery = localized(offer.destinationCountryAr, offer.destinationCountryEn, '', isAr) || localized(offer.portNameAr, offer.portNameEn, '', isAr)
  const specifications = localized(offer.descriptionAr, offer.descriptionEn, '', isAr) || localized(offer.notesAr, offer.notesEn, '', isAr)
  const allowPrice = isRequestOffer(offer) || offer.showPrice
  const unitPrice = offer.unitPrice > 0 ? offer.unitPrice : numberFrom(offer.unitPriceFormatted)
  const totalPrice = offer.totalPrice > 0 ? offer.totalPrice : offer.unitPrice > 0 && offer.quantity > 0 ? offer.unitPrice * offer.quantity : numberFrom(offer.totalPriceFormatted)
  const currency = offerCurrency(offer)
  const unitLabel = unit ? t('pricePerUnit', { unit }) : t('pricePerUnitGeneric')
  const mediaPaths = [...offer.imagePaths, ...offer.videoPaths]
  const acceptLabel = props.requestAd ? t('acceptOfferAction') : t('acceptOrderAction')
  const rejectLabel = props.requestAd ? t('rejectOfferAction') : t('rejectOrderAction')
  const [preview, setPreview] = useState<string | null>(null)

  return (
    <article className="rounded-lg border border-line bg-white px-3 py-5 shadow-[0_0_4px_rgba(0,0,0,0.15)]">
      <div className="flex items-center gap-3">
        <h3 className="min-w-0 flex-1 truncate text-sm font-bold leading-normal text-title">{name || '—'}</h3>
        <span className="shrink-0 rounded-lg px-3 py-1 text-xs leading-normal" style={{ background: colors.bg, color: colors.fg }}>
          {status}
        </span>
      </div>
      {(offer.orderId > 0 || time) && (
        <div className="mt-2 flex items-center gap-2 text-xs">
          {offer.orderId > 0 && (
            <span className="min-w-0 flex-1 truncate text-title/65">
              {t('orderNumber')}: #{offer.orderId}
            </span>
          )}
          {time && <span className="text-title/55">{time}</span>}
        </div>
      )}

      <div className="mt-3.5 flex items-start gap-3">
        {mediaPaths.length > 0 && (
          <button type="button" onClick={() => setPreview(mediaPaths[0])}>
            <OfferThumb path={mediaPaths[0]} className="size-[72px] rounded-lg" />
          </button>
        )}
        <div className="min-w-0 flex-1 space-y-3.5">
          {(delivery || quantity) && (
            <div className="flex gap-5">
              {delivery && <Metric label={t('delivery')}>{delivery}</Metric>}
              {quantity && <Metric label={t('quantity')}>{quantity}</Metric>}
            </div>
          )}
          {!allowPrice ? (
            <div className="flex gap-5">
              <Metric label={unitLabel}>—</Metric>
              <Metric label={t('total')}>—</Metric>
            </div>
          ) : (
            (unitPrice > 0 || totalPrice > 0) && (
              <div className="flex gap-5">
                {unitPrice > 0 && (
                  <Metric label={unitLabel}>
                    <OfferPrice amount={unitPrice} currency={currency} />
                  </Metric>
                )}
                {totalPrice > 0 && (
                  <Metric label={t('total')}>
                    <OfferPrice amount={totalPrice} currency={currency} bold />
                  </Metric>
                )}
              </div>
            )
          )}
        </div>
      </div>

      {mediaPaths.length > 1 && (
        <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
          {mediaPaths.map((path) => (
            <button key={path} type="button" onClick={() => setPreview(path)}>
              <OfferThumb path={path} className="size-14 rounded-md" />
            </button>
          ))}
        </div>
      )}

      {offer.documentPaths.length > 0 && (
        <div className="mt-4">
          <p className="text-sm text-title/80">{t('productDocuments')}</p>
          <div className="mt-2 flex flex-wrap gap-2">
            {offer.documentPaths.map((path, i) => (
              <a
                key={path}
                href={resolveMediaUrl(path)}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-1.5 rounded-lg bg-[#EFF6FF] px-3 py-2 text-[13px] font-semibold text-[#3A7DC5]"
              >
                <Icon name="doc" size={18} />
                Doc {i + 1}
              </a>
            ))}
          </div>
        </div>
      )}

      {specifications && (
        <div className="mt-4 rounded-lg border border-[#EAECF0] bg-[#F8FAFC] p-3">
          <div className="flex items-center gap-2 text-sm font-semibold text-title">
            <Icon name="doc" size={18} className="text-[#3A7DC5]" />
            {t('specifications')}
          </div>
          <p className="mt-2.5 whitespace-pre-line text-[13px] leading-relaxed text-title/85">{specifications}</p>
        </div>
      )}

      {offer.orderId > 0 && (
        <button
          type="button"
          onClick={props.onTrack}
          className="mt-4 flex w-full items-center justify-center gap-2 rounded-lg border border-[#3A7DC5] bg-white px-4 py-2.5 text-sm font-bold text-[#3A7DC5]"
        >
          <Icon name="truck" size={18} />
          {t('trackOrder')}
        </button>
      )}

      {(offer.canAccept || offer.canReject) && (
        <div className="mt-3 flex gap-3">
          {pending ? (
            <>
              <span className={`flex flex-[3] items-center justify-center rounded-lg px-4 py-2 text-sm font-bold text-white ${pending === 'accept' ? 'bg-[#3A7DC5]' : 'bg-[#C83D30]'}`}>
                <SendingText label={t('sending')} />
              </span>
              <button type="button" onClick={props.onCancel} className="flex-[2] rounded-xl bg-[#E53935] px-2 py-2.5 text-sm font-bold text-white">
                {t('cancel')}
              </button>
            </>
          ) : (
            <>
              {offer.canAccept && (
                <button type="button" onClick={props.onAccept} className="flex-1 rounded-lg bg-[#3A7DC5] px-4 py-2 text-sm text-white">
                  {acceptLabel}
                </button>
              )}
              {offer.canReject && (
                <button type="button" onClick={props.onReject} className="flex-1 rounded-lg bg-[#C83D30] px-4 py-2 text-sm text-white">
                  {rejectLabel}
                </button>
              )}
            </>
          )}
        </div>
      )}

      {preview && <MediaPreview path={preview} onClose={() => setPreview(null)} />}
    </article>
  )
}

function MediaPreview({ path, onClose }: { path: string; onClose: () => void }) {
  const url = resolveMediaUrl(path)
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])
  return (
    <div className="fixed inset-0 z-[80] grid place-items-center bg-black/85 p-4" onClick={onClose}>
      <button type="button" onClick={onClose} className="absolute end-4 top-4 grid size-10 place-items-center rounded-full bg-white/15 text-white">
        <Icon name="close" size={22} />
      </button>
      <div onClick={(e) => e.stopPropagation()} className="max-h-full max-w-4xl">
        {VIDEO_PATH.test(path) ? (
          <video src={url} controls autoPlay playsInline className="max-h-[85vh] max-w-full rounded-lg" />
        ) : (
          <img src={url} alt="" className="max-h-[85vh] max-w-full rounded-lg object-contain" />
        )}
      </div>
    </div>
  )
}

export function OfferCardSkeleton() {
  return (
    <div className="space-y-3 rounded-lg border border-line bg-white px-3 py-5">
      <div className="flex justify-between gap-3">
        <div className="shimmer h-4 w-1/2 rounded" />
        <div className="shimmer h-5 w-20 rounded-lg" />
      </div>
      <div className="shimmer h-3 w-1/3 rounded" />
      <div className="flex gap-3">
        <div className="shimmer size-[72px] rounded-lg" />
        <div className="flex-1 space-y-2">
          <div className="shimmer h-3 w-2/3 rounded" />
          <div className="shimmer h-3 w-1/2 rounded" />
        </div>
      </div>
    </div>
  )
}
