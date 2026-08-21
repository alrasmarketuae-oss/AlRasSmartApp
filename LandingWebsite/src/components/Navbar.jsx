import { useEffect, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { content } from '../data/content'

export default function Navbar({ lang, setLang }) {
  const t = content[lang].nav
  const isAr = lang === 'ar'
  const location = useLocation()
  const [menuOpen, setMenuOpen] = useState(false)

  useEffect(() => {
    setMenuOpen(false)
  }, [location.pathname])

  useEffect(() => {
    document.body.style.overflow = menuOpen ? 'hidden' : ''
    return () => {
      document.body.style.overflow = ''
    }
  }, [menuOpen])

  const links = [
    { to: '/#features', label: t.features, hash: true },
    { to: '/#download', label: t.download, hash: true },
    { to: '/terms', label: t.terms },
    { to: '/privacy', label: lang === 'ar' ? 'الخصوصية' : 'Privacy' },
    { to: '/delete-account', label: t.deleteAccount },
    { to: '/model-training', label: t.modelTraining },
    { to: '/encrypted-messages', label: t.encryptedChat },
    { to: '/contact', label: t.contact },
  ]

  function NavLinks({ onNavigate, className = '' }) {
    return (
      <div className={className}>
        {links.map((link) =>
          link.hash ? (
            <a
              key={link.to}
              href={link.to}
              onClick={onNavigate}
              className="block rounded-xl px-3 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-brand-blue/5 hover:text-brand-blue"
            >
              {link.label}
            </a>
          ) : (
            <Link
              key={link.to}
              to={link.to}
              onClick={onNavigate}
              className="block rounded-xl px-3 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-brand-blue/5 hover:text-brand-blue"
            >
              {link.label}
            </Link>
          ),
        )}
      </div>
    )
  }

  return (
    <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/95 backdrop-blur-xl">
      <div className="mx-auto flex max-w-7xl items-center justify-between gap-3 px-4 py-3 sm:px-6 sm:py-4">
        <Link to="/" className="flex min-w-0 items-center gap-2.5 sm:gap-3" onClick={() => setMenuOpen(false)}>
          <img
            src="/logo.png"
            alt="الراس الذكي"
            className="h-9 w-9 shrink-0 rounded-xl bg-white object-cover p-1 shadow-lg ring-1 ring-brand-blue/20 sm:h-10 sm:w-10"
          />
          <div className={`min-w-0 ${isAr ? 'text-right' : 'text-left'}`}>
            <p className="truncate text-sm font-bold text-brand-navy">
              {isAr ? 'الراس الذكي' : 'Al Ras Smart'}
            </p>
            <p className="truncate text-xs text-slate-600">
              {isAr ? 'تجارة الجملة' : 'Wholesale Trade'}
            </p>
          </div>
        </Link>

        <nav className="hidden items-center gap-1 text-sm font-medium text-slate-700 xl:flex">
          {links.map((link) =>
            link.hash ? (
              <a key={link.to} href={link.to} className="rounded-lg px-2.5 py-2 transition hover:bg-brand-blue/5 hover:text-brand-blue">
                {link.label}
              </a>
            ) : (
              <Link key={link.to} to={link.to} className="rounded-lg px-2.5 py-2 transition hover:bg-brand-blue/5 hover:text-brand-blue">
                {link.label}
              </Link>
            ),
          )}
        </nav>

        <div className="flex shrink-0 items-center gap-2">
          <button
            type="button"
            onClick={() => setLang(lang === 'ar' ? 'en' : 'ar')}
            className="rounded-full border border-slate-300 px-3 py-1.5 text-xs font-semibold text-slate-800 transition hover:bg-slate-100"
          >
            {lang === 'ar' ? 'EN' : 'عربي'}
          </button>

          <button
            type="button"
            className="inline-flex h-10 w-10 items-center justify-center rounded-xl border border-slate-300 text-slate-800 transition hover:bg-slate-100 xl:hidden"
            aria-expanded={menuOpen}
            aria-label={menuOpen ? (isAr ? 'إغلاق القائمة' : 'Close menu') : isAr ? 'فتح القائمة' : 'Open menu'}
            onClick={() => setMenuOpen((v) => !v)}
          >
            {menuOpen ? (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
                <path d="M6 6l12 12M18 6L6 18" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" />
              </svg>
            ) : (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
                <path d="M4 7h16M4 12h16M4 17h16" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" />
              </svg>
            )}
          </button>
        </div>
      </div>

      {menuOpen ? (
        <div className="border-t border-slate-200 bg-white xl:hidden">
          <div className="mx-auto max-h-[min(70vh,520px)] max-w-7xl overflow-y-auto px-4 py-3 sm:px-6">
            <NavLinks
              onNavigate={() => setMenuOpen(false)}
              className={`flex flex-col gap-1 ${isAr ? 'text-right' : 'text-left'}`}
            />
            <a
              href="/#download"
              onClick={() => setMenuOpen(false)}
              className="mt-3 block rounded-full brand-gradient px-4 py-3 text-center text-sm font-bold text-white shadow-lg"
            >
              {t.download}
            </a>
          </div>
        </div>
      ) : null}
    </header>
  )
}
