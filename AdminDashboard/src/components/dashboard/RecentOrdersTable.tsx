import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { RecentOrder } from '../../types/dashboard'
import { formatDashboardAmount } from '../../utils/formatMoney'
import { getOrderStatusLabel, getOrderStatusStyle } from '../../utils/orderStatus'

type RecentOrdersTableProps = {
  orders: RecentOrder[]
}

export default function RecentOrdersTable({ orders }: RecentOrdersTableProps) {
  const { t, locale } = useAppPreferences()

  return (
    <div className="admin-card rounded-2xl border border-slate-100 p-4 shadow-sm sm:p-6 dark:border-slate-300">
      <h2 className="admin-text mb-4 text-right text-base font-bold sm:mb-5 sm:text-lg">
        {t('dashboard.recentOrders')}
      </h2>

      {orders.length === 0 ? (
        <p className="admin-text-subtle py-10 text-center">{t('dashboard.noOrders')}</p>
      ) : (
        <>
          <div className="space-y-3 lg:hidden">
            {orders.map((order) => {
              const status = getOrderStatusStyle(order.statusId)
              const statusLabel = getOrderStatusLabel(order.statusId, locale)

              return (
                <article
                  key={order.id}
                  className="admin-border admin-surface rounded-xl border p-4"
                >
                  <div className="flex items-start justify-between gap-3">
                    <p className="font-semibold text-blue-600 dark:text-blue-400">
                      #{order.id}
                    </p>
                    <span
                      className={`inline-block max-w-[55%] truncate rounded-full px-3 py-1 text-xs font-semibold ${status.className}`}
                    >
                      {statusLabel}
                    </span>
                  </div>
                  <dl className="mt-3 space-y-2 text-sm">
                    <div className="flex justify-between gap-3">
                      <dt className="admin-text-subtle shrink-0">{t('dashboard.customer')}</dt>
                      <dd className="admin-text truncate text-right">{order.customerName}</dd>
                    </div>
                    <div className="flex justify-between gap-3">
                      <dt className="admin-text-subtle shrink-0">{t('dashboard.supplier')}</dt>
                      <dd className="admin-text truncate text-right">{order.supplierName}</dd>
                    </div>
                    <div className="flex justify-between gap-3">
                      <dt className="admin-text-subtle shrink-0">{t('dashboard.amount')}</dt>
                      <dd className="admin-text font-semibold">
                        {formatDashboardAmount(
                          order.totalPrice,
                          locale,
                          order.amountFormatted,
                        )}
                      </dd>
                    </div>
                  </dl>
                </article>
              )
            })}
          </div>

          <div className="hidden overflow-x-auto lg:block">
            <table className="admin-data-table admin-data-table--card min-w-[640px] table-fixed">
              <colgroup>
                <col className="w-[12%]" />
                <col className="w-[24%]" />
                <col className="w-[24%]" />
                <col className="w-[22%]" />
                <col className="w-[18%]" />
              </colgroup>
              <thead>
                <tr>
                  <th>{t('dashboard.orderNumber')}</th>
                  <th>{t('dashboard.customer')}</th>
                  <th>{t('dashboard.supplier')}</th>
                  <th>{t('users.status')}</th>
                  <th className="admin-table-cell-end">{t('dashboard.amount')}</th>
                </tr>
              </thead>
              <tbody>
                {orders.map((order) => {
                  const status = getOrderStatusStyle(order.statusId)
                  const statusLabel = getOrderStatusLabel(order.statusId, locale)
                  return (
                    <tr
                      key={order.id}
                      className="admin-row-hover admin-border border-b last:border-0"
                    >
                      <td className="font-semibold text-blue-600 dark:text-blue-700">
                        #{order.id}
                      </td>
                      <td className="admin-text">{order.customerName}</td>
                      <td className="admin-text">{order.supplierName}</td>
                      <td>
                        <span
                          className={`inline-flex whitespace-nowrap rounded-full px-3 py-1 text-xs font-semibold ${status.className}`}
                        >
                          {statusLabel}
                        </span>
                      </td>
                      <td className="admin-table-cell-end admin-text font-semibold">
                        {formatDashboardAmount(
                          order.totalPrice,
                          locale,
                          order.amountFormatted,
                        )}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  )
}
