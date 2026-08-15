import { Link } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'
import type { AdminRelatedOrder } from '../../types/adminOrder'

export default function RelatedOrdersBanner({
  relatedOrders,
}: {
  relatedOrders?: AdminRelatedOrder[] | null
}) {
  const { t } = useAppPreferences()
  const items = relatedOrders ?? []
  if (items.length === 0) return null

  return (
    <section className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3.5 shadow-sm dark:border-amber-900/60 dark:bg-amber-950/30">
      <p className="text-sm font-bold text-amber-800 dark:text-amber-200">
        {t('orders.groupedOrderNotice', { count: items.length })}
      </p>
      <p className="mt-1 text-xs font-semibold text-amber-700 dark:text-amber-300">
        {t('orders.otherProductsInCheckout')}
      </p>
      <ul className="mt-3 space-y-2">
        {items.map((item) => (
          <li key={item.id}>
            <Link
              to={`/orders/${item.id}`}
              className="flex items-center gap-3 rounded-xl bg-white/80 px-3 py-2 text-start shadow-sm ring-1 ring-amber-100 transition hover:bg-white dark:bg-slate-900/80 dark:ring-amber-900/40"
            >
              {item.primaryImagePath ? (
                <img
                  src={resolveAssetUrl(item.primaryImagePath)}
                  alt=""
                  className="h-11 w-11 shrink-0 rounded-lg object-cover"
                />
              ) : (
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-amber-100 text-xs font-bold text-amber-700">
                  #{item.id}
                </span>
              )}
              <span className="min-w-0 flex-1">
                <span className="block truncate text-sm font-bold text-slate-800 dark:text-slate-100">
                  {item.productName}
                </span>
                <span className="block text-[11px] font-medium text-slate-500">
                  #{item.id}
                  {item.supplierName ? ` · ${item.supplierName}` : ''}
                </span>
              </span>
              <span className="shrink-0 text-xs font-bold text-[#3B7FC7]">
                {t('orders.viewRelatedOrder')}
              </span>
            </Link>
          </li>
        ))}
      </ul>
    </section>
  )
}
