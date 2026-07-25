import { content } from '../data/content'
import PhoneShowcase from '../components/PhoneShowcase'
import { STORE_LINKS } from '../data/config'

export default function Home({ lang }) {
  const t = content[lang]
  const isAr = lang === 'ar'

  return (
    <>
      <PhoneShowcase lang={lang} />

      {/* Hero */}
      <section className="hero-glow relative overflow-hidden bg-brand-navy pb-20 pt-16 text-white" dir={isAr ? 'rtl' : 'ltr'}>
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_70%_30%,rgba(208,9,30,0.15),transparent_50%)]" />
        <div className="relative mx-auto grid max-w-7xl items-center gap-12 px-4 sm:px-6 lg:grid-cols-2">
          <div className={isAr ? 'text-right' : 'text-left'}>
            <span className="inline-block rounded-full border border-white/25 bg-white/10 px-4 py-1.5 text-sm font-semibold text-slate-100">
              {t.hero.badge}
            </span>
            <h1 className="mt-6 text-5xl font-black leading-tight sm:text-6xl">
              <span className="gradient-text bg-gradient-to-r from-white to-blue-200 bg-clip-text text-transparent">
                {t.hero.title}
              </span>
            </h1>
            <p className="mt-6 max-w-xl text-lg font-medium leading-8 text-slate-100">{t.hero.subtitle}</p>
            <div className={`mt-8 flex flex-wrap gap-4 ${isAr ? 'justify-end' : 'justify-start'}`}>
              <a
                href={STORE_LINKS.android}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-full bg-white px-6 py-3 text-sm font-bold text-brand-navy shadow-xl transition hover:scale-105"
              >
                {t.phones.androidBtn}
              </a>
              <a
                href={STORE_LINKS.ios}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-full border border-white/40 px-6 py-3 text-sm font-bold text-white transition hover:bg-white/10"
              >
                {t.phones.iosBtn}
              </a>
            </div>
            <div className={`mt-10 grid grid-cols-3 gap-4 ${isAr ? 'text-right' : 'text-left'}`}>
              {t.hero.stats.map((s) => (
                <div key={s.label} className="rounded-2xl border border-white/20 bg-white/10 p-4 backdrop-blur">
                  <p className="ltr-token text-2xl font-black text-white">{s.value}</p>
                  <p className="mt-1 text-xs font-medium text-slate-100">{s.label}</p>
                </div>
              ))}
            </div>
          </div>

          <div className="relative flex justify-center">
            <div className="absolute -inset-4 rounded-full bg-gradient-to-r from-brand-blue/30 to-brand-red/30 blur-3xl" />
            <div className="relative rounded-[2.5rem] border border-white/10 bg-slate-900/60 p-6 shadow-2xl backdrop-blur">
              <img src="/logo.png" alt="" className="mx-auto h-32 w-32 rounded-3xl object-cover shadow-2xl ring-4 ring-white/10" />
              <p className="mt-6 text-center text-2xl font-bold">{t.phones.screenTitle}</p>
              <p className="text-center font-medium text-slate-100">{t.phones.screenSubtitle}</p>
              <div className="mt-6 grid grid-cols-2 gap-3">
                {['📦', '🛒', '📅', '🚢'].map((icon) => (
                  <div key={icon} className="rounded-xl bg-white/10 p-4 text-center text-2xl">{icon}</div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="scroll-mt-24 bg-white py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <div className={`mb-12 ${isAr ? 'text-right' : 'text-center'}`}>
            <h2 className="text-3xl font-extrabold text-slate-900 sm:text-4xl">{t.features.title}</h2>
            <p className="mt-3 text-lg text-slate-600">{t.features.subtitle}</p>
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

      {/* Audience */}
      <section className="bg-slate-50 py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <h2 className={`mb-10 text-3xl font-extrabold text-slate-900 ${isAr ? 'text-right' : 'text-center'}`}>
            {t.audience.title}
          </h2>
          <div className="grid gap-6 md:grid-cols-3">
            {t.audience.items.map((item, i) => (
              <div
                key={item.title}
                className="rounded-2xl bg-gradient-to-br from-brand-blue to-brand-red p-[1px] shadow-lg"
              >
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

      {/* Categories */}
      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <h2 className={`mb-8 text-3xl font-extrabold text-slate-900 ${isAr ? 'text-right' : 'text-center'}`}>
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

      {/* Final CTA */}
      <section className="bg-gradient-to-r from-brand-blue to-brand-red py-16 text-white">
        <div className={`mx-auto max-w-4xl px-4 text-center sm:px-6`}>
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
        </div>
      </section>
    </>
  )
}
