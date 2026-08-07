import { type ReactNode, useState } from 'react'
import { Link } from 'react-router-dom'
import { resolveAssetUrl } from '../../lib/assets'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import {
  useApproveRequestOfferMutation,
  useManualRefundOrderMutation,
  useMarkOrderReceivedMutation,
  useRejectRequestOfferMutation,
  useRespondToOrderReturnMutation,
  useSetCustomOrderStatusMutation,
} from '../../store'
import type { AdminOrder } from '../../types/adminOrder'
import ProductShippingPanel from '../shared/ProductShippingPanel'
import CountryFlag from '../shared/CountryFlag'
import WhatsAppPhoneLink from '../shared/WhatsAppPhoneLink'
import {
  IconInfoField,
  IconInfoSectionTitle,
  InfoFieldIcons,
} from '../shared/IconInfoField'
import ConfirmDialog from '../ui/ConfirmDialog'
import CompactMediaStrip from './CompactMediaStrip'
import OrderNotifyPartyDialog from './OrderNotifyPartyDialog'
import OrderStatusActionButtons from './OrderStatusActionButtons'
import OrderStatusHistoryStrip from './OrderStatusHistoryStrip'
import { formatAdAmount, amountsLookEqual, productTypeFieldAccent, resolveOrderChannelTypeKey, resolveOrderChannelTypeName } from '../../utils/adsDisplay'
import {
  formatOrderAmount,
  formatOrderQuantityWithUnit,
  getDeliveryMethodLabel,
  resolveOrderedQuantity,
} from '../../utils/ordersDisplay'
import { getOrderStatusLabel, getOrderStatusStyle } from '../../utils/orderStatus'
import {
  canMarkOrderReceived,
  canSetCustomTextStatus,
  canUpdateOrderStatus,
  needsAdminOrderModeration,
} from '../../utils/orderWorkflow'

type OrderDetailViewProps = {
  order: AdminOrder
  isUpdating: boolean
  onStatusChange: (statusId: number) => void
  backToListPath?: string
  listTitleKey?: string
}

type TabKey = 'overview' | 'shipping' | 'history'

function CopyableIdField({
  label,
  value,
  copyLabel,
  copiedLabel,
}: {
  label: string
  value?: string | null
  copyLabel: string
  copiedLabel: string
}) {
  const [copied, setCopied] = useState(false)
  const text = value?.trim() || ''

  const handleCopy = async () => {
    if (!text) return
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
      window.setTimeout(() => setCopied(false), 1500)
    } catch {
      // Ignore clipboard failures in restricted contexts.
    }
  }

  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50/80 px-3 py-2.5">
      <div className="flex items-start justify-between gap-2">
        <p className="admin-text text-[12px] font-bold leading-snug">{label}</p>
        {text ? (
          <button
            type="button"
            onClick={handleCopy}
            className="shrink-0 rounded-md px-2 py-0.5 text-[11px] font-semibold text-indigo-600 hover:bg-indigo-50"
          >
            {copied ? copiedLabel : copyLabel}
          </button>
        ) : null}
      </div>
      <p
        className={`mt-1 break-all font-mono text-[12px] leading-relaxed ${
          text ? 'admin-text' : 'admin-text-muted'
        }`}
        dir="ltr"
      >
        {text || '—'}
      </p>
    </div>
  )
}

function Icon({
  children,
  className = 'h-5 w-5',
}: {
  children: ReactNode
  className?: string
}) {
  return (
    <svg
      className={className}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={1.8}
      aria-hidden
    >
      {children}
    </svg>
  )
}

const Icons = {
  printer: (
    <Icon>
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M6.72 13.829c-.24.03-.48.062-.72.096m.72-.096a42.415 42.415 0 0 1 10.56 0m-10.56 0L6.34 18m10.94-4.171c.24.03.48.062.72.096m-.72-.096L17.66 18m0 0 .229 2.523a1.125 1.125 0 0 1-1.12 1.227H7.231c-.662 0-1.18-.568-1.12-1.227L6.34 18m11.32 0H6.34m11.32 0 1.14-8.354A1.125 1.125 0 0 0 17.684 8.25H6.316a1.125 1.125 0 0 0-1.116 1.396L6.34 18M9 8.25h6V6.375A1.125 1.125 0 0 0 13.875 5.25h-3.75A1.125 1.125 0 0 0 9 6.375V8.25Z"
      />
    </Icon>
  ),
  money: (
    <Icon>
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0 1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 0 0-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 0 1-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 0 0 3 15h-.75M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm3 0h.008v.008H18V10.5Zm-12 0h.008v.008H6V10.5Z"
      />
    </Icon>
  ),
  package: (
    <Icon>
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="m21 7.5-9-5.25L3 7.5m18 0-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9"
      />
    </Icon>
  ),
  users: (
    <Icon>
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"
      />
    </Icon>
  ),
  eye: (
    <Icon>
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z"
      />
      <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
    </Icon>
  ),
  box: (
    <Icon className="h-4 w-4">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M21 7.5 12 2.25 3 7.5m18 0-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9"
      />
    </Icon>
  ),
  clipboard: (
    <Icon className="h-4 w-4">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18A2.25 2.25 0 0 0 20.25 16.5V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 0 0-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 0 0 .75-.75 2.25 2.25 0 0 0-.1-.664m-5.8 0A2.251 2.251 0 0 1 13.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25ZM6.75 12h.008v.008H6.75V12Zm0 3h.008v.008H6.75V15Zm0 3h.008v.008H6.75V18Z"
      />
    </Icon>
  ),
  truck: (
    <Icon className="h-4 w-4">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0H21M3.375 14.25h17.25m0 0V9.375c0-.621-.504-1.125-1.125-1.125H4.5A1.125 1.125 0 0 0 3.375 9.375v4.875Z"
      />
    </Icon>
  ),
  paperclip: (
    <Icon className="h-4 w-4">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="m18.375 12.739-7.693 7.693a4.5 4.5 0 0 1-6.364-6.364l10.94-10.94A3 3 0 1 1 19.5 7.372L8.552 18.32m.009-.01-.003.004-.003-.004.003-.004Zm0 0 .003-.004.003.004-.003.004-.003-.004Z"
      />
    </Icon>
  ),
  user: (
    <Icon className="h-4 w-4">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z"
      />
    </Icon>
  ),
  note: (
    <Icon className="h-4 w-4">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"
      />
    </Icon>
  ),
  check: (
    <Icon className="h-5 w-5">
      <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
    </Icon>
  ),
  x: (
    <Icon className="h-5 w-5">
      <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
    </Icon>
  ),
  history: (
    <Icon className="h-4 w-4">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
      />
    </Icon>
  ),
  shield: (
    <Icon className="h-4 w-4">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z"
      />
    </Icon>
  ),
  upload: (
    <Icon className="h-5 w-5">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5m-13.5-9L12 3m0 0 4.5 4.5M12 3v13.5"
      />
    </Icon>
  ),
}

