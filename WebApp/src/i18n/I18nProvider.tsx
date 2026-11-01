import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import { STRINGS, type Lang, type StringKey } from './strings'

type I18nValue = {
  lang: Lang
  isAr: boolean
  t: (key: StringKey, vars?: Record<string, string | number>) => string
  toggleLang: () => void
}

const I18nContext = createContext<I18nValue | null>(null)
const KEY = 'alras_web_lang'

function initialLang(): Lang {
  const stored = localStorage.getItem(KEY)
  if (stored === 'ar' || stored === 'en') return stored
  return navigator.language?.toLowerCase().startsWith('ar') ? 'ar' : 'en'
}

export function I18nProvider({ children }: { children: ReactNode }) {
  const [lang, setLang] = useState<Lang>(initialLang)

  useEffect(() => {
    localStorage.setItem(KEY, lang)
    document.documentElement.lang = lang
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr'
  }, [lang])

  const t = useCallback(
    (key: StringKey, vars?: Record<string, string | number>) => {
      let text: string = STRINGS[lang][key] ?? STRINGS.en[key] ?? key
      if (vars) for (const [name, value] of Object.entries(vars)) text = text.replace(`{${name}}`, String(value))
      return text
    },
    [lang],
  )

  const value = useMemo<I18nValue>(
    () => ({ lang, isAr: lang === 'ar', t, toggleLang: () => setLang((current) => (current === 'ar' ? 'en' : 'ar')) }),
    [lang, t],
  )

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>
}

export function useI18n() {
  const value = useContext(I18nContext)
  if (!value) throw new Error('useI18n must be used inside I18nProvider')
  return value
}
