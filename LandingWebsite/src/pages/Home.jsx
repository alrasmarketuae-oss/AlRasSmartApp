import { content } from '../data/content'
import SeoHelmet from '../components/SeoHelmet'
import AppShowcase from '../components/AppShowcase'
import AiAgentSection from '../components/AiAgentSection'
import HeroScrollFrames from '../components/HeroScrollFrames'
import { STORE_LINKS } from '../data/config'

export default function Home({ lang, onAskAi }) {
  const t = content[lang]
  const isAr = lang === 'ar'

  return (
    <>
      <SeoHelmet pageKey="home" lang={lang} />

      <HeroScrollFrames lang={lang} />

      <section className="relative bg-white py-12 sm:py-16" dir={isAr ? 'rtl' : 'ltr'}>
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <div className={`max-w-3xl ${isAr ? 'ms-auto text-right' : 'text-left'}`}>
            <span className="inline-block rounded-full border border-slate-300 bg-slate-50 px-4 py-1.5 text-sm font-bold text-slate-900">
              {t.hero.badge}
            </span>
            <h1 className="mt-5 text-3xl font-black leading-tight text-slate-900 sm:text-5xl">
              {t.hero.title}
            </h1>
            <p className="mt-4 text-base font-bold leading-7 text-slate-800 sm:text-lg sm:leading-8">
              {t.hero.subtitle}
            </p>
            <div className={`mt-8 flex flex-wrap gap-3 ${isAr ? 'justify-end' : 'justify-start'}`}>
              <a
                href={STORE_LINKS.android}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-full bg-brand-navy px-5 py-2.5 text-sm font-bold text-white shadow-xl transition hover:scale-105 sm:px-6 sm:py-3"
              >
                {t.phones.androidBtn}
              </a>
              <a
                href={STORE_LINKS.ios}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-full border-2 border-slate-900 bg-white px-5 py-2.5 text-sm font-bold text-slate-900 transition hover:bg-slate-100 sm:px-6 sm:py-3"
              >
                {t.phones.iosBtn}
              </a>
              <button
                type="button"
                onClick={onAskAi}
                className="rounded-full border-2 border-[#7B61FF] bg-[#7B61FF]/10 px-5 py-2.5 text-sm font-bold text-slate-900 transition hover:bg-[#7B61FF]/20 sm:px-6 sm:py-3"
              >
                Ask AI
              </button>
            </div>
          </div>

          <div className={`mt-10 grid grid-cols-3 gap-3 sm:gap-6 ${isAr ? 'text-right' : 'text-left'}`}>
            {t.hero.stats.map((s) => (
              <div key={s.label}>
                <p className="ltr-token text-2xl font-black text-slate-900 sm:text-3xl">{s.value}</p>
                <p className="mt-1 text-xs font-semibold text-slate-600 sm:text-sm">{s.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <AiAgentSection lang={lang} onAskAi={onAskAi} />
      <AppShowcase lang={lang} />

      <section id="features" className="scroll-mt-24 bg-white py-12 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <div className={`mb-8 sm:mb-12 ${isAr ? 'text-right' : 'text-center'}`}>
            <h2 className="text-2xl font-extrabold text-slate-900 sm:text-3xl lg:text-4xl">{t.features.title}</h2>
            <p className="mt-3 text-base text-slate-600 sm:text-lg">{t.features.subtitle}</p>
          </div>
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {t.features.items.map((f) => (
              <div
                key={f.title}
                className="group rounded-2xl border border-slate-200 bg-slate-50 p-6 transition hover:-translate-y-1 hover:border-brand-blue/30 hover:shadow-xl"
              >
                <div className="mb-4 text-3xl">{f.icon}</div>
                <h3 className="text-lg font-bold text-slate-900">{f.title}</h3>
                <p className="mt-2 text-sm leading-7 text-slate-600">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-slate-50 py-12 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <h2 className={`mb-8 text-2xl font-extrabold text-slate-900 sm:mb-10 sm:text-3xl ${isAr ? 'text-right' : 'text-center'}`}>
            {t.audience.title}
          </h2>
          <div className="grid gap-6 md:grid-cols-3">
            {t.audience.items.map((item, i) => (
              <div key={item.title} className="rounded-2xl bg-gradient-to-br from-brand-blue to-brand-red p-[1px] shadow-lg">
                <div className="h-full rounded-2xl bg-white p-8">
                  <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-brand-blue/10 text-xl font-black text-brand-blue">
                    {i + 1}
                  </div>
                  <h3 className="text-xl font-bold text-slate-900">{item.title}</h3>
                  <p className="mt-3 text-sm leading-7 text-slate-600">{item.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="py-12 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <h2 className={`mb-6 text-2xl font-extrabold text-slate-900 sm:mb-8 sm:text-3xl ${isAr ? 'text-right' : 'text-center'}`}>
            {t.categories.title}
          </h2>
          <div className="flex flex-wrap justify-center gap-3">
            {t.categories.items.map((cat) => (
              <span
                key={cat}
                className="rounded-full border border-brand-blue/20 bg-brand-blue/5 px-5 py-2 text-sm font-semibold text-brand-blue"
              >
                {cat}
              </span>
            ))}
          </div>
        </div>
      </section>

      <section id="download" className="scroll-mt-24 bg-gradient-to-r from-brand-blue to-brand-red py-16 text-white">
        <div className="mx-auto max-w-4xl px-4 text-center sm:px-6">
          <h2 className="text-3xl font-extrabold">{t.cta.title}</h2>
          <p className="mt-4 text-lg font-medium text-slate-100">{t.cta.subtitle}</p>
          <div className="mt-8 flex flex-wrap justify-center gap-4">
            <a
              href={STORE_LINKS.android}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-full bg-white px-8 py-3 font-bold text-brand-navy shadow-xl"
            >
              Google Play
            </a>
            <a
              href={STORE_LINKS.ios}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-full border-2 border-white px-8 py-3 font-bold text-white"
            >
              App Store
            </a>
          </div>
          <p className="mt-6 text-sm font-semibold tracking-wide text-white/85">Powered by Al Ras Smart</p>
        </div>
      </section>
    </>
  )
}
