import { Link, useLocation } from 'react-router-dom'
import { PROJECT_IMAGES } from '../../constants/projectImages'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'
import { buildListReturnState, type ListReturnState } from '../../utils/listPageParams'
import {
  formatJoinDate,
  getStatusBadgeClass,
  getTypeBadgeClass,
} from '../../utils/userStatus'
import {
  isUnknownLabel,
  localizeStatusLabel,
  localizeTypeLabel,
} from '../../utils/localizedLabels'
import type { AdminUser } from '../../types/user'

type UsersTableProps = {
  users: AdminUser[]
}

function CellText({ children }: { children: React.ReactNode }) {
  return <span className="admin-text-muted">{children}</span>
}

function customerKindLabel(user: AdminUser, locale: 'ar' | 'en'): string {
  if (user.roleId === 2 && !user.isCustomer) {
    return locale === 'ar' ? 'مورد' : 'Supplier'
  }
  if (user.roleId === 2 && user.isCustomer) {
    return locale === 'ar' ? 'عميل شركة' : 'Company customer'
  }
  if (user.roleId === 3) {
    return locale === 'ar' ? 'عميل شخصي' : 'Personal customer'
  }
  return '—'
}

function TypeBadge({ label, locale }: { label: string; locale: 'ar' | 'en' }) {
  const display = localizeTypeLabel(label, locale)
  if (isUnknownLabel(label)) {
    return <CellText>—</CellText>
  }
  return (
    <span
      className={`inline-block rounded-full px-3 py-1 text-xs font-medium ${getTypeBadgeClass(label)}`}
    >
      {display}
    </span>
  )
}

function StatusBadge({ label, locale }: { label: string; locale: 'ar' | 'en' }) {
  const display = localizeStatusLabel(label, locale)
  if (isUnknownLabel(label)) {
    return <CellText>—</CellText>
  }
  return (
    <span
      className={`inline-block rounded-full px-3 py-1 text-xs font-medium ${getStatusBadgeClass(label)}`}
    >
      {display}
    </span>
  )
}

function UserAvatar({ user }: { user: AdminUser }) {
  if (user.imgPath) {
    return (
      <img
        src={resolveAssetUrl(user.imgPath)}
        alt=""
        className="h-9 w-9 rounded-full object-cover"
      />
    )
  }

  return (
    <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#dceaf8]">
      <img
        src={PROJECT_IMAGES.statUsers}
        alt=""
        className="h-[18px] w-[18px] object-contain"
      />
    </span>
  )
}

function UserMobileCard({
  user,
  locale,
  t,
  listReturnState,
}: {
  user: AdminUser
  locale: 'ar' | 'en'
  t: (key: string) => string
  listReturnState: ListReturnState
}) {
  const canReview =
    Boolean(user.canApprove) ||
    Boolean(user.hasPendingProfileChanges) ||
    ((user.roleId === 2 || user.roleId === 5) && !user.isActive && !user.isRejected)
  const phoneDisplay = user.phoneNumber?.trim() || '—'

  return (
    <article className="admin-border admin-surface rounded-2xl border p-4 shadow-sm">
      <div className="flex items-start justify-between gap-3">
        <div className="flex min-w-0 flex-1 items-center gap-3">
          <UserAvatar user={user} />
          <div className="min-w-0 text-start">
            <p className="admin-text truncate font-semibold">{user.fullName}</p>
            <p className="admin-text-muted truncate text-xs" dir="ltr">
              {phoneDisplay}
            </p>
          </div>
        </div>
        <TypeBadge label={user.typeLabelAr} locale={locale} />
      </div>

      <dl className="mt-4 grid grid-cols-2 gap-3 text-sm">
        <div>
          <dt className="admin-text-subtle text-xs">{t('users.company')}</dt>
          <dd className="admin-text-muted mt-0.5">{customerKindLabel(user, locale)}</dd>
        </div>
        <div>
          <dt className="admin-text-subtle text-xs">{t('users.orders')}</dt>
          <dd className="admin-text-muted mt-0.5">
            {user.ordersCount > 0 ? user.ordersCount : '—'}
          </dd>
        </div>
        <div>
          <dt className="admin-text-subtle text-xs">{t('users.status')}</dt>
          <dd className="mt-1">
            <div className="flex flex-wrap items-center gap-2">
              <StatusBadge label={user.statusLabelAr} locale={locale} />
              {user.hasPendingProfileChanges ? (
                <span className="inline-block rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-800 dark:bg-amber-950/60 dark:text-amber-200">
                  {t('users.profileEditBadge')}
                </span>
              ) : null}
            </div>
          </dd>
        </div>
        <div>
          <dt className="admin-text-subtle text-xs">{t('users.joinDate')}</dt>
          <dd className="admin-text-muted mt-0.5">{formatJoinDate(user.createdAt)}</dd>
        </div>
      </dl>

      {canReview ? (
        <Link
          to={`/users/${user.id}`}
          state={listReturnState}
          className="keep-white mt-4 block w-full rounded-xl bg-[#3B7FC7] px-4 py-2.5 text-center text-sm font-bold text-white transition hover:bg-[#2f6ab0]"
        >
          {t('users.review')}
        </Link>
      ) : (
        <Link
          to={`/users/${user.id}`}
          state={listReturnState}
          className="admin-btn-ghost mt-4 block w-full text-center text-sm font-semibold"
        >
          {t('users.review')}
        </Link>
      )}
    </article>
  )
}

