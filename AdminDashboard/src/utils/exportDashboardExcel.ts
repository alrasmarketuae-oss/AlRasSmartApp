import ExcelJS from 'exceljs'
import type { AdminOrder } from '../types/adminOrder'
import { getOrderStatusLabel } from './orderStatus'

type ExportLocale = 'ar' | 'en'

/** Same default as backend CurrencyConversionHelper / Stripe:UsdToAedRate. */
export const DEFAULT_USD_TO_AED_RATE = 3.6725

type ExportLabels = {
  sheetOrders: string
  sheetSummary: string
  orderId: string
  date: string
  product: string
  category: string
  type: string
  buyer: string
  seller: string
  quantity: string
  unit: string
  currency: string
  customerTotal: string
  supplierTotal: string
  commissionPercent: string
  appProfit: string
  status: string
  returned: string
  yes: string
  no: string
  totalSales: string
  totalSupplier: string
  totalProfit: string
  ordersCount: string
  returnOrdersCount: string
  avgCommission: string
  summaryTitle: string
  fxNote: string
  receivedOnlyNote: string
  filePrefix: string
}

const STATUS_FILL: Record<number, string> = {
  1: 'FEF3C7',
  2: 'E0F2FE',
  3: 'E0E7FF',
  4: 'DBEAFE',
  5: 'D1FAE5',
  6: 'FEE2E2',
  7: 'D1FAE5',
  8: 'EDE9FE',
  9: 'FFEDD5',
  10: 'CCFBF1',
  11: 'F3E8FF',
}

function labelsFor(locale: ExportLocale, rate: number): ExportLabels {
  if (locale === 'ar') {
    return {
      sheetOrders: 'الطلبات',
      sheetSummary: 'الملخص',
      orderId: 'رقم الطلب',
      date: 'التاريخ',
      product: 'المنتج',
      category: 'القسم',
      type: 'النوع',
      buyer: 'المشتري',
      seller: 'البائع',
      quantity: 'الكمية',
      unit: 'الوحدة',
      currency: 'عملة الطلب',
      customerTotal: 'إجمالي المشتري (AED)',
      supplierTotal: 'إجمالي البائع (AED)',
      commissionPercent: 'نسبة ربحي %',
      appProfit: 'ربحي (AED)',
      status: 'الحالة',
      returned: 'استرجاع',
      yes: 'نعم',
      no: 'لا',
      totalSales: 'إجمالي المبيعات (AED)',
      totalSupplier: 'إجمالي مستحق البائعين (AED)',
      totalProfit: 'إجمالي ربحي (AED)',
      ordersCount: 'عدد الطلبات المسلّمة',
      returnOrdersCount: 'عدد طلبات الاسترجاع',
      avgCommission: 'متوسط نسبة الربح %',
      summaryTitle: 'ملخص الأرباح والمبيعات',
      fxNote: `المبالغ موحّدة بالدرهم. طلبات الدولار حُوّلت بسعر ${rate} AED لكل 1 USD.`,
      receivedOnlyNote:
        'الإحصائيات والصفوف أدناه للطلبات بحالة «تم التسليم / Delivered» فقط.',
      filePrefix: 'تقرير-مبيعات-وارباح',
    }
  }

  return {
    sheetOrders: 'Orders',
    sheetSummary: 'Summary',
    orderId: 'Order #',
    date: 'Date',
    product: 'Product',
    category: 'Category',
    type: 'Type',
    buyer: 'Buyer',
    seller: 'Seller',
    quantity: 'Qty',
    unit: 'Unit',
    currency: 'Order currency',
    customerTotal: 'Buyer total (AED)',
    supplierTotal: 'Seller total (AED)',
    commissionPercent: 'My profit %',
    appProfit: 'My profit (AED)',
    status: 'Status',
    returned: 'Return',
    yes: 'Yes',
    no: 'No',
    totalSales: 'Total sales (AED)',
    totalSupplier: 'Total due to sellers (AED)',
    totalProfit: 'My total profit (AED)',
    ordersCount: 'Delivered orders count',
    returnOrdersCount: 'Return orders count',
    avgCommission: 'Avg profit %',
    summaryTitle: 'Sales & profit summary',
    fxNote: `All amounts are in AED. USD orders converted at ${rate} AED per 1 USD.`,
    receivedOnlyNote:
      'Statistics and rows below include only Delivered / تم التسليم orders.',
    filePrefix: 'sales-profit-report',
  }
}

