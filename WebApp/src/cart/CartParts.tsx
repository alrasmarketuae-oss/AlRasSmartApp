import { useState, type ReactNode } from 'react'
import type { SavedAddress } from '../address/addressApi'
import { useI18n } from '../i18n/I18nProvider'
import { resolveMediaUrl } from '../lib/media'
import { PriceText } from '../products/details/DetailsUI'
import { formatAmount } from '../products/productRules'
import { unitLabel } from '../products/units'
import { VideoFrame } from '../products/VideoFrame'
import { Icon, type IconName } from '../ui/Icon'
import { Modal } from '../ui/Modal'
import type { CartItem, PaymentMethod } from './cartApi'

export const CART = { brand: '#3A7DC5', text: '#1F2937', muted: '#6B7280', border: '#E5E7EB', danger: '#E53935' }
export const cardClass = 'rounded-[14px] bg-white shadow-[0_3px_10px_rgba(0,0,0,0.05)]'
export const infoBoxClass = 'rounded-[10px] border border-[#BFDBFE] bg-[#EFF6FF] text-[#1D4ED8]'

export function StoreIcon({ size = 22 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M4 10v10h16V10 M3 4h18l-1.5 6H4.5z M9 20v-5h6v5 M7.5 10a2.5 2.5 0 0 1-3-2 M12 10a2.5 2.5 0 0 1-3-2 M16.5 10a2.5 2.5 0 0 1-3-2" />
    </svg>
  )
}

export function CardLogos() {
  return (
    <span className="flex items-center gap-1.5" aria-hidden="true">
      <svg viewBox="0 0 750 471" className="h-[26px] w-[42px]">
        <rect width="750" height="471" rx="40" fill="#1A1F71" />
        <path fill="#fff" d="M278.2 334.2 313.6 136.8h55.1L333.3 334.2z" />
        <path fill="#fff" d="M524.3 140.1c-10.9-4.1-28.1-8.5-49.6-8.5-54.7 0-93.2 29.1-93.5 70.8-.4 30.8 27.5 47.9 48.4 58.1 21.5 10.5 28.7 17.1 28.6 26.5-.2 14.3-17.1 20.8-33 20.8-22.1 0-33.8-3.2-51.9-10.8l-7.1-3.3-7.8 48.1c12.9 5.9 36.8 11.1 61.6 11.3 58.1 0 95.9-28.7 96.5-73.2.3-24.4-14.6-43-46.6-58.3-19.4-9.9-31.3-16.5-31.2-26.6.1-8.9 10.1-18.4 31.9-18.4 18.3-.3 31.5 3.9 41.8 8.3l5 2.4 7.5-46.1z" />
        <path fill="#fff" d="M598.1 136.8h-42.6c-13.2 0-23.1 3.8-28.9 17.7l-82 179.7h57.9s9.5-26.2 11.6-31.9h70.7c1.7 7.5 6.8 31.9 6.8 31.9h51.1L598.1 136.8zm-67.7 117.3c4.5-12.1 21.7-58.8 21.7-58.8-.3.6 4.5-12.2 7.2-20.1l3.7 18.1s10.5 50.5 12.7 60.8h-45.3z" />
        <path fill="#fff" d="M232.5 136.8 178.4 279.9l-5.8-29.1c-10.1-34.2-41.5-71.2-76.6-89.7l70.2 173.1h58.1l86.4-197.4h-57.9z" />
        <path fill="#F9A533" d="M126.4 136.8H37.7l-.8 4.2c68.8 17.5 114.4 59.8 133.3 110.6l-19.2-97.1c-3.1-13.5-12.7-17.3-24.6-17.7z" />
      </svg>
      <svg viewBox="0 0 750 471" className="h-[26px] w-[42px]">
        <rect width="750" height="471" rx="40" fill="#000" />
        <circle cx="300" cy="235.5" r="130" fill="#EB001B" />
        <circle cx="450" cy="235.5" r="130" fill="#F79E1B" />
        <path fill="#FF5F00" d="M375 129.3c-26.4 21.1-43.4 53.3-43.4 89.2s17 68.1 43.4 89.2c26.4-21.1 43.4-53.3 43.4-89.2s-17-68.1-43.4-89.2z" />
      </svg>
    </span>
  )
}

