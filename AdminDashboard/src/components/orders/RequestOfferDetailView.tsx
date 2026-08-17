import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { resolveAssetUrl } from '../../lib/assets'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import {
  useApproveRequestOfferMutation,
  useSetRequestOfferAdvertiserPriceMutation,
  useDeleteAdminProductVideoMutation,
  useDeleteOrderImageMutation,
  useDeleteOrderVideoMutation,
  useMarkOrderReceivedMutation,
  useRejectRequestOfferMutation,
  useSetCustomOrderStatusMutation,
  useUploadAdminProductVideoMutation,
  useUploadOrderImageMutation,
  useUploadOrderVideoMutation,
} from '../../store'
import { adminApi } from '../../store/adminApi'
import { useAppDispatch } from '../../store/hooks'
import type { AdminOrder } from '../../types/adminOrder'
import AdminImageBlurModal from '../shared/AdminImageBlurModal'
import AdminVideoTrimModal from '../shared/AdminVideoTrimModal'
import ProductVideosPanel from '../ads/ProductVideosPanel'
import ProductShippingPanel from '../shared/ProductShippingPanel'
import ContactSupplierDialog, {
  type ContactTarget,
} from '../shared/ContactSupplierDialog'
import WhatsAppPhoneLink from '../shared/WhatsAppPhoneLink'
import ConfirmDialog from '../ui/ConfirmDialog'
import { getRtkErrorMessage } from '../../utils/rtkError'
import OrderStatusHistoryStrip from './OrderStatusHistoryStrip'
import RelatedOrdersBanner from './RelatedOrdersBanner'
import CancelOrderDialog from './CancelOrderDialog'
import OrderCancellationDetails from './OrderCancellationDetails'
import ProductDetailsDialog from './ProductDetailsDialog'
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
import { formatRelativeTime } from '../../utils/timeAgo'
import { formatUtcDateTime } from '../../utils/formatTimeAgo'
import {
  canMarkOrderReceived,
  canSetCustomTextStatus,
  canCancelOrder,
  needsAdminOrderModeration,
} from '../../utils/orderWorkflow'

