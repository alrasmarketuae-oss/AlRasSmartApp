import { resolveAssetUrl } from '../../lib/assets'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { RecentUser } from '../../types/dashboard'
import { localizeTypeLabel } from '../../utils/localizedLabels'

type RecentUsersListProps = {
  users: RecentUser[]
}

export default function RecentUsersList({ users }: RecentUsersListProps) {
  const { t, locale } = useAppPreferences()

  return (
    <div className="admin-card rounded-2xl border border-slate-100 p-6 shadow-sm dark:border-slate-300">
      <h2 className="admin-text mb-4 text-right text-lg font-bold">
        {t('dashboard.recentUsers')}
      </h2>
      <ul className="space-y-2">
        {users.length === 0 ? (
          <li className="admin-text-subtle py-6 text-center text-sm">
            {t('dashboard.noRecentUsers')}
          </li>
        ) : (
          users.map((user) => (
            <li
              key={user.id}
              className="admin-border admin-row-hover flex items-center justify-between gap-3 rounded-xl border px-4 py-3"
            >
              <span className="admin-surface-muted admin-border shrink-0 rounded-full px-3 py-1 text-xs font-medium text-slate-600 ring-1 ring-slate-200 dark:text-slate-300">
                {localizeTypeLabel(user.roleLabelAr, locale)}
              </span>
              <div className="flex min-w-0 items-center gap-3">
                <div className="min-w-0 text-right">
                  <p className="admin-text truncate text-sm font-semibold">
                    {user.fullName}
                  </p>
                  <p className="admin-text-subtle truncate text-xs" dir="ltr">
                    {user.phoneNumber?.trim() || '—'}
                  </p>
                </div>
                {user.imgPath ? (
                  <img
                    src={resolveAssetUrl(user.imgPath)}
                    alt=""
                    className="h-10 w-10 shrink-0 rounded-full object-cover"
                  />
                ) : (
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-slate-200 text-sm font-bold text-slate-600 dark:bg-slate-700 dark:text-slate-200">
                    {user.fullName[0]}
                  </div>
                )}
              </div>
            </li>
          ))
        )}
      </ul>
    </div>
  )
}
