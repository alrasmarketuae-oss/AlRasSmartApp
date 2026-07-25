import { CONTACT } from '../data/config'
import { content } from '../data/content'

function ContactCard({ icon, title, value, actionLabel, href }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:shadow-lg">
      <div className="mb-4 text-3xl">{icon}</div>
      <h3 className="text-lg font-bold text-slate-900">{title}</h3>
      <p className="mt-2 text-slate-600" dir="ltr">{value}</p>
      {href && (
        <a
          href={href}
          className="mt-4 inline-block rounded-full bg-gradient-to-r from-brand-blue to-brand-red px-5 py-2 text-sm font-bold text-white"
        >
          {actionLabel}
        </a>
      )}
    </div>
  )
}

export default function Contact({ lang }) {
  const t = content[lang].contactPage
  const isAr = lang === 'ar'
  const paymentIcons = {
    Visa: (
      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-[#1A1F71] text-[9px] font-black tracking-wide text-white">
        VISA
      </div>
    ),
    Mastercard: (
      <div className="relative h-10 w-10">
        <span className="absolute left-1 top-2 h-6 w-6 rounded-full bg-[#EB001B]" />
        <span className="absolute right-1 top-2 h-6 w-6 rounded-full bg-[#F79E1B] opacity-90" />
      </div>
    ),
    'Debit Card': (
      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-slate-700 text-white">
        <svg viewBox="0 0 24 24" className="h-5 w-5 fill-current" aria-hidden>
          <path d="M3 6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v2H3V6Zm0 4h18v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-8Zm3 5a1 1 0 0 0 0 2h4a1 1 0 1 0 0-2H6Z" />
        </svg>
      </div>
    ),
    'Credit Card': (
      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-slate-900 text-white">
        <svg viewBox="0 0 24 24" className="h-5 w-5 fill-current" aria-hidden>
          <path d="M2 7a3 3 0 0 1 3-3h14a3 3 0 0 1 3 3v1H2V7Zm0 3h20v7a3 3 0 0 1-3 3H5a3 3 0 0 1-3-3v-7Zm4 5a1 1 0 1 0 0 2h3a1 1 0 1 0 0-2H6Z" />
        </svg>
      </div>
    ),
    'Apple Pay': (
      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-black text-white">
        <svg viewBox="0 0 24 24" className="h-5 w-5 fill-current" aria-hidden>
          <path d="M16.37 12.52c.02 2.2 1.93 2.93 1.95 2.94-.02.05-.3 1.02-.98 2.01-.59.86-1.2 1.72-2.17 1.74-.95.02-1.26-.56-2.35-.56-1.1 0-1.43.54-2.33.58-.94.04-1.66-.95-2.25-1.8-1.2-1.73-2.12-4.88-.89-7.02.61-1.06 1.7-1.73 2.87-1.75.9-.02 1.75.6 2.35.6.59 0 1.69-.74 2.85-.63.48.02 1.83.19 2.7 1.47-.07.04-1.61.94-1.59 2.42ZM14.82 6.6c.5-.6.85-1.43.76-2.26-.72.03-1.59.48-2.1 1.08-.47.54-.88 1.4-.77 2.23.8.06 1.61-.41 2.11-1.05Z" />
        </svg>
      </div>
    ),
    'Google Pay': (
      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-white ring-1 ring-slate-200">
        <svg viewBox="0 0 24 24" className="h-6 w-6" aria-hidden>
          <path fill="#EA4335" d="M12 10.2v3.9h5.5c-.2 1.2-1.4 3.6-5.5 3.6-3.3 0-6-2.7-6-6s2.7-6 6-6c1.9 0 3.2.8 3.9 1.5l2.6-2.5C16.8 2.9 14.6 2 12 2 6.9 2 2.8 6.1 2.8 11.2S6.9 20.4 12 20.4c6.9 0 9.1-4.8 9.1-7.3 0-.5 0-.9-.1-1.2H12Z" />
          <path fill="#34A853" d="M2.8 11.2c0 1.6.4 3.1 1.2 4.3l3.4-2.7c-.2-.5-.3-1-.3-1.6s.1-1.1.3-1.6L4 6.9c-.8 1.2-1.2 2.7-1.2 4.3Z" />
          <path fill="#FBBC05" d="M12 20.4c2.5 0 4.7-.8 6.3-2.2l-3.1-2.5c-.8.6-1.8 1-3.2 1-2.4 0-4.5-1.6-5.2-3.9l-3.5 2.7c1.6 3 4.8 4.9 8.7 4.9Z" />
          <path fill="#4285F4" d="M21.1 11.9H12v3.9h5.5c-.3 1.3-1 2.2-2.3 2.9l3.1 2.5c1.8-1.7 2.8-4.1 2.8-7.1 0-.7-.1-1.4-.2-2.2Z" />
        </svg>
      </div>
    ),
    'Cash on Delivery': (
      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-600 text-white">
        <svg viewBox="0 0 24 24" className="h-5 w-5 fill-current" aria-hidden>
          <path d="M3 6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v2H3V6Zm0 4h18v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-8Zm9 1.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7Zm0 1.6c.56 0 1.02.24 1.02.52h1.4c0-.9-.78-1.63-1.85-1.8v-.72h-1.14v.72c-1.08.16-1.86.9-1.86 1.8 0 .96.86 1.54 1.86 1.75v1.1c-.62-.09-1.06-.39-1.06-.72H8.9c0 .95.84 1.7 1.93 1.86v.67h1.14v-.67c1.1-.16 1.94-.9 1.94-1.86 0-.97-.87-1.57-1.9-1.78V13.1Z" />
        </svg>
      </div>
    ),
  }

  return (
    <div className="py-12">
      <div className="mx-auto max-w-5xl px-4 sm:px-6">
        {/* Hero banner */}
        <div className="mb-10 overflow-hidden rounded-3xl bg-gradient-to-br from-brand-blue to-brand-red p-8 text-center text-white shadow-xl sm:p-12">
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-white/20 text-3xl">
            🎧
          </div>
          <h1 className="text-3xl font-extrabold sm:text-4xl">{t.heading}</h1>
          <p className="mx-auto mt-4 max-w-2xl text-lg text-blue-100">{t.intro}</p>
        </div>

        <div className="grid gap-6 md:grid-cols-3">
          <ContactCard
            icon="📞"
            title={t.phone}
            value={CONTACT.phone}
            actionLabel={t.callNow}
            href={`tel:${CONTACT.phoneTel}`}
          />
          <ContactCard
            icon="✉️"
            title={t.email}
            value={CONTACT.email}
            actionLabel={t.sendEmail}
            href={`mailto:${CONTACT.email}`}
          />
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="mb-4 text-3xl">🕐</div>
            <h3 className="text-lg font-bold text-slate-900">{t.hours}</h3>
            <div className="mt-4 space-y-3 text-sm">
              <div className="flex justify-between text-slate-600">
                <span>{t.weekdayLabel}</span>
                <span dir="ltr" className="font-semibold text-slate-900">{CONTACT.hours.weekdays}</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>{t.fridayLabel}</span>
                <span className="font-semibold text-slate-900">{t.closed}</span>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-8 rounded-2xl border border-slate-200 bg-slate-50 p-6">
          <h3 className={`text-lg font-bold text-slate-900 ${isAr ? 'text-right' : 'text-left'}`}>
            💬 {t.liveChat}
          </h3>
          <p className={`mt-2 text-slate-600 ${isAr ? 'text-right' : 'text-left'}`}>{t.liveChatDesc}</p>
        </div>

        <div className="mt-8 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className={`mb-2 text-lg font-bold text-slate-900 ${isAr ? 'text-right' : 'text-left'}`}>
            💳 {t.paymentTitle}
          </h3>
          <p className={`mb-4 text-sm text-slate-600 ${isAr ? 'text-right' : 'text-left'}`}>{t.paymentIntro}</p>
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {t.paymentMethods.map((method) => {
              return (
                <div
                  key={method}
                  className={`flex items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 p-3 ${isAr ? 'flex-row-reverse text-right' : 'text-left'}`}
                >
                  {paymentIcons[method] ?? paymentIcons.Visa}
                  <span className="text-sm font-semibold text-slate-800">{method}</span>
                </div>
              )
            })}
          </div>
        </div>

        <div className="mt-8 grid gap-6 md:grid-cols-2">
          <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h3 className={`text-lg font-bold text-slate-900 ${isAr ? 'text-right' : 'text-left'}`}>📦 {t.orderTrackingTitle}</h3>
            <p className={`mt-2 text-sm leading-7 text-slate-600 ${isAr ? 'text-right' : 'text-left'}`}>{t.orderTrackingDesc}</p>
            <img
              src="/help-my-orders.png"
              alt="My Orders tracking guide"
              className="mt-4 w-full rounded-xl border border-slate-200 object-cover"
            />
          </div>
          <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <h3 className={`text-lg font-bold text-slate-900 ${isAr ? 'text-right' : 'text-left'}`}>📢 {t.adsTrackingTitle}</h3>
            <p className={`mt-2 text-sm leading-7 text-slate-600 ${isAr ? 'text-right' : 'text-left'}`}>{t.adsTrackingDesc}</p>
            <img
              src="/help-my-ads.png"
              alt="My Ads tracking guide"
              className="mt-4 w-full rounded-xl border border-slate-200 object-cover"
            />
          </div>
        </div>

        <div className="mt-8 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className={`mb-4 text-lg font-bold text-slate-900 ${isAr ? 'text-right' : 'text-left'}`}>
            🧭 {t.rolesTitle}
          </h3>
          <div className="grid gap-4 md:grid-cols-2">
            {t.roles.map((role) => (
              <div
                key={role.title}
                className={`rounded-xl border border-slate-200 bg-slate-50 p-4 ${isAr ? 'text-right' : 'text-left'}`}
              >
                <div className={`mb-2 flex items-center gap-2 ${isAr ? 'flex-row-reverse' : ''}`}>
                  <span className="text-2xl">{role.icon}</span>
                  <h4 className="text-base font-bold text-slate-900">{role.title}</h4>
                </div>
                <p className="text-sm leading-7 text-slate-600">{role.desc}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="mt-8 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 className={`mb-4 text-lg font-bold text-slate-900 ${isAr ? 'text-right' : 'text-left'}`}>
            {t.faq}
          </h3>
          <ul className={`space-y-3 ${isAr ? 'text-right' : 'text-left'}`}>
            {t.faqs.map((q) => (
              <li key={q} className="border-b border-slate-100 pb-3 text-sm text-slate-600 last:border-0">
                {q}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  )
}
