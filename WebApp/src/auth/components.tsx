import { useMemo, useState, type InputHTMLAttributes, type ReactNode } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { DIAL_CODES } from '../data/dialCodes'
import { useI18n } from '../i18n/I18nProvider'
import { Icon, type IconName } from '../ui/Icon'

/** Soft dotted gradient + corner swoosh used behind every auth screen. */
export function AuthLayout({ children, wide = false }: { children: ReactNode; wide?: boolean }) {
  return (
    <div className="relative min-h-dvh overflow-hidden bg-auth-bg">
      <div className="auth-bg absolute inset-0" />
      <div className="auth-swoosh" />
      <div className={`relative mx-auto flex min-h-dvh w-full flex-col px-5 pb-6 pt-3 sm:px-8 ${wide ? 'max-w-2xl' : 'max-w-[480px]'}`}>
        {children}
      </div>
    </div>
  )
}

export function BackButton({ fallback = '/welcome' }: { fallback?: string }) {
  const { isAr } = useI18n()
  const navigate = useNavigate()
  return (
    <button
      type="button"
      onClick={() => (window.history.length > 1 ? navigate(-1) : navigate(fallback))}
      className="grid size-9 place-items-center rounded-full text-auth-title hover:bg-white/70"
      aria-label="Back"
    >
      <Icon name={isAr ? 'arrowForward' : 'arrowBack'} size={22} />
    </button>
  )
}

/** Back + language switch on the start side, logo on the end side. */
export function AuthTopBar({ showBack = true, backFallback }: { showBack?: boolean; backFallback?: string }) {
  const { t, toggleLang } = useI18n()
  return (
    <div className="flex items-center gap-1">
      {showBack && <BackButton fallback={backFallback} />}
      <button
        type="button"
        onClick={toggleLang}
        className="flex items-center gap-2 rounded-lg px-1 py-2 text-[13px] font-semibold text-auth-title hover:bg-white/60"
      >
        <img src="/assets/icons/globe.svg" alt="" className="size-5 opacity-80" />
        {t('language')}
      </button>
      <span className="flex-1" />
      <Link to="/" aria-label="Home">
        <img src="/assets/logo/logo.png" alt="Merge Spice" className="h-11 w-auto" />
      </Link>
    </div>
  )
}

export function AccentIndicator() {
  return (
    <div className="flex items-center justify-center gap-1.5">
      <span className="h-[5px] w-[26px] rounded bg-brand-dark" />
      <span className="size-[5px] rounded-full bg-[#B9CDE8]" />
    </div>
  )
}

export function GlassCard({ children }: { children: ReactNode }) {
  return <div className="rounded-3xl bg-white px-[18px] py-4 shadow-[0_12px_28px_rgba(27,59,95,0.08)] sm:px-7 sm:py-6">{children}</div>
}

export function FieldLabel({ children, htmlFor }: { children: ReactNode; htmlFor?: string }) {
  return (
    <label htmlFor={htmlFor} className="mb-1.5 block text-[13px] font-bold text-auth-label">
      {children}
    </label>
  )
}

export function FieldError({ message }: { message?: string }) {
  if (!message) return null
  return <p className="mt-1 text-[11px] leading-tight text-[#d92d20]">{message}</p>
}

type AuthFieldProps = InputHTMLAttributes<HTMLInputElement> & {
  icon: IconName
  trailing?: ReactNode
  error?: string
}

/** Login-screen field: icon on the left edge, text follows the locale. */
export function AuthField({ icon, trailing, error, className, ...input }: AuthFieldProps) {
  const { isAr } = useI18n()
  return (
    <div>
      <div
        dir="ltr"
        className={`flex items-center rounded-xl border bg-white focus-within:border-brand-light ${error ? 'border-[#d92d20]' : 'border-auth-border'}`}
      >
        <span className="ps-3.5 pe-2.5 text-brand-light">
          <Icon name={icon} size={20} />
        </span>
        <input
          dir={isAr ? 'rtl' : 'ltr'}
          className={`min-w-0 flex-1 bg-transparent py-[13px] text-sm font-medium text-[#1F2937] outline-none placeholder:text-[13px] placeholder:text-auth-hint ${isAr ? 'text-right' : 'text-left'} ${className ?? ''}`}
          {...input}
        />
        {trailing ? <span className="pe-1">{trailing}</span> : <span className="w-3.5" />}
      </div>
      <FieldError message={error} />
    </div>
  )
}

export function PasswordToggle({ visible, onToggle }: { visible: boolean; onToggle: () => void }) {
  return (
    <button type="button" onClick={onToggle} className="grid size-9 place-items-center rounded-full text-auth-hint hover:bg-slate-100" aria-label="Toggle password">
      <Icon name={visible ? 'eye' : 'eyeOff'} size={20} />
    </button>
  )
}

export function GradientButton({ children, disabled, type = 'submit', onClick }: { children: ReactNode; disabled?: boolean; type?: 'submit' | 'button'; onClick?: () => void }) {
  return (
    <button
      type={type}
      disabled={disabled}
      onClick={onClick}
      className="h-12 w-full rounded-xl bg-gradient-to-r from-brand-dark to-brand-light text-[15px] font-bold text-white shadow-[0_8px_18px_rgba(22,73,158,0.28)] transition hover:brightness-110 disabled:opacity-60"
    >
      {children}
    </button>
  )
}

