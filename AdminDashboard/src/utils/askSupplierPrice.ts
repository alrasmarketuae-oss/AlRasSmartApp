/** Structured chat payload: admin asks supplier to confirm/update product price. */

export const ASK_SUPPLIER_PRODUCT_PREFIX = 'ASK_SUPPLIER_PRODUCT:'
export const ASK_SUPPLIER_REQUESTER_PREFIX = 'ASK_SUPPLIER_REQUESTER:'
export const ASK_SUPPLIER_PRICE_HINT = 'ASK_SUPPLIER_PRICE'
export const ASK_SUPPLIER_REPLY_YES = 'ASK_SUPPLIER_REPLY:YES'
export const ASK_SUPPLIER_REPLY_NO = 'ASK_SUPPLIER_REPLY:NO'

const PRODUCT_MARKER = /ASK_SUPPLIER_PRODUCT:\s*([0-9a-fA-F-]{36})/i
const PRODUCT_NAME_LINE =
  /(?:^|\n)\s*(?:Product Name|اسم المنتج|اسم الإعلان)\s*[:：]\s*(.+)(?:\n|$)/i
const PRODUCT_CODE_LINE = /(?:^|\n)\s*(?:Product Code|كود المنتج)\s*[:：]\s*(.+)(?:\n|$)/i
const UNIT_LINE = /(?:^|\n)\s*(?:Unit|الوحدة|الوحده)\s*[:：]\s*(.+)(?:\n|$)/i
const QUANTITY_LINE =
  /(?:^|\n)\s*(?:Quantity|الكمية|الكميه)\s*[:：]\s*(.+)(?:\n|$)/i
const SUPPLIER_PRICE_LINE =
  /(?:^|\n)\s*(?:Supplier Price|سعر المورد)\s*[:：]\s*(.+)(?:\n|$)/i
const NEW_SUPPLIER_PRICE_LINE =
  /(?:^|\n)\s*(?:New Supplier Price|السعر الجديد|Confirmed Supplier Price|السعر المؤكد)\s*[:：]\s*(.+)(?:\n|$)/i
const CUSTOMER_PRICE_LINE =
  /(?:^|\n)\s*(?:Customer Price|سعر المشتري|سعر العميل)\s*[:：]\s*(.+)(?:\n|$)/i
const IMAGE_LINE = /(?:^|\n)\s*Image:\s*(.+)(?:\n|$)/i

export type AskSupplierPricePayload = {
  kind: 'ask'
  productId: string
  productName: string | null
  productCode: string | null
  unitName: string | null
  quantityLabel: string | null
  supplierPriceLabel: string | null
  imagePath: string | null
}

export type AskSupplierReplyPayload = {
  kind: 'reply'
  confirmed: boolean
  productId: string
  newSupplierPriceLabel: string | null
  customerPriceLabel: string | null
  unitName: string | null
}

export type AskSupplierPayload = AskSupplierPricePayload | AskSupplierReplyPayload

export function looksLikeAskSupplierContent(content: string | null | undefined): boolean {
  const text = content?.trim() ?? ''
  if (!text) return false
  return (
    /ASK_SUPPLIER_PRICE/i.test(text) ||
    /ASK_SUPPLIER_REPLY:/i.test(text) ||
    PRODUCT_MARKER.test(text)
  )
}

export function parseAskSupplierContent(content: string | null | undefined): AskSupplierPayload | null {
  const text = content?.trim() ?? ''
  if (!text) return null

  const productId = text.match(PRODUCT_MARKER)?.[1]?.trim()
  if (!productId) return null

  const line = (re: RegExp) => text.match(re)?.[1]?.trim() || null

  if (/ASK_SUPPLIER_REPLY:\s*YES/i.test(text)) {
    return {
      kind: 'reply',
      confirmed: true,
      productId,
      newSupplierPriceLabel: line(NEW_SUPPLIER_PRICE_LINE) || line(SUPPLIER_PRICE_LINE),
      customerPriceLabel: line(CUSTOMER_PRICE_LINE),
      unitName: line(UNIT_LINE),
    }
  }

  if (/ASK_SUPPLIER_REPLY:\s*NO/i.test(text)) {
    return {
      kind: 'reply',
      confirmed: false,
      productId,
      newSupplierPriceLabel: line(NEW_SUPPLIER_PRICE_LINE),
      customerPriceLabel: line(CUSTOMER_PRICE_LINE),
      unitName: line(UNIT_LINE),
    }
  }

  if (!/ASK_SUPPLIER_PRICE/i.test(text)) return null

  return {
    kind: 'ask',
    productId,
    productName: line(PRODUCT_NAME_LINE),
    productCode: line(PRODUCT_CODE_LINE),
    unitName: line(UNIT_LINE),
    quantityLabel: line(QUANTITY_LINE),
    supplierPriceLabel: line(SUPPLIER_PRICE_LINE),
    imagePath: line(IMAGE_LINE),
  }
}

export type BuildAskSupplierPriceArgs = {
  productId: string
  productName?: string | null
  productCode?: string | null
  unitName?: string | null
  quantityLabel?: string | null
  supplierPriceFormatted?: string | null
  supplierPriceUsd?: number | null
  imagePath?: string | null
  /** Original asker (customer) — used so supplier replies auto-relay back to them. */
  requesterUserId?: string | null
}

export function buildAskSupplierPriceMessage(args: BuildAskSupplierPriceArgs): string {
  const lines = [
    'ASK_SUPPLIER_PRICE — confirm product price:',
    `${ASK_SUPPLIER_PRODUCT_PREFIX}${args.productId}`,
  ]

  const requester = args.requesterUserId?.trim()
  if (requester) lines.push(`${ASK_SUPPLIER_REQUESTER_PREFIX}${requester}`)

  const name = args.productName?.trim()
  if (name) lines.push(`Product Name: ${name}`)

  const code = args.productCode?.trim()
  if (code) lines.push(`Product Code: ${code}`)

  const unit = args.unitName?.trim()
  if (unit) lines.push(`Unit: ${unit}`)

  const qty = args.quantityLabel?.trim()
  if (qty) lines.push(`Quantity: ${qty}`)

  const priceLabel =
    args.supplierPriceFormatted?.trim() ||
    (args.supplierPriceUsd != null && Number.isFinite(args.supplierPriceUsd)
      ? String(args.supplierPriceUsd)
      : null)
  if (priceLabel) lines.push(`Supplier Price: ${priceLabel}`)

  const image = args.imagePath?.trim()
  if (image) lines.push(`Image: ${image}`)

  return lines.join('\n')
}

export type AskSupplierTarget = {
  supplierUserId: string
  displayName: string
  avatarUrl?: string | null
  productId: string
  productName?: string | null
  productCode?: string | null
  unitName?: string | null
  quantityLabel?: string | null
  supplierPriceFormatted?: string | null
  supplierPriceUsd?: number | null
  imagePath?: string | null
}