function SidebarCard({
  title,
  icon,
  children,
}: {
  title: string
  icon?: ReactNode
  children: ReactNode
}) {
  return (
    <section className="admin-card overflow-hidden rounded-2xl shadow-sm">
      <div className="admin-border border-b px-5 py-3.5">
        <h2 className="admin-text flex items-center gap-2 text-start text-sm font-bold">
          {icon ? <span className="text-[#2563eb]">{icon}</span> : null}
          {title}
        </h2>
      </div>
      <div className="px-5 py-4">{children}</div>
    </section>
  )
}

function MetricCard({
  label,
  value,
  icon,
  iconClass,
}: {
  label: string
  value: string
  icon: ReactNode
  iconClass: string
}) {
  return (
    <div className="admin-card flex items-center gap-3 rounded-2xl px-4 py-3.5 text-start shadow-sm">
      <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${iconClass}`}>
        {icon}
      </div>
      <div className="min-w-0">
        <p className="admin-text text-xs font-bold leading-snug">{label}</p>
        <p className="admin-text-muted mt-0.5 truncate text-base font-normal tracking-tight">{value}</p>
      </div>
    </div>
  )
}

function InfoLine({
  label,
  value,
  forceLtr = false,
}: {
  label: string
  value: ReactNode
  forceLtr?: boolean
}) {
  return (
    <div className="text-start">
      <p className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">{label}</p>
      <p
        className="admin-text mt-1 text-sm font-semibold break-all"
        dir={forceLtr ? 'ltr' : undefined}
      >
        {value || '—'}
      </p>
    </div>
  )
}

function SummaryStat({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="text-center">
      <p className="admin-text-subtle text-[10px] font-semibold uppercase tracking-wide">{label}</p>
      <p className="admin-text mt-1 truncate text-sm font-bold">{value}</p>
    </div>
  )
}

function formatDetailDate(value: string, locale: 'ar' | 'en') {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US', {
    day: '2-digit',
    month: '2-digit',
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

function fileNameFromPath(path: string): string {
  const normalized = path.replace(/\\/g, '/')
  const parts = normalized.split('/')
  return parts[parts.length - 1] || path
}

export default function OffersOrderDetailView({
  order,
  isUpdating,
  onStatusChange,
  backToListPath = '/orders/retail',
  listTitleKey = 'nav.ordersRetail',
}: OrderDetailViewProps) {
  const { t, locale } = useAppPreferences()
  const [activeTab, setActiveTab] = useState<TabKey>('overview')
  const [rejectReasonEn, setRejectReasonEn] = useState('')
  const [rejectReasonAr, setRejectReasonAr] = useState('')
  const [returnReply, setReturnReply] = useState(order.returnAdminResponse ?? '')
  const [returnError, setReturnError] = useState<string | null>(null)
  const [refundError, setRefundError] = useState<string | null>(null)
  const [refundSuccess, setRefundSuccess] = useState<string | null>(null)
  const [requestOfferError, setRequestOfferError] = useState<string | null>(null)
  const [requestOfferSuccess, setRequestOfferSuccess] = useState<string | null>(null)
  const [pendingReturnAction, setPendingReturnAction] = useState<'approve' | 'reject' | null>(null)
  const [confirmRefund, setConfirmRefund] = useState(false)
  const [notifyTarget, setNotifyTarget] = useState<{
    userId: string
    name: string
    partyLabel: string
  } | null>(null)
  const [pendingRequestOfferAction, setPendingRequestOfferAction] = useState<
    'approve' | 'reject' | null
  >(null)
  const [respondToReturn, { isLoading: isResponding }] = useRespondToOrderReturnMutation()
  const [manualRefundOrder, { isLoading: isRefunding }] = useManualRefundOrderMutation()
  const [approveRequestOffer, { isLoading: isApprovingOffer }] = useApproveRequestOfferMutation()
  const [rejectRequestOffer, { isLoading: isRejectingOffer }] = useRejectRequestOfferMutation()
  const [setCustomOrderStatus, { isLoading: isSettingCustomStatus }] =
    useSetCustomOrderStatusMutation()
  const [markOrderReceived, { isLoading: isMarkingReceived }] = useMarkOrderReceivedMutation()
  const [customStatusText, setCustomStatusText] = useState('')
  const [customStatusError, setCustomStatusError] = useState<string | null>(null)
  const [customStatusSuccess, setCustomStatusSuccess] = useState<string | null>(null)
  const [confirmMarkReceived, setConfirmMarkReceived] = useState(false)

  const status = getOrderStatusStyle(order.statusId)
  const statusLabel =
    locale === 'ar'
      ? order.statusLabelAr?.trim() || getOrderStatusLabel(order.statusId, locale)
      : order.statusName?.trim() || getOrderStatusLabel(order.statusId, locale)
  const isApprovedSeller = Boolean(order.isApproved)
  const statusBadgeClass = isApprovedSeller
    ? 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200'
    : status.className

  const hasReturnRequest =
    order.statusId === 9 ||
    order.statusId === 10 ||
    Boolean(order.returnReason?.trim())
  const returnMediaPaths = order.returnMediaPaths ?? []

  const canModerate = canUpdateOrderStatus(order.statusId, {
    paymentMethodName: order.paymentMethodName,
    productTypeName: order.productTypeName,
    categoryId: order.categoryId,
  })
  const typeKey = resolveOrderChannelTypeKey(order)
  const typeName = resolveOrderChannelTypeName(order, locale)
  const typeAccent = productTypeFieldAccent(typeKey)
  const isBookingOrder =
    typeKey.toLowerCase() === 'booking' || typeKey.includes('بوكينج') || typeKey.includes('حجز')
  const canSetCustomRequestStatus = canSetCustomTextStatus(order)
  const canMarkReceived = canMarkOrderReceived(order)
  const statusHistory = order.statusHistory ?? []
  const needsAdminModeration = needsAdminOrderModeration(order)
  const isReviewingAdminModeration = isApprovingOffer || isRejectingOffer || isUpdating

  const orderedQuantity = resolveOrderedQuantity(order)
  const availableQuantity =
    order.productAvailableQuantity != null && order.productAvailableQuantity >= 0
      ? order.productAvailableQuantity
      : null

  const productImagePaths = (() => {
    const fromImages = order.images.map((img) => img.path).filter(Boolean)
    if (fromImages.length > 0) return fromImages
    const fromProduct = (order.productImagePaths ?? []).filter(Boolean)
    if (fromProduct.length > 0) return fromProduct
    return order.primaryImagePath?.trim() ? [order.primaryImagePath] : []
  })()
  const specsComments = order.notes?.trim() || order.productDescription?.trim() || ''

  const supplierTotal =
    order.supplierTotalPriceFormatted ||
    `${order.supplierTotalPrice.toFixed(2)} ${order.currency}`
  const customerTotal =
    order.customerTotalPriceFormatted ||
    `${order.customerTotalPrice.toFixed(2)} ${order.currency}`
  const appProfit = formatAdAmount(
    order.appProfitFormatted || `${order.appProfitAmount.toFixed(2)} ${order.currency}`,
    locale,
  )
  const shippingAed = order.chargedShippingAed > 0 ? order.chargedShippingAed : order.shippingCostAed
  const shippingCost =
    order.currency?.toUpperCase() === 'USD' && shippingAed <= 0
      ? '—'
      : formatAdAmount(`${shippingAed.toFixed(2)} AED`, locale)
  const vatAmount =
    order.currency?.toUpperCase() === 'USD' && order.vatAed <= 0
      ? '—'
      : formatAdAmount(`${order.vatAed.toFixed(2)} AED`, locale)
  const grandTotal = formatOrderAmount(order)
  const supplierUnitPrice =
    order.supplierUnitPriceFormatted ||
    `${order.supplierUnitPrice.toFixed(2)} ${order.currency}`
  const customerUnitPrice =
    order.customerUnitPriceFormatted ||
    `${order.customerUnitPrice.toFixed(2)} ${order.currency}`
  const chargedAmount =
    order.chargedGrandTotalFormatted?.trim() ||
    (order.chargedGrandTotalAed > 0
      ? `${order.chargedGrandTotalAed.toFixed(2)} AED`
      : null)
  const deliveryMethodLabel = getDeliveryMethodLabel(order.isSelfPickup, locale)
  const isOnlinePayment = order.paymentMethodName === 'Online'
  const showPaymentIntentId =
    isOnlinePayment && Boolean(order.paymentIntentId?.trim())
  const showRefundTracking =
    isOnlinePayment &&
    (order.isRefunded ||
      Boolean(order.stripeRefundId?.trim()) ||
      order.statusId === 6 ||
      order.statusId === 10)
  const canProcessRefund =
    isOnlinePayment &&
    !order.isRefunded &&
    !order.stripeRefundId?.trim() &&
    (order.statusId === 6 || order.statusId === 10)

  const returnImagePaths = returnMediaPaths.filter((p) => !/\.(mp4|mov|webm)$/i.test(p))
  const returnVideoPaths = returnMediaPaths.filter((p) => /\.(mp4|mov|webm)$/i.test(p))

  const customerInitials = (order.customerName || '—').slice(0, 2).toUpperCase()
  const supplierInitials = (order.supplierName || '—').slice(0, 2).toUpperCase()

  const tabs: { key: TabKey; label: string }[] = [
    { key: 'overview', label: t('orders.tabOverview') },
    { key: 'shipping', label: t('orders.tabShipping') },
    { key: 'history', label: t('orders.tabHistory') },
  ]

  const showUpdateStatusCard = canSetCustomRequestStatus || canMarkReceived

  function submitReturnDecision(approved: boolean) {
    setReturnError(null)
    setPendingReturnAction(null)
    void respondToReturn({
      orderId: order.id,
      response: returnReply.trim(),
      approved,
    })
      .unwrap()
      .catch((err: { data?: { message?: string } }) => {
        setReturnError(err?.data?.message ?? t('orders.returnReplyError'))
      })
  }

  function submitManualRefund() {
    setRefundError(null)
    setRefundSuccess(null)
    setConfirmRefund(false)
    void manualRefundOrder({ orderId: order.id })
      .unwrap()
      .then(() => {
        setRefundSuccess(t('orders.processRefundSuccess'))
      })
      .catch((err: { data?: { message?: string } }) => {
        setRefundError(err?.data?.message ?? t('orders.processRefundError'))
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

  const updateStatusCard = showUpdateStatusCard ? (
    <section className="admin-card rounded-2xl p-5 shadow-sm">
      <h2 className="admin-text text-start text-sm font-bold">{t('orders.customStatusTitle')}</h2>
      <p className="admin-text-muted mt-1 text-xs">{t('orders.customStatusHint')}</p>
      {canSetCustomRequestStatus ? (
        <>
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            <label className="block text-start sm:col-span-2">
              <span className="admin-text-subtle text-xs">{t('orders.customStatusName')}</span>
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
              disabled={isSettingCustomStatus || isMarkingReceived}
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
                disabled={isSettingCustomStatus || isMarkingReceived}
                onClick={() => setConfirmMarkReceived(true)}
                className="inline-flex h-9 items-center rounded-lg bg-emerald-600 px-4 text-xs font-semibold text-white disabled:opacity-60"
              >
                {isMarkingReceived ? t('orders.markReceivedSubmitting') : t('orders.markReceived')}
              </button>
            ) : null}
          </div>
        </>
      ) : canMarkReceived ? (
        <button
          type="button"
          disabled={isMarkingReceived}
          onClick={() => setConfirmMarkReceived(true)}
          className="mt-3 inline-flex h-9 items-center rounded-lg bg-emerald-600 px-4 text-xs font-semibold text-white disabled:opacity-60"
        >
          {isMarkingReceived ? t('orders.markReceivedSubmitting') : t('orders.markReceived')}
        </button>
      ) : null}
    </section>
  ) : null

  const tabsCard = (
    <section className="admin-card flex flex-col justify-center rounded-2xl p-4 shadow-sm sm:p-5">
      <div className="flex flex-wrap gap-1.5 rounded-xl bg-slate-100 p-1.5 dark:bg-slate-800/60">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            onClick={() => setActiveTab(tab.key)}
            className={`flex-1 rounded-lg px-3 py-2 text-center text-xs font-bold transition sm:text-sm ${
              activeTab === tab.key
                ? 'bg-white text-[#2563eb] shadow-sm dark:bg-slate-900'
                : 'admin-text-muted hover:text-slate-700'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>
    </section>
  )

  return (
    <div className="order-print-root space-y-5 print:space-y-3">
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

      {/* Header (no product thumbnail for Offers orders) */}
      <div className="flex flex-wrap items-start justify-between gap-4 print:hidden">
        <div className="min-w-0 flex-1 text-start">
          <p className="admin-text-muted text-xs">
            <Link to={backToListPath} className="hover:text-[#2563eb]">
              {t(listTitleKey)}
            </Link>
            <span className="mx-1.5 opacity-50">›</span>
            <span>{t('orders.orderDetailsPage')}</span>
          </p>
          <div className="mt-1 flex flex-wrap items-center gap-2">
            <h1 className="admin-text text-2xl font-bold tracking-tight">
              {t('orders.orderNumber')} #{order.id}
            </h1>
            <span
              className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-bold ${statusBadgeClass}`}
            >
              {isApprovedSeller ? (
                <svg
                  className="h-3 w-3"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={3}
                  aria-hidden
                >
                  <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                </svg>
              ) : (
                <span className="h-1.5 w-1.5 rounded-full bg-current opacity-80" />
              )}
              {statusLabel}
            </span>
          </div>
          <p className="admin-text-muted mt-2 text-xs">
            <span className="font-semibold">{t('orders.createdOn')}: </span>
            {formatDetailDate(order.createdAt, locale)}
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
            className="keep-white inline-flex h-10 items-center gap-2 rounded-xl bg-[#2563eb] px-4 text-xs font-bold text-white shadow-sm transition hover:bg-[#1d4ed8]"
          >
            {Icons.printer}
            {t('orders.printOrder')}
          </button>
          {canModerate && !needsAdminModeration && !canSetCustomRequestStatus ? (
            <OrderStatusActionButtons
              statusId={order.statusId}
              isUpdating={isUpdating}
              onStatusChange={onStatusChange}
              paymentMethodName={order.paymentMethodName}
              productTypeName={order.productTypeName}
            />
          ) : null}
        </div>
      </div>

      {/* Metrics */}
      <div className="grid gap-3 print:hidden sm:grid-cols-2 xl:grid-cols-[1fr_1fr_1fr_1fr_1.35fr_0.85fr]">
        <MetricCard
          label={t('orders.totalAmount')}
          value={formatAdAmount(grandTotal, locale)}
          icon={Icons.money}
          iconClass="bg-emerald-50 text-emerald-600"
        />
        <MetricCard
          label={t('orders.unitPrice')}
          value={formatAdAmount(customerUnitPrice, locale)}
          icon={Icons.money}
          iconClass="bg-blue-50 text-blue-600"
        />
        <MetricCard
          label={t('orders.orderedQuantity')}
          value={formatOrderQuantityWithUnit(orderedQuantity, order.unitName)}
          icon={Icons.package}
          iconClass="bg-orange-50 text-orange-500"
        />
        <MetricCard
          label={t('orders.supplierTotalPrice')}
          value={formatAdAmount(supplierTotal, locale)}
          icon={Icons.users}
          iconClass="bg-sky-50 text-sky-600"
        />
        <div className="admin-card flex items-start gap-3 rounded-2xl border border-[#F5E6B8] bg-[#FFF9E6] px-4 py-3.5 text-start shadow-sm">
          <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[#FEF3C7] text-[#D97706]">
            {InfoFieldIcons.note}
          </div>
          <div className="min-w-0">
            <p className="admin-text text-xs font-bold leading-snug">
              {t('orders.specificationsComments')}
            </p>
            <p className="admin-text-muted mt-0.5 text-sm font-normal leading-snug whitespace-pre-wrap">
              {specsComments || '—'}
            </p>
          </div>
        </div>
        <MetricCard
          label={t('ads.views')}
          value={String(order.productViewsCount ?? 0)}
          icon={Icons.eye}
          iconClass="bg-violet-50 text-violet-500"
        />
      </div>

      {/* Update status + Tabs */}
      {showUpdateStatusCard ? (
        <div className="grid gap-4 print:hidden xl:grid-cols-[minmax(0,1.15fr)_minmax(0,0.85fr)]">
          {updateStatusCard}
          {tabsCard}
        </div>
      ) : (
        <div className="print:hidden">{tabsCard}</div>
      )}

      {/* Print sheet: landscape A4 — order basics + buyer + supplier */}
      <section className="order-print-sheet hidden print:block">
        <div className="mb-3 flex items-end justify-between gap-4 border-b border-slate-300 pb-2">
          <div>
            <p className="text-xs font-semibold text-slate-500">{t('orders.orderDetailsPage')}</p>
            <h2 className="text-xl font-bold text-slate-900">
              {t('orders.orderNumber')} #{order.id}
            </h2>
          </div>
          <div className="text-end text-xs text-slate-600">
            <p>
              <span className="font-semibold">{t('orders.createdOn')}: </span>
              {formatDetailDate(order.createdAt, locale)}
            </p>
            <p className="mt-0.5">
              <span className="font-semibold">{t('orders.currentStatus')}: </span>
              {statusLabel}
            </p>
          </div>
        </div>

        <div className="mb-3 grid grid-cols-4 gap-2 text-xs">
          <div className="rounded border border-slate-200 p-2">
            <p className="font-semibold text-slate-500">{t('orders.productName')}</p>
            <p className="mt-0.5 font-bold text-slate-900">{order.productName || '—'}</p>
          </div>
          <div className="rounded border border-slate-200 p-2">
            <p className="font-semibold text-slate-500">{t('orders.unitPrice')}</p>
            <p className="mt-0.5 font-bold text-slate-900">
              {formatAdAmount(customerUnitPrice, locale)}
            </p>
          </div>
          <div className="rounded border border-slate-200 p-2">
            <p className="font-semibold text-slate-500">{t('orders.orderedQuantity')}</p>
            <p className="mt-0.5 font-bold text-slate-900">
              {formatOrderQuantityWithUnit(orderedQuantity, order.unitName)}
            </p>
          </div>
          <div className="rounded border border-slate-200 p-2">
            <p className="font-semibold text-slate-500">{t('orders.totalAmount')}</p>
            <p className="mt-0.5 font-bold text-slate-900">
              {formatAdAmount(grandTotal, locale)}
            </p>
          </div>
          <div className="rounded border border-slate-200 p-2">
            <p className="font-semibold text-slate-500">{t('orders.category')}</p>
            <p className="mt-0.5 font-semibold text-slate-800">{order.categoryName || '—'}</p>
          </div>
          <div className="rounded border border-slate-200 p-2">
            <p className="font-semibold text-slate-500">{t('orders.productType')}</p>
            <p className="mt-0.5 font-semibold text-slate-800">{typeName || '—'}</p>
          </div>
          <div className="rounded border border-slate-200 p-2">
            <p className="font-semibold text-slate-500">{t('orders.paymentMethod')}</p>
            <p className="mt-0.5 font-semibold text-slate-800">
              {paymentLabel(order.paymentMethodName, t)}
            </p>
          </div>
          <div className="rounded border border-slate-200 p-2">
            <p className="font-semibold text-slate-500">{t('orders.supplierTotalPrice')}</p>
            <p className="mt-0.5 font-semibold text-slate-800">
              {formatAdAmount(supplierTotal, locale)}
            </p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="rounded border border-slate-300 p-3">
            <h3 className="mb-2 text-sm font-bold text-slate-900">{t('orders.customerInfo')}</h3>
            <div className="space-y-1 text-xs text-slate-800">
              <p className="text-sm font-bold">{order.customerName || '—'}</p>
              <p dir="ltr">{order.customerPhone?.trim() || '—'}</p>
              <p className="break-all">{order.customerEmail || '—'}</p>
              <p className="text-slate-600">
                {order.deliveryCityName?.trim() || order.destinationCountryName?.trim() || '—'}
              </p>
            </div>
          </div>
          <div className="rounded border border-slate-300 p-3">
            <h3 className="mb-2 text-sm font-bold text-slate-900">{t('orders.supplierInfo')}</h3>
            <div className="space-y-1 text-xs text-slate-800">
              <p className="text-sm font-bold">{order.supplierName || '—'}</p>
              <p dir="ltr">{order.supplierPhone?.trim() || '—'}</p>
              <p className="break-all">{order.supplierEmail || '—'}</p>
            </div>
          </div>
        </div>
      </section>

      <div className="grid grid-cols-1 gap-5 xl:grid-cols-[minmax(0,1fr)_minmax(280px,320px)]">
        <div className="space-y-4">
          {/* Overview blocks: screen only — print uses order-print-sheet */}
          <div className={`space-y-4 print:hidden ${activeTab === 'overview' ? '' : 'hidden'}`}>
            <div className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
              <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)]">
                <div>
                  <IconInfoSectionTitle
                    title={t('orders.orderDetails')}
                    icon={Icons.box}
                    iconClass="bg-emerald-50 text-emerald-600"
                  />
                  <div className="grid gap-5 sm:grid-cols-2">
                    <IconInfoField
                      label={t('orders.productName')}
                      icon={InfoFieldIcons.document}
                      iconClass="bg-rose-50 text-rose-500"
                      value={order.productName || '—'}
                    />
                    <IconInfoField
                      label={t('orders.category')}
                      icon={InfoFieldIcons.bowl}
                      iconClass="bg-orange-50 text-orange-500"
                      value={
                        order.categoryName?.trim() ? (
                          <span className="inline-flex rounded-md bg-violet-50 px-2 py-0.5 text-[10px] font-bold text-violet-600">
                            {order.categoryName}
                          </span>
                        ) : (
                          '—'
                        )
                      }
                    />
                    <IconInfoField
                      label={t('orders.productType')}
                      icon={InfoFieldIcons.tag}
                      iconClass={typeAccent.iconClass}
                      className={typeAccent.fieldClassName}
                      value={
                        <span
                          className={`inline-flex rounded-md px-2 py-0.5 text-[10px] font-bold ${typeAccent.badgeClass}`}
                        >
                          {typeName}
                        </span>
                      }
                    />
                    <IconInfoField
                      label={t('ads.availableQuantity')}
                      icon={InfoFieldIcons.calendar}
                      iconClass="bg-sky-50 text-sky-600"
                      value={
                        availableQuantity != null
                          ? formatOrderQuantityWithUnit(availableQuantity, order.unitName)
                          : '—'
                      }
                    />
                    <IconInfoField
                      label={t('orders.approvalState')}
                      icon={InfoFieldIcons.search}
                      iconClass="bg-slate-100 text-slate-600"
                      value={
                        order.isApproved || order.isAdminApproved
                          ? t('orders.approved')
                          : t('orders.notApproved')
                      }
                    />
                  </div>
                </div>

                <div>
                  <h2 className="admin-text mb-4 text-start text-base font-bold">
                    {t('orders.productImages')} ({Math.max(productImagePaths.length, 1)})
                  </h2>
                  <div className="flex flex-wrap gap-3">
                    <label className="flex h-24 w-28 shrink-0 cursor-pointer flex-col items-center justify-center gap-1 rounded-xl border-2 border-dashed border-[#93C5FD] bg-[#EFF6FF] px-1.5 text-center text-[10px] font-semibold leading-tight text-[#2563eb] transition hover:border-[#2563eb] hover:bg-[#DBEAFE]">
                      <input
                        type="file"
                        accept="image/*"
                        multiple
                        className="hidden"
                        onChange={() => {}}
                      />
                      <span className="text-[#3B82F6]">{Icons.upload}</span>
                      {t('ads.uploadImages')}
                    </label>
                    <CompactMediaStrip
                      paths={productImagePaths}
                      sizeClassName="h-24 w-28"
                    />
                  </div>
                </div>
              </div>
            </div>

            <section className="grid grid-cols-1 gap-3 md:grid-cols-3">
              {/* Order information */}
              <div className="rounded-2xl border border-slate-200 bg-white p-3 shadow-sm dark:border-slate-700 dark:bg-slate-900/40">
                <div className="mb-2.5 flex items-center gap-2">
                  <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-[#eff6ff] text-[#2563eb]">
                    {InfoFieldIcons.clipboard}
                  </span>
                  <p className="text-sm font-bold text-slate-800 dark:text-slate-100">
                    {t('orders.orderInformation')}
                  </p>
                </div>
                <div className="grid grid-cols-3 gap-x-3 gap-y-2.5">
                  <IconInfoField
                    label={t('orders.orderedQuantity')}
                    icon={InfoFieldIcons.package}
                    iconClass="bg-orange-50 text-orange-500"
                    value={formatOrderQuantityWithUnit(orderedQuantity, order.unitName)}
                  />
                  <IconInfoField
                    label={t('orders.deliveryMethod')}
                    icon={InfoFieldIcons.truck}
                    iconClass="bg-sky-50 text-sky-600"
                    value={
                      <span className="inline-flex items-center gap-1.5 rounded-full bg-sky-50 px-2.5 py-1 text-[11px] font-bold text-sky-700">
                        {deliveryMethodLabel}
                      </span>
                    }
                  />
                  <IconInfoField
                    label={t('orders.orderNotes')}
                    icon={InfoFieldIcons.note}
                    iconClass="bg-slate-100 text-slate-500"
                    value={order.notes?.trim() || '—'}
                  />
                  <IconInfoField
                    label={t('orders.paymentMethod')}
                    icon={InfoFieldIcons.card}
                    iconClass="bg-slate-100 text-slate-600"
                    value={paymentLabel(order.paymentMethodName, t)}
                  />
                  <IconInfoField
                    label={t('orders.shippingCost')}
                    icon={InfoFieldIcons.truck}
                    iconClass="bg-purple-50 text-purple-600"
                    value={order.isSelfPickup ? '—' : shippingCost}
                  />
                  <IconInfoField
                    label={t('orders.vatAmount')}
                    icon={InfoFieldIcons.document}
                    iconClass="bg-amber-50 text-amber-600"
                    value={vatAmount}
                  />
                  {isBookingOrder ? (
                    <>
                      <IconInfoField
                        label={t('orders.portCountry')}
                        icon={InfoFieldIcons.pin}
                        iconClass="bg-indigo-50 text-indigo-600"
                        value={order.portCountryName?.trim() || '—'}
                      />
                      <IconInfoField
                        label={t('orders.port')}
                        icon={InfoFieldIcons.pin}
                        iconClass="bg-sky-50 text-sky-600"
                        value={order.portName?.trim() || '—'}
                      />
                      <IconInfoField
                        label={t('ads.loadingPort')}
                        icon={InfoFieldIcons.pin}
                        iconClass="bg-sky-50 text-sky-600"
                        value={order.loadingPortName?.trim() || '—'}
                      />
                      <IconInfoField
                        label={t('ads.arrivalPort')}
                        icon={InfoFieldIcons.pin}
                        iconClass="bg-indigo-50 text-indigo-600"
                        value={order.arrivalPortName?.trim() || '—'}
                      />
                    </>
                  ) : null}
                </div>
              </div>

              {/* My earnings */}
              <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-3 shadow-sm dark:border-emerald-900/50 dark:bg-emerald-950/30">
                <div className="mb-2.5 flex items-center gap-2">
                  <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300">
                    {InfoFieldIcons.money}
                  </span>
                  <p className="text-sm font-bold text-emerald-800 dark:text-emerald-200">
                    {t('orders.companyEarningsTitle')}
                  </p>
                </div>
                <div className="grid grid-cols-3 gap-x-3 gap-y-2.5">
                  <IconInfoField
                    label={t('orders.customerUnitPrice')}
                    icon={InfoFieldIcons.money}
                    iconClass="bg-emerald-100 text-emerald-700"
                    value={
                      <span className="font-semibold text-emerald-800 dark:text-emerald-200">
                        {formatAdAmount(customerUnitPrice, locale)}
                      </span>
                    }
                  />
                  <IconInfoField
                    label={t('orders.commissionPercent')}
                    icon={InfoFieldIcons.percent}
                    iconClass="bg-emerald-100 text-emerald-700"
                    value={
                      <span className="font-semibold text-emerald-800 dark:text-emerald-200">
                        {`${order.commissionPercent.toFixed(2)}%`}
                      </span>
                    }
                  />
                  <IconInfoField
                    label={t('orders.customerTotalPrice')}
                    icon={InfoFieldIcons.money}
                    iconClass="bg-emerald-100 text-emerald-700"
                    value={
                      <span className="font-semibold text-emerald-800 dark:text-emerald-200">
                        {formatAdAmount(customerTotal, locale)}
                      </span>
                    }
                  />
                  <IconInfoField
                    label={t('orders.appProfitAmount')}
                    icon={InfoFieldIcons.money}
                    iconClass="bg-emerald-100 text-emerald-700"
                    value={
                      <span className="text-sm font-bold text-emerald-700 dark:text-emerald-300">
                        {appProfit}
                      </span>
                    }
                  />
                  <IconInfoField
                    label={t('orders.grandTotal')}
                    icon={InfoFieldIcons.money}
                    iconClass="bg-emerald-100 text-emerald-700"
                    value={
                      <span className="text-sm font-bold text-emerald-700 dark:text-emerald-300">
                        {formatAdAmount(grandTotal, locale)}
                      </span>
                    }
                  />
                  {chargedAmount &&
                  !amountsLookEqual(chargedAmount, grandTotal) ? (
                    <IconInfoField
                      label={t('orders.chargedAmount')}
                      icon={InfoFieldIcons.card}
                      iconClass="bg-emerald-100 text-emerald-700"
                      value={
                        <span className="font-semibold text-emerald-800 dark:text-emerald-200">
                          {formatAdAmount(chargedAmount, locale)}
                        </span>
                      }
                    />
                  ) : null}
                </div>
              </div>

              {/* Supplier summary */}
              <div className="rounded-2xl border border-sky-200 bg-sky-50 p-3 shadow-sm dark:border-sky-900/50 dark:bg-sky-950/30">
                <div className="mb-2.5 flex items-center gap-2">
                  <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-sky-100 text-sky-700 dark:bg-sky-900/40 dark:text-sky-300">
                    {InfoFieldIcons.users}
                  </span>
                  <p className="text-sm font-bold text-sky-800 dark:text-sky-200">
                    {t('orders.supplierPricingTitle')}
                  </p>
                </div>
                <div className="grid grid-cols-3 gap-x-3 gap-y-2.5">
                  {!amountsLookEqual(supplierUnitPrice, supplierTotal) ? (
                    <IconInfoField
                      label={t('orders.supplierUnitPrice')}
                      icon={InfoFieldIcons.lock}
                      iconClass="bg-sky-100 text-sky-700"
                      value={
                        <span className="font-semibold text-sky-800 dark:text-sky-200">
                          {formatAdAmount(supplierUnitPrice, locale)}
                        </span>
                      }
                    />
                  ) : null}
                  <IconInfoField
                    label={t('orders.supplierTotalPrice')}
                    icon={InfoFieldIcons.users}
                    iconClass="bg-sky-100 text-sky-700"
                    value={
                      <span className="text-sm font-bold text-sky-700 dark:text-sky-300">
                        {formatAdAmount(supplierTotal, locale)}
                      </span>
                    }
                  />
                </div>
              </div>
            </section>

            {(showPaymentIntentId || showRefundTracking || !order.isSelfPickup) ? (
              <section className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
              {showPaymentIntentId ? (
                <div className="space-y-3">
                  <div>
                    <IconInfoSectionTitle
                      title={t('orders.paymentIds')}
                      icon={InfoFieldIcons.card}
                      iconClass="bg-indigo-50 text-indigo-600"
                    />
                    <p className="admin-text-subtle -mt-2 mb-4 text-xs">
                      {t('orders.paymentIdsHint')}
                    </p>
                  </div>
                  <CopyableIdField
                    label={t('orders.paymentIntentId')}
                    value={order.paymentIntentId}
                    copyLabel={t('orders.copyId')}
                    copiedLabel={t('orders.copiedId')}
                  />
                </div>
              ) : null}
              {showRefundTracking ? (
                <div className={`${showPaymentIntentId ? 'mt-5 border-t border-slate-100 pt-5' : ''} space-y-4`}>
                  <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-3">
                    <IconInfoField
                      label={t('orders.refundStatus')}
                      icon={InfoFieldIcons.money}
                      iconClass="bg-rose-50 text-rose-500"
                      value={
                        order.isRefunded ? t('orders.refundCompleted') : t('orders.refundPending')
                      }
                    />
                    <IconInfoField
                      label={t('orders.refundDate')}
                      icon={InfoFieldIcons.calendar}
                      iconClass="bg-sky-50 text-sky-600"
                      value={
                        order.refundedAtUtc ? formatDetailDate(order.refundedAtUtc, locale) : '—'
                      }
                    />
                    <IconInfoField
                      label={t('orders.refundReference')}
                      icon={InfoFieldIcons.document}
                      iconClass="bg-slate-100 text-slate-600"
                      value={order.stripeRefundId?.trim() || '—'}
                    />
                  </div>
                  {canProcessRefund ? (
                    <div className="space-y-2 print:hidden">
                      <p className="admin-text-subtle text-xs">{t('orders.processRefundHint')}</p>
                      {refundError ? <p className="text-xs text-red-600">{refundError}</p> : null}
                      {refundSuccess ? (
                        <p className="text-xs text-emerald-600">{refundSuccess}</p>
                      ) : null}
                      <button
                        type="button"
                        disabled={isRefunding}
                        onClick={() => setConfirmRefund(true)}
                        className="rounded-lg bg-rose-600 px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-50"
                      >
                        {isRefunding ? t('orders.processRefunding') : t('orders.processRefund')}
                      </button>
                    </div>
                  ) : null}
                </div>
              ) : null}
              {!order.isSelfPickup ? (
                <div
                  className={`${showPaymentIntentId || showRefundTracking ? 'mt-5 border-t border-slate-100 pt-5' : ''} grid gap-5 sm:grid-cols-2`}
                >
                  <IconInfoField
                    label={t('orders.deliveryCity')}
                    icon={InfoFieldIcons.pin}
                    iconClass="bg-indigo-50 text-indigo-600"
                    value={order.deliveryCityName?.trim() || '—'}
                  />
                  <IconInfoField
                    label={t('orders.deliveryAddress')}
                    icon={InfoFieldIcons.pin}
                    iconClass="bg-indigo-50 text-indigo-600"
                    value={order.deliveryAddressLine?.trim() || '—'}
                  />
                </div>
              ) : null}
              </section>
            ) : null}
          </div>

          {(activeTab === 'overview' || activeTab === 'shipping') && (
            <section className="admin-card rounded-2xl p-5 shadow-sm print:hidden">
              <IconInfoSectionTitle
                title={t('orders.tabShipping')}
                icon={Icons.truck}
                iconClass="bg-purple-50 text-purple-600"
              />
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
          )}

          {activeTab === 'history' ? (
            <section className="admin-card rounded-2xl p-5 shadow-sm">
              <IconInfoSectionTitle title={t('orders.statusHistoryTitle')} icon={Icons.history} />
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
                          className={`mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-[10px] font-bold ${
                            isLatest
                              ? 'bg-emerald-500 text-white'
                              : 'bg-emerald-100 text-emerald-700'
                          }`}
                        >
                          ✓
                        </span>
                        <div>
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
            </section>
          ) : null}

          {hasReturnRequest ? (
            <section className="admin-card rounded-2xl border border-orange-200/80 p-5 shadow-sm dark:border-orange-900/50">
              <h2 className="admin-text mb-3 text-start text-sm font-bold">
                {t('orders.returnRequest')}
              </h2>
              <div className="grid gap-3 sm:grid-cols-2">
                <InfoLine label={t('orders.returnReason')} value={order.returnReason?.trim() || '—'} />
                {order.returnRequestedAtUtc ? (
                  <InfoLine
                    label={t('orders.returnRequestedAt')}
                    value={formatDetailDate(order.returnRequestedAtUtc, locale)}
                  />
                ) : null}
              </div>
              {returnMediaPaths.length > 0 ? (
                <div className="mt-3 space-y-3 print:hidden">
                  {returnImagePaths.length > 0 ? (
                    <div>
                      <p className="admin-text-subtle mb-2 text-xs font-semibold">
                        {t('orders.returnMedia')}
                      </p>
                      <CompactMediaStrip paths={returnImagePaths} />
                    </div>
                  ) : null}
                  {returnVideoPaths.length > 0 ? (
                    <div className="space-y-2">
                      <p className="admin-text-subtle text-xs font-semibold">{t('orders.videos')}</p>
                      {returnVideoPaths.map((path) => (
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
                </div>
              ) : null}
              {order.returnRespondedAtUtc ? (
                <InfoLine
                  label={t('orders.returnRespondedAt')}
                  value={formatDetailDate(order.returnRespondedAtUtc, locale)}
                />
              ) : null}
              {order.returnAdminResponse?.trim() ? (
                <InfoLine
                  label={t('orders.returnAdminResponse')}
                  value={order.returnAdminResponse}
                />
              ) : order.statusId === 9 ? (
                <div className="mt-3 space-y-2 print:hidden">
                  <textarea
                    value={returnReply}
                    onChange={(e) => setReturnReply(e.target.value)}
                    rows={2}
                    className="admin-input w-full rounded-lg px-2 py-1.5 text-xs"
                    placeholder={t('orders.returnReplyPlaceholder')}
                  />
                  {returnError ? <p className="text-xs text-red-600">{returnError}</p> : null}
                  <div className="flex flex-wrap gap-2">
                    <button
                      type="button"
                      disabled={isResponding}
                      onClick={() => setPendingReturnAction('approve')}
                      className="rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-50"
                    >
                      {isResponding ? t('orders.returnReplying') : t('orders.returnApprove')}
                    </button>
                    <button
                      type="button"
                      disabled={isResponding || returnReply.trim().length < 2}
                      onClick={() => setPendingReturnAction('reject')}
                      className="rounded-lg bg-red-600 px-3 py-1.5 text-xs font-semibold text-white disabled:opacity-50"
                    >
                      {t('orders.returnReject')}
                    </button>
                  </div>
                </div>
              ) : null}
            </section>
          ) : null}
        </div>

        <aside className="space-y-4 print:hidden">
          <SidebarCard title={t('orders.customerInfo')} icon={Icons.user}>
            <div className="space-y-3 text-start">
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-full bg-[#eff6ff] text-xs font-bold text-[#2563eb]">
                  {customerInitials}
                </span>
                <p className="admin-text text-sm font-bold">{order.customerName || '—'}</p>
              </div>
              <p className="flex items-center gap-2 text-sm" dir="ltr">
                <CountryFlag phone={order.customerPhone} city={order.deliveryCityName} size={20} />
                <WhatsAppPhoneLink phone={order.customerPhone} />
              </p>
              <p className="admin-text break-all text-sm">{order.customerEmail || '—'}</p>
              <p className="flex items-center gap-2 text-sm">
                <CountryFlag
                  city={order.deliveryCityName || order.destinationCountryName}
                  phone={order.customerPhone}
                  size={20}
                />
                <span className="admin-text-muted">
                  {order.deliveryCityName?.trim() || order.destinationCountryName?.trim() || '—'}
                </span>
              </p>
              {order.customerUserId ? (
                <button
                  type="button"
                  onClick={() =>
                    setNotifyTarget({
                      userId: order.customerUserId!,
                      name: order.customerName,
                      partyLabel: t('orders.customerInfo'),
                    })
                  }
                  className="mt-1 inline-flex h-9 w-full items-center justify-center rounded-xl border border-[#3B7FC7]/30 bg-[#eff6ff] text-xs font-bold text-[#2563eb] hover:bg-[#dbeafe]"
                >
                  {t('orders.notifyBuyer')}
                </button>
              ) : null}
            </div>
          </SidebarCard>

          <SidebarCard title={t('orders.supplierInfo')} icon={Icons.user}>
            <div className="space-y-3 text-start">
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-full bg-slate-100 text-xs font-bold text-slate-600">
                  {supplierInitials}
                </span>
                <p className="admin-text text-sm font-bold">{order.supplierName || '—'}</p>
              </div>
              <p className="flex items-center gap-2 text-sm" dir="ltr">
                <CountryFlag
                  phone={order.supplierPhone}
                  countryName={order.originCountryName}
                  size={20}
                />
                <WhatsAppPhoneLink phone={order.supplierPhone} />
              </p>
              <p className="admin-text break-all text-sm">{order.supplierEmail || '—'}</p>
              {order.supplierUserId ? (
                <button
                  type="button"
                  onClick={() =>
                    setNotifyTarget({
                      userId: order.supplierUserId!,
                      name: order.supplierName,
                      partyLabel: t('orders.supplierInfo'),
                    })
                  }
                  className="mt-1 inline-flex h-9 w-full items-center justify-center rounded-xl border border-[#3B7FC7]/30 bg-[#eff6ff] text-xs font-bold text-[#2563eb] hover:bg-[#dbeafe]"
                >
                  {t('orders.notifySeller')}
                </button>
              ) : null}
            </div>
          </SidebarCard>

          <SidebarCard title={t('orders.adminNotes')} icon={Icons.note}>
            <div className="space-y-3">
              <div>
                <p className="admin-text-muted mb-1 text-xs font-medium">
                  {t('ads.rejectReasonEn')}
                </p>
                <textarea
                  value={rejectReasonEn}
                  onChange={(e) => setRejectReasonEn(e.target.value)}
                  rows={3}
                  placeholder={t('ads.rejectReasonEnPlaceholder')}
                  className="admin-input w-full resize-y px-3 py-2.5 text-sm"
                />
              </div>
              <div>
                <p className="admin-text-muted mb-1 text-xs font-medium">
                  {t('ads.rejectReasonAr')}
                </p>
                <textarea
                  value={rejectReasonAr}
                  onChange={(e) => setRejectReasonAr(e.target.value)}
                  rows={3}
                  placeholder={t('ads.rejectReasonArPlaceholder')}
                  className="admin-input w-full resize-y px-3 py-2.5 text-sm"
                />
              </div>
            </div>
          </SidebarCard>

          {needsAdminModeration ? (
            <section className="admin-card space-y-2 rounded-2xl p-4 shadow-sm">
              <p className="admin-text mb-1 text-sm font-bold">{t('orders.requestOfferReview')}</p>
              <p className="admin-text-muted mb-2 text-xs">{t('orders.requestOfferReviewHint')}</p>
              <button
                type="button"
                disabled={isReviewingAdminModeration}
                onClick={() => setPendingRequestOfferAction('approve')}
                className="keep-white inline-flex h-11 w-full items-center justify-center gap-2 rounded-xl bg-[#619D51] text-sm font-bold text-white disabled:opacity-60"
              >
                {Icons.check}
                {isApprovingOffer
                  ? t('orders.requestOfferApproving')
                  : t('orders.requestOfferApprove')}
              </button>
              <button
                type="button"
                disabled={isReviewingAdminModeration}
                onClick={() => setPendingRequestOfferAction('reject')}
                className="inline-flex h-11 w-full items-center justify-center gap-2 rounded-xl bg-[#ef4444] text-sm font-bold text-white disabled:opacity-60"
              >
                {Icons.x}
                {isRejectingOffer
                  ? t('orders.requestOfferRejecting')
                  : t('orders.requestOfferReject')}
              </button>
            </section>
          ) : null}
        </aside>
      </div>

      {/* Footer: quick summary + trust badges */}
      <div className="print:hidden">
        <section className="admin-card rounded-2xl p-4 shadow-sm sm:p-5">
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4 lg:grid-cols-7">
            <SummaryStat label={t('orders.orderNumber')} value={`#${order.id}`} />
            <SummaryStat label={t('orders.orderStatusCard')} value={statusLabel} />
            <SummaryStat label={t('orders.totalAmount')} value={formatAdAmount(grandTotal, locale)} />
            <SummaryStat
              label={t('orders.orderedQuantity')}
              value={formatOrderQuantityWithUnit(orderedQuantity, order.unitName)}
            />
            <SummaryStat
              label={t('orders.supplierTotalPrice')}
              value={formatAdAmount(supplierTotal, locale)}
            />
            <SummaryStat
              label={t('orders.paymentMethod')}
              value={paymentLabel(order.paymentMethodName, t)}
            />
            <SummaryStat
              label={t('orders.shippingCost')}
              value={order.isSelfPickup ? '—' : shippingCost}
            />
          </div>
        </section>

        <div className="mt-3 flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-xs font-semibold text-slate-500">
          <span className="inline-flex items-center gap-1.5">
            {InfoFieldIcons.lock}
            {t('orders.trustSecureTransaction')}
          </span>
          <span className="inline-flex items-center gap-1.5">
            {Icons.check}
            {t('orders.trustVerifiedSupplier')}
          </span>
          <span className="inline-flex items-center gap-1.5">
            {Icons.shield}
            {t('orders.trustBuyerProtection')}
          </span>
          <span className="inline-flex items-center gap-1.5">
            {Icons.history}
            {t('orders.trust247Support')}
          </span>
          <span className="inline-flex items-center gap-1.5">
            {Icons.truck}
            {t('orders.trustFastDelivery')}
          </span>
        </div>
      </div>

      <div className="print:hidden">
        <OrderNotifyPartyDialog
          open={notifyTarget != null}
          onClose={() => setNotifyTarget(null)}
          targetUserId={notifyTarget?.userId ?? ''}
          targetName={notifyTarget?.name ?? ''}
          partyLabel={notifyTarget?.partyLabel ?? ''}
          orderId={order.id}
        />

        <ConfirmDialog
          open={pendingReturnAction != null}
          title={
            pendingReturnAction === 'reject'
              ? t('orders.returnRejectConfirmTitle')
              : t('orders.returnApproveConfirmTitle')
          }
          message={
            pendingReturnAction === 'reject'
              ? t('orders.returnRejectConfirmMessage')
              : t('orders.returnApproveConfirmMessage')
          }
          confirmLabel={t('orders.statusChangeConfirmAction')}
          cancelLabel={t('cancel')}
          danger={pendingReturnAction === 'reject'}
          busy={isResponding}
          onCancel={() => {
            if (!isResponding) setPendingReturnAction(null)
          }}
          onConfirm={() => {
            if (pendingReturnAction === 'approve') submitReturnDecision(true)
            else if (pendingReturnAction === 'reject') submitReturnDecision(false)
          }}
        />

        <ConfirmDialog
          open={confirmRefund}
          title={t('orders.processRefundConfirmTitle')}
          message={t('orders.processRefundConfirmMessage')}
          confirmLabel={t('orders.processRefund')}
          cancelLabel={t('cancel')}
          busy={isRefunding}
          onCancel={() => {
            if (!isRefunding) setConfirmRefund(false)
          }}
          onConfirm={submitManualRefund}
        />

        <ConfirmDialog
          open={pendingRequestOfferAction != null}
          title={
            pendingRequestOfferAction === 'reject'
              ? t('orders.requestOfferRejectConfirmTitle')
              : t('orders.requestOfferApproveConfirmTitle')
          }
          message={
            pendingRequestOfferAction === 'reject'
              ? t('orders.requestOfferRejectConfirmMessage')
              : t('orders.requestOfferApproveConfirmMessage')
          }
          confirmLabel={t('orders.statusChangeConfirmAction')}
          cancelLabel={t('cancel')}
          danger={pendingRequestOfferAction === 'reject'}
          busy={isReviewingAdminModeration}
          onCancel={() => {
            if (!isReviewingAdminModeration) setPendingRequestOfferAction(null)
          }}
          onConfirm={() => {
            if (pendingRequestOfferAction === 'approve') submitRequestOfferDecision(true)
            else if (pendingRequestOfferAction === 'reject') submitRequestOfferDecision(false)
          }}
        />

        <ConfirmDialog
          open={confirmMarkReceived}
          title={t('orders.markReceivedConfirmTitle')}
          message={t('orders.markReceivedConfirmMessage')}
          confirmLabel={t('orders.markReceived')}
          cancelLabel={t('cancel')}
          busy={isMarkingReceived}
          onCancel={() => {
            if (!isMarkingReceived) setConfirmMarkReceived(false)
          }}
          onConfirm={submitMarkReceived}
        />
      </div>
    </div>
  )
}
