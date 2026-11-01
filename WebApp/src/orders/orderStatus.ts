import type { StringKey } from '../i18n/strings'
import { relativeTime } from '../products/productRules'
import { isOnlinePayment, type MyOrder } from './ordersApi'

type T = (key: StringKey, vars?: Record<string, string | number>) => string

export const OrderStatus = {
  ordered: 1,
  approved: 2,
  paid: 3,
  shipping: 4,
  delivered: 5,
  cancelled: 6,
  received: 7,
  paidToSupplier: 8,
  returnRequested: 9,
  returnApproved: 10,
  awaitingSellerApproval: 11,
} as const

type StatusColors = { fg: string; bg: string }
const BY_ID: Record<number, StatusColors> = {
  1: { fg: '#1565C0', bg: '#E3F2FD' },
  2: { fg: '#6A1B9A', bg: '#F3E5F5' },
  3: { fg: '#00796B', bg: '#E0F2F1' },
  4: { fg: '#E65100', bg: '#FFF3E0' },
  5: { fg: '#2E7D32', bg: '#E8F5E9' },
  6: { fg: '#C62828', bg: '#FFEBEE' },
  7: { fg: '#2E7D32', bg: '#E8F5E9' },
  8: { fg: '#3949AB', bg: '#E8EAF6' },
  9: { fg: '#EF6C00', bg: '#FFF8E1' },
  10: { fg: '#AD1457', bg: '#FCE4EC' },
  11: { fg: '#6A1B9A', bg: '#F3E5F5' },
}

/** OrderStatusStyle: by id first, then by keywords in the status name. */
export function statusColors(statusId: number, name: string): StatusColors {
  if (BY_ID[statusId]) return BY_ID[statusId]
  const n = name.toLowerCase()
  if (n.includes('cancel')) return BY_ID[6]
  if (n.includes('ship')) return BY_ID[4]
  if (n.includes('deliver') || n.includes('received')) return BY_ID[5]
  if (n.includes('return')) return BY_ID[9]
  if (n.includes('paid')) return BY_ID[3]
  if (n.includes('approv')) return BY_ID[2]
  return { fg: '#3A7DC5', bg: '#E0F1FF' }
}

/** First-person wording when the viewer is the seller/advertiser deciding on the order. */
export function remapForDecisionMaker(apiLabel: string, statusId: number, t: T) {
  const label = apiLabel.trim()
  if (!label || label === '—') return label
  const lower = label.toLowerCase()
  if (
    statusId === OrderStatus.awaitingSellerApproval ||
    lower.includes('awaiting seller approval') ||
    label.includes('بانتظار موافقة البائع') ||
    lower.includes('awaiting advertiser approval') ||
    label.includes('بانتظار موافقة المعلن')
  )
    return t('awaitingYourApproval')
  if (lower.includes('accepted by the seller') || lower.includes('accepted by seller') || label.includes('تم قبول الطلب من البائع'))
    return t('youAcceptedTheOrder')
  if (lower.includes('order rejected') || label === 'تم رفض الطلب') return t('youRejectedTheOrder')
  if (lower.includes('accepted by the requester') || lower.includes('accepted by requester') || label.includes('قبول من قبل الطالب'))
    return t('youAcceptedTheOffer')
  if (lower.includes('rejected by the advertiser') || lower.includes('rejected by advertiser') || label.includes('رفض من قبل المعلن'))
    return t('youRejectedTheOffer')
  return label
}

export function remapOfferStatus(statusName: string, statusAr: string, statusId: number, isAr: boolean, t: T) {
  const primary = (isAr ? statusAr : statusName).trim()
  const secondary = (isAr ? statusName : statusAr).trim()
  const candidates = [primary, secondary].filter((c, i, all) => c && all.indexOf(c) === i)
  for (const candidate of candidates) {
    const remapped = remapForDecisionMaker(candidate, statusId, t)
    if (remapped !== candidate) return remapped
  }
  return candidates[0] || remapForDecisionMaker('', statusId, t) || '—'
}

