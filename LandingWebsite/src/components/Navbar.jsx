import { Link } from 'react-router-dom'
import { content } from '../data/content'

export default function Navbar({ lang, setLang }) {
  const t = content[lang].nav
  const isAr = lang === 'ar'

  return (
    <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/95 backdrop-blur-xl">
      <div className="mx-auto flex max-w-7xl items-center justify-between gap-4 px-4 py-4 sm:px-6">
        <Link to="/" className="flex items-center gap-3">
          <img src="/logo.png" alt="Al Ras Smart" className="h-10 w-10 rounded-xl bg-white object-cover p-1 shadow-lg ring-1 ring-slate-200" />
          <div className={isAr ? 'text-right' : 'text-left'}>
            <p className="text-sm font-bold text-slate-900">{isAr ? 'الراس الذكي' : 'Al Ras Smart'}</p>
            <p className="text-xs text-slate-600">{isAr ? 'تجارة الجملة' : 'Wholesale Trade'}</p>
          </div>
        </Link>

        <nav className="hidden items-center gap-6 text-sm font-medium text-slate-700 md:flex">
          <a href="/#features" className="transition hover:text-slate-900">{t.features}</a>
          <a href="/#download" className="transition hover:text-slate-900">{t.download}</a>
          <Link to="/terms" className="transition hover:text-slate-900">{t.terms}</Link>
          <Link to="/privacy" className="transition hover:text-slate-900">
            {lang === 'ar' ? 'الخصوصية' : 'Privacy'}
          </Link>
          <Link to="/delete-account" className="transition hover:text-slate-900">{t.deleteAccount}</Link>
          <Link to="/model-training" className="transition hover:text-slate-900">{t.modelTraining}</Link>
          <Link to="/encrypted-messages" className="transition hover:text-slate-900">{t.encryptedChat}</Link>
          <Link to="/contact" className="transition hover:text-slate-900">{t.contact}</Link>
        </nav>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => setLang(lang === 'ar' ? 'en' : 'ar')}
            className="rounded-full border border-slate-300 px-3 py-1.5 text-xs font-semibold text-slate-800 transition hover:bg-slate-100"
          >
            {lang === 'ar' ? 'EN' : 'عربي'}
          </button>
          <a
            href="/#download"
            className="hidden rounded-full bg-gradient-to-r from-brand-blue to-brand-red px-4 py-2 text-xs font-bold text-white shadow-lg sm:inline-block"
          >
            {t.download}
          </a>
        </div>
      </div>
    </header>
  )
}