export default function UsersTable({ users }: UsersTableProps) {
  const { t, locale } = useAppPreferences()
  const location = useLocation()
  const listReturnState = buildListReturnState(location.pathname, location.search)

  if (users.length === 0) {
    return (
      <p className="admin-text-subtle px-4 py-16 text-center sm:px-6">{t('users.noUsers')}</p>
    )
  }

  return (
    <>
      <div className="space-y-3 p-4 lg:hidden">
        {users.map((user) => (
          <UserMobileCard
            key={user.id}
            user={user}
            locale={locale}
            t={t}
            listReturnState={listReturnState}
          />
        ))}
      </div>

      <div className="hidden overflow-x-auto px-2 pb-2 lg:block">
        <table className="w-full min-w-[960px] border-collapse text-sm">
          <thead>
            <tr className="admin-text-muted">
              <th className="admin-text-muted px-5 py-3 text-start text-sm font-medium">
                {t('users.user')}
              </th>
              <th className="admin-text-muted px-5 py-3 text-start text-sm font-medium">
                {t('users.phone')}
              </th>
              <th className="admin-text-muted px-5 py-3 text-start text-sm font-medium">
                {t('users.type')}
              </th>
              <th className="admin-text-muted px-5 py-3 text-start text-sm font-medium">
                {t('users.company')}
              </th>
              <th className="admin-text-muted px-5 py-3 text-start text-sm font-medium">
                {t('users.status')}
              </th>
              <th className="admin-text-muted px-5 py-3 text-start text-sm font-medium">
                {t('users.orders')}
              </th>
              <th className="admin-text-muted px-5 py-3 text-start text-sm font-medium">
                {t('users.joinDate')}
              </th>
              <th className="admin-text-muted px-5 py-3 text-start text-sm font-medium">
                {t('users.actions')}
              </th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => {
              const canReview =
                Boolean(user.canApprove) ||
                Boolean(user.hasPendingProfileChanges) ||
                ((user.roleId === 2 || user.roleId === 5) && !user.isActive && !user.isRejected)

              return (
                <tr key={user.id} className="admin-border border-t">
                  <td className="px-5 py-5 text-start">
                    <div className="flex items-center justify-start gap-3">
                      <UserAvatar user={user} />
                      <Link
                        to={`/users/${user.id}`}
          state={listReturnState}
                        className="admin-text font-medium transition hover:text-[#3B7FC7]"
                      >
                        {user.fullName}
                      </Link>
                    </div>
                  </td>
                  <td className="px-5 py-5 text-start">
                    <CellText>
                      <span dir="ltr">{user.phoneNumber?.trim() || '—'}</span>
                    </CellText>
                  </td>
                  <td className="px-5 py-5 text-start">
                    <TypeBadge label={user.typeLabelAr} locale={locale} />
                  </td>
                  <td className="px-5 py-5 text-start">
                    <CellText>{customerKindLabel(user, locale)}</CellText>
                  </td>
                  <td className="px-5 py-5 text-start">
                    <div className="flex flex-wrap items-center gap-2">
                      <StatusBadge label={user.statusLabelAr} locale={locale} />
                      {user.hasPendingProfileChanges ? (
                        <span className="inline-block rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-800 dark:bg-amber-950/60 dark:text-amber-200">
                          {t('users.profileEditBadge')}
                        </span>
                      ) : null}
                    </div>
                  </td>
                  <td className="px-5 py-5 text-start">
                    <CellText>{user.ordersCount > 0 ? user.ordersCount : '—'}</CellText>
                  </td>
                  <td className="px-5 py-5 text-start">
                    <CellText>{formatJoinDate(user.createdAt)}</CellText>
                  </td>
                  <td className="px-5 py-5 text-start">
                    <Link
                      to={`/users/${user.id}`}
          state={listReturnState}
                      className={`inline-block rounded-xl px-4 py-2 text-xs font-bold transition ${
                        canReview
                          ? 'keep-white bg-[#3B7FC7] text-white hover:bg-[#2f6ab0]'
                          : 'admin-btn-ghost'
                      }`}
                    >
                      {t('users.review')}
                    </Link>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </>
  )
}
