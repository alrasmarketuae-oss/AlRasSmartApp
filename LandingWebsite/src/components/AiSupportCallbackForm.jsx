import { useState } from 'react'
import { createSupportCallback } from '../services/supportCallbackApi'

export default function AiSupportCallbackForm({ lang, question, onSubmitted }) {
  const isAr = lang === 'ar'
  const [fullName, setFullName] = useState('')
  const [phone, setPhone] = useState('')
  const [email, setEmail] = useState('')
  const [busy, setBusy] = useState(false)
  const [done, setDone] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const labels = isAr
    ? {
        title: 'طلب اتصال بالدعم الفني',
        name: 'الاسم الكامل',
        phone: 'رقم الهاتف',
        email: 'البريد الإلكتروني',
        submit: 'إرسال',
        sending: 'جارٍ الإرسال…',
        invalid: 'من فضلك أدخل الاسم ورقم التليفون والبريد الإلكتروني بشكل صحيح.',
        ok: 'تم استلام بياناتك. فريق الدعم الفني هيتواصل معاك خلال خمس دقايق.',
        fail: 'تعذر إرسال الطلب. حاول مرة أخرى.',
      }
    : {
        title: 'Request a support call',
        name: 'Full name',
        phone: 'Phone number',
        email: 'Email',
        submit: 'Submit',
        sending: 'Sending…',
        invalid: 'Please enter a valid name, phone number, and email.',
        ok: 'Got your details. Technical support will call you within five minutes.',
        fail: 'Could not send the request. Please try again.',
      }

  async function onSubmit(e) {
    e.preventDefault()
    e.stopPropagation()
    if (busy || done) return

    const name = fullName.trim()
    const tel = phone.trim()
    const mail = email.trim()
    if (name.length < 2 || tel.length < 6 || !mail.includes('@')) {
      setError(labels.invalid)
      return
    }

    setBusy(true)
    setError('')
    try {
      const result = await createSupportCallback({
        fullName: name,
        phone: tel,
        email: mail,
        question,
        language: isAr ? 'ar' : 'en',
        source: 'landing_ask_ai',
      })
      const msg = result?.message || result?.Message || labels.ok
      setSuccess(msg)
      setDone(true)
      onSubmitted?.()
    } catch (err) {
      setError(err?.message || labels.fail)
    } finally {
      setBusy(false)
    }
  }

  if (done) {
    return (
      <div
        className="mt-3 rounded-2xl border border-brand-green/30 bg-brand-green/10 px-3 py-3 text-sm font-semibold text-brand-navy"
        dir={isAr ? 'rtl' : 'ltr'}
      >
        {success || labels.ok}
      </div>
    )
  }

  return (
    <form
      onSubmit={onSubmit}
      className="mt-3 space-y-2 rounded-2xl border border-brand-blue/15 bg-brand-blue/[0.04] p-3"
      dir={isAr ? 'rtl' : 'ltr'}
    >
      <p className="text-sm font-extrabold text-brand-navy">{labels.title}</p>
      <input
        value={fullName}
        onChange={(e) => setFullName(e.target.value)}
        placeholder={labels.name}
        className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-brand-blue"
        autoComplete="name"
        disabled={busy}
      />
      <input
        value={phone}
        onChange={(e) => setPhone(e.target.value)}
        placeholder={labels.phone}
        className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-brand-blue"
        autoComplete="tel"
        inputMode="tel"
        dir="ltr"
        disabled={busy}
      />
      <input
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder={labels.email}
        className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-brand-blue"
        autoComplete="email"
        inputMode="email"
        dir="ltr"
        disabled={busy}
      />
      {error ? <p className="text-xs font-semibold text-brand-red">{error}</p> : null}
      <button
        type="submit"
        disabled={busy}
        className="w-full rounded-full bg-brand-blue px-4 py-2.5 text-sm font-bold text-white disabled:opacity-60"
      >
        {busy ? labels.sending : labels.submit}
      </button>
    </form>
  )
}

export function looksLikeSupportCallbackCue(answer) {
  const text = String(answer ?? '').trim().toLowerCase()
  if (!text) return false
  const markers = [
    'خمس دقايق',
    'خلال خمس',
    'خلال 5',
    'النموذج تحت',
    'رقم تليفونك',
    'five minutes',
    'form below',
    'leave your name',
    'phone number, and email',
    'technical support will call',
    "we'll call you",
    'we’ll call you',
  ]
  return markers.some((m) => text.includes(m))
}
