import { useMemo, useState } from 'react'
import InsightMiniCard from '../components/dashboard/InsightMiniCard'
import LiveActivityFeed from '../components/dashboard/LiveActivityFeed'
import MonthlySalesChart from '../components/dashboard/MonthlySalesChart'
import OverviewStatCard from '../components/dashboard/OverviewStatCard'
import RecentOrdersTable from '../components/dashboard/RecentOrdersTable'
import RecentUsersList from '../components/dashboard/RecentUsersList'
import SalesSummaryCard from '../components/dashboard/SalesSummaryCard'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useGetDashboardQuery, useLazyGetAdminOrdersQuery } from '../store'
import { queryViewState } from '../store/queryView'
import type { AdminOrder } from '../types/adminOrder'
import type { DashboardInsights, SalesSummary } from '../types/dashboard'
import { exportDashboardOrdersExcel } from '../utils/exportDashboardExcel'
import { formatDashboardAmount } from '../utils/formatMoney'
import { getRtkErrorMessage } from '../utils/rtkError'

function IconUsers() {
  return (
    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z" />
    </svg>
  )
}

function IconSuppliers() {
  return (
    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 21v-7.5a.75.75 0 0 1 .75-.75h3a.75.75 0 0 1 .75.75V21m-4.5 0H2.36m11.14 0H18m0 0h3.64m-1.39 0V9.349M3.75 21V9.349m0 0a3.001 3.001 0 0 0 3.75-.615A2.993 2.993 0 0 0 9.75 9.75c.896 0 1.7-.393 2.25-1.016a2.993 2.993 0 0 0 2.25 1.016c.414 0 .8-.084 1.15-.232" />
    </svg>
  )
}

function IconOrders() {
  return (
    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 10.5V6a3.75 3.75 0 1 0-7.5 0v4.5m11.356-1.993 1.263 12c.07.665-.45 1.243-1.119 1.243H4.25a1.125 1.125 0 0 1-1.12-1.243l1.264-12A1.125 1.125 0 0 1 5.513 7.5h12.974c.576 0 1.059.435 1.119 1.007ZM8.625 10.5a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm7.5 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" />
    </svg>
  )
}

function IconSales() {
  return (
    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 18.75a60.07 60.07 0 0 1 15.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 0 1 3 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 0 0-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 0 1-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 0 0 3 15h-.75M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm3 0h.008v.008H18V10.5Zm-12 0h.008v.008H6V10.5Z" />
    </svg>
  )
}

function defaultInsights(): DashboardInsights {
  return {
    avgOrderValue: 0,
    avgOrderValueFormatted: '0 AED',
    conversionRate: 0,
    pendingOrders: 0,
    growthRate: 0,
  }
}

function defaultSalesSummary(): SalesSummary {
  return {
    totalSales: 0,
    totalSalesFormatted: '0 AED',
    thisMonth: 0,
    thisMonthFormatted: '0 AED',
    growthPercent: 0,
  }
}

function toDateInputValue(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

function currentMonthDateInputs(): { from: string; to: string } {
  const now = new Date()
  const start = new Date(now.getFullYear(), now.getMonth(), 1)
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 0)
  return { from: toDateInputValue(start), to: toDateInputValue(end) }
}

function formatDateRangeLabel(from: string, to: string, locale: string): string {
  const start = new Date(`${from}T00:00:00`)
  const end = new Date(`${to}T00:00:00`)
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
    return `${from} – ${to}`
  }
  const fmt = new Intl.DateTimeFormat(locale === 'ar' ? 'en-US' : 'en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
  const a = fmt.format(start).replace(',', '')
  const b = fmt.format(end).replace(',', '')
  const startParts = a.split(' ')
  const endParts = b.split(' ')
  if (startParts.length >= 3 && endParts.length >= 3) {
    return `${startParts[0]} ${startParts[1]} – ${endParts[0]} ${endParts[1]}, ${endParts[2]}`
  }
  return `${a} – ${b}`
}

/** Local calendar dates → UTC day bounds for API (matches admin orders filter). */
function dateInputToUtcRange(from: string, to: string): { createdFrom: string; createdTo: string } {
  return {
    createdFrom: `${from}T00:00:00.000Z`,
    createdTo: `${to}T00:00:00.000Z`,
  }
}

