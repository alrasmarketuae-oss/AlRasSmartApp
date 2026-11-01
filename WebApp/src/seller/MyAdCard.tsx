import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useEffect, useRef, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { Spinner } from '../auth/components'
import { useI18n } from '../i18n/I18nProvider'
import { MaskIcon } from '../layout/MaskIcon'
import { ApiError } from '../lib/api'
import { resolveMediaUrl } from '../lib/media'
import { CurrencyMark } from '../products/ProductCard'
import { useViewer } from '../products/ProductGrid'
import {
  amountValue,
  categoryLabel,
  currencyCode,
  formatAmount,
  isRequestProduct,
  isRetailFeedProduct,
  isSoldOut,
  priceTypeLabel,
  productImages,
  productTitle,
  productVideos,
  quantityWithUnit,
  unitSuffix,
} from '../products/productRules'
import { VideoFrame } from '../products/VideoFrame'
import { Icon, type IconName } from '../ui/Icon'
import { Modal } from '../ui/Modal'
import { useToast } from '../ui/Toast'
import { canToggleListing, isListingActive, isRejectedWithReason, listingBadge, type BadgeStyle } from './listingRules'
import { deleteProduct, fetchAdStatistics, markSoldOut, setListingStatus, type MyListing } from './sellerApi'

export const MY_LISTINGS_KEY = 'my-listings'

const errorText = (error: unknown, fallback: string) => (error instanceof ApiError ? error.message : fallback)

export function MediaThumb({ product, className }: { product: MyListing; className: string }) {
  const [failed, setFailed] = useState(false)
  const image = productImages(product)[0] || ''
  const video = image ? '' : productVideos(product)[0] || ''
  const placeholder = (
    <span className="grid size-full place-items-center text-[#9CA3AF]">
      <Icon name="image" size={22} />
    </span>
  )
  return (
    <span className={`relative block shrink-0 overflow-hidden bg-[#F3F4F6] ${className}`}>
      {image && !failed ? (
        <img src={image} alt="" loading="lazy" onError={() => setFailed(true)} className="size-full object-cover" />
      ) : video ? (
        <>
          <VideoFrame src={video} className="size-full object-cover" fallback={placeholder} />
          <span className="absolute inset-0 grid place-items-center">
            <span className="grid size-7 place-items-center rounded-full bg-black/45 text-white">
              <Icon name="play" size={13} />
            </span>
          </span>
        </>
      ) : product.categoryImagePath ? (
        <img src={resolveMediaUrl(product.categoryImagePath)} alt="" loading="lazy" className="size-full object-cover" />
      ) : (
        placeholder
      )}
    </span>
  )
}

export function StatusBadge({ badge, compact }: { badge: BadgeStyle; compact?: boolean }) {
  return (
    <span
      className={`inline-flex max-w-full items-center gap-1 rounded-[10px] font-semibold leading-tight ${compact ? 'px-2 py-1 text-[11px]' : 'px-3 py-2 text-sm'}`}
      style={{ background: badge.bg, color: badge.fg }}
    >
      <span className="truncate">{badge.label}</span>
      {badge.icon === 'stop' ? <MaskIcon src="/assets/profile/Stop.svg" color={badge.fg} size={compact ? 13 : 18} /> : <Icon name={badge.icon} size={compact ? 13 : 18} />}
    </span>
  )
}

export function ViewsBadge({ count, compact }: { count: number; compact?: boolean }) {
  const { t } = useI18n()
  return (
    <span className={`inline-flex shrink-0 items-center gap-1 text-[#6B7280] ${compact ? 'text-[11px]' : 'text-[13px]'}`}>
      <Icon name="eye" size={compact ? 13 : 17} />
      {t('adViewsCount', { count: formatAmount(count) })}
    </span>
  )
}

/** `ProductPriceText.unitPrice`: amount + currency mark + "/ unit". */
export function UnitPrice({ product, preferRetail, className = 'text-[15px]' }: { product: MyListing; preferRetail: boolean; className?: string }) {
  const { isAr } = useI18n()
  const viewer = useViewer()
  const amount = amountValue(product, viewer, preferRetail)
  if (amount <= 0) return null
  const currency = preferRetail && product.hasRetailPricing ? 'AED' : currencyCode(product, viewer)
  return (
    <span className={`flex flex-wrap items-center gap-1 font-extrabold leading-tight text-brand ${className}`}>
      {formatAmount(amount)}
      <CurrencyMark currency={currency} size={14} />
      <span className="text-[11px] font-normal text-subtitle">{unitSuffix(product, isAr, preferRetail)}</span>
    </span>
  )
}

