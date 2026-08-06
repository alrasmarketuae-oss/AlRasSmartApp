import { STORE_LINKS } from '../data/config'

export default function PhoneShowcase({ lang }) {
  const isAr = lang === 'ar'
  const copy = {
    ar: {
      title: 'حمّل التطبيق على هاتفك',
      subtitle: 'اختر منصتك وابدأ التجارة بسهولة وأمان',
      screenTitle: 'الراس الذكي',
      screenSubtitle: 'تجارة الجملة الذكية',
      androidBtn: 'تحميل الآن',
      iosBtn: 'تحميل الآن',
    },
    en: {
      title: 'Get the app on your phone',
      subtitle: 'Choose your platform and start trading securely',
      screenTitle: 'Al Ras Smart',
      screenSubtitle: 'Smart wholesale trade',
      androidBtn: 'Download Now',
      iosBtn: 'Download Now',
    },
  }[lang]
  const screenshot = isAr ? '/screen-ar.png' : '/screen-en.png'

  return (
    <section id="download" className="scroll-mt-24 py-12" dir={isAr ? 'rtl' : 'ltr'}>
      <div className="mx-auto max-w-5xl px-4 sm:px-6">
        <div className={`mb-8 ${isAr ? 'text-right' : 'text-center'}`}>
          <h2 className="text-3xl font-extrabold text-slate-900 sm:text-4xl">{copy.title}</h2>
          <p className="mt-3 text-lg font-medium text-slate-700">{copy.subtitle}</p>
        </div>

        <div className="mx-auto max-w-sm overflow-hidden rounded-3xl border border-slate-200 bg-white p-3 shadow-xl sm:max-w-md">
          <img
            src={screenshot}
            alt={isAr ? 'واجهة تطبيق الراس الذكي بالعربية' : 'Al Ras Smart app in English'}
            className="h-auto w-full rounded-2xl border border-slate-200 object-cover"
          />
        </div>

        <div className="mt-7 flex flex-wrap items-center justify-center gap-4">
          <a
            href={STORE_LINKS.android}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center gap-2 rounded-full border border-slate-300 bg-white px-6 py-3 text-sm font-bold text-slate-900 shadow-lg transition hover:scale-[1.02]"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5 fill-current" aria-hidden>
              <path d="M3 20.5V3.5C3 2.91 3.34 2.39 3.84 2.15L13.69 12L3.84 21.85C3.34 21.6 3 21.09 3 20.5ZM16.81 15.12L6.05 21.34L14.54 12.85L16.81 15.12ZM20.16 10.81C20.5 11.08 20.75 11.5 20.75 12C20.75 12.5 20.53 12.9 20.18 13.18L17.89 14.5L15.39 12L17.89 9.5L20.16 10.81ZM6.05 2.66L16.81 8.88L14.54 11.15L6.05 2.66Z" />
            </svg>
            <span>{isAr ? 'Google Play' : 'Google Play'}</span>
          </a>
          <a
            href={STORE_LINKS.ios}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center justify-center gap-2 rounded-full bg-black px-6 py-3 text-sm font-bold text-white shadow-lg transition hover:scale-[1.02]"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5 fill-current" aria-hidden>
              <path d="M18.71 19.5C17.88 20.3 16.97 20.2 16.07 19.75C15.09 19.28 14.22 19.27 13.17 19.75C11.98 20.32 11.27 20.19 10.54 19.5C6.09 15.03 6.67 8.36 11.64 8.09C12.59 8.17 13.24 8.62 13.84 8.68C14.77 8.49 15.67 8.02 16.69 8.13C17.89 8.26 18.78 8.73 19.43 9.64C16.28 11.45 16.96 15.84 19.86 16.96C19.34 18.22 18.63 19.44 18.71 19.5ZM13.01 8.01C12.87 6.14 14.36 4.54 16.09 4.28C16.34 6.39 14.2 8.05 13.01 8.01Z" />
            </svg>
            <span>{isAr ? 'App Store' : 'App Store'}</span>
          </a>
        </div>
      </div>
    </section>
  )
}
