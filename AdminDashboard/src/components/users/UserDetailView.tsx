import { useState } from 'react'
import { resolveAssetUrl } from '../../lib/assets'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
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
import type { AdminUserDetail } from '../../types/adminUserDetail'

type UserDetailViewProps = {
  user: AdminUserDetail
  isApproving: boolean
  isRejecting: boolean
  isDeactivating: boolean
  isDeleting: boolean
  onApprove: () => void
  onReject: (reason: string) => void
  onDeactivate: () => void
  onActivate: () => void
  onDelete: () => void
}

function isImagePath(path: string): boolean {
  return /\.(jpe?g|png|gif|webp|bmp)$/i.test(path)
}

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-1 text-right sm:flex-row sm:items-start sm:justify-between">
      <dt className="admin-text-subtle shrink-0 text-sm font-medium">{label}</dt>
      <dd className="admin-text-muted text-sm">{value}</dd>
    </div>
  )
}

function displayOrDash(value: string | null | undefined): string {
  const trimmed = value?.trim()
  return trimmed ? trimmed : '—'
}

function PendingChangeRow({
  label,
  currentValue,
  proposedValue,
  currentLabel,
  proposedLabel,
  ltr = false,
}: {
  label: string
  currentValue: string | null | undefined
  proposedValue: string | null | undefined
  currentLabel: string
  proposedLabel: string
  ltr?: boolean
}) {
  if (proposedValue == null) return null
  return (
    <div className="rounded-xl border border-amber-200 bg-amber-50/60 p-3 dark:border-amber-800/50 dark:bg-amber-950/20">
      <p className="admin-text mb-2 text-sm font-semibold">{label}</p>
      <div className="grid gap-2 sm:grid-cols-2">
        <div>
          <p className="admin-text-subtle text-xs">{currentLabel}</p>
          <p className="admin-text mt-1 text-sm" dir={ltr ? 'ltr' : undefined}>
            {displayOrDash(currentValue)}
          </p>
        </div>
        <div>
          <p className="admin-text-subtle text-xs">{proposedLabel}</p>
          <p className="admin-text mt-1 text-sm font-semibold text-[#B54708]" dir={ltr ? 'ltr' : undefined}>
            {displayOrDash(proposedValue)}
          </p>
        </div>
      </div>
    </div>
  )
}

