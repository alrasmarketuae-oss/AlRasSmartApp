import { termsAr, termsEn } from '../data/terms'
import { content } from '../data/content'

export default function Terms({ lang }) {
  const terms = lang === 'ar' ? termsAr : termsEn
  const page = content[lang].termsPage
  const isAr = lang === 'ar'

  return (
    <div className="py-12" dir={isAr ? 'rtl' : 'ltr'} lang={lang}>
      <div className="mx-auto max-w-4xl px-4 sm:px-6">
        <div className={`mb-10 ${isAr ? 'text-right' : 'text-left'}`}>
          <h1 className="text-4xl font-extrabold text-slate-900">{page.heading}</h1>
          <p className="mt-3 text-slate-600">{page.intro}</p>
        </div>

        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm sm:p-10">
          <h2 className={`mb-8 text-2xl font-bold text-brand-blue ${isAr ? 'text-right' : 'text-left'}`}>
            {terms.title}
          </h2>

          <div className="space-y-8">
            {terms.sections.map((section) => (
              <section key={section.title}>
                <h3 className={`mb-4 text-lg font-bold text-slate-900 ${isAr ? 'text-right' : 'text-left'}`}>
                  {section.title}
                </h3>
                <ul className={`space-y-3 ${isAr ? 'pr-4' : 'pl-4'}`} dir={isAr ? 'rtl' : 'ltr'}>
                  {section.items.map((item) => (
                    <li
                      key={item}
                      className={`flex gap-3 text-sm leading-7 text-slate-700 ${isAr ? 'flex-row-reverse text-right' : 'text-left'}`}
                    >
                      <span className="mt-2 h-2 w-2 shrink-0 rounded-full bg-brand-blue" />
                      <span>{item}</span>
                    </li>
                  ))}
                </ul>
              </section>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
