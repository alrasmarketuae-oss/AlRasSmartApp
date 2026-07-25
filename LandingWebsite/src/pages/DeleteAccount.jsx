import { Link } from 'react-router-dom'
import { CONTACT } from '../data/config'
import { content } from '../data/content'
import { deleteAccountAr, deleteAccountEn } from '../data/deleteAccount'

export default function DeleteAccount({ lang }) {
  const isAr = lang === 'ar'
  const page = content[lang].deleteAccountPage
  const data = isAr ? deleteAccountAr : deleteAccountEn

  return (
    <div className="py-12" dir={isAr ? 'rtl' : 'ltr'} lang={lang}>
      <div className="mx-auto max-w-4xl px-4 sm:px-6">
        <div className={`mb-10 ${isAr ? 'text-right' : 'text-left'}`}>
          <p className="mb-3 text-sm font-semibold text-brand-red">{page.badge}</p>
          <h1 className="text-4xl font-extrabold text-slate-900">{page.heading}</h1>
          <p className="mt-4 text-base leading-8 text-slate-600">{data.intro}</p>
          <p className="mt-3 text-sm text-slate-500">{data.lastUpdated}</p>
          <div className="mt-6 flex flex-wrap gap-3">
            <a
              href={`mailto:${CONTACT.email}?subject=${encodeURIComponent(
                isAr ? 'طلب حذف حساب — Al Ras Smart App' : 'Account deletion request — Al Ras Smart App',
              )}`}
              className="inline-flex rounded-full bg-gradient-to-r from-brand-blue to-brand-red px-5 py-2.5 text-sm font-bold text-white shadow-md"
            >
              {page.emailCta}
            </a>
            <Link
              to="/contact"
              className="inline-flex rounded-full border border-slate-300 bg-white px-5 py-2.5 text-sm font-semibold text-slate-800 hover:bg-slate-50"
            >
              {page.contactCta}
            </Link>
            <Link
              to="/terms"
              className="inline-flex rounded-full border border-slate-300 bg-white px-5 py-2.5 text-sm font-semibold text-slate-800 hover:bg-slate-50"
            >
              {content[lang].nav.terms}
            </Link>
          </div>
        </div>

        <article className="space-y-8 rounded-3xl border border-slate-200 bg-white p-6 shadow-sm sm:p-10">
          <h2 className={`text-2xl font-bold text-brand-blue ${isAr ? 'text-right' : 'text-left'}`}>
            {data.title}
          </h2>

          <div
            className={`rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm leading-7 text-amber-950 ${
              isAr ? 'text-right' : 'text-left'
            }`}
          >
            {page.googlePlayNote}
          </div>

          {data.sections.map((section) => (
            <section key={section.title} className={isAr ? 'text-right' : 'text-left'}>
              <h3 className="mb-3 text-lg font-bold text-slate-900">{section.title}</h3>
              <ul className={`space-y-3 ${isAr ? 'pr-1' : 'pl-1'}`}>
                {section.paragraphs.map((paragraph) => (
                  <li
                    key={paragraph}
                    className={`flex gap-3 text-sm leading-8 text-slate-700 ${
                      isAr ? 'flex-row-reverse' : ''
                    }`}
                  >
                    <span className="mt-3 h-2 w-2 shrink-0 rounded-full bg-brand-blue" />
                    <span>{paragraph}</span>
                  </li>
                ))}
              </ul>
            </section>
          ))}

          <div
            className={`rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4 text-sm leading-7 text-slate-700 ${
              isAr ? 'text-right' : 'text-left'
            }`}
          >
            <p className="font-semibold text-slate-900">{page.supportLabel}</p>
            <a
              href={`mailto:${CONTACT.email}`}
              className="mt-1 inline-block font-semibold text-brand-blue hover:underline"
              dir="ltr"
            >
              {CONTACT.email}
            </a>
            <p className="mt-3 text-slate-600">{page.urlHint}</p>
            <code className="mt-1 block break-all rounded-lg bg-white px-3 py-2 text-xs text-slate-800 ring-1 ring-slate-200" dir="ltr">
              /delete-account
            </code>
          </div>
        </article>
      </div>
    </div>
  )
}
