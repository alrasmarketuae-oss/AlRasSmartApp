import { Link } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'
import type { AdminShippingProvider } from '../../types/adminShipping'
type ShippingProvidersListProps = {
  providers: AdminShippingProvider[]
  deletingId: string | null
  onDelete: (providerId: string) => void
}

export default function ShippingProvidersList({
  providers,
  deletingId,
  onDelete,
}: ShippingProvidersListProps) {
  const { t, locale } = useAppPreferences()

  return (
    <div className="divide-y divide-slate-100 dark:divide-slate-800">
      {providers.map((provider) => (
        <div
          key={provider.id}
          className="admin-row-hover flex flex-wrap items-center justify-between gap-4 px-4 py-5 sm:px-6"
        >
          <Link to={`/shipping/${provider.id}`} className="flex min-w-0 flex-1 items-center gap-3 text-right">
            <CompanyAvatar provider={provider} />
            <div className="min-w-0 flex-1">
              <p className="admin-text truncate text-base font-bold">{provider.companyName}</p>
              <p className="admin-text-muted mt-1 truncate text-sm">{provider.email}</p>
              {provider.routeSummary ? (
                <p className="mt-1 truncate text-xs font-semibold text-[#3B7FC7] dark:text-[#7eb8ff]">
                  {provider.routeSummary}
                </p>
              ) : null}
            </div>
          </Link>
          <div className="flex flex-wrap items-center gap-3">
            <span
              className={`rounded-full px-3 py-1 text-xs font-semibold ${
                provider.isActive
                  ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300'
                  : 'bg-red-50 text-red-700 dark:bg-red-950/40 dark:text-red-300'
              }`}
            >
              {provider.isActive ? t('shippingPage.active') : t('shippingPage.inactive')}
            </span>
            <span className="admin-text-muted text-sm">
              {provider.totalShipments}{' '}
              {locale === 'ar' ? 'شحنة' : 'shipments'}
            </span>
            <Link
              to={`/shipping/${provider.id}?edit=1`}
              className="admin-btn-ghost text-xs font-semibold"
            >
              {t('shippingPage.edit')}
            </Link>
            <button
              type="button"
              disabled={deletingId === provider.id}
              onClick={() => onDelete(provider.id)}
              className="rounded-lg px-3 py-1.5 text-xs font-semibold text-red-600 transition hover:bg-red-50 disabled:opacity-60 dark:text-red-400 dark:hover:bg-red-950/30"
            >
              {deletingId === provider.id ? t('shippingPage.deletingCompany') : t('delete')}
            </button>
            <Link
              to={`/shipping/${provider.id}`}
              className="keep-white rounded-lg bg-[#3B7FC7] px-3 py-1.5 text-xs font-semibold text-white hover:bg-[#2f6ab0]"
            >
              {t('shippingPage.viewDetails')}
            </Link>
          </div>
        </div>
      ))}
    </div>
  )
}

function CompanyAvatar({ provider }: { provider: AdminShippingProvider }) {
  const imageUrl = resolveAssetUrl(provider.imgPath)
  if (imageUrl) {
    return (
      <img
        src={imageUrl}
        alt=""
        className="h-12 w-12 shrink-0 rounded-2xl object-cover ring-1 ring-[#3B7FC7]/15"
      />
    )
  }

  return (
    <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-[#3B7FC7] to-[#619d51] text-sm font-bold text-white">
      {provider.companyName.charAt(0).toUpperCase()}
    </div>
  )
}
