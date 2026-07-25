import { useAppPreferences } from '../../context/AppPreferencesProvider'

type AdsFilterBarProps = {
  search: string
  onSearchChange: (value: string) => void
  approval: 'pending' | 'approved' | 'rejected' | 'all'
  onApprovalChange: (value: 'pending' | 'approved' | 'rejected' | 'all') => void
  productTypeId: string
  onProductTypeIdChange: (value: string) => void
  createdOn: string
  onCreatedOnChange: (value: string) => void
  onApply: () => void
  hideApproval?: boolean
}

export default function AdsFilterBar({
  search,
  onSearchChange,
  approval,
  onApprovalChange,
  productTypeId,
  onProductTypeIdChange,
  createdOn,
  onCreatedOnChange,
  onApply,
  hideApproval = false,
}: AdsFilterBarProps) {
  const { t } = useAppPreferences()

  return (
    <div className="admin-border flex flex-col gap-3 border-b px-4 py-4 sm:flex-row sm:flex-wrap sm:items-center sm:justify-between sm:px-6">
      <div className="flex flex-wrap items-center gap-2 sm:gap-3">
        <button
          type="button"
          onClick={onApply}
          className="keep-white inline-flex h-10 items-center gap-2 rounded-xl bg-[#3B7FC7] px-4 text-sm font-bold text-white shadow-sm transition hover:bg-[#2f6ab0]"
        >
          <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M10.5 6h9.75M10.5 6a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m-9.75 0h9.75"
            />
          </svg>
          {t('ads.filter')}
        </button>

        <select
          value={productTypeId}
          onChange={(e) => onProductTypeIdChange(e.target.value)}
          className="admin-input h-10 min-w-[9rem] px-3 text-sm"
        >
          <option value="">{t('ads.allTypes')}</option>
          <option value="3">{t('ads.typeOffers')}</option>
          <option value="1">{t('ads.typeRetail')}</option>
          <option value="2">{t('ads.typeBooking')}</option>
          <option value="4">{t('ads.typeRequests')}</option>
        </select>

        {!hideApproval ? (
          <select
            value={approval}
            onChange={(e) =>
              onApprovalChange(e.target.value as 'pending' | 'approved' | 'rejected' | 'all')
            }
            className="admin-input h-10 min-w-[9rem] px-3 text-sm"
          >
            <option value="all">{t('ads.allStatuses')}</option>
            <option value="pending">{t('ads.statusPending')}</option>
            <option value="approved">{t('ads.statusActive')}</option>
            <option value="rejected">{t('ads.statusRejected')}</option>
          </select>
        ) : null}

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
          onKeyDown={(e) => e.key === 'Enter' && onApply()}
          placeholder={t('ads.searchPlaceholderShort')}
          className="admin-input h-10 w-full ps-10 pe-3 text-sm"
        />
        <svg
          className="admin-text-subtle pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={2}
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z"
          />
        </svg>
      </div>
    </div>
  )
}