export function SectionTitle({ title, icon }: { title: string; icon: ReactNode }) {
  return (
    <div className="flex items-center gap-2" style={{ color: CART.brand }}>
      {icon}
      <h2 className="text-base font-extrabold" style={{ color: CART.text }}>
        {title}
      </h2>
    </div>
  )
}

export function MessageState({ message, action, onAction }: { message: string; action: string; onAction: () => void }) {
  return (
    <div className="flex min-h-[50vh] flex-col items-center justify-center gap-4 px-6 text-center">
      <p className="text-[15px]" style={{ color: CART.text }}>
        {message}
      </p>
      <button type="button" onClick={onAction} className="h-11 w-44 rounded-xl bg-gradient-to-r from-brand-dark to-brand-light text-sm font-bold text-white hover:brightness-110">
        {action}
      </button>
    </div>
  )
}

export function SendingText({ label }: { label: string }) {
  return (
    <span className="inline-flex items-baseline">
      {label}
      <span className="inline-block w-4 animate-pulse text-start">...</span>
    </span>
  )
}

const capitalize = (s: string) => (s ? s.charAt(0).toUpperCase() + s.slice(1) : s)

function QuantitySelector({ item, onIncrement, onDecrement, onCommit }: { item: CartItem; onIncrement: () => void; onDecrement: () => void; onCommit: (value: number) => void }) {
  const [draft, setDraft] = useState<string | null>(null)
  const canIncrement = !item.availableQuantity || item.quantity + 0.0001 < item.availableQuantity
  const commit = () => {
    if (draft === null) return
    const parsed = Number(draft.replace(/,/g, ''))
    setDraft(null)
    if (!Number.isFinite(parsed) || parsed <= 0 || parsed === item.quantity) return
    onCommit(parsed)
  }
  const step = (icon: IconName, onClick: () => void, enabled: boolean, emphasize = false) => (
    <button
      type="button"
      onClick={onClick}
      disabled={!enabled}
      className="grid size-7 place-items-center rounded-full hover:bg-black/5 disabled:cursor-not-allowed"
      style={{ color: !enabled ? 'rgba(107,114,128,0.45)' : emphasize ? CART.brand : CART.text }}
    >
      <Icon name={icon} size={16} strokeWidth={2.4} />
    </button>
  )
  return (
    <div className="flex items-center rounded-full border bg-[#F8FAFC] px-1.5 py-1" style={{ borderColor: CART.border }}>
      {step('minus', onDecrement, true)}
      <input
        dir="ltr"
        inputMode="decimal"
        value={draft ?? formatAmount(item.quantity)}
        onChange={(e) => setDraft(e.target.value.replace(/[^\d.,]/g, ''))}
        onBlur={commit}
        onKeyDown={(e) => e.key === 'Enter' && e.currentTarget.blur()}
        className="w-14 bg-transparent text-center text-sm font-bold outline-none"
        style={{ color: CART.text }}
      />
      {step('plus', onIncrement, canIncrement, true)}
    </div>
  )
}

function CartThumb({ item }: { item: CartItem }) {
  const image = resolveMediaUrl(item.imageUrl)
  const video = resolveMediaUrl(item.videoUrl)
  const placeholder = <img src="/assets/logo/brand_mark.png" alt="" className="size-full bg-[#F1F5F9] object-contain p-3" />
  return (
    <div className="relative size-[76px] shrink-0 overflow-hidden rounded-[10px] bg-[#F1F5F9]">
      {image ? <img src={image} alt="" loading="lazy" className="size-full object-cover" /> : video ? <VideoFrame src={video} className="size-full object-cover" fallback={placeholder} /> : placeholder}
      {video && (
        <span className="absolute inset-0 grid place-items-center">
          <span className="grid size-7 place-items-center rounded-full bg-black/45 text-white">
            <Icon name="play" size={14} fill="currentColor" />
          </span>
        </span>
      )}
    </div>
  )
}