export default function DashboardPage() {
  const { t, locale } = useAppPreferences()
  const initialRange = useMemo(() => currentMonthDateInputs(), [])
  const [dateFrom, setDateFrom] = useState(initialRange.from)
  const [dateTo, setDateTo] = useState(initialRange.to)

  const dashboardParams = useMemo(() => {
    if (!dateFrom || !dateTo) return undefined
    const range = dateInputToUtcRange(dateFrom, dateTo)
    return {
      createdFrom: range.createdFrom,
      createdTo: range.createdTo,
    }
  }, [dateFrom, dateTo])

  const { data, error, isLoading, isFetching } = useGetDashboardQuery(dashboardParams)
  const [fetchOrders] = useLazyGetAdminOrdersQuery()
  const [exporting, setExporting] = useState(false)
  const [exportError, setExportError] = useState<string | null>(null)
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({
    isLoading,
    isFetching,
  })
  const numberLocale = locale === 'ar' ? 'ar-AE' : 'en-US'
  const rangeLabel = formatDateRangeLabel(dateFrom, dateTo, locale)

  async function handleExportExcel() {
    setExportError(null)
    setExporting(true)
    try {
      const range = dateInputToUtcRange(dateFrom, dateTo)
      const pageSize = 100
      let page = 1
      let totalPages = 1
      const allOrders: AdminOrder[] = []

      while (page <= totalPages) {
        const result = await fetchOrders({
          page,
          pageSize,
          createdFrom: range.createdFrom,
          createdTo: range.createdTo,
        }).unwrap()
        allOrders.push(...result.items)
        totalPages = Math.max(result.totalPages || 1, 1)
        page += 1
        if (page > 200) break
      }

      await exportDashboardOrdersExcel({
        orders: allOrders,
        locale,
        rangeLabel,
      })
    } catch (err) {
      setExportError(getRtkErrorMessage(err as never, t('dashboard.exportError')))
    } finally {
      setExporting(false)
    }
  }

  if (showInitialLoader) {
    return (
      <div className="flex min-h-[50vh] items-center justify-center">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-blue-600 border-t-transparent" />
      </div>
    )
  }

  if (error || !data) {
    const message = getRtkErrorMessage(error, t('dashboard.loadError'))
    return <div className="admin-alert-error p-8 text-center">{message}</div>
  }

  const { stats } = data
  const insights = data.insights ?? defaultInsights()
  const salesSummary = data.salesSummary ?? defaultSalesSummary()
  const vsLastMonth = t('dashboard.vsPreviousPeriod')

  return (
    <div className="space-y-6">
      {showBackgroundUpdate ? (
        <p className="admin-text-subtle text-center text-xs">{t('dashboard.updating')}</p>
      ) : null}

      {exportError ? (
        <div className="admin-alert-error px-4 py-3 text-sm">{exportError}</div>
      ) : null}

      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="admin-text text-2xl font-bold tracking-tight sm:text-3xl">
            {t('dashboard.overviewTitle')}
          </h1>
          <p className="admin-text-muted mt-1 text-sm">{t('dashboard.overviewSubtitle')}</p>
          <p className="admin-text-subtle mt-1 text-xs">{t('dashboard.deliveredStatsHint')}</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <label className="admin-input inline-flex h-10 items-center gap-2 rounded-xl px-3 text-sm font-medium">
            <span className="admin-text-subtle whitespace-nowrap text-xs">{t('dashboard.dateFrom')}</span>
            <input
              type="date"
              value={dateFrom}
              max={dateTo || undefined}
              onChange={(e) => {
                const next = e.target.value
                setDateFrom(next)
                if (dateTo && next && next > dateTo) setDateTo(next)
              }}
              className="admin-text bg-transparent text-sm outline-none"
              aria-label={t('dashboard.dateFrom')}
            />
          </label>
          <label className="admin-input inline-flex h-10 items-center gap-2 rounded-xl px-3 text-sm font-medium">
            <span className="admin-text-subtle whitespace-nowrap text-xs">{t('dashboard.dateTo')}</span>
            <input
              type="date"
              value={dateTo}
              min={dateFrom || undefined}
              onChange={(e) => {
                const next = e.target.value
                setDateTo(next)
                if (dateFrom && next && next < dateFrom) setDateFrom(next)
              }}
              className="admin-text bg-transparent text-sm outline-none"
              aria-label={t('dashboard.dateTo')}
            />
          </label>
          <button
            type="button"
            disabled={exporting || !dateFrom || !dateTo}
            onClick={() => void handleExportExcel()}
            className="inline-flex h-10 items-center gap-2 rounded-xl bg-[#3B7FC7] px-4 text-sm font-bold text-white hover:bg-[#2f6ab0] disabled:opacity-60"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3" />
            </svg>
            {exporting ? t('dashboard.exporting') : t('dashboard.export')}
          </button>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <OverviewStatCard
          title={t('dashboard.totalUsers')}
          value={stats.totalUsers.value.toLocaleString(numberLocale)}
          changePercent={Number(stats.totalUsers.changePercent)}
          accent="blue"
          icon={<IconUsers />}
          sparkline={stats.totalUsers.sparkline ?? []}
          changeLabel={vsLastMonth}
        />
        <OverviewStatCard
          title={t('dashboard.activeSuppliers')}
          value={stats.activeSuppliers.value.toLocaleString(numberLocale)}
          changePercent={Number(stats.activeSuppliers.changePercent)}
          accent="green"
          icon={<IconSuppliers />}
          sparkline={stats.activeSuppliers.sparkline ?? []}
          changeLabel={vsLastMonth}
        />
        <OverviewStatCard
          title={t('dashboard.monthlyOrders')}
          value={stats.monthlyOrders.value.toLocaleString(numberLocale)}
          changePercent={Number(stats.monthlyOrders.changePercent)}
          accent="orange"
          icon={<IconOrders />}
          sparkline={stats.monthlyOrders.sparkline ?? []}
          changeLabel={vsLastMonth}
        />
        <OverviewStatCard
          title={t('dashboard.sales')}
          value={formatDashboardAmount(
            stats.totalSales.value,
            locale,
            stats.totalSales.formatted,
          )}
          changePercent={Number(stats.totalSales.changePercent)}
          accent="purple"
          icon={<IconSales />}
          sparkline={stats.totalSales.sparkline ?? []}
          changeLabel={vsLastMonth}
        />
      </div>

      <div className="grid items-start gap-6 xl:grid-cols-3">
        <div className="space-y-4 xl:col-span-2">
          <MonthlySalesChart data={data.monthlyProfits} />
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <InsightMiniCard
              title={t('dashboard.avgOrderValue')}
              value={formatDashboardAmount(
                insights.avgOrderValue,
                locale,
                insights.avgOrderValueFormatted,
              )}
              iconClassName="bg-[#E8F1FF] text-[#3B7FC7]"
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 6a7.5 7.5 0 1 0 7.5 7.5h-7.5V6Z" />
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 10.5H21A7.5 7.5 0 0 0 13.5 3v7.5Z" />
                </svg>
              }
            />
            <InsightMiniCard
              title={t('dashboard.conversionRate')}
              value={`${Number(insights.conversionRate).toLocaleString(numberLocale)}%`}
              iconClassName="bg-[#E9F9EF] text-[#22C55E]"
              icon={<IconOrders />}
            />
            <InsightMiniCard
              title={t('dashboard.pendingOrders')}
              value={insights.pendingOrders.toLocaleString(numberLocale)}
              iconClassName="bg-[#FFF1E8] text-[#F97316]"
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                </svg>
              }
            />
            <InsightMiniCard
              title={t('dashboard.growthRate')}
              value={`${Number(insights.growthRate) >= 0 ? '+' : ''}${Number(insights.growthRate)}%`}
              iconClassName="bg-[#F3EAFF] text-[#8B5CF6]"
              icon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 18 9 11.25l4.306 4.306a11.95 11.95 0 0 1 5.814-5.518l2.74-1.22m0 0-5.94-2.281m5.94 2.28-2.28 5.941" />
                </svg>
              }
            />
          </div>

          <RecentOrdersTable orders={data.recentOrders} />
          <RecentUsersList users={data.recentUsers} />
        </div>

        <div className="space-y-4 xl:sticky xl:top-4">
          <SalesSummaryCard summary={salesSummary} />
          <LiveActivityFeed items={data.recentActivity} />
        </div>
      </div>
    </div>
  )
}
