import { useState, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
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
import type { AdminUserAddress, AdminUserDetail } from '../../types/adminUserDetail'
import BilingualNameLines from '../ui/BilingualNameLines'
import WhatsAppPhoneLink from '../shared/WhatsAppPhoneLink'
import {
  FieldIcon,
  IconInfoSectionTitle,
  InfoFieldIcons,
} from '../shared/IconInfoField'

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

const ICON_BLUE = 'bg-[#eff6ff] text-[#3B7FC7]'

function isImagePath(path: string): boolean {
  return /\.(jpe?g|png|gif|webp|bmp)$/i.test(path)
}

function displayOrDash(value: string | null | undefined): string {
  const trimmed = value?.trim()
  return trimmed ? trimmed : '—'
}

function ProfileFieldRow({
  icon,
  label,
  value,
}: {
  icon: ReactNode
  label: string
  value: ReactNode
}) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-slate-100 py-3 last:border-b-0 dark:border-slate-800">
      <div className="flex min-w-0 items-center gap-2.5">
        <span className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${ICON_BLUE}`}>
          {icon}
        </span>
        <span className="admin-text-subtle text-sm font-medium">{label}</span>
      </div>
      <div className="admin-text max-w-[62%] text-end text-sm font-semibold">{value || '—'}</div>
    </div>
  )
}

function DocumentFileRow({
  label,
  href,
  icon,
  emptyLabel,
}: {
  label: string
  href?: string | null
  icon: ReactNode
  emptyLabel: string
}) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-slate-100 py-3 last:border-b-0 dark:border-slate-800">
      <span className="admin-text-subtle text-sm font-medium">{label}</span>
      {href ? (
        <a
          href={href}
          target="_blank"
          rel="noreferrer"
          className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#eff6ff] text-[#3B7FC7] transition hover:bg-[#dbeafe]"
          aria-label={label}
        >
          {icon}
        </a>
      ) : (
        <span className="admin-text-subtle text-sm">{emptyLabel}</span>
      )}
    </div>
  )
}

function HeroMetaItem({
  icon,
  label,
  value,
}: {
  icon: ReactNode
  label: string
  value: ReactNode
}) {
  return (
    <div className="flex min-w-0 items-start gap-2.5">
      <span className={`mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${ICON_BLUE}`}>
        {icon}
      </span>
      <div className="min-w-0">
        <p className="admin-text-subtle text-xs font-medium">{label}</p>
        <div className="admin-text mt-0.5 text-sm font-semibold">{value}</div>
      </div>
    </div>
  )
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
          <p
            className="admin-text mt-1 text-sm font-semibold text-[#B54708]"
            dir={ltr ? 'ltr' : undefined}
          >
            {displayOrDash(proposedValue)}
          </p>
        </div>
      </div>
    </div>
  )
}

function PdfFileIcon() {
  return (
    <FieldIcon className="h-5 w-5">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"
      />
    </FieldIcon>
  )
}

function pickPrimaryAddress(addresses: AdminUserAddress[]): AdminUserAddress | undefined {
  return (
    addresses.find((item) => item.addressTypeId === 1) ??
    addresses[0]
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
  const showVerifiedBadge =
    (isSupplier || isShippingCompany) && user.isVerified && !user.isRejected && user.isActive

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
          : typeLabel || '—'
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

  const companyTitle =
    user.companyName?.trim() || user.fullName?.trim() || user.email
  const primaryAddress = pickPrimaryAddress(user.addresses ?? [])
  const extraAddresses = (user.addresses ?? []).filter(
    (item) => item.addressId !== primaryAddress?.addressId,
  )
  const primaryLogo =
    user.companyImages.find((image) => image.isPrimary) ?? user.companyImages[0]
  const logoHref = primaryLogo
    ? resolveAssetUrl(primaryLogo.imagePath)
    : user.imgPath
      ? resolveAssetUrl(user.imgPath)
      : null
  const licenceHref = user.licencePath ? resolveAssetUrl(user.licencePath) : null
  const licenceIsImage = Boolean(user.licencePath && isImagePath(user.licencePath))
  const documentNumber = user.commercialRegister?.trim() || user.licenseNumber?.trim() || ''

  const outlineBtn =
    'inline-flex items-center gap-2 rounded-xl border-2 bg-white px-5 py-2.5 text-sm font-bold transition disabled:opacity-60 dark:bg-slate-900'
  const actionButtons = user.canApprove ? (
    <div className="flex flex-wrap justify-end gap-3">
      <button
        type="button"
        disabled={isBusy}
        onClick={onApprove}
        className="keep-white inline-flex items-center gap-2 rounded-xl bg-[#619D51] px-5 py-2.5 text-sm font-bold text-white transition hover:bg-[#528a45] disabled:opacity-60"
      >
        {isApproving ? t('approving') : t('approve')}
      </button>
      <button
        type="button"
        disabled={isBusy || !rejectReason.trim()}
        onClick={() => onReject(rejectReason.trim())}
        className={`${outlineBtn} border-red-300 text-red-700 hover:bg-red-50 dark:border-red-800/60 dark:text-red-300 dark:hover:bg-red-950/30`}
      >
        {isRejecting ? t('users.rejecting') : t('users.reject')}
      </button>
    </div>
  ) : user.canDeactivate ? (
    <div className="flex flex-wrap justify-end gap-3">
      {user.canDelete ? (
        <button
          type="button"
          disabled={isBusy}
          onClick={onDelete}
          className={`${outlineBtn} border-red-400 text-red-600 hover:bg-red-50 dark:border-red-800/60 dark:text-red-300 dark:hover:bg-red-950/30`}
        >
          {isDeleting ? t('users.deletingAccount') : t('users.deleteAccount')}
        </button>
      ) : null}
      {user.isActive ? (
        <button
          type="button"
          disabled={isBusy}
          onClick={onDeactivate}
          className={`${outlineBtn} border-[#3B7FC7] text-[#3B7FC7] hover:bg-[#eff6ff] dark:hover:bg-slate-800`}
        >
          {isDeactivating ? t('users.deactivating') : t('users.deactivate')}
        </button>
      ) : !user.isRejected ? (
        <button
          type="button"
          disabled={isBusy}
          onClick={onActivate}
          className="keep-white inline-flex items-center gap-2 rounded-xl bg-[#619D51] px-5 py-2.5 text-sm font-bold text-white transition hover:bg-[#528a45] disabled:opacity-60"
        >
          {isDeactivating ? t('users.activating') : t('users.activate')}
        </button>
      ) : null}
    </div>
  ) : null

  return (
    <div className="space-y-5">
      <section className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
        {actionButtons}

        <div className={`flex flex-wrap items-start justify-between gap-4 ${actionButtons ? 'mt-4' : ''}`}>
          <div className="min-w-0">
            <div className="flex flex-wrap items-center gap-2.5">
              {showCompanyDocs ? (
                <Link to={`/users/${user.id}/ads`} className="min-w-0 hover:opacity-90">
                  <BilingualNameLines
                    nameEn={user.companyNameEn}
                    nameAr={user.companyNameAr}
                    fallback={companyTitle}
                    primaryClassName="admin-text text-2xl font-extrabold tracking-tight sm:text-[1.7rem]"
                    secondaryClassName="admin-text-muted mt-1 text-sm"
                  />
                </Link>
              ) : (
                <BilingualNameLines
                  nameEn={user.fullNameEn}
                  nameAr={user.fullNameAr}
                  fallback={user.fullName}
                  primaryClassName="admin-text text-2xl font-extrabold tracking-tight sm:text-[1.7rem]"
                  secondaryClassName="admin-text-muted mt-1 text-sm"
                />
              )}
              {showVerifiedBadge ? (
                <span className="inline-flex items-center gap-1 rounded-full bg-[#eff6ff] px-2.5 py-1 text-xs font-bold text-[#3B7FC7]">
                  <span className="flex h-4 w-4 items-center justify-center">{InfoFieldIcons.check}</span>
                  {t('users.verifiedSupplier')}
                </span>
              ) : null}
            </div>
          </div>

          <div className="space-y-1.5 text-sm">
            {user.phoneNumber?.trim() ? (
              <div className="flex items-center justify-end gap-2">
                <span className={`flex h-7 w-7 items-center justify-center rounded-lg ${ICON_BLUE}`}>
                  {InfoFieldIcons.phone}
                </span>
                <WhatsAppPhoneLink phone={user.phoneNumber} className="text-sm" />
              </div>
            ) : null}
            {user.landNumber?.trim() ? (
              <div className="flex items-center justify-end gap-2">
                <span className={`flex h-7 w-7 items-center justify-center rounded-lg ${ICON_BLUE}`}>
                  {InfoFieldIcons.phone}
                </span>
                <span dir="ltr" className="admin-text font-semibold">
                  {user.landNumber}
                </span>
              </div>
            ) : null}
            {user.email ? (
              <div className="flex items-center justify-end gap-2">
                <span className={`flex h-7 w-7 items-center justify-center rounded-lg ${ICON_BLUE}`}>
                  {InfoFieldIcons.mail}
                </span>
                <a href={`mailto:${user.email}`} className="admin-text font-semibold hover:text-[#3B7FC7]" dir="ltr">
                  {user.email}
                </a>
              </div>
            ) : null}
          </div>
        </div>

        <div className="mt-5 grid gap-4 border-t border-slate-100 pt-5 sm:grid-cols-2 lg:grid-cols-3 dark:border-slate-800">
          <HeroMetaItem
            icon={InfoFieldIcons.calendar}
            label={t('users.joinDate')}
            value={formatJoinDate(user.createdAt)}
          />
          <HeroMetaItem
            icon={InfoFieldIcons.briefcase}
            label={t('users.accountType')}
            value={customerKindLabel}
          />
          <HeroMetaItem
            icon={InfoFieldIcons.check}
            label={t('users.status')}
            value={
              isUnknownLabel(user.statusLabelAr) ? (
                '—'
              ) : (
                <span
                  className={`inline-flex rounded-full px-3 py-0.5 text-xs font-bold ${getStatusBadgeClass(user.statusLabelAr)}`}
                >
                  {statusLabel}
                </span>
              )
            }
          />
        </div>
      </section>

      <div className={`grid grid-cols-1 gap-5 ${showCompanyDocs ? 'xl:grid-cols-2' : ''}`}>
        <section className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
          <IconInfoSectionTitle
            title={t('users.basicInfo')}
            icon={InfoFieldIcons.document}
            iconClass={ICON_BLUE}
          />
          <div>
            <ProfileFieldRow
              icon={InfoFieldIcons.building}
              label={t('users.company')}
              value={
                showCompanyDocs ? (
                  <Link to={`/users/${user.id}/ads`} className="font-semibold text-[#3B7FC7] hover:underline">
                    <BilingualNameLines
                      nameEn={user.companyNameEn}
                      nameAr={user.companyNameAr}
                      fallback={user.companyName?.trim() || t('users.viewCompanyAds')}
                    />
                  </Link>
                ) : (
                  user.companyName?.trim() || '—'
                )
              }
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.users}
              label={t('users.fullName')}
              value={
                <BilingualNameLines
                  nameEn={user.fullNameEn}
                  nameAr={user.fullNameAr}
                  fallback={user.fullName}
                  primaryClassName="font-semibold"
                  secondaryClassName="admin-text-muted text-xs mt-0.5"
                />
              }
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.briefcase}
              label={t('users.accountType')}
              value={
                <span className={`inline-flex rounded-full px-3 py-1 text-xs font-bold ${getTypeBadgeClass(user.typeLabelAr)}`}>
                  {customerKindLabel}
                </span>
              }
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.tag}
              label={t('users.type')}
              value={
                isUnknownLabel(user.typeLabelAr) ? (
                  '—'
                ) : (
                  <span
                    className={`inline-flex rounded-full px-3 py-1 text-xs font-medium ${getTypeBadgeClass(user.typeLabelAr)}`}
                  >
                    {typeLabel}
                  </span>
                )
              }
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.check}
              label={t('users.status')}
              value={
                isUnknownLabel(user.statusLabelAr) ? (
                  '—'
                ) : (
                  <span
                    className={`inline-flex rounded-full px-3 py-1 text-xs font-medium ${getStatusBadgeClass(user.statusLabelAr)}`}
                  >
                    {statusLabel}
                  </span>
                )
              }
            />
            {user.isRejected && user.rejectionReason ? (
              <ProfileFieldRow
                icon={InfoFieldIcons.note}
                label={t('users.rejectReasonTitle')}
                value={user.rejectionReason}
              />
            ) : null}
            <ProfileFieldRow
              icon={InfoFieldIcons.phone}
              label={t('users.phone')}
              value={<WhatsAppPhoneLink phone={user.phoneNumber} className="text-sm" />}
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.phone}
              label={t('users.landLine')}
              value={<span dir="ltr">{user.landNumber?.trim() || '—'}</span>}
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.calendar}
              label={t('users.joinDate')}
              value={formatJoinDate(user.createdAt)}
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.clipboard}
              label={t('users.orders')}
              value={user.ordersCount > 0 ? user.ordersCount : '—'}
            />
          </div>
        </section>

        {showCompanyDocs ? (
          <section className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
            <IconInfoSectionTitle
              title={t('users.companyDocuments')}
              icon={InfoFieldIcons.document}
              iconClass={ICON_BLUE}
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.document}
              label={t('users.documentNumber')}
              value={documentNumber || '—'}
            />
            {isSupplier ? (
              <ProfileFieldRow
                icon={InfoFieldIcons.document}
                label={t('users.licenseNumber')}
                value={user.licenseNumber?.trim() || '—'}
              />
            ) : null}
            <ProfileFieldRow
              icon={InfoFieldIcons.document}
              label={t('users.taxNumber')}
              value={user.taxNumber?.trim() || '—'}
            />
            {isSupplier ? (
              <>
                <DocumentFileRow
                  label={t('users.licenceFile')}
                  href={licenceHref}
                  icon={<PdfFileIcon />}
                  emptyLabel={t('users.noLicence')}
                />
                <DocumentFileRow
                  label={t('users.licenseImage')}
                  href={licenceIsImage ? licenceHref : null}
                  icon={InfoFieldIcons.photo}
                  emptyLabel={t('users.noLicence')}
                />
              </>
            ) : null}
            <DocumentFileRow
              label={t('users.companyLogo')}
              href={logoHref}
              icon={InfoFieldIcons.photo}
              emptyLabel={t('users.noCompanyPhotos')}
            />
            {user.companyImages.length > 1 ? (
              <div className="mt-4 grid grid-cols-3 gap-2">
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
                      <span className="absolute bottom-1.5 start-1.5 rounded-full bg-[#3B7FC7] px-2 py-0.5 text-[10px] font-bold text-white">
                        {t('users.primaryPhoto')}
                      </span>
                    ) : null}
                  </a>
                ))}
              </div>
            ) : null}
          </section>
        ) : null}
      </div>

      <section className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
        <IconInfoSectionTitle
          title={t('users.primaryAddress')}
          icon={InfoFieldIcons.pin}
          iconClass={ICON_BLUE}
        />
        {primaryAddress ? (
          <div>
            <ProfileFieldRow
              icon={InfoFieldIcons.pin}
              label={t('users.addressText')}
              value={
                <span className="inline-flex flex-wrap items-center justify-end gap-x-2 gap-y-1">
                  <span className="whitespace-pre-wrap">{primaryAddress.formattedAddress || '—'}</span>
                  {primaryAddress.mapsUrl ? (
                    <a
                      href={primaryAddress.mapsUrl}
                      target="_blank"
                      rel="noreferrer"
                      className="shrink-0 text-xs font-bold text-[#3B7FC7] hover:underline"
                    >
                      {t('users.openMap')}
                    </a>
                  ) : null}
                </span>
              }
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.mail}
              label={t('users.postalCode')}
              value={primaryAddress.postalCode?.trim() || '—'}
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.document}
              label={t('users.documentNumber')}
              value={documentNumber || '—'}
            />
            <ProfileFieldRow
              icon={InfoFieldIcons.tag}
              label={t('users.addressType')}
              value={
                locale === 'ar'
                  ? primaryAddress.addressTypeNameAr || primaryAddress.addressTypeNameEn || '—'
                  : primaryAddress.addressTypeNameEn || primaryAddress.addressTypeNameAr || '—'
              }
            />
          </div>
        ) : (
          <p className="admin-text-muted text-sm">{t('users.noAddresses')}</p>
        )}

        {extraAddresses.length > 0 ? (
          <div className="mt-5 space-y-3 border-t border-slate-100 pt-4 dark:border-slate-800">
            <h3 className="admin-text-subtle text-sm font-semibold">{t('users.savedAddresses')}</h3>
            {extraAddresses.map((address) => {
              const typeName =
                locale === 'ar'
                  ? address.addressTypeNameAr || address.addressTypeNameEn
                  : address.addressTypeNameEn || address.addressTypeNameAr
              return (
                <div
                  key={address.addressId}
                  className="rounded-xl border border-slate-100 p-3 dark:border-slate-800"
                >
                  <p className="text-sm font-bold text-[#3B7FC7]">{typeName || '—'}</p>
                  <p className="admin-text mt-1 whitespace-pre-wrap text-sm leading-relaxed">
                    {address.formattedAddress || '—'}
                  </p>
                  {address.coordinates ? (
                    <p className="admin-text-muted mt-2 text-xs" dir="ltr">
                      {t('users.coordinates')}: {address.coordinates}
                      {address.mapsUrl ? (
                        <>
                          {' · '}
                          <a
                            href={address.mapsUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="font-semibold text-[#3B7FC7] hover:underline"
                          >
                            {t('users.openMap')}
                          </a>
                        </>
                      ) : null}
                    </p>
                  ) : null}
                </div>
              )
            })}
          </div>
        ) : null}
      </section>

      {hasPendingChanges && pending ? (
        <section className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
          <h2 className="admin-text mb-5 text-start text-lg font-bold">
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

      {user.canApprove ? (
        <section className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
          <h2 className="admin-text mb-3 text-start text-lg font-bold">
            {t('users.rejectReasonTitle')}
          </h2>
          <p className="admin-text-muted mb-4 text-start text-sm leading-relaxed">
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
      ) : null}
    </div>
  )
}