export function CartItemCard(props: {
  item: CartItem
  showDelete: boolean
  onIncrement: () => void
  onDecrement: () => void
  onCommit: (value: number) => void
  onDelete: () => void
}) {
  const { t } = useI18n()
  const { item } = props
  return (
    <div className={`flex gap-3 p-3 ${cardClass}`}>
      <CartThumb item={item} />
      <div className="min-w-0 flex-1">
        <div className="flex items-start gap-2">
          <p className="line-clamp-2 min-w-0 flex-1 text-sm font-extrabold leading-snug" style={{ color: CART.text }}>
            {capitalize(item.productName)}
          </p>
          {props.showDelete && (
            <button type="button" onClick={props.onDelete} aria-label={t('delete')} className="rounded-full p-0.5 hover:bg-red-50" style={{ color: CART.danger }}>
              <Icon name="trash" size={20} />
            </button>
          )}
        </div>
        <p className="mt-1 text-xs font-medium" style={{ color: CART.muted }}>
          {`${formatAmount(item.quantity)} ${item.unitName ? unitLabel(item.unitName, t) : ''}`.trim()}
        </p>
        <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
          <QuantitySelector item={item} onIncrement={props.onIncrement} onDecrement={props.onDecrement} onCommit={props.onCommit} />
          <PriceText amount={item.unitPriceAed} currency="AED" size={15} className="text-[15px] font-extrabold text-deal-green" />
        </div>
      </div>
    </div>
  )
}

function SelectableCard({ selected, onClick, children, className = '' }: { selected: boolean; onClick?: () => void; children: ReactNode; className?: string }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={!onClick}
      className={`w-full text-start transition ${cardClass} ${className}`}
      style={{ border: `${selected ? 1.6 : 1}px solid ${selected ? CART.brand : CART.border}` }}
    >
      {children}
    </button>
  )
}

function CheckBadge({ size = 20 }: { size?: number }) {
  return (
    <span className="grid shrink-0 place-items-center rounded-full text-white" style={{ width: size, height: size, background: CART.brand }}>
      <Icon name="check" size={size * 0.65} strokeWidth={3} />
    </span>
  )
}

export function DeliveryMethodSection({ selfPickup, onChange }: { selfPickup: boolean; onChange: (value: boolean) => void }) {
  const { t } = useI18n()
  const option = (value: boolean, icon: ReactNode, label: string, hint: string) => (
    <SelectableCard selected={selfPickup === value} onClick={() => onChange(value)} className="relative px-3 py-3.5">
      <span className="block" style={{ color: CART.brand }}>
        {icon}
      </span>
      <span className="mt-2.5 block text-sm font-extrabold" style={{ color: CART.text }}>
        {label}
      </span>
      <span className="mt-1 line-clamp-2 block text-[11px] font-medium leading-snug" style={{ color: CART.muted }}>
        {hint}
      </span>
      {selfPickup === value && (
        <span className="absolute end-3 top-3.5">
          <CheckBadge />
        </span>
      )}
    </SelectableCard>
  )
  return (
    <section>
      <SectionTitle title={t('deliveryMethod')} icon={<Icon name="truck" size={18} />} />
      <div className="mt-3 grid grid-cols-2 gap-2.5">
        {option(false, <Icon name="truck" size={22} />, t('delivery'), t('deliveryToAddressHint'))}
        {option(true, <StoreIcon />, t('selfPickup'), t('selfPickupHint'))}
      </div>
    </section>
  )
}

