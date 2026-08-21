import { Link } from 'react-router-dom'
import { content } from '../data/content'

export default function Footer({ lang }) {
  const t = content[lang].footer
  const nav = content[lang].nav
  const isAr = lang === 'ar'

  return (
    <footer className="border-t border-brand-navy/20 bg-brand-navy text-white/80">
      <div className="mx-auto grid max-w-7xl gap-8 px-4 py-12 sm:px-6 md:grid-cols-3">
        <div className={isAr ? 'text-right' : 'text-left'}>
          <div className="mb-4 flex items-center gap-3">
            <img src="/logo.png" alt="الراس الذكي" className="h-12 w-12 rounded-xl object-cover ring-2 ring-white/15" />
            <div>
              <p className="font-bold text-white">{isAr ? 'الراس الذكي' : 'Al Ras Smart'}</p>
              <p className="text-sm text-brand-green">{t.tagline}</p>
            </div>
          </div>
          <p className="text-sm leading-7 text-white/75">{t.rights}</p>
          <p className="mt-4 text-xs font-semibold tracking-wide text-white/65">
            Powered by Al Ras Smart
          </p>
        </div>

        <div className={isAr ? 'text-right' : 'text-left'}>
          <p className="mb-3 font-semibold text-white">{isAr ? 'روابط سريعة' : 'Quick Links'}</p>
          <div className="flex flex-col gap-2 text-sm">
            <a href="/#features" className="transition hover:text-brand-green">{nav.features}</a>
            <a href="/#download" className="transition hover:text-brand-green">{nav.download}</a>
            <Link to="/terms" className="transition hover:text-brand-green">{nav.terms}</Link>
            <Link to="/privacy" className="transition hover:text-brand-green">
              {isAr ? 'سياسة الخصوصية' : 'Privacy Policy'}
            </Link>
            <Link to="/delete-account" className="transition hover:text-brand-green">{nav.deleteAccount}</Link>
            <Link to="/model-training" className="transition hover:text-brand-green">{nav.modelTraining}</Link>
            <Link to="/encrypted-messages" className="transition hover:text-brand-green">{nav.encryptedChat}</Link>
            <Link to="/contact" className="transition hover:text-brand-green">{nav.contact}</Link>
          </div>
        </div>

        <div className={isAr ? 'text-right' : 'text-left'}>
          <p className="mb-3 font-semibold text-white">{isAr ? 'الشركة' : 'Company'}</p>
          <p className="text-sm leading-7 text-white/75">
            Merge Spice Foodstuff Trading LLC
            <br />
            {isAr ? 'دبي، الإمارات العربية المتحدة' : 'Dubai, United Arab Emirates'}
          </p>
        </div>
      </div>
    </footer>
  )
}
