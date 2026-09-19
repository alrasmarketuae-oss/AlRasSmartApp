import type { ReactNode } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'
import type { AdminShippingProviderDetail } from '../../types/adminShipping'
import {
  formatRegistrationDate,
  formatShipmentDate,
  getShipmentStatusStyle,
} from '../../utils/shipmentStatus'

type ShippingProviderDetailViewProps = {
  provider: AdminShippingProviderDetail
  isUpdating: boolean
  isDeleting: boolean
  isModeratingPost?: boolean
  moderatingPostId?: number | null
  onEdit: () => void
  onEditPost?: (postId: number) => void
  onDelete: () => void
  onToggleActive: () => void
  onApprovePost?: (postId: number) => void
  onRejectPost?: (postId: number) => void
  onQuickAction: (action: 'notify' | 'update' | 'block') => void
}

function Card({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="admin-card p-5 sm:p-6">
      <h2 className="admin-text mb-5 text-right text-lg font-bold">{title}</h2>
      {children}
    </section>
  )
}

function InfoRow({
  icon,
  label,
  value,
}: {
  icon: ReactNode
  label: string
  value: ReactNode
}) {
  return (
    <div className="admin-border flex items-start gap-4 border-b py-4 last:border-b-0">
      <div className="admin-text-subtle mt-0.5 shrink-0">{icon}</div>
      <div className="min-w-0 flex-1 text-right">
        <p className="admin-text-subtle text-xs font-medium">{label}</p>
        <p className="admin-text mt-1 text-sm font-semibold">{value}</p>
      </div>
    </div>
  )
}

function StatRow({
  label,
  value,
  valueClassName,
}: {
  label: string
  value: ReactNode
  valueClassName: string
}) {
  return (
    <div className="admin-border flex items-center justify-between border-b py-3.5 last:border-b-0">
      <span className={`text-lg font-bold ${valueClassName}`}>{value}</span>
      <span className="admin-text-muted text-sm">{label}</span>
    </div>
  )
}

function formatPortLabel(portName: string, unLocode: string | null | undefined): string {
  if (!portName) return '—'
  return unLocode ? `${portName} (${unLocode})` : portName
}

