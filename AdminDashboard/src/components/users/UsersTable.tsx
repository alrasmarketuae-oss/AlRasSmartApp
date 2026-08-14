import { Link, useLocation } from 'react-router-dom'
import { PROJECT_IMAGES } from '../../constants/projectImages'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'
import { buildListReturnState, type ListReturnState } from '../../utils/listPageParams'
import {
  getStatusBadgeClass,
  getTypeBadgeClass,
} from '../../utils/userStatus'
import { formatRelativeTime } from '../../utils/timeAgo'
import {
  isUnknownLabel,
  localizeStatusLabel,
  localizeTypeLabel,
} from '../../utils/localizedLabels'
import type { AdminUser } from '../../types/user'
import BilingualNameLines from '../ui/BilingualNameLines'

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

function isCompanyAccount(user: AdminUser): boolean {
  return user.roleId === 2 || user.roleId === 5
}

function companyCellLabel(user: AdminUser, locale: 'ar' | 'en'): string {
  const companyName = user.companyName?.trim()
  if (companyName) return companyName
  if (isCompanyAccount(user)) return user.fullName?.trim() || customerKindLabel(user, locale)
  return customerKindLabel(user, locale)
}

function UserNameCell({
  user,
  listReturnState,
}: {
  user: AdminUser
  listReturnState: ListReturnState
}) {
  const name = (
    <BilingualNameLines
      nameEn={user.fullNameEn}
      nameAr={user.fullNameAr}
      fallback={user.fullName}
    />
  )

  if (isCompanyAccount(user)) {
    return (
      <Link
        to={`/users/${user.id}/ads`}
        state={listReturnState}
        className="block min-w-0 text-[#3B7FC7] transition hover:text-[#2f6ab0] hover:underline"
      >
        {name}
      </Link>
    )
  }

  return (
    <Link
      to={`/users/${user.id}`}
      state={listReturnState}
      className="block min-w-0 transition hover:text-[#3B7FC7]"
    >
      {name}
    </Link>
  )
}

function CompanyNameCell({
  user,
  locale,
  listReturnState,
}: {
  user: AdminUser
  locale: 'ar' | 'en'
  listReturnState: ListReturnState
}) {
  if (!isCompanyAccount(user)) {
    return <CellText>{customerKindLabel(user, locale)}</CellText>
  }

  const label = companyCellLabel(user, locale)
  const hasBilingualCompany =
    Boolean(user.companyNameEn?.trim()) || Boolean(user.companyNameAr?.trim())

  return (
    <Link
      to={`/users/${user.id}/ads`}
      state={listReturnState}
      className="block min-w-0 font-medium text-[#3B7FC7] transition hover:text-[#2f6ab0] hover:underline"
    >
      {hasBilingualCompany ? (
        <BilingualNameLines
          nameEn={user.companyNameEn}
          nameAr={user.companyNameAr}
          fallback={label}
        />
      ) : (
        label
      )}
    </Link>
  )
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
            {isCompanyAccount(user) ? (
              <Link
                to={`/users/${user.id}/ads`}
                state={listReturnState}
                className="block min-w-0 text-[#3B7FC7] hover:underline"
              >
                <BilingualNameLines
                  nameEn={user.fullNameEn}
                  nameAr={user.fullNameAr}
                  fallback={user.fullName}
                />
              </Link>
            ) : (
              <BilingualNameLines
                nameEn={user.fullNameEn}
                nameAr={user.fullNameAr}
                fallback={user.fullName}
              />
            )}
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
          <dd className="admin-text-muted mt-0.5">
            <CompanyNameCell user={user} locale={locale} listReturnState={listReturnState} />
          </dd>
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
          <dd className="admin-text-muted mt-0.5">{formatRelativeTime(user.createdAt, locale)}</dd>
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
                      <UserNameCell user={user} listReturnState={listReturnState} />
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
                    <CompanyNameCell
                      user={user}
                      locale={locale}
                      listReturnState={listReturnState}
                    />
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
                    <CellText>{formatRelativeTime(user.createdAt, locale)}</CellText>
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
