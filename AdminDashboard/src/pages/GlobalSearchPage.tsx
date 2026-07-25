import { useMemo } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import GlobalSearchBox from '../components/search/GlobalSearchBox'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useGetGlobalSearchQuery } from '../store'
import { queryViewState } from '../store/queryView'
import type { GlobalSearchSection } from '../types/globalSearch'
import { getRtkErrorMessage } from '../utils/rtkError'
import { resolvePrimaryRoute } from '../utils/searchIntelligence'

function SearchSectionBlock({
  title,
  section,
  seeAllRoute,
}: {
  title: string
  section: GlobalSearchSection
  seeAllRoute: string
}) {
  const { t } = useAppPreferences()

  if (!section.items.length) return null

  return (
    <section className="admin-card overflow-hidden">
      <div className="admin-border flex flex-wrap items-center justify-between gap-2 border-b px-4 py-3 sm:px-6">
        <h2 className="admin-text text-lg font-bold">{title}</h2>
        <Link
          to={seeAllRoute}
          className="text-sm font-semibold text-[#3B7FC7] hover:underline"
        >
          {t('globalSearch.seeAll')}
        </Link>
      </div>
      <ul className="divide-y divide-slate-100 dark:divide-slate-800">
        {section.items.map((item) => (
          <li key={`${section.section}-${item.id}`}>
            <Link
              to={item.route}
              className="flex flex-col gap-0.5 px-4 py-3 transition hover:bg-slate-50 sm:px-6 dark:hover:bg-slate-800/50"
            >
              <span className="admin-text font-medium">{item.title}</span>
              {item.subtitle ? (
                <span className="admin-text-subtle text-sm">{item.subtitle}</span>
              ) : null}
              {item.meta ? (
                <span className="admin-text-subtle text-xs">{item.meta}</span>
              ) : null}
            </Link>
          </li>
        ))}
      </ul>
    </section>
  )
}

export default function GlobalSearchPage() {
  const { t } = useAppPreferences()
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const query = params.get('q')?.trim() ?? ''

  const { data, error, isLoading, isFetching } = useGetGlobalSearchQuery(query, {
    skip: !query,
  })
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({
    isLoading,
    isFetching,
  })

  const expandedHint = useMemo(() => {
    if (!data?.expandedTerms?.length || data.expandedTerms.length <= 1) return null
    return data.expandedTerms.slice(0, 8).join(' · ')
  }, [data?.expandedTerms])

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <header className="space-y-4">
        <div>
          <h1 className="admin-page-title">{t('globalSearch.title')}</h1>
          <p className="admin-text-subtle mt-1">{t('globalSearch.subtitle')}</p>
        </div>
        <GlobalSearchBox
          variant="inline"
          className="w-full"
          inputClassName="admin-input w-full rounded-full py-3 pl-12 pr-5 text-sm"
        />
      </header>

      {!query ? (
        <div className="admin-card p-8 text-center">
          <p className="admin-text-subtle">{t('globalSearch.emptyPrompt')}</p>
        </div>
      ) : null}

      {query && showInitialLoader ? (
        <p className="admin-text-subtle text-center text-sm">{t('loading')}</p>
      ) : null}

      {query && error ? (
        <p className="text-center text-sm text-red-600">
          {getRtkErrorMessage(error, t('globalSearch.loadError'))}
        </p>
      ) : null}

      {query && data ? (
        <>
          {showBackgroundUpdate ? (
            <p className="admin-text-subtle text-center text-xs">{t('updating')}</p>
          ) : null}

          <div className="admin-card px-4 py-3 sm:px-6">
            <p className="admin-text text-sm">
              {t('globalSearch.resultsFor').replace('{query}', data.query)}
            </p>
            {expandedHint ? (
              <p className="admin-text-subtle mt-1 text-xs">
                {t('globalSearch.relatedTerms')}: {expandedHint}
              </p>
            ) : null}
            {data.primaryRoute && !data.primaryRoute.startsWith('/search') ? (
              <button
                type="button"
                onClick={() => navigate(data.primaryRoute)}
                className="mt-3 inline-flex rounded-xl bg-[#3B7FC7] px-4 py-2 text-sm font-bold text-white transition hover:bg-[#2f6ab0]"
              >
                {t('globalSearch.goToBestMatch')}
              </button>
            ) : data.sections.items.length === 0 ? (
              <button
                type="button"
                onClick={() => navigate(resolvePrimaryRoute(data.query))}
                className="mt-3 inline-flex rounded-xl border border-[#3B7FC7] px-4 py-2 text-sm font-semibold text-[#3B7FC7] transition hover:bg-blue-50 dark:hover:bg-slate-800"
              >
                {t('globalSearch.trySmartRoute')}
              </button>
            ) : null}
          </div>

          <SearchSectionBlock
            title={t('globalSearch.matchedSections')}
            section={data.sections}
            seeAllRoute="/"
          />
          <SearchSectionBlock
            title={t('nav.ads')}
            section={data.ads}
            seeAllRoute={`/ads?search=${encodeURIComponent(query)}`}
          />
          <SearchSectionBlock
            title={t('nav.users')}
            section={data.users}
            seeAllRoute={`/users?search=${encodeURIComponent(query)}`}
          />
          <SearchSectionBlock
            title={t('nav.orders')}
            section={data.orders}
            seeAllRoute={`/orders?search=${encodeURIComponent(query)}`}
          />
          <SearchSectionBlock
            title={t('nav.shipping')}
            section={data.shipping}
            seeAllRoute={`/shipping?search=${encodeURIComponent(query)}`}
          />
          <SearchSectionBlock
            title={t('nav.categories')}
            section={data.categories}
            seeAllRoute="/categories"
          />

          {!data.ads.items.length &&
          !data.users.items.length &&
          !data.orders.items.length &&
          !data.shipping.items.length &&
          !data.categories.items.length &&
          !data.sections.items.length ? (
            <div className="admin-card p-8 text-center">
              <p className="admin-text font-medium">{t('globalSearch.noResults')}</p>
              <p className="admin-text-subtle mt-2 text-sm">{t('globalSearch.tryDifferent')}</p>
            </div>
          ) : null}
        </>
      ) : null}
    </div>
  )
}
