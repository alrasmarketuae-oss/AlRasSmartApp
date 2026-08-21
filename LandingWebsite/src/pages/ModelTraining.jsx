import { Link } from 'react-router-dom'
import { content } from '../data/content'
import { modelTrainingAr, modelTrainingEn } from '../data/modelTraining'
import SeoHelmet from '../components/SeoHelmet'

export default function ModelTraining({ lang }) {
  const isAr = lang === 'ar'
  const page = content[lang].modelTrainingPage
  const data = isAr ? modelTrainingAr : modelTrainingEn

  return (
    <div className="py-12" dir={isAr ? 'rtl' : 'ltr'} lang={lang}>
      <SeoHelmet pageKey="modelTraining" lang={lang} />
      <div className="mx-auto max-w-4xl px-4 sm:px-6">
        <div className={`mb-10 ${isAr ? 'text-right' : 'text-left'}`}>
          <p className="mb-3 text-sm font-semibold text-brand-blue">{page.badge}</p>
          <h1 className="text-4xl font-extrabold text-slate-900">{page.heading}</h1>
          <p className="mt-4 text-base leading-8 text-slate-600">{data.intro}</p>
          <p className="mt-4 text-sm text-slate-500">
            {page.termsHint}{' '}
            <Link to="/terms" className="font-semibold text-brand-blue hover:underline">
              {content[lang].nav.terms}
            </Link>
          </p>
        </div>

        <article className="space-y-8 rounded-3xl border border-slate-200 bg-white p-6 shadow-sm sm:p-10">
          <h2 className={`text-2xl font-bold text-brand-blue ${isAr ? 'text-right' : 'text-left'}`}>
            {data.title}
          </h2>

          {data.sections.map((section) => (
            <section key={section.title} className={isAr ? 'text-right' : 'text-left'}>
              <h3 className="mb-3 text-lg font-bold text-slate-900">{section.title}</h3>
              <div className="space-y-3">
                {section.paragraphs.map((paragraph) => (
                  <p key={paragraph} className="text-sm leading-8 text-slate-700">
                    {paragraph}
                  </p>
                ))}
              </div>
            </section>
          ))}
        </article>
      </div>
    </div>
  )
}
