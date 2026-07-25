import { Link } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'

type TabKey = 'requests' | 'offers'
type RequestFilter = 'all' | 'hasNewOffers'
type OfferReviewFilter = 'all' | 'awaitingAdmin' | 'awaitingSeller' | 'sellerApproved'

type ReqsOffersToolbarProps = {
  activeTab: TabKey
  onTabChange: (tab: TabKey) => void
  requestFilter: RequestFilter
  onRequestFilterChange: (value: RequestFilter) => void
  offerReview: OfferReviewFilter
  onOfferReviewChange: (value: OfferReviewFilter) => void
  localSearch: string
  onLocalSearchChange: (value: string) => void
  onApplySearch: () => void
  createdOn: string
  onCreatedOnChange: (value: string) => void
}

export default function ReqsOffersToolbar({
  activeTab,
  onTabChange,
  requestFilter,
  onRequestFilterChange,
  offerReview,
  onOfferReviewChange,
  localSearch,
  onLocalSearchChange,
  onApplySearch,
  createdOn,
  onCreatedOnChange,
}: ReqsOffersToolbarProps) {
  const { t } = useAppPreferences()

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="admin-text text-2xl font-bold tracking-tight">{t('reqsOffers.title')}</h1>
          <p className="admin-text-muted mt-1 text-xs">
            <Link to="/" className="hover:text-[#3B7FC7]">
              {t('nav.dashboard')}
            </Link>
            <span className="mx-1.5 opacity-50">›</span>
            <span>{t('reqsOffers.title')}</span>
          </p>
        </div>
        <Link
          to="/ads"
          className="keep-white inline-flex h-10 items-center gap-1.5 rounded-xl bg-[#2563eb] px-4 text-sm font-bold text-white shadow-sm transition hover:bg-[#1d4ed8]"
        >
          <span className="text-lg leading-none">+</span>
          {t('reqsOffers.newRequestOffer')}
        </Link>
      </div>

      <div className="admin-card flex flex-col gap-3 rounded-2xl px-4 py-3 sm:flex-row sm:flex-wrap sm:items-center">
        <div className="flex flex-wrap items-center gap-2">
          <button
            type="button"
            onClick={onApplySearch}
            className="admin-border inline-flex h-9 items-center gap-1.5 rounded-lg border bg-white px-3 text-xs font-semibold text-slate-600 transition hover:bg-slate-50 dark:bg-slate-800 dark:text-slate-200"
          >
            <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m-9.75 0h9.75" />
            </svg>
            {t('reqsOffers.filterButton')}
          </button>

          <select
            value={activeTab}
            onChange={(e) => onTabChange(e.target.value as TabKey)}
            className="admin-input h-9 rounded-lg px-3 text-xs font-semibold"
          >
            <option value="requests">{t('reqsOffers.requestsTab')}</option>
            <option value="offers">{t('reqsOffers.offersTab')}</option>
          </select>

          {activeTab === 'requests' ? (
            <select
              value={requestFilter}
              onChange={(e) => onRequestFilterChange(e.target.value as RequestFilter)}
              className="admin-input h-9 rounded-lg px-3 text-xs font-semibold"
            >
              <option value="all">{t('reqsOffers.filterAllRequests')}</option>
              <option value="hasNewOffers">{t('reqsOffers.filterHasNewOffers')}</option>
            </select>
          ) : (
            <select
              value={offerReview}
              onChange={(e) => onOfferReviewChange(e.target.value as OfferReviewFilter)}
              className="admin-input h-9 rounded-lg px-3 text-xs font-semibold"
            >
              <option value="all">{t('reqsOffers.filterAllOffers')}</option>
              <option value="awaitingAdmin">{t('reqsOffers.filterAwaitingAdmin')}</option>
              <option value="awaitingSeller">{t('reqsOffers.filterAwaitingSeller')}</option>
              <option value="sellerApproved">{t('reqsOffers.filterSellerApproved')}</option>
            </select>
          )}

          <input
            type="date"
            value={createdOn}
            onChange={(e) => onCreatedOnChange(e.target.value)}
            className="admin-input h-9 rounded-lg px-3 text-xs"
          />
        </div>

        <div className="relative min-w-[200px] flex-1 sm:max-w-xs sm:ms-auto">
          <svg
            className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" />
          </svg>
          <input
            type="search"
            value={localSearch}
            onChange={(e) => onLocalSearchChange(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') onApplySearch()
            }}
            placeholder={t('search')}
            className="admin-input h-9 w-full rounded-lg pe-3 ps-9 text-xs"
          />
        </div>
      </div>
    </div>
  )
}
