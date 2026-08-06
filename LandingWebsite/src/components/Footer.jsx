import { Link } from 'react-router-dom'
import { content } from '../data/content'

export default function Footer({ lang }) {
  const t = content[lang].footer
  const nav = content[lang].nav
  const isAr = lang === 'ar'

  return (
    <footer className="border-t border-slate-200 bg-brand-navy text-blue-100">
      <div className="mx-auto grid max-w-7xl gap-8 px-4 py-12 sm:px-6 md:grid-cols-3">
        <div className={isAr ? 'text-right' : 'text-left'}>
          <div className="mb-4 flex items-center gap-3">
            <img src="/logo.png" alt="" className="h-12 w-12 rounded-xl object-cover" />
            <div>
              <p className="font-bold text-white">{isAr ? 'الراس الذكي' : 'Al Ras Smart'}</p>
              <p className="text-sm text-blue-200">{t.tagline}</p>
            </div>
          </div>
          <p className="text-sm leading-7 text-blue-200/90">{t.rights}</p>
        </div>

        <div className={isAr ? 'text-right' : 'text-left'}>
          <p className="mb-3 font-semibold text-white">{isAr ? 'روابط سريعة' : 'Quick Links'}</p>
          <div className="flex flex-col gap-2 text-sm">
            <a href="/#features" className="hover:text-white">{nav.features}</a>
            <a href="/#download" className="hover:text-white">{nav.download}</a>
            <Link to="/terms" className="hover:text-white">{nav.terms}</Link>
            <Link to="/privacy" className="hover:text-white">
              {isAr ? 'سياسة الخصوصية' : 'Privacy Policy'}
            </Link>
            <Link to="/delete-account" className="hover:text-white">{nav.deleteAccount}</Link>
            <Link to="/model-training" className="hover:text-white">{nav.modelTraining}</Link>
            <Link to="/encrypted-messages" className="hover:text-white">{nav.encryptedChat}</Link>
            <Link to="/contact" className="hover:text-white">{nav.contact}</Link>
          </div>
        </div>

        <div className={isAr ? 'text-right' : 'text-left'}>
          <p className="mb-3 font-semibold text-white">{isAr ? 'الشركة' : 'Company'}</p>
          <p className="text-sm leading-7 text-blue-200/90">
            Merge Spice Foodstuff Trading LLC
            <br />
            {isAr ? 'دبي، الإمارات العربية المتحدة' : 'Dubai, United Arab Emirates'}
          </p>
        </div>
      </div>
    </footer>
  )
}