export function DeliveryAddressSection(props: {
  addresses: SavedAddress[]
  selected: SavedAddress | null
  loading: boolean
  onSelect: (address: SavedAddress) => void
  onAdd: () => void
}) {
  const { t } = useI18n()
  const [open, setOpen] = useState(false)
  const addButton = (
    <button type="button" onClick={props.onAdd} className="mt-1 inline-flex items-center gap-1 px-1 py-1.5 text-sm font-semibold hover:underline" style={{ color: CART.brand }}>
      <Icon name="plus" size={18} />
      {t('addNewAddress')}
    </button>
  )
  return (
    <section>
      <SectionTitle title={t('deliveryAddress')} icon={<Icon name="location" size={18} />} />
      <div className="mt-3">
        {props.loading ? (
          <div className="grid place-items-center py-3">
            <span className="size-6 animate-spin rounded-full border-2 border-brand/30 border-t-brand" />
          </div>
        ) : !props.addresses.length ? (
          <div className={`p-4 ${cardClass}`} style={{ border: `1px solid ${CART.border}` }}>
            <p className="text-sm" style={{ color: CART.muted }}>
              {t('noSavedAddresses')}
            </p>
            {addButton}
          </div>
        ) : (
          <>
            <SelectableCard selected={false} onClick={() => setOpen(true)} className="flex items-center gap-3 p-3.5">
              <span className="grid size-9 shrink-0 place-items-center rounded-[10px] bg-[#3A7DC5]/10" style={{ color: CART.brand }}>
                <Icon name="location" size={18} />
              </span>
              <span className="line-clamp-3 min-w-0 flex-1 text-[13px] font-semibold leading-snug" style={{ color: props.selected ? CART.text : CART.muted }}>
                {props.selected?.label ?? t('selectDeliveryAddress')}
              </span>
              <Icon name="chevronRight" size={22} className="shrink-0 rtl:rotate-180" style={{ color: CART.muted }} />
            </SelectableCard>
            {addButton}
          </>
        )}
      </div>
      <Modal open={open} onClose={() => setOpen(false)} title={t('selectDeliveryAddress')}>
        <div className="flex flex-col">
          {props.addresses.map((address) => (
            <button
              key={address.addressId}
              type="button"
              onClick={() => {
                setOpen(false)
                props.onSelect(address)
              }}
              className="flex items-center gap-3 rounded-xl px-2 py-3 text-start hover:bg-[#F4F7FA]"
            >
              <Icon name="location" size={22} className="shrink-0" style={{ color: CART.brand }} />
              <span className="min-w-0 flex-1 text-[13px] font-semibold" style={{ color: CART.text }}>
                {address.label}
              </span>
              {address.addressId === props.selected?.addressId && <CheckBadge />}
            </button>
          ))}
        </div>
      </Modal>
    </section>
  )
}

function SummaryRow({ label, children, bold }: { label: string; children?: ReactNode; bold?: boolean }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <span className={`line-clamp-2 min-w-0 flex-1 ${bold ? 'text-[15px] font-extrabold' : 'text-[13px] font-medium'}`} style={{ color: CART.text }}>
        {label}
      </span>
      {children}
    </div>
  )
}

export function OrderSummarySection(props: { items: CartItem[]; vat: number; deliveryFee: number; total: number; selfPickup: boolean; loadingShipping: boolean }) {
  const { t } = useI18n()
  const value = (amount: number) => <PriceText amount={amount} currency="AED" size={13} className="text-[13px] font-semibold text-[#1F2937]" />
  const muted = (text: string) => (
    <span className="text-[13px] font-medium" style={{ color: CART.muted }}>
      {text}
    </span>
  )
  return (
    <section>
      <SectionTitle title={t('orderSummary')} icon={<Icon name="receipt" size={18} />} />
      <div className={`mt-3 flex flex-col gap-2.5 p-4 ${cardClass}`} style={{ border: `1px solid ${CART.border}` }}>
        {props.items.map((item) => (
          <SummaryRow key={item.id} label={item.productName}>
            {value(item.totalPriceAed)}
          </SummaryRow>
        ))}
        <SummaryRow label={t('vatFivePercent')}>{value(props.vat)}</SummaryRow>
        <SummaryRow label={props.selfPickup ? t('selfPickup') : t('deliveryFee')}>
          {props.selfPickup ? muted(t('free')) : props.loadingShipping ? muted('...') : value(props.deliveryFee)}
        </SummaryRow>
        <hr className="my-1.5" style={{ borderColor: CART.border }} />
        <SummaryRow label={t('total')} bold>
          <PriceText amount={props.total} currency="AED" size={18} className="text-lg font-extrabold text-deal-green" />
        </SummaryRow>
        {!props.selfPickup && (
          <div className={`mt-1.5 flex items-start gap-2 px-3 py-2.5 ${infoBoxClass}`}>
            <Icon name="info" size={16} className="mt-0.5 shrink-0" />
            <p className="text-xs font-medium leading-relaxed">{t('domesticShippingWeightDisclaimer')}</p>
          </div>
        )}
      </div>
    </section>
  )
}