type RequestOfferDetailViewProps = {
  order: AdminOrder
  isUpdating: boolean
  onCancelOrder: (payload: {
    cancellationReasonId: number
    cancellationNote?: string
  }) => void
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
  return formatUtcDateTime(value, locale)
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

function defaultAdvertiserUnitPrice(order: AdminOrder): string {
  if (order.hasAdminAdvertiserPrice && (order.adminAdvertiserUnitPrice ?? 0) > 0) {
    return String(order.adminAdvertiserUnitPrice)
  }
  if (order.isBelowListingPrice && (order.listingUnitPrice ?? 0) > 0) {
    return String(order.listingUnitPrice)
  }
  if (order.customerUnitPrice > 0) {
    return String(order.customerUnitPrice)
  }
  return order.supplierUnitPrice > 0 ? String(order.supplierUnitPrice) : ''
}

function parseAdvertiserUnitPrice(value: string): number | null {
  const parsed = Number(value.trim().replace(',', '.'))
  if (!Number.isFinite(parsed) || parsed <= 0) return null
  return parsed
}

export default function RequestOfferDetailView({
  order,
  isUpdating,
  onCancelOrder,
  backToListPath,
}: RequestOfferDetailViewProps) {
  const { t, locale } = useAppPreferences()
  const dispatch = useAppDispatch()
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
  const [cancelDialogOpen, setCancelDialogOpen] = useState(false)
  const [contactTarget, setContactTarget] = useState<ContactTarget | null>(null)
  const [blurTarget, setBlurTarget] = useState<{ id: number; url: string } | null>(null)
  const [blurError, setBlurError] = useState<string | null>(null)
  const [blurSuccess, setBlurSuccess] = useState<string | null>(null)
  const [deletingImageId, setDeletingImageId] = useState<number | null>(null)
  const [deletingVideoPath, setDeletingVideoPath] = useState<string | null>(null)
  const [trimTarget, setTrimTarget] = useState<{
    path: string
    orderVideoId?: number
    source: 'order' | 'product'
    durationSeconds?: number | null
  } | null>(null)
  const queuedTrimRef = useRef<{
    path: string
    orderVideoId?: number
    source: 'order' | 'product'
    durationSeconds?: number | null
  } | null>(null)
  const [backgroundTrimPath, setBackgroundTrimPath] = useState<string | null>(null)
  const [selectedVideoIndex, setSelectedVideoIndex] = useState(0)
  const [showProductDetails, setShowProductDetails] = useState(false)
  const [advertiserUnitPrice, setAdvertiserUnitPrice] = useState(() =>
    defaultAdvertiserUnitPrice(order),
  )

  const [approveRequestOffer, { isLoading: isApprovingOffer }] =
    useApproveRequestOfferMutation()
  const [setAdvertiserPrice, { isLoading: isSavingAdvertiserPrice }] =
    useSetRequestOfferAdvertiserPriceMutation()
  const [rejectRequestOffer, { isLoading: isRejectingOffer }] =
    useRejectRequestOfferMutation()
  const [setCustomOrderStatus, { isLoading: isSettingCustomStatus }] =
    useSetCustomOrderStatusMutation()
  const [markOrderReceived, { isLoading: isMarkingReceived }] =
    useMarkOrderReceivedMutation()
  const [uploadOrderImage, { isLoading: isUploadingBlur }] = useUploadOrderImageMutation()
  const [deleteOrderImage, { isLoading: isDeletingBlur }] = useDeleteOrderImageMutation()
  const [uploadOrderVideo, { isLoading: isUploadingOrderVideo }] =
    useUploadOrderVideoMutation()
  const [deleteOrderVideo, { isLoading: isDeletingOrderVideo }] =
    useDeleteOrderVideoMutation()
  const [uploadProductVideo, { isLoading: isUploadingProductVideo }] =
    useUploadAdminProductVideoMutation()
  const [deleteProductVideo, { isLoading: isDeletingProductVideo }] =
    useDeleteAdminProductVideoMutation()

  const status = getOrderStatusStyle(order.statusId)
  const statusLabel =
    locale === 'ar'
      ? order.statusLabelAr?.trim() || getOrderStatusLabel(order.statusId, locale)
      : order.statusName?.trim() || getOrderStatusLabel(order.statusId, locale)

  const needsAdminModeration = needsAdminOrderModeration(order)
  const canCancel = canCancelOrder(order) && !needsAdminModeration
  const canSetCustomRequestStatus = canSetCustomTextStatus(order)
  const canMarkReceived = canMarkOrderReceived(order)
  const statusHistory = order.statusHistory ?? []
  const isReplacingImage = isUploadingBlur || isDeletingBlur
  const isTrimmingVideo = isUploadingOrderVideo || isUploadingProductVideo
  const isDeletingVideo = isDeletingOrderVideo || isDeletingProductVideo
  const trimmingVideoPath = backgroundTrimPath
  const isBusy =
    isUpdating ||
    isApprovingOffer ||
    isSavingAdvertiserPrice ||
    isRejectingOffer ||
    isSettingCustomStatus ||
    isMarkingReceived ||
    isReplacingImage ||
    isTrimmingVideo ||
    isDeletingVideo ||
    deletingImageId != null

  const requiredQuantity = resolveRequiredQuantity(order)
  const offeredQuantity = resolveOfferedQuantity(order)
  const extraQuantity = Math.max(0, offeredQuantity - requiredQuantity)

  const supplierUnitPrice =
    order.supplierUnitPriceFormatted?.trim() ||
    `${(order.supplierUnitPrice || 0).toFixed(2)} ${order.currency}`
  const listingUnitPrice =
    order.listingUnitPriceFormatted?.trim() ||
    ((order.listingUnitPrice ?? 0) > 0
      ? `${order.listingUnitPrice!.toFixed(2)} ${order.currency}`
      : '')
  const unitPrice =
    order.adminAdvertiserUnitPriceFormatted?.trim() ||
    order.customerUnitPriceFormatted?.trim() ||
    (order.customerUnitPrice > 0
      ? `${order.customerUnitPrice.toFixed(2)} ${order.currency}`
      : supplierUnitPrice)

  useEffect(() => {
    setAdvertiserUnitPrice(defaultAdvertiserUnitPrice(order))
  }, [
    order.id,
    order.hasAdminAdvertiserPrice,
    order.adminAdvertiserUnitPrice,
    order.isBelowListingPrice,
    order.listingUnitPrice,
    order.customerUnitPrice,
    order.supplierUnitPrice,
  ])

  const subtotal =
    order.customerTotalPriceFormatted?.trim() ||
    `${(order.customerTotalPrice || order.totalPrice || 0).toFixed(2)} ${order.currency}`

  const vatAmount =
    order.vatAed > 0 ? formatAdAmount(`${order.vatAed.toFixed(2)} AED`, locale) : '—'
  const appProfit = formatAdAmount(
    order.appProfitFormatted || `${order.appProfitAmount.toFixed(2)} ${order.currency}`,
    locale,
  )
  const grandTotal = formatOrderAmount(order)

  const fulfillmentLabel = formatPriceTypeLabel(order.shippingDescription, t)

  const typeName = displayAdProductTypeName(
    { productTypeName: order.productTypeName, categoryName: order.categoryName },
    locale,
  )

  const supplierInitials = (order.supplierName || '—').slice(0, 2).toUpperCase()
  const buyerLabel = order.customerName?.trim() || '—'
  const buyerInitials = buyerLabel.slice(0, 2).toUpperCase()

  const photoItems = useMemo(() => {
    const byPath = new Map<string, { id?: number; path: string }>()
    for (const image of order.images) {
      if (!image.path) continue
      byPath.set(image.path, { id: image.id, path: image.path })
    }
    for (const path of order.productImagePaths ?? []) {
      if (!path || byPath.has(path)) continue
      byPath.set(path, { path })
    }
    if (order.primaryImagePath && !byPath.has(order.primaryImagePath)) {
      byPath.set(order.primaryImagePath, { path: order.primaryImagePath })
    }
    return Array.from(byPath.values())
  }, [order.images, order.productImagePaths, order.primaryImagePath])

  const videoItems = useMemo(() => {
    const byPath = new Map<
      string,
      { path: string; orderVideoId?: number; source: 'order' | 'product' }
    >()
    for (const video of order.videos ?? []) {
      if (!video.path) continue
      byPath.set(video.path, {
        path: video.path,
        orderVideoId: video.id,
        source: 'order',
      })
    }
    for (const path of order.videoPaths ?? []) {
      if (!path || byPath.has(path)) continue
      byPath.set(path, { path, source: 'product' })
    }
    return Array.from(byPath.values())
  }, [order.videos, order.videoPaths])

  const panelVideos = useMemo(
    () => videoItems.map((item) => ({ path: item.path, isMuted: true })),
    [videoItems],
  )

  function invalidateOrderDetail() {
    dispatch(adminApi.util.invalidateTags([{ type: 'Orders', id: String(order.id) }]))
  }

  async function handleDeleteImage(imageId: number) {
    if (!window.confirm(t('orders.deleteImageConfirm'))) return
    setBlurError(null)
    setBlurSuccess(null)
    setDeletingImageId(imageId)
    try {
      await deleteOrderImage({ orderId: order.id, imageId }).unwrap()
      setBlurSuccess(t('orders.imageDeleteSuccess'))
    } catch (err) {
      setBlurError(getRtkErrorMessage(err as never, t('orders.imageDeleteError')))
    } finally {
      setDeletingImageId(null)
    }
  }

  async function handleDeleteVideo(path: string) {
    if (!window.confirm(`${t('ads.deleteVideo')}?`)) return
    const item = videoItems.find((video) => video.path === path)
    if (!item) return

    setBlurError(null)
    setBlurSuccess(null)
    setDeletingVideoPath(path)
    try {
      if (item.source === 'order' && item.orderVideoId) {
        await deleteOrderVideo({ orderId: order.id, videoId: item.orderVideoId }).unwrap()
      } else {
        await deleteProductVideo({ productId: order.productId, path }).unwrap()
        invalidateOrderDetail()
      }
      setBlurSuccess(t('ads.deleteVideoSuccess'))
    } catch (err) {
      setBlurError(getRtkErrorMessage(err as never, t('ads.deleteVideoError')))
    } finally {
      setDeletingVideoPath(null)
    }
  }

  function openTrimVideo(path: string) {
    if (backgroundTrimPath) return
    const item = videoItems.find((video) => video.path === path)
    if (!item) return
    setBlurError(null)
    setBlurSuccess(null)
    setTrimTarget({
      path: item.path,
      orderVideoId: item.orderVideoId,
      source: item.source,
    })
  }

  function handleTrimQueued() {
    queuedTrimRef.current = trimTarget
    setBackgroundTrimPath(trimTarget?.path ?? null)
    setBlurError(null)
    setBlurSuccess(t('ads.trimVideoProcessing'))
  }

  function handleTrimFailed(message: string) {
    queuedTrimRef.current = null
    setBackgroundTrimPath(null)
    setBlurSuccess(null)
    setBlurError(message)
  }

  async function handleTrimSave(file: File, durationSeconds: number) {
    const target = queuedTrimRef.current
    if (!target) return
    setBlurError(null)
    try {
      if (target.source === 'order' && target.orderVideoId) {
        await uploadOrderVideo({ orderId: order.id, file }).unwrap()
        await deleteOrderVideo({
          orderId: order.id,
          videoId: target.orderVideoId,
        }).unwrap()
      } else {
        await uploadProductVideo({
          productId: order.productId,
          file,
          videoDurationSeconds: durationSeconds,
          replaceVideoPath: target.path,
        }).unwrap()
        invalidateOrderDetail()
      }
      setBlurSuccess(t('ads.trimVideoSaveSuccess'))
    } catch (err) {
      setBlurSuccess(null)
      setBlurError(getRtkErrorMessage(err as never, t('ads.trimVideoSaveError')))
    } finally {
      queuedTrimRef.current = null
      setBackgroundTrimPath(null)
    }
  }

  async function handleBlurSave(file: File) {
    if (!blurTarget) return
    setBlurError(null)
    setBlurSuccess(null)
    try {
      await uploadOrderImage({ orderId: order.id, file }).unwrap()
      await deleteOrderImage({ orderId: order.id, imageId: blurTarget.id }).unwrap()
      setBlurTarget(null)
      setBlurSuccess(t('ads.blurSaveSuccess'))
    } catch (err) {
      setBlurError(getRtkErrorMessage(err as never, t('ads.blurSaveError')))
      throw err
    }
  }

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
    if (approved) {
      const unit = parseAdvertiserUnitPrice(advertiserUnitPrice)
      if (unit == null) {
        setRequestOfferError(t('reqsOffers.advertiserPriceInvalid'))
        setPendingRequestOfferAction(null)
        return
      }
      setPendingRequestOfferAction(null)
      void approveRequestOffer({ orderId: order.id, adminUnitPrice: unit })
        .unwrap()
        .then(() => {
          setRequestOfferSuccess(t('orders.requestOfferApproveSuccess'))
        })
        .catch((err: { data?: { message?: string } }) => {
          setRequestOfferError(err?.data?.message ?? t('orders.requestOfferActionError'))
        })
      return
    }

    setPendingRequestOfferAction(null)
    void rejectRequestOffer({ orderId: order.id })
      .unwrap()
      .then(() => {
        setRequestOfferSuccess(t('orders.requestOfferRejectSuccess'))
      })
      .catch((err: { data?: { message?: string } }) => {
        setRequestOfferError(err?.data?.message ?? t('orders.requestOfferActionError'))
      })
  }

  function saveAdvertiserPrice() {
    const unit = parseAdvertiserUnitPrice(advertiserUnitPrice)
    setRequestOfferError(null)
    setRequestOfferSuccess(null)
    if (unit == null) {
      setRequestOfferError(t('reqsOffers.advertiserPriceInvalid'))
      return
    }
    void setAdvertiserPrice({ orderId: order.id, adminUnitPrice: unit })
      .unwrap()
      .then(() => {
        setRequestOfferSuccess(t('reqsOffers.advertiserPriceSaved'))
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
      {blurSuccess ? (
        <div className="admin-alert-success print:hidden">{blurSuccess}</div>
      ) : null}
      {blurError ? (
        <div className="admin-alert-error print:hidden">{blurError}</div>
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
          <p className="admin-text-muted mt-1 text-xs" title={formatDetailDate(order.createdAt, locale)}>
            {t('reqsOffers.submittedOn', {
              date: formatRelativeTime(order.createdAt, locale),
            })}
          </p>
          {(order.relatedOrders?.length ?? 0) > 0 ? (
            <div className="mt-3 print:hidden">
              <RelatedOrdersBanner relatedOrders={order.relatedOrders} />
            </div>
          ) : null}
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
          {canCancel ? (
            <button
              type="button"
              disabled={isUpdating}
              onClick={() => setCancelDialogOpen(true)}
              className="inline-flex h-10 items-center gap-1.5 rounded-xl bg-red-600 px-3 text-xs font-bold text-white transition hover:bg-red-700 disabled:opacity-60"
            >
              {t('orders.actionCancel')}
            </button>
          ) : null}
        </div>
      </div>

      <OrderCancellationDetails order={order} />

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
                    <p className="admin-text-muted mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 text-xs">
                      <WhatsAppPhoneLink phone={order.supplierPhone} className="text-xs" />
                      {order.supplierEmail ? (
                        <span className="admin-text-muted">{order.supplierEmail}</span>
                      ) : null}
                      {!order.supplierPhone?.trim() && !order.supplierEmail ? '—' : null}
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
                      {t('reqsOffers.supplierOfferPrice')}
                    </p>
                    <p className="admin-text mt-1 text-sm font-bold">
                      {formatAdAmount(supplierUnitPrice, locale)}
                      {order.unitName ? (
                        <span className="admin-text-muted text-xs font-medium">
                          {' '}
                          / {order.unitName}
                        </span>
                      ) : null}
                    </p>
                  </div>
                  {listingUnitPrice ? (
                    <div className="admin-surface-muted rounded-xl px-3 py-3 text-start">
                      <p className="admin-text-subtle text-[10px] font-semibold uppercase">
                        {t('reqsOffers.listingUnitPrice')}
                      </p>
                      <p className="admin-text mt-1 text-sm font-bold">
                        {formatAdAmount(listingUnitPrice, locale)}
                      </p>
                    </div>
                  ) : null}
                  <div className="admin-surface-muted rounded-xl px-3 py-3 text-start">
                    <p className="admin-text-subtle text-[10px] font-semibold uppercase">
                      {t('reqsOffers.advertiserPrice')}
                    </p>
                    <p className="admin-text mt-1 text-sm font-bold">
                      {formatAdAmount(unitPrice, locale)}
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
                    <p
                      className="admin-text mt-1 text-sm font-bold"
                      title={formatDetailDate(order.createdAt, locale)}
                    >
                      {formatRelativeTime(order.createdAt, locale)}
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
                  <WhatsAppPhoneLink
                    phone={order.supplierPhone}
                    className="admin-border inline-flex h-10 items-center justify-center rounded-xl border bg-white px-3 text-xs font-bold transition hover:bg-slate-50"
                  />
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
                  {photoItems.length > 0 ? (
                    <section className="admin-card rounded-2xl p-5 shadow-sm lg:col-span-2">
                      <h3 className="admin-text mb-3 text-start text-sm font-bold">
                        {t('reqsOffers.productPhotos')}
                      </h3>
                      <div className="flex flex-wrap gap-3">
                        {photoItems.map((item) => {
                          const url = resolveAssetUrl(item.path)
                          if (!url) return null
                          return (
                            <div key={item.path} className="flex flex-col items-center gap-1.5">
                              <a
                                href={url}
                                target="_blank"
                                rel="noreferrer"
                                className="block h-14 w-14 overflow-hidden rounded-lg ring-1 ring-slate-200"
                              >
                                <img src={url} alt="" className="h-full w-full object-cover" />
                              </a>
                              {typeof item.id === 'number' && item.id > 0 ? (
                                <div className="flex flex-wrap gap-1">
                                  <button
                                    type="button"
                                    disabled={isBusy}
                                    onClick={() => {
                                      setBlurError(null)
                                      setBlurSuccess(null)
                                      setBlurTarget({ id: item.id!, url })
                                    }}
                                    className="admin-border rounded-md border px-1.5 py-0.5 text-[10px] font-semibold disabled:opacity-50"
                                  >
                                    {t('ads.blurImage')}
                                  </button>
                                  <button
                                    type="button"
                                    disabled={isBusy || deletingImageId === item.id}
                                    onClick={() => void handleDeleteImage(item.id!)}
                                    className="rounded-md border border-red-200 bg-red-50 px-1.5 py-0.5 text-[10px] font-semibold text-red-700 disabled:opacity-50"
                                  >
                                    {deletingImageId === item.id
                                      ? '…'
                                      : t('orders.deleteImage')}
                                  </button>
                                </div>
                              ) : null}
                            </div>
                          )
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
              {photoItems.length === 0 ? (
                <p className="admin-text-muted text-sm">{t('orders.noImages')}</p>
              ) : (
                <div className="flex flex-wrap gap-3">
                  {photoItems.map((item) => {
                    const url = resolveAssetUrl(item.path)
                    if (!url) return null
                    return (
                      <div
                        key={item.path}
                        className="flex w-28 flex-col gap-1.5 rounded-xl ring-1 ring-slate-200 p-2 dark:ring-slate-700"
                      >
                        <a
                          href={url}
                          target="_blank"
                          rel="noreferrer"
                          className="block aspect-square overflow-hidden rounded-lg"
                        >
                          <img src={url} alt="" className="h-full w-full object-cover" />
                        </a>
                        {typeof item.id === 'number' && item.id > 0 ? (
                          <div className="flex flex-col gap-1">
                            <button
                              type="button"
                              disabled={isBusy}
                              onClick={() => {
                                setBlurError(null)
                                setBlurSuccess(null)
                                setBlurTarget({ id: item.id!, url })
                              }}
                              className="admin-border rounded-lg border px-2 py-1 text-[10px] font-semibold disabled:opacity-50"
                            >
                              {t('ads.blurImage')}
                            </button>
                            <button
                              type="button"
                              disabled={isBusy || deletingImageId === item.id}
                              onClick={() => void handleDeleteImage(item.id!)}
                              className="rounded-lg border border-red-200 bg-red-50 px-2 py-1 text-[10px] font-semibold text-red-700 disabled:opacity-50"
                            >
                              {deletingImageId === item.id
                                ? '…'
                                : t('orders.deleteImage')}
                            </button>
                          </div>
                        ) : null}
                      </div>
                    )
                  })}
                </div>
              )}
              {videoItems.length > 0 ? (
                <div className="mt-6">
                  <p className="admin-text mb-2 text-sm font-bold">{t('orders.videos')}</p>
                  <ProductVideosPanel
                    videos={panelVideos}
                    selectedIndex={selectedVideoIndex}
                    onSelectedIndexChange={setSelectedVideoIndex}
                    onMuteChange={() => {}}
                    muteLabel={t('ads.muteVideoInApp')}
                    emptyLabel={t('orders.noVideos')}
                    isBusy={isBusy}
                    className="rounded-xl ring-1 ring-slate-200 p-3 dark:ring-slate-700"
                    videoClassName="max-h-56 w-full rounded-lg bg-black"
                    onDeleteVideo={(path) => void handleDeleteVideo(path)}
                    deleteLabel={t('ads.deleteVideo')}
                    deletingPath={deletingVideoPath}
                    onTrimVideo={openTrimVideo}
                    trimLabel={t('ads.trimVideo')}
                    trimmingPath={trimmingVideoPath}
                  />
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
                  productLatitude: order.productLatitude,
                  productLongitude: order.productLongitude,
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
                  {order.productName?.trim() ? (
                    <button
                      type="button"
                      onClick={() => setShowProductDetails(true)}
                      title={t('ads.productDetails')}
                      className="admin-text text-start text-sm font-bold text-[#2563eb] underline decoration-dotted underline-offset-2 transition hover:text-[#1d4ed8]"
                    >
                      {order.productName}
                    </button>
                  ) : (
                    <p className="admin-text text-sm font-bold">—</p>
                  )}
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
              <p className="text-sm" dir="ltr">
                <WhatsAppPhoneLink phone={order.customerPhone} />
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
            {order.isBelowListingPrice ? (
              <p className="rounded-lg bg-amber-50 px-3 py-2 text-start text-xs font-semibold text-amber-800 dark:bg-amber-950/40 dark:text-amber-200">
                {t('reqsOffers.belowListingWarning')}
              </p>
            ) : null}
            <label className="block text-start">
              <span className="admin-text-subtle text-xs">{t('reqsOffers.advertiserPrice')}</span>
              <input
                type="number"
                min="0"
                step="0.01"
                value={advertiserUnitPrice}
                onChange={(e) => setAdvertiserUnitPrice(e.target.value)}
                className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm"
              />
            </label>
            <p className="admin-text-muted text-start text-[11px] leading-relaxed">
              {t('reqsOffers.advertiserPriceHint')}
            </p>
            {!needsAdminModeration ? (
              <button
                type="button"
                disabled={isBusy}
                onClick={saveAdvertiserPrice}
                className="admin-border inline-flex h-11 w-full items-center justify-center rounded-xl border bg-white text-sm font-bold text-slate-700 transition hover:bg-slate-50 disabled:opacity-60"
              >
                {isSavingAdvertiserPrice ? t('saving') : t('reqsOffers.saveAdvertiserPrice')}
              </button>
            ) : null}
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

      <CancelOrderDialog
        open={cancelDialogOpen}
        busy={isUpdating}
        onClose={() => {
          if (!isUpdating) setCancelDialogOpen(false)
        }}
        onConfirm={(payload) => {
          setCancelDialogOpen(false)
          onCancelOrder(payload)
        }}
      />

      <ProductDetailsDialog
        open={showProductDetails}
        order={order}
        onClose={() => setShowProductDetails(false)}
      />

      <ContactSupplierDialog
        open={contactTarget != null}
        target={contactTarget}
        onClose={() => setContactTarget(null)}
      />

      <AdminImageBlurModal
        open={blurTarget != null}
        imageUrl={blurTarget?.url ?? ''}
        isSaving={isReplacingImage}
        blurPx={32}
        onClose={() => setBlurTarget(null)}
        onSave={handleBlurSave}
      />

      <AdminVideoTrimModal
        open={trimTarget != null}
        videoPath={trimTarget?.path ?? ''}
        knownDurationSeconds={trimTarget?.durationSeconds}
        isSaving={isTrimmingVideo}
        onClose={() => setTrimTarget(null)}
        onQueued={handleTrimQueued}
        onFailed={handleTrimFailed}
        onSave={handleTrimSave}
      />
    </div>
  )
}
