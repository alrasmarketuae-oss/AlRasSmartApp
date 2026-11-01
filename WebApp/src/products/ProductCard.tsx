import { memo, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { productPath } from './productLinks'
import { useI18n } from '../i18n/I18nProvider'
import { Icon } from '../ui/Icon'
import {
  amountValue,
  canShowProductPrice,
  currencyCode,
  discountEndsAt,
  discountPercent,
  formatAmount,
  isDiscountActive,
  isOfferProduct,
  isRequestProduct,
  isSoldOut,
  priceTypeLabel,
  productDescription,
  productImages,
  productTitle,
  productVideos,
  quantityWithUnit,
  relativeTime,
  saleAndOriginal,
  shouldShowAskForPrice,
  unitSuffix,
  type Viewer,
} from './productRules'
import type { ApiProduct } from './types'
import { VideoFrame } from './VideoFrame'

export function CurrencyMark({ currency, size }: { currency: string; size: number }) {
  if (currency === 'AED') {
    return <img src="/assets/icons/dirham.svg" alt="AED" style={{ height: size * 0.82, width: 'auto' }} className="inline-block shrink-0" />
  }
  return <span style={{ fontSize: size }}>{currency === 'USD' ? '$' : currency}</span>
}

function useCountdown(endsAt: Date | null, enabled: boolean) {
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    if (!enabled) return
    const id = window.setInterval(() => setNow(Date.now()), 1000)
    return () => window.clearInterval(id)
  }, [enabled])
  if (!enabled || !endsAt) return '00:00:00'
  const remaining = Math.max(0, Math.floor((endsAt.getTime() - now) / 1000))
  const days = Math.floor(remaining / 86400)
  const pad = (n: number) => String(n).padStart(2, '0')
  const hms = `${pad(Math.floor((remaining % 86400) / 3600))}:${pad(Math.floor((remaining % 3600) / 60))}:${pad(remaining % 60)}`
  return days > 0 ? `${days}d ${hms}` : hms
}

function PostedAt({ createdAt }: { createdAt?: string | null }) {
  const { t } = useI18n()
  const [, tick] = useState(0)
  useEffect(() => {
    const id = window.setInterval(() => tick((n) => n + 1), 60_000)
    return () => window.clearInterval(id)
  }, [])
  const label = relativeTime(createdAt, t)
  if (!label) return null
  return (
    <span className="mt-1.5 inline-flex w-fit items-center gap-1 rounded-full border border-[#E6ECF3] bg-[#F2F5F9] px-2 py-1 text-[10px] leading-none text-[#6B7A90]">
      <Icon name="clock" size={11} />
      {label}
    </span>
  )
}

type Props = {
  product: ApiProduct
  viewer: Viewer
  preferRetail?: boolean
}