export default function ShippingProviderDetailView({
  provider,
  isUpdating,
  isDeleting,
  isModeratingPost = false,
  moderatingPostId = null,
  onEdit,
  onEditPost,
  onDelete,
  onToggleActive,
  onApprovePost,
  onRejectPost,
  onQuickAction,
}: ShippingProviderDetailViewProps) {
  const { t, locale } = useAppPreferences()

  const posts = provider.posts?.length
    ? provider.posts
    : provider.latestPostId
      ? [
          {
            id: provider.latestPostId,
            fromCountryName: provider.fromCountryName,
            fromCountryNameAr: provider.fromCountryNameAr,
            fromPortName: provider.fromPortName,
            fromPortUnLocode: provider.fromPortUnLocode,
            toCountryName: provider.toCountryName,
            toCountryNameAr: provider.toCountryNameAr,
            toPortName: provider.toPortName,
            toPortUnLocode: provider.toPortUnLocode,
            routeSummary: provider.routeSummary,
            routeSummaryAr: provider.routeSummaryAr,
            container20ftPriceUsd: provider.container20ftPriceUsd,
            container40ftPriceUsd: provider.container40ftPriceUsd,
            container20ftPriceFormatted: provider.container20ftPriceFormatted,
            container40ftPriceFormatted: provider.container40ftPriceFormatted,
            phoneNumber: provider.phoneNumber,
            details: null,
            minDurationDays: null,
            maxDurationDays: null,
            status: provider.postStatus,
            statusLabelAr: provider.postStatusLabelAr,
            isApproved: provider.isPostApproved,
            canApprove: provider.canApprovePost,
            createdAt: provider.registrationDate,
          },
        ]
      : []

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="flex min-w-0 items-center gap-4">
          <CompanyLogo provider={provider} />
          <div className="min-w-0 text-right">
            <h1 className="admin-text text-2xl font-bold">{provider.companyName}</h1>
            {provider.fullName?.trim() ? (
              <p className="admin-text-muted mt-1 text-sm">{provider.fullName}</p>
            ) : null}
          </div>
        </div>
        <div className="flex flex-wrap gap-3">
          <button
            type="button"
            onClick={onEdit}
            className="keep-white inline-flex items-center gap-2 rounded-xl bg-[#3B7FC7] px-5 py-3 text-sm font-bold text-white transition hover:bg-[#2f6ab0]"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Z" />
            </svg>
            {t('shippingPage.editCompany')}
          </button>
          <button
            type="button"
            disabled={isDeleting}
            onClick={onDelete}
            className="inline-flex items-center gap-2 rounded-xl border-2 border-red-300 bg-white px-5 py-3 text-sm font-bold text-red-700 transition hover:bg-red-50 disabled:opacity-60 dark:border-red-800/60 dark:bg-slate-900 dark:text-red-300 dark:hover:bg-red-950/30"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
            </svg>
            {isDeleting ? t('shippingPage.deletingCompany') : t('shippingPage.deleteCompany')}
          </button>
          <button
            type="button"
            disabled={isUpdating}
            onClick={onToggleActive}
            className="inline-flex items-center gap-2 rounded-xl border-2 border-red-200 bg-white px-5 py-3 text-sm font-bold text-red-700 transition hover:bg-red-50 disabled:opacity-60 dark:border-red-800/60 dark:bg-slate-900 dark:text-red-300 dark:hover:bg-red-950/30"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
            </svg>
            {provider.isActive ? t('shippingPage.disableCompany') : t('shippingPage.enableCompany')}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-[1fr_minmax(280px,320px)]">
        <div className="order-2 space-y-6 xl:order-none">
          <Card title={t('shippingPage.companyAdsTitle')}>
            {posts.length === 0 ? (
              <p className="admin-text-subtle py-4 text-center text-sm">
                {t('shippingPage.noCompanyAds')}
              </p>
            ) : (
              <div className="space-y-3">
                <p className="admin-text-muted text-end text-xs">
                  {t('shippingPage.companyAdsCount').replace('{count}', String(posts.length))}
                </p>
                {posts.map((post) => {
                  const postFromCountry =
                    locale === 'ar'
                      ? post.fromCountryNameAr || post.fromCountryName
                      : post.fromCountryName
                  const postToCountry =
                    locale === 'ar'
                      ? post.toCountryNameAr || post.toCountryName
                      : post.toCountryName
                  const postRoute =
                    locale === 'ar' ? post.routeSummaryAr || post.routeSummary : post.routeSummary
                  const busy = isModeratingPost && moderatingPostId === post.id
                  const durationLabel =
                    post.minDurationDays || post.maxDurationDays
                      ? [
                          post.minDurationDays ?? '—',
                          post.maxDurationDays ?? '—',
                        ].join(' – ')
                      : null

                  return (
                    <div
                      key={post.id}
                      className="rounded-xl border border-slate-200/80 bg-slate-50/60 px-4 py-3.5 dark:border-slate-700 dark:bg-slate-900/40"
                    >
                      <div className="flex flex-wrap items-start justify-between gap-3">
                        <div className="min-w-0 flex-1 text-right">
                          <div className="mb-1.5 flex flex-wrap items-center justify-end gap-2">
                            <span className="rounded-md bg-white px-2 py-0.5 text-[11px] font-semibold text-[#3B7FC7] ring-1 ring-[#3B7FC7]/20 dark:bg-slate-800">
                              {post.statusLabelAr || t('shippingPage.postStatus')}
                            </span>
                            <span className="admin-text-muted text-[11px]" dir="ltr">
                              #{post.id}
                            </span>
                          </div>
                          <p className="admin-text text-sm font-bold leading-snug">
                            {postRoute ||
                              `${postFromCountry} · ${formatPortLabel(post.fromPortName, post.fromPortUnLocode)} → ${postToCountry} · ${formatPortLabel(post.toPortName, post.toPortUnLocode)}`}
                          </p>
                          <div className="admin-text-muted mt-2 flex flex-wrap justify-end gap-x-4 gap-y-1 text-xs">
                            <span>
                              {t('shippingPage.price20ft')}:{' '}
                              <span className="admin-text font-semibold">
                                {post.container20ftPriceFormatted || '—'}
                              </span>
                            </span>
                            <span>
                              {t('shippingPage.price40ft')}:{' '}
                              <span className="admin-text font-semibold">
                                {post.container40ftPriceFormatted || '—'}
                              </span>
                            </span>
                            {post.phoneNumber ? (
                              <span dir="ltr">
                                {t('shippingPage.mobile')}: {post.phoneNumber}
                              </span>
                            ) : null}
                            {durationLabel ? (
                              <span>
                                {t('shippingPage.durationDays')}: {durationLabel}
                              </span>
                            ) : null}
                          </div>
                          {post.details?.trim() ? (
                            <p className="admin-text-muted mt-2 line-clamp-2 text-xs">
                              {post.details}
                            </p>
                          ) : null}
                        </div>
                        <div className="flex shrink-0 flex-wrap justify-end gap-2">
                          <button
                            type="button"
                            onClick={() => onEditPost?.(post.id)}
                            className="keep-white rounded-lg bg-[#3B7FC7] px-3.5 py-2 text-xs font-bold text-white hover:bg-[#2f6ab0]"
                          >
                            {t('shippingPage.editAd')}
                          </button>
                          {post.canApprove ? (
                            <>
                              <button
                                type="button"
                                disabled={busy}
                                onClick={() => onApprovePost?.(post.id)}
                                className="keep-white rounded-lg bg-[#619d51] px-3.5 py-2 text-xs font-bold text-white disabled:opacity-60"
                              >
                                {t('shippingPage.approveShippingAd')}
                              </button>
                              <button
                                type="button"
                                disabled={busy}
                                onClick={() => onRejectPost?.(post.id)}
                                className="rounded-lg border border-red-300 bg-white px-3.5 py-2 text-xs font-bold text-red-700 disabled:opacity-60 dark:border-red-800 dark:bg-slate-900 dark:text-red-300"
                              >
                                {t('shippingPage.rejectShippingAd')}
                              </button>
                            </>
                          ) : null}
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </Card>

          <Card title={t('shippingPage.basicInfo')}>
            <InfoRow
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3 21h18M5 21V7l7-4 7 4v14M9 21v-6h6v6" />
                </svg>
              }
              label={t('shippingPage.companyName')}
              value={provider.companyName}
            />
            <InfoRow
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z" />
                </svg>
              }
              label={t('users.fullName')}
              value={provider.fullName?.trim() || '—'}
            />
            <InfoRow
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15A2.25 2.25 0 0 1 2.25 17.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75" />
                </svg>
              }
              label={t('shippingPage.email')}
              value={provider.email}
            />
            <InfoRow
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 0 0 2.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 0 1-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 0 0-1.091-.852H4.5A2.25 2.25 0 0 0 2.25 4.5v2.25Z" />
                </svg>
              }
              label={t('shippingPage.mobile')}
              value={provider.phoneNumber ?? '—'}
            />
            <InfoRow
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 0 0 2.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 0 1-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 0 0-1.091-.852H4.5A2.25 2.25 0 0 0 2.25 4.5v2.25Z" />
                </svg>
              }
              label={t('users.landLine')}
              value={<span dir="ltr">{provider.landNumber?.trim() || '—'}</span>}
            />
            <InfoRow
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 21a9.004 9.004 0 0 0 8.716-6.747M12 21a9.004 9.004 0 0 1-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 0 1 7.843 4.582M12 3a8.997 8.997 0 0 0-7.843 4.582m15.686 0A11.953 11.953 0 0 1 12 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0 1 21 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0 1 12 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 0 1 3 12c0-1.605.42-3.113 1.157-4.418" />
                </svg>
              }
              label={t('users.website')}
              value={provider.website?.trim() || '—'}
            />
            <InfoRow
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />
                </svg>
              }
              label={t('users.commercialRegister')}
              value={provider.commercialRegister?.trim() || '—'}
            />
            <InfoRow
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0 1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 0 0-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 0 1-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 0 0 3 15h-.75M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm3 0h.008v.008H18V10.5Zm-12 0h.008v.008H6V10.5Z" />
                </svg>
              }
              label={t('users.taxNumber')}
              value={provider.taxNumber?.trim() || '—'}
            />
          </Card>

          <Card title={t('shippingPage.shipmentLog')}>
            {provider.shipments.length === 0 ? (
              <p className="admin-text-subtle py-8 text-center text-sm">
                {t('shippingPage.noShipments')}
              </p>
            ) : (
              <div className="space-y-3">
                {provider.shipments.map((shipment) => {
                  const statusStyle = getShipmentStatusStyle(shipment.statusId)
                  const statusLabel =
                    locale === 'ar' ? shipment.statusLabelAr : shipment.statusName

                  return (
                    <div
                      key={shipment.id}
                      className="admin-border admin-surface flex items-center gap-4 rounded-2xl border px-4 py-4"
                    >
                      <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#eef4fb] dark:bg-slate-800">
                        <img
                          src="/ProjectImages/ShippingOrder.png"
                          alt=""
                          className="h-7 w-7 object-contain"
                        />
                      </div>
                      <div className="min-w-0 flex-1 text-right">
                        <div className="flex flex-wrap items-center justify-between gap-2">
                          <span
                            className={`rounded-full px-3 py-1 text-xs font-semibold ${statusStyle.className}`}
                          >
                            {statusLabel}
                          </span>
                          <p className="admin-text font-bold">#{shipment.shipmentCode}</p>
                        </div>
                        <div className="admin-text-muted mt-2 flex flex-wrap items-center justify-between gap-2 text-sm">
                          <span>{formatShipmentDate(shipment.createdAt, locale)}</span>
                          <span>{t('shippingPage.orderRef').replace('{id}', String(shipment.orderId))}</span>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </Card>

          <Card title={t('shippingPage.phoneRevealsTitle')}>
            <div className="mb-4 flex items-center justify-between gap-3 rounded-xl bg-slate-50 px-4 py-3 dark:bg-slate-900/50">
              <span className="text-2xl font-bold text-[#3B7FC7]">
                {provider.phoneRevealCount}
              </span>
              <span className="admin-text-muted text-sm">
                {t('shippingPage.phoneRevealsTotal')}
              </span>
            </div>
            {provider.phoneRevealsByViewer.length === 0 ? (
              <p className="admin-text-subtle py-6 text-center text-sm">
                {t('shippingPage.phoneRevealsEmpty')}
              </p>
            ) : (
              <div className="space-y-2">
                <p className="admin-text-muted mb-2 text-end text-xs font-medium">
                  {t('shippingPage.phoneRevealsViewers')}
                </p>
                {provider.phoneRevealsByViewer.map((row) => (
                  <div
                    key={row.viewerUserId}
                    className="admin-border flex items-start justify-between gap-3 border-b py-3 last:border-b-0"
                  >
                    <span className="shrink-0 rounded-full bg-[#eef4fb] px-3 py-1 text-sm font-bold text-[#3B7FC7] dark:bg-slate-800">
                      {t('shippingPage.phoneRevealsTimes').replace(
                        '{count}',
                        String(row.revealCount),
                      )}
                    </span>
                    <div className="min-w-0 flex-1 text-right">
                      <p className="admin-text truncate text-sm font-semibold">
                        {row.viewerName}
                      </p>
                      {row.viewerPhone?.trim() ? (
                        <p className="admin-text-muted mt-0.5 text-xs" dir="ltr">
                          {row.viewerPhone}
                        </p>
                      ) : null}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </div>

        <div className="order-1 space-y-6 xl:order-none">
          <Card title={t('shippingPage.statusCard')}>
            <div className="space-y-4 text-right">
              <div className="flex items-center justify-between gap-3">
                <span
                  className={`rounded-full px-3 py-1 text-xs font-semibold ${
                    provider.isActive
                      ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300'
                      : 'bg-red-50 text-red-700 dark:bg-red-950/40 dark:text-red-300'
                  }`}
                >
                  {provider.isActive ? t('shippingPage.active') : t('shippingPage.inactive')}
                </span>
                <span className="admin-text-muted text-sm">{t('shippingPage.companyStatus')}</span>
              </div>
              <div className="flex items-center justify-between gap-3">
                <span className="inline-flex items-center gap-1.5 text-sm font-semibold text-emerald-600 dark:text-emerald-400">
                  {provider.registrationLinkSent ? (
                    <>
                      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                      </svg>
                      {t('shippingPage.linkSent')}
                    </>
                  ) : (
                    t('shippingPage.linkNotSent')
                  )}
                </span>
                <span className="admin-text-muted text-sm">{t('shippingPage.registrationLink')}</span>
              </div>
              <div className="flex items-center justify-between gap-3">
                <span className="admin-text text-sm font-semibold">
                  {formatRegistrationDate(provider.registrationDate, locale)}
                </span>
                <span className="admin-text-muted text-sm">{t('shippingPage.registrationDate')}</span>
              </div>
            </div>
          </Card>

          <Card title={t('shippingPage.statsTitle')}>
            <StatRow
              label={t('shippingPage.phoneRevealsTotal')}
              value={provider.phoneRevealCount}
              valueClassName="text-[#3B7FC7]"
            />
            <StatRow
              label={t('shippingPage.totalShipments')}
              value={provider.stats.totalShipments}
              valueClassName="text-[#3B7FC7]"
            />
            <StatRow
              label={t('shippingPage.completed')}
              value={provider.stats.completed}
              valueClassName="text-emerald-600 dark:text-emerald-400"
            />
            <StatRow
              label={t('shippingPage.inDelivery')}
              value={provider.stats.inDelivery}
              valueClassName="text-amber-500 dark:text-amber-400"
            />
            <StatRow
              label={t('shippingPage.late')}
              value={provider.stats.late}
              valueClassName="text-red-600 dark:text-red-400"
            />
            <StatRow
              label={t('shippingPage.successRate')}
              value={`${provider.stats.successRate}%`}
              valueClassName="text-emerald-600 dark:text-emerald-400"
            />
          </Card>

          <Card title={t('shippingPage.quickActions')}>
            <div className="space-y-3">
              <button
                type="button"
                onClick={() => onQuickAction('notify')}
                className="admin-border admin-text flex w-full items-center justify-end gap-3 rounded-xl border bg-white px-4 py-3.5 text-sm font-semibold transition hover:bg-slate-50 dark:bg-slate-900 dark:hover:bg-slate-800"
              >
                <span>{t('shippingPage.sendNotification')}</span>
                <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-emerald-50 text-emerald-600 dark:bg-emerald-950/40 dark:text-emerald-400">
                  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M14.857 17.082A23.848 23.848 0 0 1 12 17.25c-2.652 0-5.176-.568-7.5-1.583m14.357 1.65A9.003 9.003 0 0 0 12 21a9.003 9.003 0 0 0-8.143-4.168M18 8A6 6 0 1 0 6 8c0 7-3 9-3 9h18s-3-2-3-9Z" />
                  </svg>
                </span>
              </button>
              <button
                type="button"
                onClick={() => onQuickAction('update')}
                className="admin-border admin-text flex w-full items-center justify-end gap-3 rounded-xl border bg-white px-4 py-3.5 text-sm font-semibold transition hover:bg-slate-50 dark:bg-slate-900 dark:hover:bg-slate-800"
              >
                <span>{t('shippingPage.requestDataUpdate')}</span>
                <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-50 text-blue-600 dark:bg-blue-950/40 dark:text-blue-400">
                  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />
                  </svg>
                </span>
              </button>
              <button
                type="button"
                onClick={() => onQuickAction('block')}
                className="admin-border flex w-full items-center justify-end gap-3 rounded-xl border-2 border-red-200 bg-white px-4 py-3.5 text-sm font-bold text-red-700 transition hover:bg-red-50 dark:border-red-800/60 dark:bg-slate-900 dark:text-red-300 dark:hover:bg-red-950/30"
              >
                <span>{t('shippingPage.temporaryBlock')}</span>
                <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-red-50 text-red-600 dark:bg-red-950/40 dark:text-red-400">
                  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 0 0 5.636 5.636m12.728 12.728A9 9 0 0 1 5.636 5.636m12.728 12.728L5.636 5.636" />
                  </svg>
                </span>
              </button>
            </div>
          </Card>
        </div>
      </div>
    </div>
  )
}

function CompanyLogo({ provider }: { provider: AdminShippingProviderDetail }) {
  const imageUrl = resolveAssetUrl(provider.imgPath)
  if (imageUrl) {
    return (
      <img
        src={imageUrl}
        alt=""
        className="h-16 w-16 shrink-0 rounded-2xl object-cover ring-2 ring-[#3B7FC7]/20"
      />
    )
  }

  return (
    <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-[#3B7FC7] to-[#619d51] text-xl font-bold text-white">
      {provider.companyName.charAt(0).toUpperCase()}
    </div>
  )
}
