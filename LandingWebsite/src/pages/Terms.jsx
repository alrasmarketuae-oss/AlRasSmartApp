import { privacyAr, privacyEn } from '../data/privacy'
import { termsAr, termsEn } from '../data/terms'
import { content } from '../data/content'
import SeoHelmet from '../components/SeoHelmet'

function PolicyBlock({ title, lastUpdated, intro, sections, isAr, accent = 'text-brand-blue' }) {
  return (
    <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm sm:p-10">
      <h2 className={`mb-2 text-2xl font-bold ${accent} ${isAr ? 'text-right' : 'text-left'}`}>
        {title}
      </h2>
      {lastUpdated ? (
        <p className={`mb-4 text-sm text-slate-500 ${isAr ? 'text-right' : 'text-left'}`}>{lastUpdated}</p>
      ) : null}
      {intro ? (
        <p className={`mb-8 text-sm leading-7 text-slate-600 ${isAr ? 'text-right' : 'text-left'}`}>{intro}</p>
      ) : null}

      <div className="space-y-8">
        {sections.map((section) => (
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
  )
}

export default function Terms({ lang, privacyOnly = false }) {
  const privacy = lang === 'ar' ? privacyAr : privacyEn
  const terms = lang === 'ar' ? termsAr : termsEn
  const page = content[lang].termsPage
  const isAr = lang === 'ar'

  return (
    <div className="py-12" dir={isAr ? 'rtl' : 'ltr'} lang={lang}>
      <SeoHelmet pageKey={privacyOnly ? 'privacy' : 'terms'} lang={lang} />
      <div className="mx-auto max-w-4xl space-y-10 px-4 sm:px-6">
        <div className={isAr ? 'text-right' : 'text-left'}>
          <h1 className="text-4xl font-extrabold text-slate-900">
            {privacyOnly ? page.privacyHeading : page.heading}
          </h1>
          <p className="mt-3 text-slate-600">
            {privacyOnly ? page.privacyIntro : page.intro}
          </p>
          <p className="mt-2 text-xs text-slate-500">
            {isAr
              ? 'رابط سياسة الخصوصية لـ Google Play / App Store: /privacy (ونفس المحتوى ضمن /terms).'
              : 'Privacy Policy URL for Google Play / App Store: /privacy (same content also on /terms).'}
          </p>
        </div>

        <PolicyBlock
          title={privacy.title}
          lastUpdated={privacy.lastUpdated}
          intro={privacy.intro}
          sections={privacy.sections}
          isAr={isAr}
        />

        {!privacyOnly ? (
          <PolicyBlock
            title={terms.title}
            intro={null}
            lastUpdated={null}
            sections={terms.sections}
            isAr={isAr}
            accent="text-brand-navy"
          />
        ) : null}
      </div>
    </div>
  )
}
