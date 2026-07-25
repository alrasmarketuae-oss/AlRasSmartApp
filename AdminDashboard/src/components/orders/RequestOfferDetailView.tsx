import { useMemo, useState, type ReactNode } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { resolveAssetUrl } from '../../lib/assets'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import {
  useApproveRequestOfferMutation,
  useMarkOrderReceivedMutation,
  useRejectRequestOfferMutation,
  useSetCustomOrderStatusMutation,
} from '../../store'
import type { AdminOrder } from '../../types/adminOrder'
import ProductShippingPanel from '../shared/ProductShippingPanel'
import ContactSupplierDialog, {
  type ContactTarget,
} from '../shared/ContactSupplierDialog'
import ConfirmDialog from '../ui/ConfirmDialog'
import OrderStatusHistoryStrip from './OrderStatusHistoryStrip'
import {
  displayAdProductTypeName,
  formatAdAmount,
  formatPriceTypeLabel,
  productTypeBadgeClass,
  resolveOrderChannelTypeKey,
} from '../../utils/adsDisplay'
import { resolveReturnToListPath } from '../../utils/listPageParams'
import {
  formatOrderAmount,
  formatOrderQuantityWithUnit,
  resolveOfferedQuantity,
  resolveRequiredQuantity,
} from '../../utils/ordersDisplay'
import { getOrderStatusLabel, getOrderStatusStyle } from '../../utils/orderStatus'
import {
  canMarkOrderReceived,
  canSetCustomTextStatus,
  needsAdminOrderModeration,
} from '../../utils/orderWorkflow'

type RequestOfferDetailViewProps = {
  order: AdminOrder
  isUpdating: boolean
  backToListPath?: string
}

type TabKey =
  | 'details'
  | 'photos'
  | 'shipping'
  | 'documents'
  | 'conversation'
  | 'activity'

