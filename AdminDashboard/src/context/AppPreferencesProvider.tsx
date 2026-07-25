import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { messages, type Locale } from '../i18n/messages'
import {
  isAlertSoundMuted,
  setAlertSoundMuted,
} from '../lib/alertSound'

export type Theme = 'light' | 'dark'

const THEME_KEY = 'rasalsouq_theme'
const LOCALE_KEY = 'rasalsouq_locale'

type AppPreferencesContextValue = {
  theme: Theme
  locale: Locale
  dir: 'rtl' | 'ltr'
  isDark: boolean
  alertSoundMuted: boolean
  setTheme: (theme: Theme) => void
  toggleTheme: () => void
  setLocale: (locale: Locale) => void
  toggleLocale: () => void
  setAlertSoundMuted: (muted: boolean) => void
  toggleAlertSoundMuted: () => void
  t: (key: string, params?: Record<string, string | number>) => string
}

const AppPreferencesContext = createContext<AppPreferencesContextValue | null>(
  null,
)

function readStoredTheme(): Theme {
  const stored = localStorage.getItem(THEME_KEY)
  return stored === 'dark' ? 'dark' : 'light'
}

function readStoredLocale(): Locale {
  const stored = localStorage.getItem(LOCALE_KEY)
  return stored === 'en' ? 'en' : 'ar'
}

function getNestedMessage(locale: Locale, key: string): string | undefined {
  const parts = key.split('.')
  let current: unknown = messages[locale]
  for (const part of parts) {
    if (current && typeof current === 'object' && part in current) {
      current = (current as Record<string, unknown>)[part]
    } else {
      return undefined
    }
  }
  return typeof current === 'string' ? current : undefined
}

export function AppPreferencesProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<Theme>(() => readStoredTheme())
  const [locale, setLocaleState] = useState<Locale>(() => readStoredLocale())
  const [alertSoundMuted, setAlertSoundMutedState] = useState<boolean>(() =>
    isAlertSoundMuted(),
  )

  const dir: 'rtl' | 'ltr' = locale === 'ar' ? 'rtl' : 'ltr'
  const isDark = theme === 'dark'

  useEffect(() => {
    const root = document.documentElement
    root.classList.toggle('dark', isDark)
    root.lang = locale
    root.dir = dir
    document.title =
      locale === 'ar' ? 'سوق الراس - الإدارة' : 'Ras Al Souq — Admin'
  }, [isDark, locale, dir])

  const setTheme = useCallback((next: Theme) => {
    setThemeState(next)
    localStorage.setItem(THEME_KEY, next)
  }, [])

  const toggleTheme = useCallback(() => {
    setTheme(theme === 'dark' ? 'light' : 'dark')
  }, [setTheme, theme])

  const setLocale = useCallback((next: Locale) => {
    setLocaleState(next)
    localStorage.setItem(LOCALE_KEY, next)
  }, [])

  const toggleLocale = useCallback(() => {
    setLocale(locale === 'ar' ? 'en' : 'ar')
  }, [locale, setLocale])

  const setAlertSoundMutedPreference = useCallback((muted: boolean) => {
    setAlertSoundMuted(muted)
    setAlertSoundMutedState(muted)
  }, [])

  const toggleAlertSoundMuted = useCallback(() => {
    setAlertSoundMutedState((prev) => {
      const next = !prev
      setAlertSoundMuted(next)
      return next
    })
  }, [])

  const t = useCallback(
    (key: string, params?: Record<string, string | number>) => {
      let value =
        getNestedMessage(locale, key) ??
        getNestedMessage('ar', key) ??
        key

      if (params) {
        for (const [paramKey, paramValue] of Object.entries(params)) {
          value = value.replace(`{${paramKey}}`, String(paramValue))
        }
      }

      return value
    },
    [locale],
  )

  const value = useMemo(
    () => ({
      theme,
      locale,
      dir,
      isDark,
      alertSoundMuted,
      setTheme,
      toggleTheme,
      setLocale,
      toggleLocale,
      setAlertSoundMuted: setAlertSoundMutedPreference,
      toggleAlertSoundMuted,
      t,
    }),
    [
      theme,
      locale,
      dir,
      isDark,
      alertSoundMuted,
      setTheme,
      toggleTheme,
      setLocale,
      toggleLocale,
      setAlertSoundMutedPreference,
      toggleAlertSoundMuted,
      t,
    ],
  )

  return (
    <AppPreferencesContext.Provider value={value}>
      {children}
    </AppPreferencesContext.Provider>
  )
}

export function useAppPreferences() {
  const ctx = useContext(AppPreferencesContext)
  if (!ctx) {
    throw new Error('useAppPreferences must be used within AppPreferencesProvider')
  }
  return ctx
}
