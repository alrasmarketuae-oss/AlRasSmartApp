import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import type { StringKey } from '../i18n/strings'
import { useI18n } from '../i18n/I18nProvider'
import { resolveMediaUrl } from '../lib/media'
import { PriceText } from '../products/details/DetailsUI'
import { formatAmount, parseUtc, relativeTime } from '../products/productRules'
import { unitLabel } from '../products/units'
import { VideoFrame } from '../products/VideoFrame'
import { Icon } from '../ui/Icon'
import { isRequestProductOffer, isVideoPath, localize, orderImage, orderVideo, type MyOrder, type RequestOffer } from './ordersApi'
import { orderStatusLabel, remapOfferStatus, statusColors } from './orderStatus'

const TEXT_DARK = '#16233A'
const ACTION_BLUE = '#3A7DC5'
const ACTION_RED = '#C83D30'
const CANCEL_RED = '#E53935'

export function quantityText(quantity: number, unit: string, t: (key: StringKey) => string) {
  return [formatAmount(quantity), unit ? unitLabel(unit, t) : ''].filter(Boolean).join(' ')
}

const capitalize = (s: string) => (s ? s.charAt(0).toUpperCase() + s.slice(1) : s)

/** Newest first, with an "Oldest" divider before the first item older than 14 days (OrderListOldestSection). */
export function withOldestSection<T>(items: T[], createdAt: (item: T) => string): ({ header: true } | { header: false; item: T })[] {
  const time = (item: T) => parseUtc(createdAt(item))?.getTime() ?? null
  const sorted = [...items].sort((a, b) => {
    const ta = time(a)
    const tb = time(b)
    if (ta === null && tb === null) return 0
    if (ta === null) return 1
    if (tb === null) return -1
    return tb - ta
  })
  const threshold = Date.now() - 14 * 86_400_000
  const entries: ({ header: true } | { header: false; item: T })[] = []
  let headerAdded = false
  for (const item of sorted) {
    const ts = time(item)
    if (!headerAdded && ts !== null && ts <= threshold) {
      entries.push({ header: true })
      headerAdded = true
    }
    entries.push({ header: false, item })
  }
  return entries
}

export function OldestHeader() {
  const { t } = useI18n()
  return (
    <div className="flex items-center gap-3 py-1 text-xs font-bold text-subtitle">
      <span className="h-px flex-1 bg-line" />
      <span className="inline-flex items-center gap-1.5">
        <Icon name="history" size={15} />
        {t('oldestOrdersSection')}
      </span>
      <span className="h-px flex-1 bg-line" />
    </div>
  )
}

export function StatusChip({ label, statusId, fallbackName, className = '' }: { label: string; statusId: number; fallbackName: string; className?: string }) {
  const colors = statusColors(statusId, fallbackName)
  return (
    <span className={`inline-block max-w-full truncate rounded-lg px-2 py-1 text-[11px] font-semibold ${className}`} style={{ color: colors.fg, background: colors.bg }}>
      {label}
    </span>
  )
}

export function MediaThumb({ image, video, size, radius = 12 }: { image: string; video: string; size: number; radius?: number }) {
  const empty = (
    <span className="grid size-full place-items-center bg-[#F1F5F9] text-[#94A3B8]">
      <Icon name="image" size={28} />
    </span>
  )
  const imageUrl = resolveMediaUrl(image)
  const videoUrl = resolveMediaUrl(video)
  return (
    <span className="relative block shrink-0 overflow-hidden bg-[#F1F5F9]" style={{ width: size, height: size, borderRadius: radius }}>
      {imageUrl ? <img src={imageUrl} alt="" loading="lazy" className="size-full object-cover" /> : videoUrl ? <VideoFrame src={videoUrl} className="size-full object-cover" fallback={empty} /> : empty}
      {videoUrl && (
        <span className="absolute inset-0 grid place-items-center">
          <span className="grid size-7 place-items-center rounded-full bg-black/45 text-white">
            <Icon name="play" size={14} />
          </span>
        </span>
      )}
    </span>
  )
}

function StatCell({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="min-w-0 flex-1">
      <p className="truncate text-[11px] text-subtitle">{label}</p>
      <div className="mt-1 truncate text-[13px] font-bold text-[#1E293B]">{children}</div>
    </div>
  )
}

