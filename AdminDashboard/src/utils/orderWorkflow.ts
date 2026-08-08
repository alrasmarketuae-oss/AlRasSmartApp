export type OrderStatusAction = {
  statusId: number
  labelKey:
    | 'orders.actionApprove'
    | 'orders.actionPaid'
    | 'orders.actionShipping'
    | 'orders.actionDelivered'
    | 'orders.actionPaidToSupplier'
    | 'orders.actionCancel'
  tone: 'primary' | 'danger' | 'neutral'
}

export type OrderWorkflowContext = {
  paymentMethodName?: string
  productTypeName?: string
  categoryId?: number | null
}

function isRetailProduct(productTypeName?: string): boolean {
  const type = (productTypeName ?? '').trim().toLowerCase()
  return type === 'retail' || type.includes('تجز')
}

function isCashOnDelivery(paymentMethodName?: string): boolean {
  const method = (paymentMethodName ?? '').trim().toLowerCase()
  return method === 'cashondelivery' || method === 'cash on delivery' || method === 'cod'
}

export function isRetailCashOnDeliveryOrder(context?: OrderWorkflowContext): boolean {
  return isRetailProduct(context?.productTypeName) && isCashOnDelivery(context?.paymentMethodName)
}

/**
 * All current catalog flows: after seller accept, admin uses bilingual text status only.
 * Paid / Shipping / Delivered / Paid-to-supplier buttons must not appear.
 */
export function usesTextStatusWorkflow(order: {
  productTypeName?: string
  categoryId?: number | null
}): boolean {
  const type = (order.productTypeName ?? '').trim().toLowerCase()
  if (
    isRetailProduct(order.productTypeName) ||
    type.includes('booking') ||
    type.includes('حجز') ||
    type.includes('offer') ||
    type.includes('عرض') ||
    type.includes('request') ||
    type.includes('طلب')
  ) {
    return true
  }

  // Category catalog products (category set, no typed product workflow).
  if (
    order.categoryId != null &&
    (!type || type === '—' || type === '-')
  ) {
    return true
  }

  // Default: treat unknown catalog orders as text-status too.
  return true
}

/** After seller accept — show custom bilingual status form, not workflow buttons. */
export function canSetCustomTextStatus(order: {
  productTypeName?: string
  categoryId?: number | null
  isApproved?: boolean
  statusId: number
}): boolean {
  const terminal = [5, 6, 7, 8, 9, 10]
  return (
    usesTextStatusWorkflow(order) &&
    Boolean(order.isApproved) &&
    !terminal.includes(order.statusId)
  )
}

/** Final Received / تم الاستلام button after seller accept. */
export function canMarkOrderReceived(order: {
  productTypeName?: string
  categoryId?: number | null
  isApproved?: boolean
  statusId: number
  canMarkReceived?: boolean
}): boolean {
  if (typeof order.canMarkReceived === 'boolean') {
    return order.canMarkReceived
  }
  return canSetCustomTextStatus(order)
}

/** Blink cue: unfinished seller-approved/retail, or request-offers not awaiting seller / not delivered. */
export function orderNeedsAttention(order: {
  productTypeName?: string
  categoryId?: number | null
  categoryName?: string
  isApproved?: boolean
  isAdminApproved?: boolean
  statusId: number
  needsAttention?: boolean
}): boolean {
  // Category / booking / offer awaiting admin approval must blink even if API
  // still returns needsAttention=false for those types.
  if (needsAdminOrderModeration(order)) {
    return true
  }

  if (typeof order.needsAttention === 'boolean') {
    return order.needsAttention
  }
  const terminal = [5, 6, 7, 8, 10]
  if (terminal.includes(order.statusId)) return false

  const type = (order.productTypeName ?? '').trim().toLowerCase()
  const isRequestOffer = type.includes('request') || type.includes('طلب')
  if (isRequestOffer) {
    // 11 = AwaitingSellerApproval
    return order.statusId !== 11
  }

  if (order.isApproved) return true
  return type.includes('retail') || type.includes('تجز')
}

/**
 * Approval-stage blink cue for order rows:
 * - 'pending'  → still awaiting the app admin's approval OR the seller's approval (yellow).
 * - 'approved' → the seller has approved the order (green).
 * - 'none'     → terminal/return states get no approval blink.
 */
export function orderApprovalBlink(order: {
  productTypeName?: string
  categoryId?: number | null
  isApproved?: boolean
  isAdminApproved?: boolean
  statusId: number
}): 'pending' | 'approved' | 'none' {
  // Delivered / Cancelled / Paid / Return states carry no approval blink.
  const settled = [5, 6, 7, 8, 9, 10]
  if (settled.includes(order.statusId)) return 'none'

  // Seller accepted the order → green.
  if (order.isApproved || order.statusId === 2) return 'approved'

  // Awaiting the app admin's approval or the seller's approval → yellow.
  if (
    needsAdminOrderModeration(order) ||
    order.statusId === 11 || // AwaitingSellerApproval
    order.statusId === 1 // Ordered, not yet approved
  ) {
    return 'pending'
  }

  return 'none'
}

/**
 * Paid/Shipping/Delivered workflow buttons are disabled for text-status orders.
 * Admin moderation (approve/reject offer) and custom status form handle the rest.
 */
export function getOrderStatusActions(
  _statusId: number,
  context?: OrderWorkflowContext,
): OrderStatusAction[] {
  if (usesTextStatusWorkflow(context ?? {})) {
    return []
  }

  return []
}

export function canUpdateOrderStatus(
  _statusId: number,
  context?: OrderWorkflowContext,
): boolean {
  // Workflow PATCH buttons are hidden; use custom status / moderation instead.
  if (usesTextStatusWorkflow(context ?? {})) {
    return false
  }

  return false
}

function isModeratedProductType(productTypeName?: string): boolean {
  const type = (productTypeName ?? '').trim().toLowerCase()
  return (
    type.includes('request') ||
    type.includes('offer') ||
    type.includes('طلب') ||
    type.includes('عرض')
  )
}

export function needsAdminOrderModeration(order: {
  productTypeName?: string
  categoryId?: number | null
  isAdminApproved?: boolean
  statusId: number
}): boolean {
  const type = (order.productTypeName ?? '').trim().toLowerCase()

  // Pure cart retail is seller-first (IsAdminApproved already true).
  // Hybrid category listings keep type "Retail" + categoryId and can await admin when notes/media exist.
  if (isRetailProduct(order.productTypeName)) {
    if (order.categoryId == null || order.isAdminApproved) {
      return false
    }
    return order.statusId === 1
  }

  if (type.includes('booking') || type.includes('حجز')) {
    if (order.isAdminApproved) {
      return false
    }
    return order.statusId === 1
  }

  // Category catalog products (no typed product workflow).
  // Hybrid wholesale POs now report productTypeName = "Wholesale".
  const isCategoryCatalog =
    order.categoryId != null &&
    (!type ||
      type === '—' ||
      type === '-' ||
      type === 'category' ||
      type === 'wholesale' ||
      type.includes('جملة') ||
      type.includes('كاتيجور') ||
      type.includes('قسم'))

  if (isCategoryCatalog) {
    if (order.isAdminApproved) {
      return false
    }
    return order.statusId === 1
  }

  if (order.isAdminApproved) {
    return false
  }

  return isModeratedProductType(order.productTypeName) && order.statusId === 1
}
