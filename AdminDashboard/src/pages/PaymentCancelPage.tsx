import PreferencesControls from '../components/layout/PreferencesControls'
import { useAppPreferences } from '../context/AppPreferencesProvider'

export default function PaymentCancelPage() {
  const { t } = useAppPreferences()

  return (
    <div className="admin-page-bg flex min-h-svh flex-col items-center justify-center px-4 py-10">
      <div className="absolute end-4 top-4">
        <PreferencesControls compact />
      </div>

      <div className="mb-8 flex w-full max-w-md flex-col items-center text-center">
        <img
          src="/ProjectImages/SouqLogo.png"
          alt={t('payment.appName')}
          className="mb-5 h-24 w-24 object-contain"
        />
        <h1 className="admin-text text-2xl font-bold tracking-tight">
          {t('payment.appName')}
        </h1>
        <p className="admin-text-muted mt-2 text-sm">{t('payment.cancelTitle')}</p>
      </div>

      <div className="admin-card w-full max-w-md rounded-3xl p-8 text-center shadow-lg shadow-slate-200/80 dark:shadow-none">
        <div
          className="mx-auto mb-6 flex h-12 w-12 items-center justify-center rounded-full bg-amber-100 text-amber-600"
          aria-hidden
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className="h-7 w-7"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M12 9v4m0 4h.01M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"
            />
          </svg>
        </div>

        <h2 className="admin-text text-xl font-bold">{t('payment.cancelled')}</h2>
        <p className="admin-text-muted mt-4 text-sm">{t('payment.cancelledDetail')}</p>
      </div>
    </div>
  )
}
