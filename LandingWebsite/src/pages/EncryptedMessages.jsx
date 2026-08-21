import { content } from '../data/content'
import { encryptedMessagesAr, encryptedMessagesEn } from '../data/encryptedMessages'
import SeoHelmet from '../components/SeoHelmet'

export default function EncryptedMessages({ lang }) {
  const page = content[lang].encryptedMessagesPage
  const sections = lang === 'ar' ? encryptedMessagesAr : encryptedMessagesEn
  const isAr = lang === 'ar'

  return (
    <div className="bg-slate-50">
      <SeoHelmet pageKey="encryptedMessages" lang={lang} />
      <section className="border-b border-slate-200 brand-gradient px-4 py-16 text-white sm:px-6">
        <div className={`mx-auto max-w-3xl ${isAr ? 'text-right' : 'text-left'}`}>
          <p className="mb-3 text-sm font-semibold text-white/85">{page.badge}</p>
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl">{page.heading}</h1>
          <p className="mt-4 text-base leading-8 text-white/90 sm:text-lg">{page.intro}</p>
        </div>
      </section>

      <section className="mx-auto max-w-3xl space-y-8 px-4 py-12 sm:px-6">
        {sections.map((section) => (
          <article
            key={section.title}
            className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
          >
            <h2
              className={`mb-3 text-xl font-bold text-slate-900 ${isAr ? 'text-right' : 'text-left'}`}
            >
              {section.title}
            </h2>
            <div
              className={`space-y-3 text-sm leading-7 text-slate-700 sm:text-[15px] ${
                isAr ? 'text-right' : 'text-left'
              }`}
            >
              {section.paragraphs.map((p) => (
                <p key={p.slice(0, 24)}>{p}</p>
              ))}
            </div>
          </article>
        ))}
      </section>
    </div>
  )
}
