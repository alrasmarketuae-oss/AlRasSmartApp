import { aiAgentContent } from '../data/aiAgent'

export default function AppShowcase({ lang }) {
  const t = aiAgentContent[lang] ?? aiAgentContent.en
  const isAr = lang === 'ar'

  return (
    <section id="app-showcase" className="scroll-mt-24 bg-white py-12 sm:py-20" dir={isAr ? 'rtl' : 'ltr'}>
      <div className="mx-auto max-w-7xl px-4 sm:px-6">
        <div className={`mb-8 sm:mb-12 ${isAr ? 'text-right' : 'text-center'}`}>
          <h2 className="text-2xl font-extrabold text-slate-900 sm:text-3xl lg:text-4xl">{t.galleryTitle}</h2>
          <p className="mt-3 text-base text-slate-600 sm:text-lg">{t.gallerySubtitle}</p>
        </div>

        <div className="grid gap-6 sm:gap-8 lg:grid-cols-2">
          {t.gallery.map((item) => (
            <article
              key={item.src}
              className="overflow-hidden rounded-3xl border border-slate-200 bg-slate-50 shadow-sm transition hover:shadow-xl"
              itemScope
              itemType="https://schema.org/ImageObject"
            >
              <div className="bg-gradient-to-br from-brand-blue/5 via-brand-green/5 to-brand-red/5 p-3 sm:p-6">
                <img
                  src={item.src}
                  alt={item.alt}
                  title={item.title}
                  loading="lazy"
                  decoding="async"
                  itemProp="contentUrl"
                  className="mx-auto h-auto max-h-[420px] w-full max-w-full rounded-2xl object-contain shadow-lg ring-1 ring-brand-blue/10 sm:max-h-[520px]"
                />
              </div>
              <div className={`space-y-2 p-4 sm:p-6 ${isAr ? 'text-right' : 'text-left'}`}>
                <h3 className="text-lg font-bold text-brand-navy sm:text-xl" itemProp="name">
                  {item.title}
                </h3>
                <p className="text-sm leading-7 text-slate-600" itemProp="description">
                  {item.desc}
                </p>
                <meta itemProp="caption" content={item.alt} />
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}