export function ConfirmDialog(props: {
  open: boolean
  title: string
  message: string
  confirmLabel: string
  danger?: boolean
  busy?: boolean
  onConfirm: () => void
  onClose: () => void
}) {
  const { t } = useI18n()
  return (
    <Modal open={props.open} onClose={props.onClose} title={props.title}>
      <p className="text-sm leading-relaxed text-subtitle">{props.message}</p>
      <div className="mt-5 flex gap-3">
        <button type="button" onClick={props.onClose} className="flex-1 rounded-xl border border-line py-3 text-sm font-bold text-subtitle">
          {t('cancel')}
        </button>
        <button
          type="button"
          disabled={props.busy}
          onClick={props.onConfirm}
          className={`flex flex-1 items-center justify-center gap-2 rounded-xl py-3 text-sm font-bold text-white disabled:opacity-60 ${props.danger ? 'bg-[#D92D20]' : 'bg-brand'}`}
        >
          {props.busy && <Spinner className="size-4 border-2 border-white/40 border-t-white" />}
          {props.confirmLabel}
        </button>
      </div>
    </Modal>
  )
}

function StatRow({ icon, label, value }: { icon: IconName; label: string; value: number }) {
  return (
    <div className="flex items-center gap-3 rounded-xl border border-[#E4E7EC] bg-[#F8FAFC] px-3.5 py-3">
      <span className="grid size-9 shrink-0 place-items-center rounded-full bg-[#E8F2FC] text-brand">
        <Icon name={icon} size={18} />
      </span>
      <span className="min-w-0 flex-1 text-sm font-semibold text-title">{label}</span>
      <span className="text-base font-extrabold text-brand">{value}</span>
    </div>
  )
}

export function StatisticsModal({ product, open, onClose }: { product: MyListing; open: boolean; onClose: () => void }) {
  const { t, isAr } = useI18n()
  const query = useQuery({ queryKey: ['ad-statistics', product.productId], queryFn: () => fetchAdStatistics(product.productId), enabled: open, retry: false })
  const stats = query.data
  const title = productTitle(product, isAr)
  return (
    <Modal open={open} onClose={onClose} title={t('adStatistics')}>
      {title && <p className="-mt-2 mb-4 line-clamp-2 text-[13px] text-subtitle first-letter:uppercase">{title}</p>}
      {query.isPending ? (
        <div className="grid place-items-center py-8">
          <Spinner className="size-7 border-[3px] border-brand/25 border-t-brand" />
        </div>
      ) : !stats ? (
        <p className="py-6 text-center text-sm text-subtitle">{t('couldNotLoadStatistics')}</p>
      ) : (
        <div className="space-y-2.5">
          <StatRow icon="eye" label={t('adStatVisits')} value={stats.viewsCount} />
          {(stats.showCartAdds || isRetailFeedProduct(product)) && <StatRow icon="cart" label={t('adStatCartAdds')} value={stats.cartAddsCount} />}
          <StatRow icon="bag" label={t('adStatPurchases')} value={stats.purchasesCount} />
          <StatRow icon="bookmark" label={t('adStatFavorites')} value={stats.favoritesCount} />
          <StatRow icon="share" label={t('adStatShares')} value={stats.sharesCount} />
        </div>
      )}
    </Modal>
  )
}

type MenuItem = { label: string; onClick: () => void; disabled?: boolean; danger?: boolean }