function SelectionDot({ selected }: { selected: boolean }) {
  return (
    <span
      className="grid size-[22px] shrink-0 place-items-center rounded-full text-white transition"
      style={{ background: selected ? CART.brand : 'transparent', border: `1.6px solid ${selected ? CART.brand : CART.border}` }}
    >
      {selected && <Icon name="check" size={14} strokeWidth={3} />}
    </span>
  )
}

export function PaymentMethodSection({ method, onChange, enabled }: { method: PaymentMethod; onChange: (m: PaymentMethod) => void; enabled: boolean }) {
  const { t } = useI18n()
  const option = (value: PaymentMethod, icon: ReactNode, label: string, trailing?: ReactNode) => (
    <SelectableCard selected={method === value} onClick={enabled ? () => onChange(value) : undefined} className="flex items-center gap-3 px-3.5 py-3.5 disabled:opacity-70">
      <span className="grid size-9 shrink-0 place-items-center rounded-[10px] bg-[#3A7DC5]/10" style={{ color: CART.brand }}>
        {icon}
      </span>
      <span className="min-w-0 flex-1 text-sm font-bold" style={{ color: CART.text }}>
        {label}
      </span>
      {trailing}
      <SelectionDot selected={method === value} />
    </SelectableCard>
  )
  return (
    <section>
      <SectionTitle title={t('paymentMethods')} icon={<CardIcon size={18} />} />
      <p className="mt-1.5 text-xs leading-relaxed" style={{ color: CART.muted }}>
        {t('retailVisaPaymentHint')}
      </p>
      <div className="mt-3 flex flex-col gap-2.5">
        {option('Online', <CardIcon size={20} />, t('payWithVisa'), <CardLogos />)}
        {option('CashOnDelivery', <CashIcon size={20} />, t('cashOnDelivery'))}
      </div>
    </section>
  )
}

function CardIcon({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.9} strokeLinecap="round" aria-hidden="true">
      <rect x="3" y="5.5" width="18" height="13" rx="2" />
      <path d="M3 10h18 M7 15h3" />
    </svg>
  )
}

function CashIcon({ size }: { size: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round" aria-hidden="true">
      <rect x="2.5" y="6" width="19" height="12" rx="2" />
      <circle cx="12" cy="12" r="2.6" />
      <path d="M6 9.5v.01 M18 14.5v.01" />
    </svg>
  )
}

export function CheckoutBar({ label, total, busy, onClick }: { label: string; total: number; busy: boolean; onClick?: () => void }) {
  const { t } = useI18n()
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={busy || !onClick}
      className="flex h-14 w-full items-center gap-2.5 rounded-[14px] px-4 text-[15px] font-extrabold text-white shadow-[0_6px_14px_rgba(58,125,197,0.28)] hover:brightness-110 disabled:hover:brightness-100"
      style={{ background: CART.brand }}
    >
      {!busy && <Icon name="lock" size={18} strokeWidth={2.2} />}
      <span className="min-w-0 flex-1 truncate text-start">{busy ? <SendingText label={t('sending')} /> : label}</span>
      <span dir="ltr" className="inline-flex items-center gap-1">
        {formatAmount(total)}
        <img src="/assets/icons/dirham.svg" alt="AED" className="h-3 w-auto brightness-0 invert" />
      </span>
      <Icon name="chevronRight" size={22} className="rtl:rotate-180" />
    </button>
  )
}