function ProductCardImpl({ product, viewer, preferRetail = false }: Props) {
  const { t, isAr } = useI18n()
  const [imageFailed, setImageFailed] = useState(false)
  const image = productImages(product)[0]
  const video = image ? undefined : productVideos(product)[0]
  const title = productTitle(product, isAr) || 'Product'
  const soldOut = isSoldOut(product, preferRetail)
  const details = soldOut ? t('soldOut') : productDescription(product, isAr, preferRetail)

  const offerMode = isOfferProduct(product)
  const discount = discountPercent(product)
  const canPrice = canShowProductPrice(product, viewer, preferRetail)
  const { sale, original } = saleAndOriginal(product, viewer)
  const dealActive = offerMode && isDiscountActive(product) && discount > 0
  const showDeal = dealActive && canPrice && sale > 0
  const countdown = useCountdown(discountEndsAt(product), showDeal)

  const amount = amountValue(product, viewer, preferRetail)
  const showPrice = canPrice && (!isRequestProduct(product) || amount > 0)
  const showAsk = shouldShowAskForPrice(product, viewer, preferRetail)
  const currency = currencyCode(product, viewer)
  const unit = unitSuffix(product, isAr, preferRetail)
  const qty = quantityWithUnit(product, isAr, preferRetail)
  const typeLabel = preferRetail ? '' : priceTypeLabel(product, t)
  const showReconfirm = !isRequestProduct(product)

  const placeholder = (
    <div className="grid size-full place-items-center">
      <img src="/assets/logo/logo.png" alt="" className="h-12 w-auto opacity-30" />
    </div>
  )

  return (
    <Link
      to={productPath(product, preferRetail)}
      state={{ seed: product, retail: preferRetail }}
      className="group flex h-full flex-col overflow-hidden rounded-[14px] border border-[#E6ECF3] bg-white shadow-[0_2px_8px_rgba(0,0,0,0.12)] transition hover:-translate-y-0.5 hover:shadow-[0_8px_20px_rgba(0,0,0,0.14)]"
    >
      <div className="relative h-32 shrink-0 overflow-hidden bg-[#F2F5F9] sm:h-36 lg:h-40">
        {image && !imageFailed ? (
          <img
            src={image}
            alt={title}
            loading="lazy"
            decoding="async"
            onError={() => setImageFailed(true)}
            className="size-full object-cover transition duration-300 group-hover:scale-[1.03]"
          />
        ) : video ? (
          <>
            <VideoFrame src={video} className="size-full object-cover transition duration-300 group-hover:scale-[1.03]" fallback={placeholder} />
            <span className="absolute inset-0 grid place-items-center">
              <span className="grid size-9 place-items-center rounded-full bg-black/45 text-white">
                <Icon name="play" size={16} />
              </span>
            </span>
          </>
        ) : (
          placeholder
        )}
        {soldOut && (
          <div className="absolute inset-0 grid place-items-center bg-white/35">
            <img src="/assets/images/sold_out_stamp.png" alt={t('soldOut')} className="w-[70%] max-w-[150px] -rotate-12" />
          </div>
        )}
      </div>

      <div className="flex flex-1 flex-col p-2.5 sm:p-3">
        <h3 className="line-clamp-2 text-[15.5px] font-bold leading-tight text-brand first-letter:uppercase">{title}</h3>
        <PostedAt createdAt={product.createdAt} />
        <p className={`mt-1 line-clamp-2 text-[11px] leading-[1.35] sm:text-xs ${soldOut ? 'font-bold text-[#DC2626]' : 'text-card-details'}`}>
          {details || '—'}
        </p>

        <div className="mt-auto">
          {showDeal && (
            <div className="mt-1.5 flex items-center gap-1.5 text-[10px] font-semibold text-deal-red">
              <span className="rounded bg-deal-red px-1.5 py-0.5 font-bold text-white">-{discount}%</span>
              <Icon name="timer" size={14} />
              <span dir="ltr" className="truncate tabular-nums">
                {countdown}
              </span>
            </div>
          )}
          <div className="my-2 h-px bg-[#EEF0F3]" />

          {showPrice ? (
            showDeal ? (
              <div dir="ltr" className={`flex flex-col ${isAr ? 'items-end' : 'items-start'}`}>
                {original > sale && (
                  <span className="flex items-center gap-1 text-[15px] font-bold leading-tight text-[#DC2626] line-through">
                    {formatAmount(original)}
                    <CurrencyMark currency={currency} size={15} />
                  </span>
                )}
                <span className="flex items-end gap-1 text-[16.5px] font-extrabold leading-tight text-deal-green">
                  {formatAmount(sale)}
                  <CurrencyMark currency={currency} size={15} />
                  {unit && <span className="text-[11px] font-normal text-subtitle">{unit}</span>}
                </span>
              </div>
            ) : (
              <div dir="ltr" className={`flex flex-wrap items-center gap-1 text-[15px] font-extrabold leading-tight text-title ${isAr ? 'justify-end' : ''}`}>
                <span>{formatAmount(amount)}</span>
                <CurrencyMark currency={currency} size={15} />
                {unit && <span className="text-[11px] font-normal text-subtitle">{unit}</span>}
              </div>
            )
          ) : showAsk ? (
            <p className="truncate text-[15px] font-bold leading-tight text-title">{t('askForPrice')}</p>
          ) : null}

          {qty && <p className={`truncate text-[11px] leading-tight text-[#6B7280] ${showPrice || showAsk ? 'mt-1.5' : 'mt-2'}`}>{qty}</p>}
          {showReconfirm && <p className="mt-1 truncate text-[11px] font-semibold leading-tight text-[#DC2626]">{t('subjectToReconfirm')}</p>}
          {typeLabel && <p className="mt-1 truncate text-[11px] font-semibold leading-tight text-brand">{typeLabel}</p>}
        </div>
      </div>
    </Link>
  )
}

export const ProductCard = memo(ProductCardImpl)

export function ProductCardSkeleton() {
  return (
    <div className="flex h-full flex-col overflow-hidden rounded-[14px] border border-[#E6ECF3] bg-white shadow-[0_2px_8px_rgba(0,0,0,0.08)]">
      <div className="shimmer h-32 sm:h-36 lg:h-40" />
      <div className="space-y-2 p-3">
        <div className="shimmer h-4 w-4/5 rounded" />
        <div className="shimmer h-3 w-1/3 rounded-full" />
        <div className="shimmer h-3 w-full rounded" />
        <div className="shimmer h-3 w-2/3 rounded" />
        <div className="my-2 h-px bg-[#EEF0F3]" />
        <div className="shimmer h-4 w-1/2 rounded" />
        <div className="shimmer h-3 w-1/3 rounded" />
      </div>
    </div>
  )
}
