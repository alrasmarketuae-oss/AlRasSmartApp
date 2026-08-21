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

      <section className="relative overflow-hidden bg-white py-12 sm:py-16" dir={isAr ? 'rtl' : 'ltr'}>
        <div className="hero-glow pointer-events-none absolute inset-0 opacity-90" aria-hidden />
        <div className="relative mx-auto max-w-7xl px-4 sm:px-6">
          <div className={`max-w-3xl ${isAr ? 'ms-auto text-right' : 'text-left'}`}>
            <span className="inline-block rounded-full border border-brand-blue/25 bg-brand-blue/5 px-4 py-1.5 text-sm font-bold text-brand-blue">
              {t.hero.badge}
            </span>
            <h1 className="mt-5 text-3xl font-black leading-tight text-brand-navy sm:text-5xl">
              {t.hero.title}
            </h1>
            <p className="mt-4 text-base font-bold leading-7 text-slate-700 sm:text-lg sm:leading-8">
              {t.hero.subtitle}
            </p>
            <div className={`mt-8 flex flex-wrap gap-3 ${isAr ? 'justify-end' : 'justify-start'}`}>
              <a
                href={STORE_LINKS.android}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-full bg-brand-blue px-5 py-2.5 text-sm font-bold text-white shadow-xl shadow-brand-blue/25 transition hover:scale-105 sm:px-6 sm:py-3"
              >
                {t.phones.androidBtn}
              </a>
              <a
                href={STORE_LINKS.ios}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-full border-2 border-brand-navy bg-white px-5 py-2.5 text-sm font-bold text-brand-navy transition hover:bg-brand-navy/5 sm:px-6 sm:py-3"
              >
                {t.phones.iosBtn}
              </a>
              <button
                type="button"
                onClick={onAskAi}
                className="rounded-full border-2 border-brand-green bg-brand-green/10 px-5 py-2.5 text-sm font-bold text-brand-navy transition hover:bg-brand-green/20 sm:px-6 sm:py-3"
              >
                Ask AI
              </button>
            </div>
          </div>

          <div className={`mt-10 grid grid-cols-3 gap-3 sm:gap-6 ${isAr ? 'text-right' : 'text-left'}`}>
            {t.hero.stats.map((s, i) => {
              const accent =
                i % 3 === 0 ? 'text-brand-blue' : i % 3 === 1 ? 'text-brand-red' : 'text-brand-green'
              return (
                <div key={s.label}>
                  <p className={`ltr-token text-2xl font-black sm:text-3xl ${accent}`}>{s.value}</p>
                  <p className="mt-1 text-xs font-semibold text-slate-600 sm:text-sm">{s.label}</p>
                </div>
              )
            })}
          </div>
        </div>
      </section>

      <AiAgentSection lang={lang} onAskAi={onAskAi} />
      <AppShowcase lang={lang} />

      <section id="features" className="scroll-mt-24 bg-white py-12 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <div className={`mb-8 sm:mb-12 ${isAr ? 'text-right' : 'text-center'}`}>
            <h2 className="text-2xl font-extrabold text-brand-navy sm:text-3xl lg:text-4xl">{t.features.title}</h2>
            <p className="mt-3 text-base text-slate-600 sm:text-lg">{t.features.subtitle}</p>
          </div>
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {t.features.items.map((f, i) => {
              const accents = [
                'border-brand-blue/20 hover:border-brand-blue/40',
                'border-brand-red/20 hover:border-brand-red/40',
                'border-brand-green/20 hover:border-brand-green/40',
                'border-brand-blue/20 hover:border-brand-blue/40',
              ]
              return (
                <div
                  key={f.title}
                  className={`group rounded-2xl border bg-slate-50 p-6 transition hover:-translate-y-1 hover:shadow-xl ${accents[i % accents.length]}`}
                >
                  <div className="mb-4 text-3xl">{f.icon}</div>
                  <h3 className="text-lg font-bold text-brand-navy">{f.title}</h3>
                  <p className="mt-2 text-sm leading-7 text-slate-600">{f.desc}</p>
                </div>
              )
            })}
          </div>
        </div>
      </section>

      <section className="bg-slate-50 py-12 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <h2 className={`mb-8 text-2xl font-extrabold text-brand-navy sm:mb-10 sm:text-3xl ${isAr ? 'text-right' : 'text-center'}`}>
            {t.audience.title}
          </h2>
          <div className="grid gap-6 md:grid-cols-3">
            {t.audience.items.map((item, i) => {
              const borders = [
                'from-brand-blue to-brand-blue',
                'from-brand-red to-brand-red',
                'from-brand-green to-brand-green',
              ]
              const icons = [
                'bg-brand-blue/10 text-brand-blue',
                'bg-brand-red/10 text-brand-red',
                'bg-brand-green/10 text-brand-green',
              ]
              return (
                <div
                  key={item.title}
                  className={`rounded-2xl bg-gradient-to-br p-[1px] shadow-lg ${borders[i % 3]}`}
                >
                  <div className="h-full rounded-2xl bg-white p-8">
                    <div className={`mb-4 flex h-12 w-12 items-center justify-center rounded-xl text-xl font-black ${icons[i % 3]}`}>
                      {i + 1}
                    </div>
                    <h3 className="text-xl font-bold text-brand-navy">{item.title}</h3>
                    <p className="mt-3 text-sm leading-7 text-slate-600">{item.desc}</p>
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      </section>

      <section className="py-12 sm:py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <h2 className={`mb-6 text-2xl font-extrabold text-brand-navy sm:mb-8 sm:text-3xl ${isAr ? 'text-right' : 'text-center'}`}>
            {t.categories.title}
          </h2>
          <div className="flex flex-wrap justify-center gap-3">
            {t.categories.items.map((cat, i) => {
              const chips = [
                'border-brand-blue/25 bg-brand-blue/5 text-brand-blue',
                'border-brand-red/25 bg-brand-red/5 text-brand-red',
                'border-brand-green/25 bg-brand-green/5 text-brand-green',
              ]
              return (
                <span
                  key={cat}
                  className={`rounded-full border px-5 py-2 text-sm font-semibold ${chips[i % 3]}`}
                >
                  {cat}
                </span>
              )
            })}
          </div>
        </div>
      </section>

      <section id="download" className="scroll-mt-24 brand-gradient py-16 text-white">
        <div className="mx-auto max-w-4xl px-4 text-center sm:px-6">
          <h2 className="text-3xl font-extrabold">{t.cta.title}</h2>
          <p className="mt-4 text-lg font-medium text-white/90">{t.cta.subtitle}</p>
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