export function OrderCard({ order, onTrack }: { order: MyOrder; onTrack: () => void }) {
  const { t, isAr } = useI18n()
  const name = localize(order.productName, isAr)
  const details = localize(order.productDescription, isAr)
  const status = orderStatusLabel(order, isAr, t) || order.statusName
  return (
    <article className="rounded-2xl border border-line bg-white p-3 shadow-[0_4px_12px_rgba(0,0,0,0.06)]">
      <button type="button" onClick={onTrack} className="flex w-full gap-3 text-start">
        <MediaThumb image={orderImage(order)} video={orderVideo(order)} size={88} />
        <div className="min-w-0 flex-1">
          <div className="flex items-start gap-1">
            <StatusChip label={status} statusId={order.statusId} fallbackName={order.statusName} className="min-w-0" />
            <Icon name="more" size={18} className="ms-auto shrink-0 text-[#94A3B8]" strokeWidth={3} />
          </div>
          <p className="mt-2 truncate text-[15px] font-bold leading-snug text-[#1E293B]">{name ? capitalize(name) : '—'}</p>
          {details && <p className="mt-1 line-clamp-2 text-xs leading-snug text-subtitle">{details}</p>}
        </div>
      </button>
      <div className="mt-3 flex gap-2">
        <StatCell label={t('requestedQuantity')}>{quantityText(order.quantity, localize(order.unitName, isAr), t)}</StatCell>
        <StatCell label={t('total')}>
          <PriceText amount={order.displayTotal} currency={order.currency} size={14} className="text-sm font-extrabold text-brand" />
        </StatCell>
        <StatCell label={t('orderDate')}>{relativeTime(order.createdAt, t)}</StatCell>
      </div>
      {order.relatedOrders.length > 0 && (
        <div className="mt-3 rounded-[10px] border border-[#FED7AA] bg-[#FFF7ED] px-2.5 py-2">
          <p className="text-xs font-bold text-[#9A3412]">{t('relatedOrdersNotice', { count: order.relatedOrders.length })}</p>
          {order.relatedOrders.map((related) => (
            <Link key={related.id} to={`/orders/${related.id}`} className="mt-1 block text-xs font-bold text-brand hover:underline">
              {t('viewRelatedProduct', { name: localize(related.productName, isAr) })}
            </Link>
          ))}
        </div>
      )}
      <button
        type="button"
        onClick={onTrack}
        className="mt-3 h-[42px] w-full rounded-xl bg-gradient-to-r from-brand-dark to-brand-light text-sm font-bold text-white hover:brightness-110"
      >
        {t('trackOrder')}
      </button>
    </article>
  )
}

function Metric({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="min-w-0 flex-1">
      <p className="text-sm" style={{ color: `${TEXT_DARK}CC` }}>
        {label}
      </p>
      <div className="mt-2 text-sm" style={{ color: TEXT_DARK }}>
        {children}
      </div>
    </div>
  )
}

function SendingText({ label }: { label: string }) {
  return (
    <span className="inline-flex items-baseline">
      {label}
      <span className="inline-block w-4 animate-pulse text-start">...</span>
    </span>
  )
}