export function OrDivider({ label }: { label: string }) {
  return (
    <div className="flex items-center gap-3">
      <span className="h-px flex-1 bg-auth-border" />
      <span className="text-xs font-semibold text-auth-hint">{label}</span>
      <span className="h-px flex-1 bg-auth-border" />
    </div>
  )
}

export function Spinner({ className = 'size-5 border-white/40 border-t-white' }: { className?: string }) {
  return <span className={`inline-block animate-spin rounded-full border-2 ${className}`} />
}

export function LoadingOverlay() {
  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-white/55">
      <Spinner className="size-10 border-[3px] border-brand/25 border-t-brand" />
    </div>
  )
}

/* ---------- Register-screen fields (label above, soft shadow, prefix icon) ---------- */

type IconFieldProps = InputHTMLAttributes<HTMLInputElement> & {
  label: string
  icon: IconName
  error?: string
  trailing?: ReactNode
}

export function IconField({ label, icon, error, trailing, id, ...input }: IconFieldProps) {
  const { isAr } = useI18n()
  const inputId = id ?? `f-${label.replace(/\s+/g, '-').toLowerCase()}`
  return (
    <div>
      <label htmlFor={inputId} className="mb-2 block text-[13px] font-semibold text-auth-label">
        {label}
      </label>
      <div
        className={`flex items-center rounded-[14px] border bg-white shadow-[0_3px_10px_rgba(0,0,0,0.04)] focus-within:border-brand focus-within:ring-1 focus-within:ring-brand ${error ? 'border-[#d92d20]' : 'border-auth-border'}`}
      >
        <span className="ps-3.5 pe-2 text-auth-hint">
          <Icon name={icon} size={20} />
        </span>
        <input
          id={inputId}
          className={`min-w-0 flex-1 bg-transparent py-3.5 pe-3.5 text-sm font-medium text-auth-title outline-none placeholder:text-[13px] placeholder:text-auth-hint ${isAr ? 'text-right' : 'text-left'}`}
          {...input}
        />
        {trailing}
      </div>
      <FieldError message={error} />
    </div>
  )
}

export function PasswordField(props: Omit<IconFieldProps, 'icon' | 'type' | 'trailing'>) {
  const [visible, setVisible] = useState(false)
  return (
    <IconField
      {...props}
      icon="lock"
      type={visible ? 'text' : 'password'}
      trailing={
        <span className="pe-1.5">
          <PasswordToggle visible={visible} onToggle={() => setVisible((v) => !v)} />
        </span>
      }
    />
  )
}

export function CountryCodeSelect({ label, value, onChange, locked }: { label: string; value: string; onChange: (dial: string) => void; locked?: boolean }) {
  const options = useMemo(() => {
    const seen = new Set<string>()
    return DIAL_CODES.filter((c) => {
      const key = `${c.dial}-${c.iso}`
      if (seen.has(key)) return false
      seen.add(key)
      return true
    })
  }, [])
  const [selectedIso, setSelectedIso] = useState(() => options.find((c) => c.dial === value)?.iso ?? 'AE')
  const selected = options.find((c) => c.iso === selectedIso)
  if (locked)
    return (
      <div>
        <span className="mb-2 block text-[13px] font-semibold text-auth-label">{label}</span>
        <div className="flex items-center gap-1.5 rounded-[14px] border border-auth-border bg-[#F1F4F8] py-3.5 ps-3 pe-3 text-sm font-medium text-auth-title" aria-label={label}>
          <span dir="ltr" className="min-w-0 flex-1 truncate">
            {selected ? `${selected.flag} ${selected.dial}` : value}
          </span>
          <Icon name="lock" size={14} className="shrink-0 text-auth-hint" />
        </div>
      </div>
    )
  return (
    <div>
      <span className="mb-2 block text-[13px] font-semibold text-auth-label">{label}</span>
      <div className="relative rounded-[14px] border border-auth-border bg-white shadow-[0_3px_10px_rgba(0,0,0,0.04)] focus-within:border-brand">
        <span dir="ltr" className="pointer-events-none block truncate py-3.5 ps-3 pe-8 text-sm font-medium text-auth-title">
          {selected ? `${selected.flag} ${selected.dial}` : value}
        </span>
        <select
          dir="ltr"
          aria-label={label}
          value={selectedIso}
          onChange={(event) => {
            const next = options.find((c) => c.iso === event.target.value)
            if (!next) return
            setSelectedIso(next.iso)
            onChange(next.dial)
          }}
          className="absolute inset-0 w-full cursor-pointer appearance-none opacity-0"
        >
          {options.map((c) => (
            <option key={c.iso} value={c.iso}>
              {c.flag} {c.dial} {c.name}
            </option>
          ))}
        </select>
        <Icon name="chevronDown" size={16} className="pointer-events-none absolute end-3 top-1/2 -translate-y-1/2 text-auth-hint" />
      </div>
    </div>
  )
}

export function PrimaryButton({ children, disabled, loading, onClick, type = 'button' }: { children: ReactNode; disabled?: boolean; loading?: boolean; onClick?: () => void; type?: 'button' | 'submit' }) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || loading}
      className="flex h-[50px] w-full items-center justify-center gap-2 rounded-[10px] bg-brand text-base font-bold text-white transition hover:brightness-110 disabled:opacity-60"
    >
      {loading ? <Spinner /> : children}
    </button>
  )
}