/** Delivered sale for dashboard/export (تم التسليم + legacy + paid to supplier). */
function isDeliveredSaleOrder(order: AdminOrder): boolean {
  // Cancelled / return flow are not counted as completed sales.
  if (order.statusId === 6 || order.statusId === 9 || order.statusId === 10) {
    return false
  }

  // Delivered (5), legacy Received (7), Paid to supplier after delivery (8).
  if (order.statusId === 5 || order.statusId === 7 || order.statusId === 8) {
    return true
  }

  const en = (order.statusName ?? '').trim().toLowerCase()
  const ar = (order.statusLabelAr ?? '').trim()
  return (
    en === 'delivered' ||
    en === 'received' ||
    ar === 'تم التسليم' ||
    ar === 'تم الاستلام'
  )
}

function isReturnOrder(order: AdminOrder): boolean {
  return (
    order.statusId === 9 ||
    order.statusId === 10 ||
    order.isRefunded === true ||
    Boolean(order.returnReason?.trim()) ||
    Boolean(order.returnRequestedAtUtc)
  )
}

function normalizeCurrency(currency?: string | null): 'AED' | 'USD' {
  return (currency || 'AED').trim().toUpperCase() === 'USD' ? 'USD' : 'AED'
}

function toAed(amount: number, currency: string | null | undefined, rate: number): number {
  if (!Number.isFinite(amount) || amount === 0) return 0
  if (normalizeCurrency(currency) === 'USD') {
    return amount * rate
  }
  return amount
}

/**
 * Buyer-facing total in AED.
 * Prefer chargedGrandTotalAed when the order used the AED checkout path (retail VAT/shipping
 * or product currency AED). Otherwise convert customerTotalPrice / totalPrice by currency.
 */
function customerTotalAed(order: AdminOrder, rate: number): number {
  const currency = normalizeCurrency(order.currency)
  const hasAedCheckoutExtras =
    (order.vatAed || 0) > 0 ||
    (order.shippingCostAed || 0) > 0 ||
    (order.chargedShippingAed || 0) > 0

  if (order.chargedGrandTotalAed > 0 && (hasAedCheckoutExtras || currency === 'AED')) {
    return order.chargedGrandTotalAed
  }

  const raw =
    order.customerTotalPrice > 0 ? order.customerTotalPrice : order.totalPrice
  return toAed(raw, order.currency, rate)
}

function supplierTotalAed(order: AdminOrder, rate: number): number {
  if (order.supplierTotalPrice > 0) {
    return toAed(order.supplierTotalPrice, order.currency, rate)
  }
  const cust = customerTotalAed(order, rate)
  const profit = profitAmountAed(order, rate)
  return Math.max(cust - profit, 0)
}

function profitAmountAed(order: AdminOrder, rate: number): number {
  if (order.appProfitAmount > 0) {
    return toAed(order.appProfitAmount, order.currency, rate)
  }
  const rawCustomer =
    order.customerTotalPrice > 0 ? order.customerTotalPrice : order.totalPrice
  const rawSupplier = order.supplierTotalPrice > 0 ? order.supplierTotalPrice : 0
  const rawProfit = Math.max(rawCustomer - rawSupplier, 0)
  return toAed(rawProfit, order.currency, rate)
}

function formatDate(raw: string): string {
  const d = new Date(raw)
  if (Number.isNaN(d.getTime())) return raw
  const dd = String(d.getUTCDate()).padStart(2, '0')
  const mm = String(d.getUTCMonth() + 1).padStart(2, '0')
  const yyyy = d.getUTCFullYear()
  return `${dd}/${mm}/${yyyy}`
}

function applyHeaderStyle(row: ExcelJS.Row) {
  row.height = 22
  row.eachCell((cell) => {
    cell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF3B7FC7' },
    }
    cell.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 }
    cell.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true }
    cell.border = {
      top: { style: 'thin', color: { argb: 'FFCBD5E1' } },
      left: { style: 'thin', color: { argb: 'FFCBD5E1' } },
      bottom: { style: 'thin', color: { argb: 'FFCBD5E1' } },
      right: { style: 'thin', color: { argb: 'FFCBD5E1' } },
    }
  })
}

