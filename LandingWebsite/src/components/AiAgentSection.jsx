import { aiAgentContent } from '../data/aiAgent'

export default function AiAgentSection({ lang, onAskAi }) {
  const t = aiAgentContent[lang] ?? aiAgentContent.en
  const isAr = lang === 'ar'

  return (
    <section
      id="alras-agent"
      className="scroll-mt-24 bg-gradient-to-b from-[#F5F9FF] to-white py-12 sm:py-20"
      dir={isAr ? 'rtl' : 'ltr'}
      itemScope
      itemType="https://schema.org/SoftwareApplication"
    >
      <meta itemProp="name" content="Al-Ras Agent" />
      <meta itemProp="applicationCategory" content="BusinessApplication" />
      <meta
        itemProp="description"
        content={t.sectionSubtitle}
      />

      <div className="mx-auto grid max-w-7xl items-center gap-12 px-4 sm:px-6 lg:grid-cols-2">
        <div className={`order-2 lg:order-1 ${isAr ? 'text-right' : 'text-left'}`}>
          <span className="inline-block rounded-full border border-[#7B61FF]/25 bg-[#7B61FF]/10 px-4 py-1.5 text-sm font-semibold text-[#7B61FF]">
            {t.sectionBadge}
          </span>
          <h2 className="mt-5 text-3xl font-extrabold text-[#163A6B] sm:text-4xl" itemProp="alternateName">
            {t.sectionTitle}
          </h2>
          <p className="mt-4 text-base leading-8 text-slate-600">{t.sectionSubtitle}</p>

          <h3 className="mt-10 text-xl font-bold text-slate-900">{t.functionsTitle}</h3>
          <ul className="mt-5 grid gap-4 sm:grid-cols-2">
            {t.functions.map((fn) => (
              <li
                key={fn.title}
                className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm"
              >
                <p className="font-bold text-[#163A6B]">{fn.title}</p>
                <p className="mt-2 text-sm leading-6 text-slate-600">{fn.desc}</p>
              </li>
            ))}
          </ul>

          <button
            type="button"
            onClick={onAskAi}
            className="mt-8 inline-flex items-center gap-3 rounded-full bg-gradient-to-r from-[#7B61FF] to-[#3A6AA5] px-6 py-3 text-sm font-bold text-white shadow-lg transition hover:scale-[1.02]"
          >
            <img
              src="/seo/alras-agent-robot.png"
              alt=""
              className="h-8 w-8 rounded-full object-cover ring-2 ring-white/40"
            />
            {t.fabLabel}
          </button>
          <p className="mt-3 text-xs font-semibold tracking-wide text-[#3A6AA5]">{t.poweredBy}</p>
        </div>

        <div className="order-1 flex justify-center lg:order-2">
          <div className="relative">
            <div className="absolute -inset-6 rounded-full bg-[#3A7DC5]/15 blur-3xl" />
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