export default function UserDetailView({
  user,
  isApproving,
  isRejecting,
  isDeactivating,
  isDeleting,
  onApprove,
  onReject,
  onDeactivate,
  onActivate,
  onDelete,
}: UserDetailViewProps) {
  const { t, locale } = useAppPreferences()
  const [rejectReason, setRejectReason] = useState('')
  const isBusy = isApproving || isRejecting || isDeactivating || isDeleting
  const isSupplier = user.roleId === 2
  const isShippingCompany = user.roleId === 5
  const showCompanyDocs = isSupplier || isShippingCompany

  const typeLabel = localizeTypeLabel(user.typeLabelAr, locale)
  const statusLabel = localizeStatusLabel(user.statusLabelAr, locale)
  const customerKindLabel =
    user.roleId === 2 && !user.isCustomer
      ? locale === 'ar'
        ? 'مورد'
        : 'Supplier'
      : user.roleId === 2 && user.isCustomer
        ? locale === 'ar'
          ? 'عميل شركة'
          : 'Company customer'
        : user.roleId === 3
          ? locale === 'ar'
            ? 'عميل شخصي'
            : 'Personal customer'
          : '—'
  const customerKindTitle =
    user.roleId === 2 && !user.isCustomer
      ? locale === 'ar'
        ? 'نوع الحساب'
        : 'Account kind'
      : locale === 'ar'
        ? 'نوع العميل'
        : 'Customer kind'
  const pending = user.pendingProfileChanges
  const hasPendingChanges = Boolean(
    pending &&
      (pending.companyName != null ||
        pending.commercialRegister != null ||
        pending.taxNumber != null ||
        pending.landNumber != null ||
        pending.fullName != null ||
        pending.phoneNumber != null),
  )

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="admin-text text-2xl font-bold">{user.fullName}</h1>
          <p className="admin-text-muted mt-1 text-sm">{user.email}</p>
        </div>

        {user.canApprove ? (
          <div className="flex flex-wrap gap-3">
            <button
              type="button"
              disabled={isBusy}
              onClick={onApprove}
              className="keep-white inline-flex items-center gap-2 rounded-xl bg-[#619D51] px-5 py-3 text-sm font-bold text-white transition hover:bg-[#528a45] disabled:opacity-60"
            >
              {isApproving ? t('approving') : t('approve')}
            </button>
            <button
              type="button"
              disabled={isBusy || !rejectReason.trim()}
              onClick={() => onReject(rejectReason.trim())}
              className="inline-flex items-center gap-2 rounded-xl border-2 border-red-200 bg-white px-5 py-3 text-sm font-bold text-red-700 transition hover:bg-red-50 disabled:opacity-60 dark:border-red-800/60 dark:bg-slate-900 dark:text-red-300 dark:hover:bg-red-950/30"
            >
              {isRejecting ? t('users.rejecting') : t('users.reject')}
            </button>
          </div>
        ) : user.canDeactivate ? (
          <div className="flex flex-wrap gap-3">
            {user.isActive ? (
              <button
                type="button"
                disabled={isBusy}
                onClick={onDeactivate}
                className="inline-flex items-center gap-2 rounded-xl border-2 border-red-200 bg-white px-5 py-3 text-sm font-bold text-red-700 transition hover:bg-red-50 disabled:opacity-60 dark:border-red-800/60 dark:bg-slate-900 dark:text-red-300 dark:hover:bg-red-950/30"
              >
                {isDeactivating ? t('users.deactivating') : t('users.deactivate')}
              </button>
            ) : !user.isRejected ? (
              <button
                type="button"
                disabled={isBusy}
                onClick={onActivate}
                className="keep-white inline-flex items-center gap-2 rounded-xl bg-[#619D51] px-5 py-3 text-sm font-bold text-white transition hover:bg-[#528a45] disabled:opacity-60"
              >
                {isDeactivating ? t('users.activating') : t('users.activate')}
              </button>
            ) : null}
            {user.canDelete ? (
              <button
                type="button"
                disabled={isBusy}
                onClick={onDelete}
                className="inline-flex items-center gap-2 rounded-xl border-2 border-red-300 bg-red-50 px-5 py-3 text-sm font-bold text-red-800 transition hover:bg-red-100 disabled:opacity-60 dark:border-red-800/60 dark:bg-red-950/20 dark:text-red-200 dark:hover:bg-red-950/40"
              >
                {isDeleting ? t('users.deletingAccount') : t('users.deleteAccount')}
              </button>
            ) : null}
          </div>
        ) : null}
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-[1fr_minmax(280px,320px)]">
        <div className="space-y-6">
          <section className="admin-card rounded-2xl p-5 sm:p-6">
            <h2 className="admin-text mb-5 text-right text-lg font-bold">
              {t('users.basicInfo')}
            </h2>
            <dl className="space-y-4">
              <InfoRow label={t('users.company')} value={user.companyName?.trim() || '—'} />
              <InfoRow label={customerKindTitle} value={customerKindLabel} />
              <InfoRow
                label={t('users.type')}
                value={
                  isUnknownLabel(user.typeLabelAr) ? (
                    '—'
                  ) : (
                    <span
                      className={`inline-block rounded-full px-3 py-1 text-xs font-medium ${getTypeBadgeClass(user.typeLabelAr)}`}
                    >
                      {typeLabel}
                    </span>
                  )
                }
              />
              <InfoRow
                label={t('users.status')}
                value={
                  isUnknownLabel(user.statusLabelAr) ? (
                    '—'
                  ) : (
                    <span
                      className={`inline-block rounded-full px-3 py-1 text-xs font-medium ${getStatusBadgeClass(user.statusLabelAr)}`}
                    >
                      {statusLabel}
                    </span>
                  )
                }
              />
              {user.isRejected && user.rejectionReason ? (
                <InfoRow
                  label={t('users.rejectReasonTitle')}
                  value={user.rejectionReason}
                />
              ) : null}
              <InfoRow
                label={t('users.phone')}
                value={<span dir="ltr">{user.phoneNumber?.trim() || '—'}</span>}
              />
              <InfoRow
                label={t('users.landLine')}
                value={<span dir="ltr">{user.landNumber?.trim() || '—'}</span>}
              />
              <InfoRow label={t('users.joinDate')} value={formatJoinDate(user.createdAt)} />
              <InfoRow
                label={t('users.orders')}
                value={user.ordersCount > 0 ? user.ordersCount : '—'}
              />
            </dl>
          </section>

          {hasPendingChanges && pending ? (
            <section className="admin-card rounded-2xl p-5 sm:p-6">
              <h2 className="admin-text mb-5 text-right text-lg font-bold">
                {t('users.pendingProfileChanges')}
              </h2>
              <div className="space-y-3">
                <PendingChangeRow
                  label={t('users.fullName')}
                  currentValue={user.fullName}
                  proposedValue={pending.fullName}
                  currentLabel={t('users.currentValue')}
                  proposedLabel={t('users.proposedValue')}
                />
                <PendingChangeRow
                  label={t('users.phone')}
                  currentValue={user.phoneNumber}
                  proposedValue={pending.phoneNumber}
                  currentLabel={t('users.currentValue')}
                  proposedLabel={t('users.proposedValue')}
                  ltr
                />
                <PendingChangeRow
                  label={t('users.company')}
                  currentValue={user.companyName}
                  proposedValue={pending.companyName}
                  currentLabel={t('users.currentValue')}
                  proposedLabel={t('users.proposedValue')}
                />
                <PendingChangeRow
                  label={t('users.commercialRegister')}
                  currentValue={user.commercialRegister}
                  proposedValue={pending.commercialRegister}
                  currentLabel={t('users.currentValue')}
                  proposedLabel={t('users.proposedValue')}
                />
                <PendingChangeRow
                  label={t('users.taxNumber')}
                  currentValue={user.taxNumber}
                  proposedValue={pending.taxNumber}
                  currentLabel={t('users.currentValue')}
                  proposedLabel={t('users.proposedValue')}
                />
                <PendingChangeRow
                  label={t('users.landLine')}
                  currentValue={user.landNumber}
                  proposedValue={pending.landNumber}
                  currentLabel={t('users.currentValue')}
                  proposedLabel={t('users.proposedValue')}
                  ltr
                />
              </div>
            </section>
          ) : null}

          {showCompanyDocs ? (
            <section className="admin-card rounded-2xl p-5 sm:p-6">
              <h2 className="admin-text mb-5 text-right text-lg font-bold">
                {t('users.companyDocuments')}
              </h2>
              <dl className="mb-6 space-y-4">
                {isSupplier ? (
                  <InfoRow
                    label={t('users.licenseNumber')}
                    value={user.licenseNumber?.trim() || '—'}
                  />
                ) : null}
                <InfoRow
                  label={t('users.commercialRegister')}
                  value={user.commercialRegister?.trim() || '—'}
                />
                <InfoRow label={t('users.taxNumber')} value={user.taxNumber?.trim() || '—'} />
              </dl>

              {isSupplier ? (
              <div className="space-y-6">
                <div>
                  <h3 className="admin-text-muted mb-3 text-right text-sm font-semibold">
                    {t('users.licenceFile')}
                  </h3>
                  {user.licencePath ? (
                    <div className="space-y-3">
                      {isImagePath(user.licencePath) ? (
                        <a
                          href={resolveAssetUrl(user.licencePath)}
                          target="_blank"
                          rel="noreferrer"
                          className="block overflow-hidden rounded-xl border border-slate-200 dark:border-slate-600"
                        >
                          <img
                            src={resolveAssetUrl(user.licencePath)}
                            alt={t('users.licenceFile')}
                            className="max-h-80 w-full object-contain bg-slate-50 dark:bg-slate-900"
                          />
                        </a>
                      ) : null}
                      <a
                        href={resolveAssetUrl(user.licencePath)}
                        target="_blank"
                        rel="noreferrer"
                        className="admin-text inline-flex text-sm font-semibold text-[#3B7FC7] hover:underline"
                      >
                        {t('users.openLicence')}
                      </a>
                    </div>
                  ) : (
                    <p className="admin-text-subtle text-right text-sm">{t('users.noLicence')}</p>
                  )}
                </div>

                <div>
                  <h3 className="admin-text-muted mb-3 text-right text-sm font-semibold">
                    {t('users.companyPhotos')}
                  </h3>
                  {user.companyImages.length > 0 ? (
                    <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                      {user.companyImages.map((image) => (
                        <a
                          key={image.id}
                          href={resolveAssetUrl(image.imagePath)}
                          target="_blank"
                          rel="noreferrer"
                          className="group relative overflow-hidden rounded-xl border border-slate-200 dark:border-slate-600"
                        >
                          <img
                            src={resolveAssetUrl(image.imagePath)}
                            alt=""
                            className="aspect-[4/3] w-full object-cover transition group-hover:scale-105"
                          />
                          {image.isPrimary ? (
                            <span className="absolute bottom-2 right-2 rounded-full bg-[#3B7FC7] px-2 py-0.5 text-[10px] font-bold text-white">
                              {t('users.primaryPhoto')}
                            </span>
                          ) : null}
                        </a>
                      ))}
                    </div>
                  ) : (
                    <p className="admin-text-subtle text-right text-sm">
                      {t('users.noCompanyPhotos')}
                    </p>
                  )}
                </div>
              </div>
              ) : null}
            </section>
          ) : null}
        </div>

        {user.canApprove ? (
          <aside className="space-y-6">
            <section className="admin-card rounded-2xl p-5 sm:p-6">
              <h2 className="admin-text mb-3 text-right text-lg font-bold">
                {t('users.rejectReasonTitle')}
              </h2>
              <p className="admin-text-muted mb-4 text-right text-sm leading-relaxed">
                {t('users.rejectReasonHint')}
              </p>
              <div className="mb-3 flex flex-wrap justify-end gap-2">
                <button
                  type="button"
                  className="rounded-full border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-medium text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200"
                  onClick={() => setRejectReason(t('users.rejectReasonUnclearLicense'))}
                >
                  {t('users.rejectReasonUnclearLicense')}
                </button>
                <button
                  type="button"
                  className="rounded-full border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-medium text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200"
                  onClick={() => setRejectReason(t('users.rejectReasonIncompleteData'))}
                >
                  {t('users.rejectReasonIncompleteData')}
                </button>
              </div>
              <textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                rows={6}
                placeholder={t('users.rejectReasonPlaceholder')}
                className="admin-input w-full resize-y px-3 py-2.5 text-sm"
              />
            </section>
          </aside>
        ) : null}
      </div>
    </div>
  )
}
