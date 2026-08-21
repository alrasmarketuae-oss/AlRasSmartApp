import { aiAgentContent } from '../data/aiAgent'

export default function AiAgentSection({ lang, onAskAi }) {
  const t = aiAgentContent[lang] ?? aiAgentContent.en
  const isAr = lang === 'ar'

  return (
    <section
      id="alras-agent"
      className="scroll-mt-24 bg-gradient-to-b from-brand-blue/5 via-white to-brand-green/5 py-12 sm:py-20"
      dir={isAr ? 'rtl' : 'ltr'}
      itemScope
      itemType="https://schema.org/SoftwareApplication"
    >
      <meta itemProp="name" content="Al-Ras Agent" />
      <meta itemProp="applicationCategory" content="BusinessApplication" />
      <meta itemProp="description" content={t.sectionSubtitle} />

      <div className="mx-auto grid max-w-7xl items-center gap-12 px-4 sm:px-6 lg:grid-cols-2">
        <div className={`order-2 lg:order-1 ${isAr ? 'text-right' : 'text-left'}`}>
          <span className="inline-block rounded-full border border-brand-blue/25 bg-brand-blue/10 px-4 py-1.5 text-sm font-semibold text-brand-blue">
            {t.sectionBadge}
          </span>
          <h2 className="mt-5 text-3xl font-extrabold text-brand-navy sm:text-4xl" itemProp="alternateName">
            {t.sectionTitle}
          </h2>
          <p className="mt-4 text-base leading-8 text-slate-600">{t.sectionSubtitle}</p>

          <h3 className="mt-10 text-xl font-bold text-brand-navy">{t.functionsTitle}</h3>
          <ul className="mt-5 grid gap-4 sm:grid-cols-2">
            {t.functions.map((fn, i) => {
              const accents = [
                'border-brand-blue/20',
                'border-brand-red/20',
                'border-brand-green/20',
                'border-brand-blue/20',
              ]
              return (
                <li
                  key={fn.title}
                  className={`rounded-2xl border bg-white p-4 shadow-sm ${accents[i % accents.length]}`}
                >
                  <p className="font-bold text-brand-navy">{fn.title}</p>
                  <p className="mt-2 text-sm leading-6 text-slate-600">{fn.desc}</p>
                </li>
              )
            })}
          </ul>

          <button
            type="button"
            onClick={onAskAi}
            className="mt-8 inline-flex items-center gap-3 rounded-full bg-gradient-to-r from-brand-blue via-brand-green to-brand-red px-6 py-3 text-sm font-bold text-white shadow-lg shadow-brand-blue/20 transition hover:scale-[1.02]"
          >
            <img
              src="/seo/alras-agent-robot.png"
              alt=""
              className="h-8 w-8 rounded-full object-cover ring-2 ring-white/40"
            />
            {t.fabLabel}
          </button>
          <p className="mt-3 text-xs font-semibold tracking-wide text-brand-blue">{t.poweredBy}</p>
        </div>

        <div className="order-1 flex justify-center lg:order-2">
          <div className="relative">
            <div className="absolute -inset-6 rounded-full bg-brand-blue/15 blur-3xl" />
            <div className="absolute -inset-2 rounded-full bg-brand-green/10 blur-2xl" />
            <img
              src="/seo/alras-agent-robot.png"
              alt={
                isAr
                  ? 'روبوت Al-Ras Agent — مساعد دعم فني ووكيل لتحديث الإعلانات على الراس الذكي'
                  : 'Al-Ras Agent robot — technical support assistant and ad-update agent for Al Ras Smart'
              }
              title="Al-Ras Agent"
              loading="lazy"
              className="relative h-52 w-52 rounded-full object-cover shadow-2xl ring-4 ring-white sm:h-72 sm:w-72 lg:h-80 lg:w-80"
            />
          </div>
        </div>
      </div>
    </section>
  )
}
