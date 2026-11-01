import type { ReactNode } from 'react'
import { useI18n } from '../../i18n/I18nProvider'
import { Icon, type IconName } from '../../ui/Icon'
import { useToast } from '../../ui/Toast'
import { CurrencyMark } from '../ProductCard'
import { formatAmount } from '../productRules'

export const BRAND = '#2F6AAD'
export const BRAND_SOFT = '#3A7DC5'
export const PRICE_GREEN = '#619D50'

export function SectionCard({ title, icon, children }: { title: string; icon: IconName; children: ReactNode }) {
  return (
    <section className="rounded-[14px] border border-line bg-white px-3.5 py-3 shadow-[0_4px_12px_rgba(15,23,42,0.05)] sm:px-5 sm:py-4">
      <div className="mb-3 flex items-center gap-2.5">
        <span className="grid size-8 place-items-center rounded-[9px] bg-[#EEF4FB] text-[#3A7DC5]">
          <Icon name={icon} size={17} />
        </span>
        <h2 className="text-[15px] font-extrabold sm:text-base" style={{ color: BRAND }}>
          {title}
        </h2>
      </div>
      {children}
    </section>
  )
}

export function FactTile({ icon, label, value, children, valueColor, bold }: { icon: IconName; label: string; value?: string; children?: ReactNode; valueColor?: string; bold?: boolean }) {
  if (!children && !value?.trim()) return null
  return (
    <div className="flex items-start gap-2 pb-3">
      <Icon name={icon} size={16} className="mt-0.5 shrink-0 text-[#3A7DC5]" />
      <div className="min-w-0 flex-1">
        <p className="text-[11px] font-bold text-title sm:text-xs">{label}</p>
        <div className={`mt-0.5 text-[13px] leading-snug sm:text-sm ${bold ? 'font-bold' : 'font-medium'}`} style={{ color: valueColor ?? 'var(--color-subtitle)' }}>
          {children ?? value}
        </div>
      </div>
    </div>
  )
}

/** Two equal columns like BookingDetailsFactsGrid; empty tiles render nothing. */
export function FactsGrid({ children }: { children: ReactNode }) {
  return <div className="grid grid-cols-2 gap-x-2.5">{children}</div>
}

export function MetaDivider() {
  return <div className="mb-2.5 mt-0.5 h-px bg-line" />
}

export function MetricCard({ label, icon, color, value, children }: { label: string; icon: IconName; color: string; value?: string; children?: ReactNode }) {
  return (
    <div className="flex min-h-[86px] flex-col rounded-xl border border-line bg-white p-2 shadow-[0_4px_12px_rgba(15,23,42,0.05)] sm:p-3">
      <div className="flex items-start gap-1">
        <p className="line-clamp-2 flex-1 text-[9.5px] font-bold leading-tight text-title sm:text-xs">{label}</p>
        <span className="grid size-5 shrink-0 place-items-center rounded-full sm:size-6" style={{ backgroundColor: `${color}1f`, color }}>
          <Icon name={icon} size={11} />
        </span>
      </div>
      <div className="mt-auto line-clamp-2 pt-1.5 text-[11px] font-semibold leading-tight text-subtitle sm:text-[13px]">{children ?? value ?? '—'}</div>
    </div>
  )
}

export function PriceText({ amount, currency, className = '', size = 14 }: { amount: number; currency: string; className?: string; size?: number }) {
  return (
    <span dir="ltr" className={`inline-flex items-center gap-1 ${className}`}>
      {formatAmount(amount)}
      <CurrencyMark currency={currency} size={size} />
    </span>
  )
}

export function CopyCode({ code }: { code: string }) {
  const { t } = useI18n()
  const toast = useToast()
  return (
    <button
      type="button"
      onClick={() => {
        void navigator.clipboard?.writeText(code)
        toast.success(t('productCodeCopied'))
      }}
      className="inline-flex items-center gap-1.5 font-semibold text-[#3A7DC5] hover:underline"
      dir="ltr"
    >
      {code}
      <Icon name="copy" size={14} />
    </button>
  )
}

export function Bullets({ items }: { items: string[] }) {
  return (
    <ul className="space-y-1.5">
      {items.map((item, i) => (
        <li key={i} className="text-[13px] leading-relaxed text-title sm:text-sm">
          • {item}
        </li>
      ))}
    </ul>
  )
}
