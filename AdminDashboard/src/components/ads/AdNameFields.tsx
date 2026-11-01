import type { CSSProperties } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'

type NamedProduct = {
  name: string
  nameEn?: string
  nameAr?: string
}

export function storedAdNames(product: NamedProduct) {
  const nameEn = product.nameEn?.trim() ?? ''
  const nameAr = product.nameAr?.trim() ?? ''
  if (!nameEn && !nameAr) {
    return { nameEn: product.name ?? '', nameAr: '' }
  }
  return { nameEn, nameAr }
}

type AdNameFieldsProps = {
  nameEn: string
  nameAr: string
  onNameEn: (value: string) => void
  onNameAr: (value: string) => void
  inputClassName: string
  inputStyle?: CSSProperties
}

export function AdNameFields({
  nameEn,
  nameAr,
  onNameEn,
  onNameAr,
  inputClassName,
  inputStyle,
}: AdNameFieldsProps) {
  const { t } = useAppPreferences()
  return (
    <div className="grid gap-2 sm:grid-cols-2">
      <label className="block text-start">
        <span className="admin-text-muted mb-1 block text-[10px] font-semibold">
          {t('ads.productNameEn')}
        </span>
        <input
          dir="ltr"
          value={nameEn}
          onChange={(e) => onNameEn(e.target.value)}
          className={inputClassName}
          style={inputStyle}
        />
      </label>
      <label className="block text-start">
        <span className="admin-text-muted mb-1 block text-[10px] font-semibold">
          {t('ads.productNameAr')}
        </span>
        <input
          dir="rtl"
          value={nameAr}
          onChange={(e) => onNameAr(e.target.value)}
          className={inputClassName}
          style={inputStyle}
        />
      </label>
    </div>
  )
}

export function AdNameReadout({
  nameEn,
  nameAr,
  fallback,
}: {
  nameEn: string
  nameAr: string
  fallback: string
}) {
  const { t } = useAppPreferences()
  return (
    <div className="space-y-1">
      <p className="text-[11px] leading-snug">
        <span className="admin-text-muted">{t('ads.productNameEn')}: </span>
        <span dir="ltr">{nameEn.trim() || fallback || '—'}</span>
      </p>
      <p className="text-[11px] leading-snug">
        <span className="admin-text-muted">{t('ads.productNameAr')}: </span>
        <span dir="rtl">{nameAr.trim() || '—'}</span>
      </p>
    </div>
  )
}
