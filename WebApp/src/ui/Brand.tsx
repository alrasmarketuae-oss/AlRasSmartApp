import { useI18n } from '../i18n/I18nProvider'

export function ColoredBrandTitle({ className = 'text-[26px]', includeAppWord = true }: { className?: string; includeAppWord?: boolean }) {
  const { isAr } = useI18n()
  const base = `font-extrabold leading-tight ${className}`
  if (isAr) {
    return (
      <p dir="rtl" className={`${base} text-center`} style={{ fontFamily: 'Cairo' }}>
        {includeAppWord && <span className="text-brand-navy">تطبيق </span>}
        <span className="text-brand-blue">ال</span>
        <span className="text-brand-red">راس</span> <span className="text-brand-green">الذكى</span>
      </p>
    )
  }
  return (
    <p className={`${base} text-center`} style={{ fontFamily: 'Inter' }}>
      <span className="text-brand-blue">Al</span> <span className="text-brand-red">Ras</span>{' '}
      <span className="text-brand-green">Smart</span>
      {includeAppWord && <span className="text-brand-navy"> App</span>}
    </p>
  )
}

export function BrandDotDivider({ className = 'w-[168px]' }: { className?: string }) {
  return (
    <div className={`flex items-center gap-1.5 ${className}`}>
      <span className="h-px flex-1 bg-brand-blue/20" />
      <span className="mx-0.5 size-[7px] rounded-full bg-brand-blue" />
      <span className="size-[7px] rounded-full bg-brand-red" />
      <span className="mx-0.5 size-[7px] rounded-full bg-brand-green" />
      <span className="h-px flex-1 bg-brand-blue/20" />
    </div>
  )
}

export function LanguagePill() {
  const { t, toggleLang } = useI18n()
  return (
    <button
      type="button"
      onClick={toggleLang}
      className="inline-flex items-center gap-1.5 rounded-full border border-[#D5DEE8] bg-white px-3 py-1.5 text-[13px] font-semibold text-brand-navy shadow-[0_2px_8px_rgba(0,0,0,0.04)] hover:bg-slate-50"
      style={{ fontFamily: 'Cairo' }}
    >
      <img src="/assets/icons/globe.svg" alt="" className="size-4" style={{ filter: 'invert(22%) sepia(98%) saturate(3000%) hue-rotate(210deg)' }} />
      {t('language')}
    </button>
  )
}