export function RequestOfferCard(props: {
  offer: RequestOffer
  useOfferLabels: boolean
  busy: 'accept' | 'reject' | null
  onTrack?: () => void
  onAccept?: () => void
  onReject?: () => void
  onCancel?: () => void
}) {
  const { t, isAr } = useI18n()
  const { offer, busy } = props
  const name = localize(offer.productName, isAr)
  const unit = localize(offer.unitName, isAr)
  const qty = offer.quantity > 0 ? quantityText(offer.quantity, unit, t) : ''
  const delivery = localize(offer.destinationCountry, isAr) || localize(offer.portName, isAr)
  const specs = localize(offer.productDescription, isAr) || localize(offer.notes, isAr)
  const allowPrice = isRequestProductOffer(offer) || offer.showPrice
  const unitPrice = offer.unitPrice
  const total = offer.totalPrice > 0 ? offer.totalPrice : offer.unitPrice * offer.quantity
  const currency = offer.currency === 'USD' ? 'USD' : 'AED'
  const media = [...offer.imagePaths, ...offer.videoPaths]
  const time = relativeTime(offer.createdAt, t)
  const isOffer = isRequestProductOffer(offer) || props.useOfferLabels
  const acceptLabel = isOffer ? t('acceptOfferAction') : t('acceptOrderAction')
  const rejectLabel = isOffer ? t('rejectOfferAction') : t('rejectOrderAction')
  const unitPriceLabel = t('pricePerUnit', { unit: unit ? unitLabel(unit, t) : '' })
  const priceNode = (amount: number, bold: boolean) => <PriceText amount={amount} currency={currency} size={16} className={`text-sm ${bold ? 'font-bold' : 'font-semibold'}`} />

  return (
    <article className="rounded-lg border border-line bg-white px-3 py-5 shadow-[0_0_4px_rgba(0,0,0,0.15)]">
      <div className="flex items-center gap-3">
        <p className="min-w-0 flex-1 truncate text-sm font-bold" style={{ color: TEXT_DARK }}>
          {name || '—'}
        </p>
        <StatusChip label={remapOfferStatus(offer.statusName, offer.statusAr, offer.statusId, isAr, t)} statusId={offer.statusId} fallbackName={offer.statusName} className="px-3 text-xs font-normal" />
      </div>
      {(offer.orderId > 0 || time) && (
        <div className="mt-2 flex items-center gap-2 text-xs">
          {offer.orderId > 0 && (
            <span className="min-w-0 flex-1 truncate" style={{ color: `${TEXT_DARK}A6` }}>
              {`${t('orderNumber')}: #${offer.orderId}`}
            </span>
          )}
          {time && <span style={{ color: `${TEXT_DARK}8C` }}>{time}</span>}
        </div>
      )}
      <div className="mt-3.5 flex items-start gap-3">
        {media.length > 0 && (
          <a href={resolveMediaUrl(media[0])} target="_blank" rel="noopener noreferrer">
            <MediaThumb image={isVideoPath(media[0]) ? '' : media[0]} video={isVideoPath(media[0]) ? media[0] : ''} size={72} radius={8} />
          </a>
        )}
        <div className="flex min-w-0 flex-1 flex-col gap-3.5">
          {(delivery || qty) && (
            <div className="flex gap-5">
              {delivery && <Metric label={t('delivery')}>{delivery}</Metric>}
              {qty && <Metric label={t('quantity')}>{qty}</Metric>}
            </div>
          )}
          {!allowPrice ? (
            <div className="flex gap-5">
              <Metric label={unitPriceLabel}>—</Metric>
              <Metric label={t('total')}>—</Metric>
            </div>
          ) : (
            (unitPrice > 0 || total > 0) && (
              <div className="flex gap-5">
                {unitPrice > 0 && <Metric label={unitPriceLabel}>{priceNode(unitPrice, false)}</Metric>}
                {total > 0 && <Metric label={t('total')}>{priceNode(total, true)}</Metric>}
              </div>
            )
          )}
        </div>
      </div>
      {media.length > 1 && (
        <div className="no-scrollbar mt-3 flex gap-2 overflow-x-auto">
          {media.map((path) => (
            <a key={path} href={resolveMediaUrl(path)} target="_blank" rel="noopener noreferrer">
              <MediaThumb image={isVideoPath(path) ? '' : path} video={isVideoPath(path) ? path : ''} size={56} radius={6} />
            </a>
          ))}
        </div>
      )}
      {offer.documentPaths.length > 0 && (
        <div className="mt-4">
          <p className="text-sm" style={{ color: `${TEXT_DARK}CC` }}>
            {t('productDocuments')}
          </p>
          <div className="mt-2 flex flex-wrap gap-2">
            {offer.documentPaths.map((path, i) => (
              <a
                key={path}
                href={resolveMediaUrl(path)}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 rounded-lg bg-[#EFF6FF] px-3 py-2 text-[13px] font-semibold hover:brightness-95"
                style={{ color: ACTION_BLUE }}
              >
                <Icon name="doc" size={18} />
                {t('documentNumber', { n: i + 1 })}
              </a>
            ))}
          </div>
        </div>
      )}
      {specs && (
        <div className="mt-4 rounded-lg border border-[#EAECF0] bg-[#F8FAFC] p-3">
          <p className="flex items-center gap-2 text-sm font-semibold" style={{ color: TEXT_DARK }}>
            <Icon name="doc" size={18} style={{ color: ACTION_BLUE }} />
            {t('specifications')}
          </p>
          <p className="mt-2.5 whitespace-pre-line text-[13px] leading-relaxed" style={{ color: `${TEXT_DARK}D9` }}>
            {specs}
          </p>
        </div>
      )}
      {props.onTrack && (
        <button
          type="button"
          onClick={props.onTrack}
          className="mt-4 flex w-full items-center justify-center gap-2 rounded-lg border bg-white px-4 py-2.5 text-sm font-bold hover:bg-[#3A7DC5]/5"
          style={{ borderColor: ACTION_BLUE, color: ACTION_BLUE }}
        >
          <Icon name="truck" size={18} />
          {t('trackOrder')}
        </button>
      )}
      {(props.onAccept || props.onReject) && (
        <div className="mt-3 flex gap-3">
          {busy && props.onCancel ? (
            <>
              <span
                className="flex flex-[3] items-center justify-center rounded-lg px-4 py-2 text-sm font-bold text-white"
                style={{ background: busy === 'accept' ? ACTION_BLUE : ACTION_RED }}
              >
                <SendingText label={t('sending')} />
              </span>
              <button type="button" onClick={props.onCancel} className="h-11 flex-[2] rounded-xl text-sm font-bold text-white hover:brightness-110" style={{ background: CANCEL_RED }}>
                {t('cancel')}
              </button>
            </>
          ) : (
            <>
              {props.onAccept && (
                <button type="button" disabled={!!busy} onClick={props.onAccept} className="flex-1 rounded-lg px-4 py-2 text-sm text-white hover:brightness-110 disabled:opacity-60" style={{ background: ACTION_BLUE }}>
                  {acceptLabel}
                </button>
              )}
              {props.onReject && (
                <button type="button" disabled={!!busy} onClick={props.onReject} className="flex-1 rounded-lg px-4 py-2 text-sm text-white hover:brightness-110 disabled:opacity-60" style={{ background: ACTION_RED }}>
                  {rejectLabel}
                </button>
              )}
            </>
          )}
        </div>
      )}
    </article>
  )
}