export function orderStatusLabel(order: MyOrder, isAr: boolean, t: T, forDecisionMaker = false) {
  const fromApi = (isAr && order.statusLabelAr ? order.statusLabelAr : order.statusName).trim()
  const resolved =
    fromApi ||
    (order.statusId === OrderStatus.received
      ? t('delivered')
      : order.statusId === OrderStatus.awaitingSellerApproval
        ? t('awaitingSellerApproval')
        : order.statusId === OrderStatus.ordered && !order.isApproved
          ? t('awaitingAdminApproval')
          : t('unknownStatus'))
  return forDecisionMaker ? remapForDecisionMaker(resolved, order.statusId, t) : resolved
}

export type TimelineStep = { title: string; done: boolean; date?: string; subtitle?: string }

/** TrackOrderStatusHelper.buildSteps. */
export function buildTimeline(order: MyOrder, isAr: boolean, t: T, forDecisionMaker: boolean): TimelineStep[] {
  const rel = (raw: string) => relativeTime(raw, t) || undefined
  const online = isOnlinePayment(order)

  if (order.statusId === OrderStatus.cancelled) {
    const steps: TimelineStep[] = [{ title: t('orderCancelledStatus'), done: true, subtitle: t('orderCancelledStatus') }]
    if (online)
      steps.push({
        title: order.isRefunded ? t('orderRefundCompleted') : t('orderRefundPending'),
        done: order.isRefunded,
        subtitle: order.isRefunded ? (rel(order.refundedAtUtc) ?? t('orderRefundCompleted')) : t('orderRefundNotice'),
      })
    return steps
  }

  if (order.statusId === OrderStatus.returnRequested || order.statusId === OrderStatus.returnApproved) {
    const approved = order.statusId === OrderStatus.returnApproved
    const steps: TimelineStep[] = [
      { title: t('returnOrder'), done: approved, subtitle: order.returnReason.trim() || t('returnOrderConfirmMessage'), date: rel(order.returnRequestedAtUtc) },
    ]
    if (approved || order.returnAdminResponse.trim())
      steps.push({ title: t('orderReturnSuccess'), done: approved, subtitle: order.returnAdminResponse.trim() || t('orderReturnSuccess'), date: rel(order.returnRespondedAtUtc) })
    if (approved && online) {
      const refunded = order.isRefunded || !!order.stripeRefundId
      steps.push({
        title: refunded ? t('orderRefundCompleted') : t('orderRefundPending'),
        done: refunded,
        subtitle: refunded
          ? order.stripeRefundId
            ? `${t('orderRefundIdLabel')}: ${order.stripeRefundId}`
            : (rel(order.refundedAtUtc) ?? t('orderRefundCompleted'))
          : t('orderRefundNotice'),
        date: refunded ? rel(order.refundedAtUtc) : undefined,
      })
    }
    return steps
  }

  const created = rel(order.createdAt)
  const isReceived = order.statusId === OrderStatus.delivered || order.statusId === OrderStatus.received
  const steps: TimelineStep[] = [{ title: t('ordered'), done: true, date: created }]

  if (order.statusHistory.length) {
    order.statusHistory.forEach((entry, i) => {
      const label = (isAr && entry.nameAr ? entry.nameAr : entry.nameEn).trim()
      const isLast = i === order.statusHistory.length - 1
      steps.push({
        title: forDecisionMaker ? remapForDecisionMaker(label, entry.statusId, t) : label,
        done: !isLast || isReceived,
        date: rel(entry.createdAtUtc),
      })
    })
    return steps
  }

  const current = orderStatusLabel(order, isAr, t, forDecisionMaker)
  if (order.statusId === OrderStatus.ordered && !order.isApproved) {
    steps.push({ title: t('awaitingAdminApproval'), done: false, subtitle: current })
  } else if (order.statusId === OrderStatus.awaitingSellerApproval) {
    steps.push({ title: forDecisionMaker ? t('awaitingYourApproval') : t('awaitingSellerApproval'), done: false, subtitle: current })
  } else if (order.isApproved) {
    steps.push({ title: t('approved'), done: true }, { title: current, done: isReceived })
  } else {
    steps.push({ title: current, done: false })
  }
  return steps
}
