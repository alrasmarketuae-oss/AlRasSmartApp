import { useAppPreferences } from '../../context/AppPreferencesProvider'

type PreferencesControlsProps = {
  compact?: boolean
}

export default function PreferencesControls({
  compact = false,
}: PreferencesControlsProps) {
  const { theme, locale, toggleTheme, setLocale, alertSoundMuted, toggleAlertSoundMuted, t } =
    useAppPreferences()

  return (
    <div
      className={`flex items-center gap-2 ${compact ? '' : 'shrink-0'}`}
      dir="ltr"
    >
      <div className="admin-border flex overflow-hidden rounded-xl border bg-slate-50 dark:bg-slate-800">
        <button
          type="button"
          onClick={() => setLocale('ar')}
          className={`px-2.5 py-1.5 text-xs font-semibold transition ${
            locale === 'ar'
              ? 'keep-white bg-[#3B7FC7] text-white'
              : 'admin-text-muted hover:bg-slate-100 dark:hover:bg-slate-700'
          }`}
          aria-label={t('langAr')}
        >
          AR
        </button>
        <button
          type="button"
          onClick={() => setLocale('en')}
          className={`px-2.5 py-1.5 text-xs font-semibold transition ${
            locale === 'en'
              ? 'keep-white bg-[#3B7FC7] text-white'
              : 'admin-text-muted hover:bg-slate-100 dark:hover:bg-slate-700'
          }`}
          aria-label={t('langEn')}
        >
          EN
        </button>
      </div>

      <button
        type="button"
        onClick={(e) => {
          e.stopPropagation()
          toggleAlertSoundMuted()
        }}
        className="admin-border admin-text flex h-9 w-9 items-center justify-center rounded-xl border bg-slate-50 transition hover:bg-slate-100 dark:bg-slate-800 dark:hover:bg-slate-700"
        aria-label={alertSoundMuted ? t('alerts.unmuteSound') : t('alerts.muteSound')}
        title={alertSoundMuted ? t('alerts.unmuteSound') : t('alerts.muteSound')}
        aria-pressed={alertSoundMuted}
      >
        {alertSoundMuted ? (
          /* Muted: speaker with X */
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="h-5 w-5 text-red-500" aria-hidden>
            <path d="M13.5 4.06c0-1.336-1.616-2.005-2.56-1.06l-4.5 4.5H4.508c-1.141 0-2.318.664-2.66 1.905A9.76 9.76 0 0 0 1.5 12c0 .898.121 1.768.35 2.595.341 1.241 1.518 1.905 2.659 1.905h1.93l4.5 4.5c.945.945 2.561.276 2.561-1.06V4.06ZM17.78 9.22a.75.75 0 1 0-1.06 1.06L18.94 12l-1.22 1.22a.75.75 0 1 0 1.06 1.06l1.22-1.22 1.22 1.22a.75.75 0 1 0 1.06-1.06L21.06 12l1.22-1.22a.75.75 0 0 0-1.06-1.06l-1.22 1.22-1.22-1.22Z" />
          </svg>
        ) : (
          /* Unmuted: speaker with waves */
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="h-5 w-5" aria-hidden>
            <path d="M13.5 4.06c0-1.336-1.616-2.005-2.56-1.06l-4.5 4.5H4.508c-1.141 0-2.318.664-2.66 1.905A9.76 9.76 0 0 0 1.5 12c0 .898.121 1.768.35 2.595.341 1.241 1.518 1.905 2.659 1.905h1.93l4.5 4.5c.945.945 2.561.276 2.561-1.06V4.06ZM18.584 5.106a.75.75 0 0 1 1.06 0c3.808 3.807 3.808 9.98 0 13.788a.75.75 0 0 1-1.06-1.06 8.25 8.25 0 0 0 0-11.668.75.75 0 0 1 0-1.06Z" />
            <path d="M15.932 7.757a.75.75 0 0 1 1.061 0 6 6 0 0 1 0 8.486.75.75 0 0 1-1.06-1.061 4.5 4.5 0 0 0 0-6.364.75.75 0 0 1 0-1.06Z" />
          </svg>
        )}
      </button>

      <button
        type="button"
        onClick={toggleTheme}
        className="admin-border admin-text flex h-9 w-9 items-center justify-center rounded-xl border bg-slate-50 transition hover:bg-slate-100 dark:bg-slate-800 dark:hover:bg-slate-700"
        aria-label={theme === 'dark' ? t('themeLight') : t('themeDark')}
        title={theme === 'dark' ? t('themeLight') : t('themeDark')}
      >
        {theme === 'dark' ? (
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="h-5 w-5" aria-hidden>
            <path d="M12 2.25a.75.75 0 0 1 .75.75v2.25a.75.75 0 0 1-1.5 0V3a.75.75 0 0 1 .75-.75ZM7.5 12a4.5 4.5 0 1 1 9 0 4.5 4.5 0 0 1-9 0ZM18.894 6.166a.75.75 0 0 0-1.06-1.06l-1.591 1.59a.75.75 0 1 0 1.06 1.061l1.591-1.59ZM21.75 12a.75.75 0 0 1-.75.75h-2.25a.75.75 0 0 1 0-1.5H21a.75.75 0 0 1 .75.75ZM17.834 18.894a.75.75 0 0 0 1.06-1.06l-1.59-1.591a.75.75 0 1 0-1.061 1.06l1.59 1.591ZM12 18a.75.75 0 0 1 .75.75V21a.75.75 0 0 1-1.5 0v-2.25A.75.75 0 0 1 12 18ZM7.758 17.303a.75.75 0 0 0-1.061-1.06l-1.591 1.59a.75.75 0 0 0 1.06 1.061l1.591-1.59ZM6 12a.75.75 0 0 1-.75.75H3a.75.75 0 0 1 0-1.5h2.25A.75.75 0 0 1 6 12ZM6.697 7.757a.75.75 0 0 0 1.06-1.06l-1.59-1.591a.75.75 0 0 0-1.061 1.06l1.59 1.591Z" />
          </svg>
        ) : (
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="h-5 w-5" aria-hidden>
            <path fillRule="evenodd" d="M9.528 1.718a.75.75 0 0 1 .162.819A8.97 8.97 0 0 0 9 6a9 9 0 0 0 9 9 8.97 8.97 0 0 0 3.463-.69.75.75 0 0 1 .981.98 10.503 10.503 0 0 1-9.694 6.46c-5.799 0-10.5-4.701-10.5-10.5 0-4.368 2.667-8.112 6.46-9.694a.75.75 0 0 1 .818.162Z" clipRule="evenodd" />
          </svg>
        )}
      </button>
    </div>
  )
}
