import type { ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { useI18n } from '../i18n/I18nProvider'
import { Icon } from '../ui/Icon'

export function useGoBack(fallback = '/') {
  const navigate = useNavigate()
  return () => (window.history.state?.idx > 0 ? navigate(-1) : navigate(fallback, { replace: true }))
}

export function BackButton({ fallback = '/', onClick, className = 'text-title hover:bg-black/5' }: { fallback?: string; onClick?: () => void; className?: string }) {
  const { t, isAr } = useI18n()
  const goBack = useGoBack(fallback)
  return (
    <button
      type="button"
      onClick={onClick ?? goBack}
      aria-label={t('back')}
      className={`grid size-10 shrink-0 place-items-center rounded-full ${className}`}
    >
      <Icon name={isAr ? 'arrowForward' : 'arrowBack'} size={22} />
    </button>
  )
}

type ScreenProps = {
  title: ReactNode
  actions?: ReactNode
  footer?: ReactNode
  children: ReactNode
  fallback?: string
  onBack?: () => void
  width?: 'narrow' | 'wide'
  contentClassName?: string
}

/** Pushed-screen chrome from the app: back + centered title + trailing actions, optional sticky footer. */
export function Screen({ title, actions, footer, children, fallback, onBack, width = 'narrow', contentClassName = '' }: ScreenProps) {
  const column = width === 'narrow' ? 'max-w-3xl' : 'max-w-5xl'
  return (
    <div className="flex min-h-dvh flex-col bg-page">
      <header className="sticky top-0 z-30 border-b border-line/70 bg-white/95 backdrop-blur">
        <div className={`mx-auto flex h-14 w-full items-center gap-1 px-2 sm:px-4 ${column}`}>
          <BackButton fallback={fallback} onClick={onBack} />
          <h1 className="min-w-0 flex-1 truncate text-center text-[17px] font-bold text-title">{title}</h1>
          <div className="flex min-w-10 items-center justify-end gap-0.5">{actions}</div>
        </div>
      </header>
      <main className={`mx-auto w-full flex-1 px-4 pb-6 pt-4 sm:px-6 ${column} ${contentClassName}`}>{children}</main>
      {footer && (
        <div className="sticky bottom-0 z-30 border-t border-line bg-white/95 pb-[env(safe-area-inset-bottom)] shadow-[0_-6px_18px_rgba(15,23,42,0.06)] backdrop-blur">
          <div className={`mx-auto w-full px-4 py-3 sm:px-6 ${column}`}>{footer}</div>
        </div>
      )}
    </div>
  )
}

export function IconAction({ icon, label, onClick, active, disabled }: { icon: Parameters<typeof Icon>[0]['name']; label: string; onClick: () => void; active?: boolean; disabled?: boolean }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-label={label}
      title={label}
      className={`grid size-10 place-items-center rounded-full hover:bg-black/5 disabled:opacity-40 ${active ? 'text-brand' : 'text-title'}`}
    >
      <Icon name={icon} size={21} fill={active && icon === 'bookmark' ? 'currentColor' : 'none'} />
    </button>
  )
}

export function PrimaryButton({ children, onClick, disabled, busy, type = 'button', className = '' }: { children: ReactNode; onClick?: () => void; disabled?: boolean; busy?: boolean; type?: 'button' | 'submit'; className?: string }) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || busy}
      className={`flex h-12 w-full flex-1 items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-brand-dark to-brand-light px-4 text-[15px] font-bold text-white shadow-[0_8px_18px_rgba(22,73,158,0.22)] hover:brightness-110 disabled:opacity-60 ${className}`}
    >
      {busy && <span className="size-4 animate-spin rounded-full border-2 border-white/40 border-t-white" />}
      {children}
    </button>
  )
}

export function OutlineButton({ children, onClick, disabled, className = '' }: { children: ReactNode; onClick?: () => void; disabled?: boolean; className?: string }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={`flex h-12 w-full flex-1 items-center justify-center gap-2 rounded-xl border-[1.5px] border-brand bg-white px-4 text-[15px] font-bold text-brand hover:bg-brand/5 disabled:opacity-60 ${className}`}
    >
      {children}
    </button>
  )
}