function formatDetailDate(value: string, locale: 'ar' | 'en') {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function paymentLabel(name: string, t: (key: string) => string) {
  if (name === 'Online') return t('orders.paymentOnline')
  if (name === 'CashOnDelivery') return t('orders.paymentCod')
  return name || '—'
}

function SidebarCard({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="admin-card overflow-hidden rounded-2xl shadow-sm">
      <div className="admin-border border-b px-5 py-3.5">
        <h2 className="admin-text text-start text-sm font-bold">{title}</h2>
      </div>
      <div className="px-5 py-4">{children}</div>
    </section>
  )
}

function SummaryRow({
  label,
  value,
  emphasize,
}: {
  label: string
  value: string
  emphasize?: boolean
}) {
  return (
    <div
      className={`flex items-center justify-between gap-3 border-b border-slate-100 py-2.5 last:border-0 dark:border-slate-700/60 ${
        emphasize ? 'pt-3' : ''
      }`}
    >
      <span
        className={`text-xs font-bold ${
          emphasize ? 'text-emerald-700' : 'admin-text'
        }`}
      >
        {label}
      </span>
      <span
        className={`text-sm font-bold ${
          emphasize ? 'text-base text-emerald-600' : 'admin-text'
        }`}
      >
        {value}
      </span>
    </div>
  )
}

function InfoGridItem({ label, value }: { label: string; value: string }) {
  return (
    <div className="text-start">
      <p className="admin-text-subtle text-[10px] font-semibold uppercase tracking-wide">{label}</p>
      <p className="admin-text mt-1 text-sm font-semibold">{value || '—'}</p>
    </div>
  )
}

function fileNameFromPath(path: string): string {
  const normalized = path.replace(/\\/g, '/')
  const parts = normalized.split('/')
  return parts[parts.length - 1] || path
}

export default function RequestOfferDetailView({
  order,
  isUpdating,
  backToListPath,
}: RequestOfferDetailViewProps) {
  const { t, locale } = useAppPreferences()
  const location = useLocation()
  const resolvedBack =
    backToListPath ||
    resolveReturnToListPath('/reqs-offers', location.state) ||
    '/reqs-offers'

  const [activeTab, setActiveTab] = useState<TabKey>('details')
  const [requestOfferError, setRequestOfferError] = useState<string | null>(null)
  const [requestOfferSuccess, setRequestOfferSuccess] = useState<string | null>(null)
  const [pendingRequestOfferAction, setPendingRequestOfferAction] = useState<
    'approve' | 'reject' | null
  >(null)
  const [customStatusText, setCustomStatusText] = useState('')
  const [customStatusError, setCustomStatusError] = useState<string | null>(null)
  const [customStatusSuccess, setCustomStatusSuccess] = useState<string | null>(null)
  const [confirmMarkReceived, setConfirmMarkReceived] = useState(false)
  const [contactTarget, setContactTarget] = useState<ContactTarget | null>(null)

  const [approveRequestOffer, { isLoading: isApprovingOffer }] =
    useApproveRequestOfferMutation()
  const [rejectRequestOffer, { isLoading: isRejectingOffer }] =
    useRejectRequestOfferMutation()
  const [setCustomOrderStatus, { isLoading: isSettingCustomStatus }] =
    useSetCustomOrderStatusMutation()
  const [markOrderReceived, { isLoading: isMarkingReceived }] =
    useMarkOrderReceivedMutation()

  const status = getOrderStatusStyle(order.statusId)
  const statusLabel =
    locale === 'ar'
      ? order.statusLabelAr?.trim() || getOrderStatusLabel(order.statusId, locale)
      : order.statusName?.trim() || getOrderStatusLabel(order.statusId, locale)

  const needsAdminModeration = needsAdminOrderModeration(order)
  const canSetCustomRequestStatus = canSetCustomTextStatus(order)
  const canMarkReceived = canMarkOrderReceived(order)
  const statusHistory = order.statusHistory ?? []
  const isBusy =
    isUpdating ||
    isApprovingOffer ||
    isRejectingOffer ||
    isSettingCustomStatus ||
    isMarkingReceived

  const requiredQuantity = resolveRequiredQuantity(order)
  const offeredQuantity = resolveOfferedQuantity(order)
  const extraQuantity = Math.max(0, offeredQuantity - requiredQuantity)

  const unitPrice =
    order.customerUnitPriceFormatted?.trim() ||
    (order.customerUnitPrice > 0
      ? `${order.customerUnitPrice.toFixed(2)} ${order.currency}`
      : order.supplierUnitPriceFormatted ||
        `${order.supplierUnitPrice.toFixed(2)} ${order.currency}`)

  const subtotal =
    order.customerTotalPriceFormatted?.trim() ||
    `${(order.customerTotalPrice || order.totalPrice || 0).toFixed(2)} ${order.currency}`

  const vatAmount =
    order.vatAed > 0 ? `${order.vatAed.toFixed(2)} AED` : '—'
  const appProfit =
    order.appProfitFormatted || `${order.appProfitAmount.toFixed(2)} ${order.currency}`
  const grandTotal = formatOrderAmount(order)

  const fulfillmentLabel = formatPriceTypeLabel(order.shippingDescription, t)

  const typeName = displayAdProductTypeName(
    { productTypeName: order.productTypeName, categoryName: order.categoryName },
    locale,
  )

  const supplierInitials = (order.supplierName || '—').slice(0, 2).toUpperCase()
  const buyerLabel = order.customerName?.trim() || '—'
  const buyerInitials = buyerLabel.slice(0, 2).toUpperCase()

  const photoPaths = useMemo(() => {
    const fromOrder = order.images.map((i) => i.path).filter(Boolean)
    const fromProduct = order.productImagePaths ?? []
    const primary = order.primaryImagePath ? [order.primaryImagePath] : []
    return Array.from(new Set([...fromOrder, ...fromProduct, ...primary].filter(Boolean)))
  }, [order.images, order.productImagePaths, order.primaryImagePath])

  const documentPaths = useMemo(() => {
    return Array.from(
      new Set([...(order.documentPaths ?? []), ...(order.productDocumentPaths ?? [])]),
    )
  }, [order.documentPaths, order.productDocumentPaths])

  const requestImageUrl = resolveAssetUrl(
    order.primaryImagePath ?? order.productImagePaths?.[0] ?? order.images[0]?.path,
  )

  const tabs: { key: TabKey; label: string }[] = [
    { key: 'details', label: t('reqsOffers.offerTabDetails') },
    { key: 'photos', label: t('reqsOffers.offerTabPhotos') },
    { key: 'shipping', label: t('reqsOffers.offerTabShipping') },
    { key: 'documents', label: t('reqsOffers.offerTabDocuments') },
    { key: 'conversation', label: t('reqsOffers.offerTabConversation') },
    { key: 'activity', label: t('reqsOffers.offerTabActivity') },
  ]

  function openSupplierContact() {
    setContactTarget({
      displayName: order.supplierName,
      email: order.supplierEmail,
      phone: order.supplierPhone,
      userId: order.supplierUserId,
      avatarPath: order.supplierAvatarPath,
    })
  }

  function submitRequestOfferDecision(approved: boolean) {
    setRequestOfferError(null)
    setRequestOfferSuccess(null)
    setPendingRequestOfferAction(null)
    const action = approved ? approveRequestOffer : rejectRequestOffer
    void action({ orderId: order.id })
      .unwrap()
      .then(() => {
        setRequestOfferSuccess(
          approved
            ? t('orders.requestOfferApproveSuccess')
            : t('orders.requestOfferRejectSuccess'),
        )
      })
      .catch((err: { data?: { message?: string } }) => {
        setRequestOfferError(err?.data?.message ?? t('orders.requestOfferActionError'))
      })
  }

  function submitCustomStatus() {
    const text = customStatusText.trim()
    if (!text) {
      setCustomStatusError(t('orders.customStatusRequired'))
      setCustomStatusSuccess(null)
      return
    }
    const isArabic = /[\u0600-\u06FF]/.test(text)
    setCustomStatusError(null)
    setCustomStatusSuccess(null)
    void setCustomOrderStatus({
      orderId: order.id,
      statusNameEn: isArabic ? '' : text,
      statusNameAr: isArabic ? text : '',
    })
      .unwrap()
      .then(() => {
        setCustomStatusSuccess(t('orders.customStatusSuccess'))
        setCustomStatusText('')
      })
      .catch((err: { data?: { message?: string } }) => {
        setCustomStatusError(err?.data?.message ?? t('orders.customStatusError'))
      })
  }

  function submitMarkReceived() {
    setConfirmMarkReceived(false)
    setCustomStatusError(null)
    setCustomStatusSuccess(null)
    void markOrderReceived({ orderId: order.id })
      .unwrap()
      .then(() => {
        setCustomStatusSuccess(t('orders.markReceivedSuccess'))
      })
      .catch((err: { data?: { message?: string } }) => {
        setCustomStatusError(err?.data?.message ?? t('orders.markReceivedError'))
      })
  }

  return (
    <div className="space-y-5 print:space-y-3">
      {requestOfferSuccess ? (
        <div className="admin-alert-success print:hidden">{requestOfferSuccess}</div>
      ) : null}
      {requestOfferError ? (
        <div className="admin-alert-error print:hidden">{requestOfferError}</div>
      ) : null}
      {customStatusSuccess ? (
        <div className="admin-alert-success print:hidden">{customStatusSuccess}</div>
      ) : null}
      {customStatusError ? (
        <div className="admin-alert-error print:hidden">{customStatusError}</div>
      ) : null}

      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="min-w-0 text-start">
          <p className="admin-text-muted text-xs">
            <Link to="/reqs-offers" className="hover:text-[#2563eb]">
              {t('reqsOffers.title')}
            </Link>
            {order.productId ? (
              <>
                <span className="mx-1.5 opacity-50">›</span>
                <Link
                  to={`/ads/${order.productId}`}
                  state={{ from: '/reqs-offers' }}
                  className="hover:text-[#2563eb]"
                >
                  {t('reqsOffers.requestDetails')}
                </Link>
              </>
            ) : null}
            <span className="mx-1.5 opacity-50">›</span>
            <span>
              {t('reqsOffers.offerNumber', { id: order.id })}
            </span>
          </p>

          <Link
            to={resolvedBack}
            className="admin-text-muted mt-3 inline-flex items-center gap-1.5 text-sm font-semibold transition hover:text-[#2563eb]"
          >
            <span aria-hidden>←</span>
            {t('reqsOffers.backToOffers')}
          </Link>

          <div className="mt-3 flex flex-wrap items-center gap-2">
            <h1 className="admin-text text-2xl font-bold tracking-tight">
              {t('reqsOffers.offerNumber', { id: order.id })}
            </h1>
            <span
              className={`inline-flex rounded-full px-2.5 py-1 text-[11px] font-bold ${status.className}`}
            >
              {statusLabel}
            </span>
          </div>
          <p className="admin-text-muted mt-1 text-xs">
            {t('reqsOffers.submittedOn', {
              date: formatDetailDate(order.createdAt, locale),
            })}
          </p>
          {statusHistory.length > 0 ? (
            <div className="admin-card mt-3 rounded-2xl border border-slate-200/80 px-3 py-3 shadow-sm dark:border-slate-700">
              <OrderStatusHistoryStrip entries={statusHistory} locale={locale} />
            </div>
          ) : null}
        </div>

        <div className="flex flex-wrap items-center gap-2 print:hidden">
          <button
            type="button"
            onClick={() => window.print()}
            className="admin-border inline-flex h-10 items-center gap-1.5 rounded-xl border bg-white px-3 text-xs font-bold text-slate-600 transition hover:bg-slate-50"
          >
            {t('reqsOffers.print')}
          </button>
          <button
            type="button"
            onClick={() => window.print()}
            className="admin-border inline-flex h-10 items-center gap-1.5 rounded-xl border bg-white px-3 text-xs font-bold text-slate-600 transition hover:bg-slate-50"
          >
            {t('reqsOffers.downloadPdf')}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-5 xl:grid-cols-[minmax(0,1fr)_minmax(260px,300px)]">
        <div className="space-y-5">
          {(canSetCustomRequestStatus || canMarkReceived) && (
            <section className="admin-card rounded-2xl p-5 shadow-sm print:hidden">
              <h3 className="admin-text text-start text-sm font-bold">
                {t('orders.customStatusTitle')}
              </h3>
              <p className="admin-text-muted mt-1 text-start text-xs">
                {t('orders.customStatusHint')}
              </p>
              {canSetCustomRequestStatus ? (
                <>
                  <div className="mt-3">
                    <label className="block text-start">
                      <span className="admin-text-subtle text-xs">
                        {t('orders.customStatusName')}
                      </span>
                      <input
                        type="text"
                        value={customStatusText}
                        onChange={(e) => setCustomStatusText(e.target.value)}
                        className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm"
                      />
                    </label>
                  </div>
                  <div className="mt-3 flex flex-wrap gap-2">
                    <button
                      type="button"
                      disabled={isBusy}
                      onClick={submitCustomStatus}
                      className="inline-flex h-9 items-center rounded-lg bg-[#3B7FC7] px-4 text-xs font-semibold text-white disabled:opacity-60"
                    >
                      {isSettingCustomStatus
                        ? t('orders.customStatusSubmitting')
                        : t('orders.customStatusSubmit')}
                    </button>
                    {canMarkReceived ? (
                      <button
                        type="button"
                        disabled={isBusy}
                        onClick={() => setConfirmMarkReceived(true)}
                        className="inline-flex h-9 items-center rounded-lg bg-emerald-600 px-4 text-xs font-semibold text-white disabled:opacity-60"
                      >
                        {isMarkingReceived
                          ? t('orders.markReceivedSubmitting')
                          : t('orders.markReceived')}
                      </button>
                    ) : null}
                  </div>
                </>
              ) : canMarkReceived ? (
                <button
                  type="button"
                  disabled={isBusy}
                  onClick={() => setConfirmMarkReceived(true)}
                  className="mt-3 inline-flex h-9 items-center rounded-lg bg-emerald-600 px-4 text-xs font-semibold text-white disabled:opacity-60"
                >
                  {isMarkingReceived
                    ? t('orders.markReceivedSubmitting')
                    : t('orders.markReceived')}
                </button>
              ) : null}
            </section>
          )}

          {/* Supplier offer card */}
          <section className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
            <div className="flex flex-col gap-5 lg:flex-row lg:items-start">
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-start gap-3">
                  <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-slate-100 text-sm font-bold text-slate-600">
                    {supplierInitials}
                  </span>
                  <div className="min-w-0 text-start">
                    <div className="flex flex-wrap items-center gap-2">
                      <h2 className="admin-text text-lg font-bold">{order.supplierName}</h2>
                      {order.isAdminApproved ? (
                        <span className="inline-flex rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] font-bold text-emerald-700">
                          {t('reqsOffers.verifiedSupplier')}
                        </span>
                      ) : null}
                    </div>
                    <p className="admin-text-muted mt-1 text-xs">
                      {[order.supplierPhone, order.supplierEmail].filter(Boolean).join(' · ') ||
                        '—'}
                    </p>
                  </div>
                </div>

                <div className="mt-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                  <div className="admin-surface-muted rounded-xl px-3 py-3 text-start">
                    <p className="admin-text-subtle text-[10px] font-semibold uppercase">
                      {t('reqsOffers.offeredQuantity')}
                    </p>
                    <p className="admin-text mt-1 text-sm font-bold">
                      {formatOrderQuantityWithUnit(offeredQuantity, order.unitName)}
                      {extraQuantity > 0 ? (
                        <span className="ms-1 text-[11px] font-bold text-emerald-600">
                          +{formatOrderQuantityWithUnit(extraQuantity, order.unitName)}
                        </span>
                      ) : null}
                    </p>
                  </div>
                  <div className="admin-surface-muted rounded-xl px-3 py-3 text-start">
                    <p className="admin-text-subtle text-[10px] font-semibold uppercase">
                      {t('reqsOffers.unitPrice')}
                    </p>
                    <p className="admin-text mt-1 text-sm font-bold">
                      {formatAdAmount(unitPrice, locale)}
                      {order.unitName ? (
                        <span className="admin-text-muted text-xs font-medium">
                          {' '}
                          / {order.unitName}
                        </span>
                      ) : null}
                    </p>
                  </div>
                  <div className="admin-surface-muted rounded-xl px-3 py-3 text-start">
                    <p className="admin-text-subtle text-[10px] font-semibold uppercase">
                      {t('reqsOffers.totalAmount')}
                    </p>
                    <p className="mt-1 text-sm font-bold text-emerald-600">
                      {formatAdAmount(grandTotal, locale)}
                    </p>
                  </div>
                  <div className="admin-surface-muted rounded-xl px-3 py-3 text-start">
                    <p className="admin-text-subtle text-[10px] font-semibold uppercase">
                      {t('orders.orderDate')}
                    </p>
                    <p className="admin-text mt-1 text-sm font-bold">
                      {formatDetailDate(order.createdAt, locale)}
                    </p>
                  </div>
                </div>
              </div>

              <div className="flex w-full shrink-0 flex-col gap-2 lg:w-44 print:hidden">
                {order.supplierEmail || order.supplierPhone || order.supplierUserId ? (
                  <button
                    type="button"
                    onClick={openSupplierContact}
                    className="keep-white inline-flex h-10 items-center justify-center rounded-xl bg-[#2563eb] px-3 text-xs font-bold text-white transition hover:bg-[#1d4ed8]"
                  >
                    {t('reqsOffers.contactSupplier')}
                  </button>
                ) : null}
                {order.supplierPhone ? (
                  <a
                    href={`tel:${order.supplierPhone}`}
                    className="admin-border inline-flex h-10 items-center justify-center rounded-xl border bg-white px-3 text-xs font-bold text-slate-600 transition hover:bg-slate-50"
                    dir="ltr"
                  >
                    {order.supplierPhone}
                  </a>
                ) : null}
              </div>
            </div>
          </section>

          {/* Tabs */}
          <div className="admin-border flex flex-wrap gap-1 border-b print:hidden">
            {tabs.map((tab) => (
              <button
                key={tab.key}
                type="button"
                onClick={() => setActiveTab(tab.key)}
                className={`rounded-t-lg px-3 py-2.5 text-xs font-bold transition sm:px-4 ${
                  activeTab === tab.key
                    ? 'border-b-2 border-[#2563eb] text-[#2563eb]'
                    : 'admin-text-muted hover:text-slate-700'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {activeTab === 'details' || activeTab === 'activity' ? (
            <div className="grid gap-4 lg:grid-cols-2">
              {(activeTab === 'details' || activeTab === 'activity') && activeTab === 'details' ? (
                <>
                  <section className="admin-card rounded-2xl p-5 shadow-sm">
                    <h3 className="admin-text mb-3 flex items-center gap-2 text-start text-base font-bold">
                      <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-[#EFF6FF] text-[#2563eb]">
                        <svg
                          className="h-4 w-4"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                          strokeWidth={2.2}
                          aria-hidden
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            d="M9 12h6m-6 4h6m2 5H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5.586a1 1 0 0 1 .707.293l5.414 5.414a1 1 0 0 1 .293.707V19a2 2 0 0 1-2 2Z"
                          />
                        </svg>
                      </span>
                      {t('reqsOffers.offerSummary')}
                    </h3>
                    <SummaryRow
                      label={t('reqsOffers.offeredQuantity')}
                      value={formatOrderQuantityWithUnit(offeredQuantity, order.unitName)}
                    />
                    <SummaryRow
                      label={t('reqsOffers.requiredQuantity')}
                      value={formatOrderQuantityWithUnit(requiredQuantity, order.unitName)}
                    />
                    <SummaryRow
                      label={t('reqsOffers.extraQuantity')}
                      value={
                        extraQuantity > 0
                          ? formatOrderQuantityWithUnit(extraQuantity, order.unitName)
                          : '—'
                      }
                    />
                    <SummaryRow
                      label={t('reqsOffers.unitPrice')}
                      value={formatAdAmount(unitPrice, locale)}
                    />
                    <SummaryRow label={t('reqsOffers.subtotal')} value={formatAdAmount(subtotal, locale)} />
                    <SummaryRow label={t('orders.vatAmount')} value={vatAmount} />
                    <SummaryRow
                      label={`${t('orders.appProfitAmount')} (${order.commissionPercent.toFixed(1)}%)`}
                      value={appProfit}
                    />
                    <SummaryRow
                      label={t('orders.grandTotal')}
                      value={formatAdAmount(grandTotal, locale)}
                      emphasize
                    />
                  </section>

                  <section className="admin-card rounded-2xl p-5 shadow-sm">
                    <h3 className="admin-text mb-3 text-start text-sm font-bold">
                      {t('reqsOffers.offerInformation')}
                    </h3>
                    <div className="grid gap-4 sm:grid-cols-2">
                      <InfoGridItem
                        label={t('ads.originCountry')}
                        value={order.originCountryName?.trim() || '—'}
                      />
                      <InfoGridItem
                        label={t('orders.paymentMethod')}
                        value={paymentLabel(order.paymentMethodName, t)}
                      />
                      <InfoGridItem
                        label={t('ads.loadingPort')}
                        value={order.loadingPortName?.trim() || order.portName?.trim() || '—'}
                      />
                      <InfoGridItem
                        label={t('ads.arrivalPort')}
                        value={order.arrivalPortName?.trim() || '—'}
                      />
                      <InfoGridItem
                        label={t('ads.shippingDuration')}
                        value={order.shippingDuration?.trim() || '—'}
                      />
                      <InfoGridItem label={t('ads.adType')} value={typeName} />
                    </div>
                    {order.notes?.trim() ? (
                      <div className="mt-4 rounded-xl bg-emerald-50 px-3 py-3 text-start dark:bg-emerald-950/30">
                        <p className="text-[10px] font-bold uppercase text-emerald-700">
                          {t('reqsOffers.supplierRemarks')}
                        </p>
                        <p className="mt-1 text-sm font-medium text-emerald-900 dark:text-emerald-200">
                          {order.notes}
                        </p>
                      </div>
                    ) : null}
                  </section>
                </>
              ) : null}

              {activeTab === 'details' ? (
                <>
                  {photoPaths.length > 0 ? (
                    <section className="admin-card rounded-2xl p-5 shadow-sm lg:col-span-2">
                      <h3 className="admin-text mb-3 text-start text-sm font-bold">
                        {t('reqsOffers.productPhotos')}
                      </h3>
                      <div className="flex flex-wrap gap-2">
                        {photoPaths.map((path) => {
                          const url = resolveAssetUrl(path)
                          return url ? (
                            <a
                              key={path}
                              href={url}
                              target="_blank"
                              rel="noreferrer"
                              className="block h-14 w-14 overflow-hidden rounded-lg ring-1 ring-slate-200"
                            >
                              <img src={url} alt="" className="h-full w-full object-cover" />
                            </a>
                          ) : null
                        })}
                      </div>
                    </section>
                  ) : null}

                  <section className="admin-card rounded-2xl p-5 shadow-sm">
                    <h3 className="admin-text mb-3 text-start text-sm font-bold">
                      {t('reqsOffers.priceBreakdown')}
                    </h3>
                    <table className="w-full text-sm">
                      <tbody>
                        {[
                          { label: t('reqsOffers.subtotal'), value: formatAdAmount(subtotal, locale) },
                          { label: t('orders.vatAmount'), value: vatAmount },
                          { label: t('orders.appProfitAmount'), value: appProfit },
                          {
                            label: t('orders.grandTotal'),
                            value: formatAdAmount(grandTotal, locale),
                            bold: true,
                          },
                        ].map((row) => (
                          <tr
                            key={row.label}
                            className="border-b border-slate-100 last:border-0 dark:border-slate-700/60"
                          >
                            <td
                              className={`py-2.5 text-start ${
                                row.bold ? 'font-bold text-emerald-700' : 'admin-text-muted'
                              }`}
                            >
                              {row.label}
                            </td>
                            <td
                              className={`py-2.5 text-end font-semibold ${
                                row.bold ? 'text-emerald-600' : 'admin-text'
                              }`}
                            >
                              {row.value}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </section>
                </>
              ) : null}

              <section
                className={`admin-card rounded-2xl p-5 shadow-sm ${
                  activeTab === 'activity' ? 'lg:col-span-2' : ''
                }`}
              >
                <h3 className="admin-text mb-3 text-start text-sm font-bold">
                  {t('orders.statusHistoryTitle')}
                </h3>
                {statusHistory.length === 0 ? (
                  <p className="admin-text-muted text-sm">{t('reqsOffers.noActivityYet')}</p>
                ) : (
                  <ol className="space-y-3">
                    {statusHistory.map((entry, index) => {
                      const label =
                        locale === 'ar'
                          ? entry.statusNameAr.trim() || entry.statusNameEn
                          : entry.statusNameEn.trim() || entry.statusNameAr
                      const isLatest = index === statusHistory.length - 1
                      return (
                        <li key={entry.id || `${entry.createdAtUtc}-${index}`} className="flex gap-3">
                          <span
                            className={`mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full ${
                              isLatest
                                ? 'bg-emerald-500 text-white'
                                : 'bg-emerald-100 text-emerald-700'
                            }`}
                          >
                            <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                              <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                            </svg>
                          </span>
                          <div className="min-w-0 text-start">
                            <p className="admin-text text-sm font-bold">{label}</p>
                            <p className="admin-text-muted text-[11px]">
                              {formatDetailDate(entry.createdAtUtc, locale)}
                            </p>
                          </div>
                        </li>
                      )
                    })}
                  </ol>
                )}
                {order.notes?.trim() && activeTab === 'details' ? (
                  <div className="admin-border mt-4 border-t pt-3 text-start">
                    <p className="admin-text-subtle text-[10px] font-bold uppercase">
                      {t('orders.orderNotes')}
                    </p>
                    <p className="admin-text mt-1 text-sm">{order.notes}</p>
                  </div>
                ) : null}
              </section>
            </div>
          ) : null}

          {activeTab === 'photos' ? (
            <section className="admin-card rounded-2xl p-5 shadow-sm">
              <h3 className="admin-text mb-3 text-start text-sm font-bold">
                {t('reqsOffers.productPhotos')}
              </h3>
              {photoPaths.length === 0 ? (
                <p className="admin-text-muted text-sm">{t('orders.noImages')}</p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {photoPaths.map((path) => {
                    const url = resolveAssetUrl(path)
                    return url ? (
                      <a
                        key={path}
                        href={url}
                        target="_blank"
                        rel="noreferrer"
                        className="h-14 w-14 overflow-hidden rounded-lg ring-1 ring-slate-200"
                      >
                        <img src={url} alt="" className="h-full w-full object-cover" />
                      </a>
                    ) : null
                  })}
                </div>
              )}
              {order.videoPaths?.length ? (
                <div className="mt-4 space-y-2">
                  <p className="admin-text text-sm font-bold">{t('orders.videos')}</p>
                  {order.videoPaths.map((path) => (
                    <a
                      key={path}
                      href={resolveAssetUrl(path)}
                      target="_blank"
                      rel="noreferrer"
                      className="block text-sm font-semibold text-[#2563eb]"
                    >
                      {fileNameFromPath(path)}
                    </a>
                  ))}
                </div>
              ) : null}
            </section>
          ) : null}

          {activeTab === 'shipping' ? (
            <section className="admin-card rounded-2xl p-5 shadow-sm">
              <h3 className="admin-text mb-3 text-start text-sm font-bold">
                {t('ads.shippingDetails')}
              </h3>
              <ProductShippingPanel
                shipping={{
                  originCountryName: order.originCountryName,
                  destinationCountryName: order.destinationCountryName,
                  loadingPortName: order.loadingPortName,
                  arrivalPortName: order.arrivalPortName,
                  shippingDescription: order.shippingDescription,
                  shippingRouteSummary: order.shippingRouteSummary,
                  shippingDuration: order.shippingDuration,
                  productAddress: order.productAddress,
                  orderPortName: order.portName,
                }}
                showOrderPort
              />
            </section>
          ) : null}

          {activeTab === 'documents' ? (
            <section className="admin-card rounded-2xl p-5 shadow-sm">
              <h3 className="admin-text mb-3 text-start text-sm font-bold">
                {t('reqsOffers.offerTabDocuments')}
              </h3>
              {documentPaths.length === 0 ? (
                <p className="admin-text-muted text-sm">{t('orders.noDocuments')}</p>
              ) : (
                <ul className="space-y-2">
                  {documentPaths.map((path) => (
                    <li key={path}>
                      <a
                        href={resolveAssetUrl(path)}
                        target="_blank"
                        rel="noreferrer"
                        className="admin-surface-muted flex items-center justify-between gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold text-[#2563eb]"
                      >
                        <span className="truncate" dir="ltr">
                          {fileNameFromPath(path)}
                        </span>
                        <span className="text-xs">{t('orders.openFile')}</span>
                      </a>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          ) : null}

          {activeTab === 'conversation' ? (
            <section className="admin-card rounded-2xl px-5 py-10 text-center shadow-sm">
              <p className="admin-text text-sm font-semibold">
                {t('reqsOffers.conversationEmpty')}
              </p>
              {order.supplierEmail || order.supplierPhone || order.supplierUserId ? (
                <button
                  type="button"
                  onClick={openSupplierContact}
                  className="mt-4 inline-flex h-10 items-center rounded-xl bg-[#2563eb] px-4 text-xs font-bold text-white"
                >
                  {t('reqsOffers.contactSupplier')}
                </button>
              ) : null}
            </section>
          ) : null}
        </div>

        {/* Sidebar */}
        <aside className="space-y-4 print:hidden">
          <SidebarCard title={t('reqsOffers.requestOverview')}>
            <div className="space-y-3 text-start">
              <div className="flex gap-3">
                {requestImageUrl ? (
                  <img
                    src={requestImageUrl}
                    alt=""
                    className="h-14 w-14 rounded-xl object-cover ring-1 ring-slate-200"
                  />
                ) : (
                  <span className="flex h-14 w-14 items-center justify-center rounded-xl bg-slate-100 text-slate-400">
                    —
                  </span>
                )}
                <div className="min-w-0">
                  <p className="admin-text text-sm font-bold">{order.productName}</p>
                  <span
                    className={`mt-1 inline-flex rounded-md px-2 py-0.5 text-[10px] font-bold ${productTypeBadgeClass(resolveOrderChannelTypeKey(order))}`}
                  >
                    {typeName}
                  </span>
                </div>
              </div>
              <dl className="space-y-2 text-xs">
                <div className="flex justify-between gap-2">
                  <dt className="admin-text-muted">{t('reqsOffers.requiredQuantity')}</dt>
                  <dd className="admin-text font-semibold">
                    {formatOrderQuantityWithUnit(requiredQuantity, order.unitName)}
                  </dd>
                </div>
                <div className="flex justify-between gap-2">
                  <dt className="admin-text-muted">{t('ads.requestFulfillment')}</dt>
                  <dd className="admin-text font-semibold">{fulfillmentLabel}</dd>
                </div>
                <div className="flex justify-between gap-2">
                  <dt className="admin-text-muted">{t('ads.category')}</dt>
                  <dd className="admin-text font-semibold">{order.categoryName || '—'}</dd>
                </div>
              </dl>
              {order.productId ? (
                <Link
                  to={`/ads/${order.productId}`}
                  state={{ from: '/reqs-offers' }}
                  className="inline-flex text-xs font-bold text-[#2563eb] hover:underline"
                >
                  {t('reqsOffers.viewRequestDetails')}
                </Link>
              ) : null}
            </div>
          </SidebarCard>

          <SidebarCard title={t('reqsOffers.requesterBuyer')}>
            <div className="space-y-3 text-start">
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-[#eff6ff] text-xs font-bold text-[#2563eb]">
                  {buyerInitials}
                </span>
                <div>
                  <p className="admin-text text-sm font-bold">{buyerLabel}</p>
                </div>
              </div>
              <p className="admin-text text-sm" dir="ltr">
                {order.customerPhone?.trim() || '—'}
              </p>
              <p className="admin-text break-all text-sm">{order.customerEmail || '—'}</p>
              {order.customerEmail ? (
                <a
                  href={`mailto:${order.customerEmail}`}
                  className="inline-flex text-xs font-bold text-[#2563eb] hover:underline"
                >
                  {t('reqsOffers.contactBuyer')}
                </a>
              ) : null}
            </div>
          </SidebarCard>

          <section className="admin-card space-y-2 rounded-2xl p-4 shadow-sm">
            <p className="admin-text mb-1 text-sm font-bold">{t('reqsOffers.requestActions')}</p>
            {needsAdminModeration ? (
              <>
                <button
                  type="button"
                  disabled={isBusy}
                  onClick={() => setPendingRequestOfferAction('approve')}
                  className="keep-white inline-flex h-11 w-full items-center justify-center gap-2 rounded-xl bg-[#619D51] text-sm font-bold text-white transition hover:bg-[#528a45] disabled:opacity-60"
                >
                  {isApprovingOffer
                    ? t('approving')
                    : t('orders.requestOfferApprove')}
                </button>
                <button
                  type="button"
                  disabled={isBusy}
                  onClick={() => setPendingRequestOfferAction('reject')}
                  className="inline-flex h-11 w-full items-center justify-center gap-2 rounded-xl bg-[#ef4444] text-sm font-bold text-white transition hover:bg-[#dc2626] disabled:opacity-60"
                >
                  {isRejectingOffer
                    ? t('ads.rejecting')
                    : t('orders.requestOfferReject')}
                </button>
              </>
            ) : (
              <p className="admin-text-muted py-2 text-center text-xs">
                {order.isAdminApproved
                  ? t('reqsOffers.adminApproved')
                  : statusLabel}
              </p>
            )}
            {order.supplierEmail || order.supplierPhone || order.supplierUserId ? (
              <button
                type="button"
                onClick={openSupplierContact}
                className="admin-border inline-flex h-11 w-full items-center justify-center gap-2 rounded-xl border bg-white text-sm font-bold text-slate-700 transition hover:bg-slate-50"
              >
                {t('reqsOffers.startNegotiation')}
              </button>
            ) : null}
            {canMarkReceived ? (
              <button
                type="button"
                disabled={isBusy}
                onClick={() => setConfirmMarkReceived(true)}
                className="inline-flex h-11 w-full items-center justify-center rounded-xl bg-emerald-600 text-sm font-bold text-white disabled:opacity-60"
              >
                {t('orders.markReceived')}
              </button>
            ) : null}
          </section>
        </aside>
      </div>

      <ConfirmDialog
        open={pendingRequestOfferAction != null}
        title={
          pendingRequestOfferAction === 'approve'
            ? t('orders.requestOfferApproveConfirmTitle')
            : t('orders.requestOfferRejectConfirmTitle')
        }
        message={
          pendingRequestOfferAction === 'approve'
            ? t('orders.requestOfferApproveConfirmMessage')
            : t('orders.requestOfferRejectConfirmMessage')
        }
        confirmLabel={t('orders.statusChangeConfirmAction')}
        cancelLabel={t('cancel')}
        danger={pendingRequestOfferAction === 'reject'}
        busy={isApprovingOffer || isRejectingOffer}
        onConfirm={() =>
          submitRequestOfferDecision(pendingRequestOfferAction === 'approve')
        }
        onCancel={() => {
          if (!isApprovingOffer && !isRejectingOffer) setPendingRequestOfferAction(null)
        }}
      />

      <ConfirmDialog
        open={confirmMarkReceived}
        title={t('orders.markReceivedConfirmTitle')}
        message={t('orders.markReceivedConfirmMessage')}
        confirmLabel={t('orders.markReceived')}
        cancelLabel={t('cancel')}
        busy={isMarkingReceived}
        onConfirm={submitMarkReceived}
        onCancel={() => {
          if (!isMarkingReceived) setConfirmMarkReceived(false)
        }}
      />

      <ContactSupplierDialog
        open={contactTarget != null}
        target={contactTarget}
        onClose={() => setContactTarget(null)}
      />
    </div>
  )
}
