export type OrderPrintSectionKey =
  | 'orderSummary'
  | 'customerInfo'
  | 'supplierInfo'
  | 'pricingBreakdown'
  | 'specifications'
  | 'statusHistory'

export type OrderPrintOptions = Record<OrderPrintSectionKey, boolean>

export const ORDER_PRINT_SECTION_KEYS: OrderPrintSectionKey[] = [
  'orderSummary',
  'customerInfo',
  'supplierInfo',
  'pricingBreakdown',
  'specifications',
  'statusHistory',
]

/** Defaults: supplier included (including retail delivery slips). */
export const DEFAULT_ORDER_PRINT_OPTIONS: OrderPrintOptions = {
  orderSummary: true,
  customerInfo: true,
  supplierInfo: true,
  pricingBreakdown: false,
  specifications: false,
  statusHistory: false,
}

export function orderPrintSectionLabelKey(key: OrderPrintSectionKey): string {
  return `orders.printSection.${key}`
}

export function orderPrintSectionHintKey(key: OrderPrintSectionKey): string {
  return `orders.printSectionHint.${key}`
}