function ActionsMenu({ items }: { items: MenuItem[] }) {
  const { t } = useI18n()
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    if (!open) return
    const close = (event: MouseEvent) => ref.current && !ref.current.contains(event.target as Node) && setOpen(false)
    document.addEventListener('mousedown', close)
    return () => document.removeEventListener('mousedown', close)
  }, [open])
  return (
    <div ref={ref} className="relative -me-1.5 -mt-1 shrink-0">
      <button
        type="button"
        aria-label={t('edit')}
        onClick={(e) => {
          e.stopPropagation()
          setOpen((v) => !v)
        }}
        className="grid size-8 place-items-center rounded-full text-[#475467] hover:bg-black/5"
      >
        <Icon name="more" size={22} strokeWidth={2.6} />
      </button>
      {open && (
        <div className="absolute end-0 top-full z-30 min-w-40 overflow-hidden rounded-[10px] border border-line bg-white py-1 shadow-[0_10px_28px_rgba(15,23,42,0.16)]">
          {items.map((item) => (
            <button
              key={item.label}
              type="button"
              disabled={item.disabled}
              onClick={(e) => {
                e.stopPropagation()
                setOpen(false)
                item.onClick()
              }}
              className={`block w-full px-4 py-2.5 text-start text-sm hover:bg-[#F4F7FB] disabled:opacity-50 ${item.danger ? 'text-[#D92D20]' : 'text-title'}`}
            >
              {item.label}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

export type CardChannel = { preferRetail: boolean; preferCategory: boolean; showBoth: boolean }

/** Compact Account list card (`MyAdAnnouncementCard(compact: true)`). */
export function MyAdCard({ product, highlighted, channel }: { product: MyListing; highlighted: boolean; channel: CardChannel }) {
  const { t, isAr } = useI18n()
  const toast = useToast()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [active, setActive] = useState(() => isListingActive(product))
  const [busy, setBusy] = useState<'' | 'toggle' | 'soldOut' | 'delete'>('')
  const [dialog, setDialog] = useState<'' | 'soldOut' | 'delete' | 'stats'>('')
  const [blink, setBlink] = useState(highlighted)

  useEffect(() => setActive(isListingActive(product)), [product])
  useEffect(() => {
    if (!highlighted) return
    setBlink(true)
    const id = window.setTimeout(() => setBlink(false), 5000)
    return () => window.clearTimeout(id)
  }, [highlighted])

  const title = productTitle(product, isAr)
  const badge = listingBadge(product, t, isAr)
  const canToggle = canToggleListing(product)
  const showSoldOut = !isRequestProduct(product) && !isSoldOut(product, channel.preferRetail)
  const category = categoryLabel(product, isAr)
  const priceType = priceTypeLabel(product, t)
  const quantity = quantityWithUnit(product, isAr, false)
  const glow = blink || product.pendingOffersCount > 0
  const refresh = () => queryClient.invalidateQueries({ queryKey: [MY_LISTINGS_KEY] })

  const open = () => navigate(`/my-ads/${encodeURIComponent(product.productId)}`, { state: { product, ...channel } })

  const toggle = async () => {
    if (busy) return
    setBusy('toggle')
    const next = !active
    try {
      await setListingStatus(product.productId, next)
      setActive(next)
      toast.success(next ? t('listingActivated') : t('listingPausedToast'))
      void refresh()
    } catch (error) {
      toast.error(errorText(error, t('unexpectedError')))
    } finally {
      setBusy('')
    }
  }

  const soldOut = async () => {
    setBusy('soldOut')
    try {
      await markSoldOut(product.productId)
      setDialog('')
      toast.success(t('soldOut'))
      void refresh()
    } catch (error) {
      toast.error(errorText(error, t('unexpectedError')))
    } finally {
      setBusy('')
    }
  }

  const remove = async () => {
    setBusy('delete')
    try {
      await deleteProduct(product.productId)
      setDialog('')
      toast.success(t('adDeletedSuccessfully'))
      void refresh()
    } catch (error) {
      toast.error(errorText(error, t('unexpectedError')))
    } finally {
      setBusy('')
    }
  }

  const menu: MenuItem[] = [
    { label: t('edit'), onClick: () => navigate(`/create-ad?edit=${encodeURIComponent(product.productId)}`, { state: { product } }) },
    { label: t('adStatistics'), onClick: () => setDialog('stats') },
    ...(canToggle ? [{ label: active ? t('pauseListing') : t('publish'), onClick: toggle, disabled: busy === 'toggle' }] : []),
    ...(showSoldOut ? [{ label: t('soldOut'), onClick: () => setDialog('soldOut'), disabled: busy === 'soldOut' }] : []),
    { label: t('delete'), onClick: () => setDialog('delete'), disabled: busy === 'delete', danger: true },
  ]

  return (
    <article
      id={`ad-${product.productId}`}
      className={`flex rounded-2xl border bg-white shadow-[0_2px_8px_rgba(0,0,0,0.06)] ${glow ? 'seller-blink border-2' : 'border-[#E7EEF6]'}`}
    >
      <button type="button" onClick={open} className="shrink-0 p-2">
        <MediaThumb product={product} className="size-24 rounded-xl" />
      </button>
      <div className="min-w-0 flex-1 py-2 pe-2 ps-0.5">
        <div className="flex items-start gap-1">
          <button type="button" onClick={open} className="min-w-0 flex-1 truncate text-start text-[13.5px] font-extrabold leading-tight text-title first-letter:uppercase">
            {title || '—'}
          </button>
          <ActionsMenu items={menu} />
        </div>
        <div className="mt-1 flex items-center gap-1.5">
          <StatusBadge badge={badge} compact />
          {canToggle && (
            <button
              type="button"
              onClick={toggle}
              disabled={busy === 'toggle'}
              aria-label={active ? t('pauseListing') : t('publish')}
              className="grid size-[22px] place-items-center rounded-full bg-[#E8F2FC] text-brand"
            >
              {busy === 'toggle' ? <Spinner className="size-2.5 border-[1.6px] border-brand/25 border-t-brand" /> : <Icon name={active ? 'minus' : 'plus'} size={14} strokeWidth={2.4} />}
            </button>
          )}
        </div>
        <button type="button" onClick={open} className="block w-full text-start">
          <span className="mt-1 flex items-center gap-2">
            <span className="min-w-0 flex-1 truncate text-[11px] text-subtitle">{category}</span>
            <ViewsBadge count={product.viewsCount ?? 0} compact />
          </span>
          <span className="mt-1 block">
            <UnitPrice product={product} preferRetail={channel.preferRetail} className="text-[14px]" />
          </span>
          <span className="mt-1 flex items-center gap-2">
            {priceType && <span className="truncate rounded-md bg-[#E8F2FC] px-1.5 py-0.5 text-[10px] font-bold text-brand">{priceType}</span>}
            {quantity && <span className="min-w-0 flex-1 truncate text-[11px] text-[#6B7280]">{quantity}</span>}
          </span>
          {isRejectedWithReason(product) && (
            <span className="mt-1 block truncate text-[11px] text-[#D92D20]">
              {t('rejectionReason')}: {product.supplierNotes?.trim()}
            </span>
          )}
        </button>
      </div>

      <ConfirmDialog
        open={dialog === 'soldOut'}
        title={t('soldOutConfirmTitle')}
        message={t('markSoldOutQuestion', { label: t('soldOut') })}
        confirmLabel={t('soldOut')}
        busy={busy === 'soldOut'}
        onConfirm={soldOut}
        onClose={() => setDialog('')}
      />
      <ConfirmDialog
        open={dialog === 'delete'}
        title={t('deleteAdConfirmTitle')}
        message={t('deleteAdConfirmMessage', { name: title })}
        confirmLabel={t('delete')}
        danger
        busy={busy === 'delete'}
        onConfirm={remove}
        onClose={() => setDialog('')}
      />
      {dialog === 'stats' && <StatisticsModal product={product} open onClose={() => setDialog('')} />}
    </article>
  )
}

export function MyAdCardSkeleton() {
  return (
    <div className="flex gap-2 rounded-2xl border border-[#E7EEF6] bg-white p-2">
      <div className="shimmer size-24 rounded-xl" />
      <div className="flex-1 space-y-2 py-1">
        <div className="shimmer h-4 w-3/4 rounded" />
        <div className="shimmer h-5 w-20 rounded-lg" />
        <div className="shimmer h-3 w-1/2 rounded" />
        <div className="shimmer h-4 w-1/3 rounded" />
        <div className="shimmer h-3 w-2/5 rounded" />
      </div>
    </div>
  )
}

export function MessageView({ icon, title, children }: { icon: IconName; title: string; children?: ReactNode }) {
  return (
    <div className="flex flex-col items-center gap-4 px-8 py-20 text-center">
      <Icon name={icon} size={52} className="text-brand/50" />
      <p className="line-clamp-3 text-base font-semibold text-subtitle">{title}</p>
      {children}
    </div>
  )
}

export const BLINK_STYLE = `@keyframes seller-blink{0%,100%{border-color:#F97066}50%{border-color:#D92D20}}.seller-blink{animation:seller-blink .84s ease-in-out infinite}`
