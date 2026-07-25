import { useAppPreferences } from '../../context/AppPreferencesProvider'

type OrdersFilterBarProps = {
  search: string
  onSearchChange: (value: string) => void
  statusId: string
  onStatusIdChange: (value: string) => void
  productTypeId?: string
  onProductTypeIdChange?: (value: string) => void
  createdOn: string
  onCreatedOnChange: (value: string) => void
  hideProductTypeFilter?: boolean
}

export default function OrdersFilterBar({
  search,
  onSearchChange,
  statusId,
  onStatusIdChange,
  productTypeId = '',
  onProductTypeIdChange,
  createdOn,
  onCreatedOnChange,
  hideProductTypeFilter = false,
}: OrdersFilterBarProps) {
  const { t } = useAppPreferences()

  return (
    <div className="admin-border flex flex-col gap-3 border-b px-4 py-4 sm:flex-row sm:flex-wrap sm:items-center sm:justify-between sm:px-6">
      <div className="flex flex-wrap items-center gap-2 sm:gap-3">
        {!hideProductTypeFilter && onProductTypeIdChange ? (
          <select
            value={productTypeId}
            onChange={(e) => onProductTypeIdChange(e.target.value)}
            className="admin-input h-10 min-w-[9rem] px-3 text-sm"
          >
            <option value="">{t('orders.allTypes')}</option>
            <option value="3">{t('orders.typeOffers')}</option>
            <option value="1">{t('orders.typeRetail')}</option>
            <option value="2">{t('orders.typeBooking')}</option>
            <option value="4">{t('orders.typeRequests')}</option>
          </select>
        ) : null}

        <select
          value={statusId}
          onChange={(e) => onStatusIdChange(e.target.value)}
          className="admin-input h-10 min-w-[9rem] px-3 text-sm"
        >
          <option value="">{t('orders.allStatuses')}</option>
          <option value="1">{t('orders.statusOrdered')}</option>
          <option value="11">{t('orders.statusAwaitingSeller')}</option>
          <option value="2">{t('orders.statusApproved')}</option>
          <option value="3">{t('orders.statusPaid')}</option>
          <option value="4">{t('orders.statusShipping')}</option>
          <option value="5">{t('orders.statusDelivered')}</option>
          <option value="9">{t('orders.statusReturnRequested')}</option>
          <option value="10">{t('orders.statusReturnApproved')}</option>
          <option value="6">{t('orders.statusCancelled')}</option>
        </select>

        <input
          type="date"
          value={createdOn}
          onChange={(e) => onCreatedOnChange(e.target.value)}
          className="admin-input h-10 min-w-[10.5rem] px-3 text-sm"
        />
      </div>

      <div className="relative w-full sm:max-w-xs">
        <input
          type="search"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder={t('orders.searchPlaceholderShort')}
          className="admin-input h-10 w-full ps-10 pe-3 text-sm"
        />
        <svg
          className="admin-text-subtle pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={2}
        >
          <path strokeLinecap="round" strokeLinejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
        </svg>
      </div>
    </div>
  )
}