function applyDataRowStyle(row: ExcelJS.Row, statusId: number) {
  const fill = STATUS_FILL[statusId] ?? 'F8FAFC'
  row.eachCell((cell) => {
    cell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: `FF${fill}` },
    }
    cell.font = { size: 10, color: { argb: 'FF0F172A' } }
    cell.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true }
    cell.border = {
      top: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      left: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      right: { style: 'thin', color: { argb: 'FFE2E8F0' } },
    }
  })
}

function applyTotalStyle(row: ExcelJS.Row) {
  row.height = 24
  row.eachCell((cell) => {
    cell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF166534' },
    }
    cell.font = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 }
    cell.alignment = { vertical: 'middle', horizontal: 'center' }
    cell.border = {
      top: { style: 'thin', color: { argb: 'FF14532D' } },
      left: { style: 'thin', color: { argb: 'FF14532D' } },
      bottom: { style: 'thin', color: { argb: 'FF14532D' } },
      right: { style: 'thin', color: { argb: 'FF14532D' } },
    }
  })
}

export async function exportDashboardOrdersExcel(params: {
  orders: AdminOrder[]
  locale: ExportLocale
  rangeLabel: string
  /** Override FX rate; defaults to backend Stripe:UsdToAedRate fallback. */
  usdToAedRate?: number
}): Promise<void> {
  const rate =
    params.usdToAedRate && params.usdToAedRate > 0
      ? params.usdToAedRate
      : DEFAULT_USD_TO_AED_RATE
  const { locale, rangeLabel } = params
  // Sales / profit stats only for Delivered orders.
  const orders = params.orders.filter(isDeliveredSaleOrder)
  const returnCount = params.orders.filter(isReturnOrder).length
  const L = labelsFor(locale, rate)
  const workbook = new ExcelJS.Workbook()
  workbook.creator = 'Al Ras Market Admin'
  workbook.created = new Date()

  const sheet = workbook.addWorksheet(L.sheetOrders, {
    views: [{ rightToLeft: locale === 'ar' }],
  })

  const headers = [
    L.orderId,
    L.date,
    L.product,
    L.category,
    L.type,
    L.buyer,
    L.seller,
    L.quantity,
    L.unit,
    L.currency,
    L.customerTotal,
    L.supplierTotal,
    L.commissionPercent,
    L.appProfit,
    L.status,
    L.returned,
  ]

  sheet.addRow(headers)
  applyHeaderStyle(sheet.getRow(1))

  let sumCustomer = 0
  let sumSupplier = 0
  let sumProfit = 0
  let commissionSum = 0

  for (const order of orders) {
    const cust = customerTotalAed(order, rate)
    const supp = supplierTotalAed(order, rate)
    const profit = profitAmountAed(order, rate)
    const returned = isReturnOrder(order)
    sumCustomer += cust
    sumSupplier += supp
    sumProfit += profit
    commissionSum += Number(order.commissionPercent) || 0

    const row = sheet.addRow([
      order.id,
      formatDate(order.createdAt),
      order.productName || '—',
      order.categoryName || '—',
      order.productTypeName || '—',
      order.customerName || '—',
      order.supplierName || '—',
      order.quantity,
      order.unitName || '—',
      normalizeCurrency(order.currency),
      Number(cust.toFixed(2)),
      Number(supp.toFixed(2)),
      Number((order.commissionPercent || 0).toFixed(2)),
      Number(profit.toFixed(2)),
      locale === 'ar'
        ? order.statusLabelAr?.trim() || getOrderStatusLabel(order.statusId, 'ar')
        : order.statusName?.trim() || getOrderStatusLabel(order.statusId, 'en'),
      returned ? L.yes : L.no,
    ])
    applyDataRowStyle(row, order.statusId)
  }

  const totalRow = sheet.addRow([
    '',
    '',
    '',
    '',
    '',
    '',
    locale === 'ar' ? 'الإجمالي' : 'TOTAL',
    orders.length,
    '',
    'AED',
    Number(sumCustomer.toFixed(2)),
    Number(sumSupplier.toFixed(2)),
    orders.length ? Number((commissionSum / orders.length).toFixed(2)) : 0,
    Number(sumProfit.toFixed(2)),
    '',
    '',
  ])
  applyTotalStyle(totalRow)

  sheet.columns = [
    { width: 12 },
    { width: 12 },
    { width: 28 },
    { width: 14 },
    { width: 12 },
    { width: 22 },
    { width: 22 },
    { width: 10 },
    { width: 10 },
    { width: 12 },
    { width: 18 },
    { width: 18 },
    { width: 12 },
    { width: 14 },
    { width: 22 },
    { width: 12 },
  ]

  const summary = workbook.addWorksheet(L.sheetSummary, {
    views: [{ rightToLeft: locale === 'ar' }],
  })
  summary.mergeCells('A1:B1')
  summary.getCell('A1').value = `${L.summaryTitle} — ${rangeLabel}`
  summary.getCell('A1').font = { bold: true, size: 14, color: { argb: 'FFFFFFFF' } }
  summary.getCell('A1').fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF3B7FC7' },
  }
  summary.getRow(1).height = 28

  summary.mergeCells('A2:B2')
  summary.getCell('A2').value = L.fxNote
  summary.getCell('A2').font = { size: 10, italic: true, color: { argb: 'FF334155' } }
  summary.getRow(2).height = 36
  summary.getCell('A2').alignment = { wrapText: true, vertical: 'middle' }

  summary.mergeCells('A3:B3')
  summary.getCell('A3').value = L.receivedOnlyNote
  summary.getCell('A3').font = { size: 10, bold: true, color: { argb: 'FF166534' } }
  summary.getRow(3).height = 28
  summary.getCell('A3').alignment = { wrapText: true, vertical: 'middle' }

  const summaryRows: Array<[string, string | number]> = [
    [L.ordersCount, orders.length],
    [L.returnOrdersCount, returnCount],
    [L.totalSales, Number(sumCustomer.toFixed(2))],
    [L.totalSupplier, Number(sumSupplier.toFixed(2))],
    [L.totalProfit, Number(sumProfit.toFixed(2))],
    [
      L.avgCommission,
      orders.length ? Number((commissionSum / orders.length).toFixed(2)) : 0,
    ],
  ]

  summary.addRow([locale === 'ar' ? 'البند' : 'Metric', locale === 'ar' ? 'القيمة' : 'Value'])
  applyHeaderStyle(summary.getRow(4))

  summaryRows.forEach((entry, index) => {
    const row = summary.addRow(entry)
    const isProfit = index === 4
    row.eachCell((cell) => {
      cell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: isProfit ? 'FFDCFCE7' : 'FFF8FAFC' },
      }
      cell.font = {
        bold: isProfit,
        color: { argb: isProfit ? 'FF166534' : 'FF0F172A' },
        size: 11,
      }
      cell.border = {
        top: { style: 'thin', color: { argb: 'FFE2E8F0' } },
        left: { style: 'thin', color: { argb: 'FFE2E8F0' } },
        bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } },
        right: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      }
      cell.alignment = { vertical: 'middle', horizontal: 'center' }
    })
  })

  summary.addRow([])
  const legendTitle = summary.addRow([
    locale === 'ar' ? 'ألوان الحالات' : 'Status colors',
    '',
  ])
  legendTitle.getCell(1).font = { bold: true, size: 12 }
  const legend: Array<[number, string]> = [
    [1, getOrderStatusLabel(1, locale)],
    [2, getOrderStatusLabel(2, locale)],
    [3, getOrderStatusLabel(3, locale)],
    [4, getOrderStatusLabel(4, locale)],
    [5, getOrderStatusLabel(5, locale)],
    [6, getOrderStatusLabel(6, locale)],
    [8, getOrderStatusLabel(8, locale)],
    [9, getOrderStatusLabel(9, locale)],
    [10, getOrderStatusLabel(10, locale)],
    [11, getOrderStatusLabel(11, locale)],
  ]
  for (const [statusId, label] of legend) {
    const row = summary.addRow([label, ''])
    row.getCell(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: `FF${STATUS_FILL[statusId]}` },
    }
    row.getCell(1).border = {
      top: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      left: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } },
      right: { style: 'thin', color: { argb: 'FFE2E8F0' } },
    }
  }

  summary.getColumn(1).width = 42
  summary.getColumn(2).width = 18

  const buffer = await workbook.xlsx.writeBuffer()
  const blob = new Blob([buffer], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  const stamp = new Date().toISOString().slice(0, 10)
  a.href = url
  a.download = `${L.filePrefix}-${stamp}.xlsx`
  a.click()
  URL.revokeObjectURL(url)
}
