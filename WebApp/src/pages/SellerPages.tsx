import { useInfiniteQuery, useQuery, useQueryClient, type InfiniteData } from '@tanstack/react-query'
import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { useLocation, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { Spinner } from '../auth/components'
import { useI18n } from '../i18n/I18nProvider'
import { PageContainer } from '../layout/MainLayout'
import { PrimaryButton, Screen } from '../layout/ScreenLayout'
import { ApiError } from '../lib/api'
import { resolveMediaUrl } from '../lib/media'
import { usePageTitle } from '../lib/usePageTitle'
import { fetchNotifications, markAllNotificationsRead, markNotificationRead, navigationRoute, type AppNotification, type NotificationsPage } from '../notifications/notificationsApi'
import { notificationTarget } from '../notifications/notificationRoute'
import { unreadNotificationsKey } from '../notifications/useUnreadNotifications'
import { CurrencyMark } from '../products/ProductCard'
import { formatAmount, isPureRetailProduct, localized, productTitle, relativeTime } from '../products/productRules'
import { AdInfoCard, OfferCardSkeleton, RequestOfferCard, orderStatusStyle, type OfferAction } from '../seller/AdOrders'
import {
  STATUS_FILTERS,
  STATUS_FILTER_META,
  TYPE_FILTERS,
  TYPE_FILTER_LABEL,
  isHybridCategoryRetail,
  matchesStatus,
  matchesType,
  ownerListingPrice,
  requiresAdminOrderModeration,
  typeFilterFor,
  wholesaleCurrency,
  withPendingFirst,
  type StatusFilter,
  type TypeFilter,
} from '../seller/listingRules'
import { BLINK_STYLE, MY_LISTINGS_KEY, MediaThumb, MessageView, MyAdCard, MyAdCardSkeleton, type CardChannel } from '../seller/MyAdCard'
import {
  fetchAdOrders,
  fetchMyListings,
  fetchMySubmittedOffers,
  updateOrderStatus,
  updateProductPrice,
  type AdOrder,
  type MyListing,
  type OrdersPage,
  type SubmittedOffer,
} from '../seller/sellerApi'
import { useInfiniteSentinel } from '../seller/useInfiniteSentinel'
import { formatNumberInput } from '../ui/Form'
import { Icon, type IconName } from '../ui/Icon'
import { useToast } from '../ui/Toast'

const errorText = (error: unknown, fallback: string) => (error instanceof ApiError ? error.message : error instanceof Error ? error.message : fallback)
const sameId = (a?: string | null, b?: string | null) => !!a && !!b && a.trim().toLowerCase() === b.trim().toLowerCase()

function useMyListings() {
  const { isAuthenticated, session } = useAuth()
  return useQuery({ queryKey: [MY_LISTINGS_KEY, session?.id], queryFn: fetchMyListings, enabled: isAuthenticated })
}

function LoginPrompt({ message }: { message: string }) {
  const { t } = useI18n()
  const navigate = useNavigate()
  return (
    <MessageView icon="lock" title={message}>
      <button type="button" onClick={() => navigate('/login')} className="rounded-xl bg-brand px-8 py-3 text-sm font-bold text-white hover:brightness-110">
        {t('login')}
      </button>
    </MessageView>
  )
}

/* ─────────────────────────── My Ads (Account tab) ─────────────────────────── */

function ChangePricesBanner() {
  const { t } = useI18n()
  const navigate = useNavigate()
  const { isCompanyCustomer } = useAuth()
  return (
    <button
      type="button"
      onClick={() => navigate('/change-prices')}
      className="flex w-full items-center gap-3 rounded-[14px] border border-[#E6EEF8] bg-white px-3.5 py-3 text-start shadow-[0_4px_14px_rgba(22,35,58,0.05)] hover:bg-[#FBFDFF]"
    >
      <span className="grid size-[42px] shrink-0 place-items-center rounded-xl bg-brand text-white">
        <Icon name="tag" size={20} />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block truncate text-[14px] font-extrabold text-title">{isCompanyCustomer ? t('changeTargetPrices') : t('changePrices')}</span>
        <span className="mt-0.5 line-clamp-2 block text-[11.5px] leading-snug text-subtitle">
          {isCompanyCustomer ? t('changeTargetPricesSubtitle') : t('changePricesSubtitle')}
        </span>
      </span>
      <span className="grid size-7 shrink-0 place-items-center rounded-full bg-brand text-white">
        <Icon name="chevronRight" size={16} strokeWidth={2.4} className="rtl:rotate-180" />
      </span>
    </button>
  )
}

function SectionTabs({ index, onChange }: { index: number; onChange: (i: number) => void }) {
  const { t } = useI18n()
  const items: { label: string; icon: IconName }[] = [
    { label: t('myAds'), icon: 'doc' },
    { label: t('myOffers'), icon: 'tag' },
  ]
  return (
    <div className="grid grid-cols-2 gap-4">
      {items.map((item, i) => {
        const selected = index === i
        return (
          <button
            key={item.label}
            type="button"
            onClick={() => onChange(i)}
            className={`flex items-center gap-1.5 rounded-2xl border-[1.4px] border-brand px-3 py-3 shadow-[0_2px_6px_rgba(0,0,0,0.05)] transition-colors ${selected ? 'bg-brand text-white' : 'bg-white text-brand'}`}
          >
            <Icon name={item.icon} size={16} />
            <span className="min-w-0 flex-1 truncate text-start text-[13px] font-bold">{item.label}</span>
            <Icon name="chevronRight" size={18} className="rtl:rotate-180" />
          </button>
        )
      })}
    </div>
  )
}

const TYPE_ICON: Record<TypeFilter, IconName> = { all: 'grid', categories: 'box', requests: 'doc', offers: 'tag', booking: 'calendar', retail: 'building' }
const STATUS_ICON: Record<StatusFilter, IconName> = { all: 'grid', active: 'check', paused: 'stop', review: 'timer', soldOut: 'close' }

function TypeFilterCards({ value, onChange }: { value: TypeFilter; onChange: (f: TypeFilter) => void }) {
  const { t } = useI18n()
  return (
    <div className="grid grid-cols-6 gap-1.5">
      {TYPE_FILTERS.map((filter) => {
        const selected = filter === value
        return (
          <button
            key={filter}
            type="button"
            onClick={() => onChange(filter)}
            className={`flex min-w-0 flex-col items-center gap-1 rounded-[14px] bg-white px-0.5 py-2 shadow-[0_1px_4px_rgba(0,0,0,0.04)] ${selected ? 'border-[1.6px] border-brand' : 'border border-[#E6EEF5]'}`}
          >
            <Icon name={TYPE_ICON[filter]} size={18} className={selected ? 'text-brand' : 'text-[#94A3B8]'} />
            <span className={`w-full truncate text-center text-[11px] leading-tight ${selected ? 'font-extrabold text-brand' : 'font-semibold text-[#1F2937]'}`}>
              {t(TYPE_FILTER_LABEL[filter])}
            </span>
          </button>
        )
      })}
    </div>
  )
}

function StatusFilterChips({ value, onChange, counts }: { value: StatusFilter; onChange: (f: StatusFilter) => void; counts: Record<StatusFilter, number> }) {
  const { t } = useI18n()
  return (
    <div className="grid grid-cols-5 gap-1">
      {STATUS_FILTERS.map((filter) => {
        const selected = filter === value
        const { label, color } = STATUS_FILTER_META[filter]
        return (
          <button
            key={filter}
            type="button"
            onClick={() => onChange(filter)}
            className="flex min-w-0 flex-col items-center gap-0.5 rounded-[14px] px-0.5 py-[7px]"
            style={{ color, border: `${selected ? 1.6 : 1.15}px solid ${color}`, background: selected ? `${color}1A` : '#fff' }}
          >
            <Icon name={STATUS_ICON[filter]} size={15} />
            <span className={`w-full truncate text-center text-[10px] leading-tight ${selected ? 'font-extrabold' : 'font-semibold'}`}>{t(label)}</span>
            <span className="text-[13px] font-extrabold leading-none">{counts[filter]}</span>
          </button>
        )
      })}
    </div>
  )
}

function SubmittedOfferCard({ order }: { order: SubmittedOffer }) {
  const { t, isAr } = useI18n()
  const navigate = useNavigate()
  const colors = orderStatusStyle(order.statusId)
  const status = (isAr ? order.statusAr : order.statusName) || order.statusName || order.statusAr
  const name = localized(order.productNameAr, order.productNameEn, order.productName, isAr)
  const details = localized(order.descriptionAr, order.descriptionEn, '', isAr)
  const unit = localized(order.unitNameAr, order.unitNameEn, '', isAr)
  const qty = [formatAmount(order.quantity), unit].filter(Boolean).join(' ')
  const image = resolveMediaUrl(order.imagePath)
  return (
    <button
      type="button"
      onClick={() => navigate(`/orders/${order.orderId}`)}
      className="block w-full rounded-2xl border border-line bg-white p-3 text-start shadow-[0_4px_12px_rgba(0,0,0,0.06)] hover:bg-[#FBFDFF]"
    >
      <div className="flex items-start gap-3">
        <span className="size-[88px] shrink-0 overflow-hidden rounded-xl bg-[#F3F4F6]">
          {image ? (
            <img src={image} alt="" loading="lazy" className="size-full object-cover" />
          ) : (
            <span className="grid size-full place-items-center text-[#9CA3AF]">
              <Icon name="box" size={26} />
            </span>
          )}
        </span>
        <span className="min-w-0 flex-1">
          <span className="flex items-start gap-1">
            <span className="truncate rounded-lg px-2 py-1 text-[11px] font-semibold" style={{ background: colors.bg, color: colors.fg }}>
              {status || '—'}
            </span>
          </span>
          <span className="mt-2 block truncate text-[15px] font-bold leading-snug text-[#1E293B] first-letter:uppercase">{name || '—'}</span>
          {details && <span className="mt-1 line-clamp-2 block text-xs leading-snug text-subtitle">{details}</span>}
        </span>
      </div>
      <span className="mt-3 grid grid-cols-3 gap-2">
        <StatCell label={t('requestedQuantity')}>{qty}</StatCell>
        <StatCell label={t('total')}>
          <span dir="ltr" className="inline-flex items-center gap-1 text-[14px] font-extrabold text-brand">
            {formatAmount(order.totalPrice)}
            <CurrencyMark currency={order.currency.toUpperCase()} size={14} />
          </span>
        </StatCell>
        <StatCell label={t('orderDate')}>{relativeTime(order.createdAt, t)}</StatCell>
      </span>
    </button>
  )
}

function StatCell({ label, children }: { label: string; children: ReactNode }) {
  return (
    <span className="min-w-0">
      <span className="block truncate text-[11px] text-subtitle">{label}</span>
      <span className="mt-1 block truncate text-[13px] font-bold text-[#1E293B]">{children}</span>
    </span>
  )
}

function MyOffersList() {
  const { t } = useI18n()
  const { session } = useAuth()
  const query = useInfiniteQuery({
    queryKey: ['my-submitted-offers', session?.id],
    initialPageParam: 1,
    queryFn: ({ pageParam, signal }) => fetchMySubmittedOffers(pageParam, signal),
    getNextPageParam: (last) => (last.page < last.totalPages && last.items.length > 0 ? last.page + 1 : undefined),
  })
  const items = query.data?.pages.flatMap((p) => p.items) ?? []
  const sentinel = useInfiniteSentinel(() => void query.fetchNextPage(), query.hasNextPage && !query.isFetchingNextPage, items.length)

  if (query.isPending) return <ListSkeleton />
  if (query.isError && !items.length) return <ErrorView message={errorText(query.error, t('unexpectedError'))} onRetry={() => void query.refetch()} />
  if (!items.length) return <MessageView icon="tag" title={t('noOffersYet')} />
  return (
    <div className="space-y-3">
      {items.map((order) => (
        <SubmittedOfferCard key={order.orderId} order={order} />
      ))}
      <div ref={sentinel} />
      {query.isFetchingNextPage && <LoadingMore />}
    </div>
  )
}

function ListSkeleton() {
  return (
    <div className="space-y-3">
      {Array.from({ length: 4 }, (_, i) => (
        <MyAdCardSkeleton key={i} />
      ))}
    </div>
  )
}

function LoadingMore() {
  return (
    <div className="grid place-items-center py-4">
      <Spinner className="size-6 border-brand/25 border-t-brand" />
    </div>
  )
}

function ErrorView({ message, onRetry }: { message: string; onRetry: () => void }) {
  const { t } = useI18n()
  return (
    <div className="flex flex-col items-center gap-3 px-6 py-16 text-center">
      <p className="text-sm text-subtitle">{message}</p>
      <button type="button" onClick={onRetry} className="text-sm font-bold text-brand hover:underline">
        {t('retry')}
      </button>
    </div>
  )
}

export function MyAdsPage() {
  const { t } = useI18n()
  const { isAuthenticated, isCompanyCustomer, isSupplier, isUaePhone } = useAuth()
  const [params, setParams] = useSearchParams()
  const highlight = params.get('highlight')?.trim() || ''
  usePageTitle(t('myAds'))

  const lockedType: TypeFilter | null = isCompanyCustomer ? 'requests' : isSupplier && !isUaePhone ? 'booking' : null
  const showOffersSection = !isCompanyCustomer
  const [section, setSection] = useState(0)
  const [typeFilter, setTypeFilter] = useState<TypeFilter>('all')
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
  const activeType = lockedType ?? typeFilter

  const query = useMyListings()
  const products = useMemo(() => query.data?.products ?? [], [query.data])
  const typeFiltered = useMemo(() => products.filter((p) => matchesType(p, activeType)), [products, activeType])
  const preferRetail = activeType === 'retail'
  const counts = useMemo(() => {
    const result = {} as Record<StatusFilter, number>
    for (const f of STATUS_FILTERS) result[f] = typeFiltered.filter((p) => matchesStatus(p, f, preferRetail)).length
    return result
  }, [typeFiltered, preferRetail])
  const visible = useMemo(() => withPendingFirst(typeFiltered.filter((p) => matchesStatus(p, statusFilter, preferRetail))), [typeFiltered, statusFilter, preferRetail])

  const handledHighlight = useRef('')
  useEffect(() => {
    if (!highlight || handledHighlight.current === highlight || !products.length) return
    const target = products.find((p) => sameId(p.productId, highlight))
    if (!target) return
    handledHighlight.current = highlight
    setSection(0)
    setStatusFilter('all')
    if (!lockedType) {
      const mapped = typeFilterFor(target)
      setTypeFilter(mapped)
    }
    window.setTimeout(() => document.getElementById(`ad-${target.productId}`)?.scrollIntoView({ behavior: 'smooth', block: 'center' }), 120)
    const id = window.setTimeout(() => {
      setParams(
        (prev) => {
          const next = new URLSearchParams(prev)
          next.delete('highlight')
          return next
        },
        { replace: true },
      )
    }, 5200)
    return () => window.clearTimeout(id)
  }, [highlight, products, lockedType, setParams])

  const channelFor = (p: MyListing): CardChannel => ({
    preferRetail: preferRetail || isPureRetailProduct(p),
    preferCategory: activeType === 'categories',
    showBoth: activeType === 'all' && isHybridCategoryRetail(p),
  })

  const viewAll = () => {
    if (!lockedType) setTypeFilter('all')
    setStatusFilter('all')
  }

  if (!isAuthenticated) {
    return (
      <PageContainer narrow className="py-4">
        <LoginPrompt message={t('pleaseLoginToViewYourAds')} />
      </PageContainer>
    )
  }

  const filtersActive = activeType !== (lockedType ?? 'all') || statusFilter !== 'all'
  const heading = query.data?.ownerName?.trim() || t('account')

  return (
    <PageContainer narrow className="space-y-3 py-4">
      <style>{BLINK_STYLE}</style>
      <h1 className="text-center text-lg font-extrabold text-title first-letter:uppercase">{heading}</h1>
      <ChangePricesBanner />
      {showOffersSection && <SectionTabs index={section} onChange={setSection} />}

      {showOffersSection && section === 1 ? (
        <MyOffersList />
      ) : (
        <>
          {!lockedType && <TypeFilterCards value={typeFilter} onChange={setTypeFilter} />}
          <StatusFilterChips value={statusFilter} onChange={setStatusFilter} counts={counts} />
          <div className="flex items-center gap-2 pt-0.5">
            <h2 className="flex-1 text-[15px] font-extrabold text-title">{t('recentListings')}</h2>
            <button type="button" onClick={viewAll} className="flex items-center text-[13px] font-bold text-brand hover:underline">
              {t('viewAll')}
              <Icon name="chevronRight" size={18} className="rtl:rotate-180" />
            </button>
          </div>

          {query.isPending ? (
            <ListSkeleton />
          ) : query.isError && !products.length ? (
            <ErrorView message={errorText(query.error, t('unexpectedError'))} onRetry={() => void query.refetch()} />
          ) : !visible.length ? (
            <MessageView icon="box" title={filtersActive && products.length ? t('noAdsMatchFilter') : t('noProductsFound')} />
          ) : (
            <div className="space-y-3">
              {visible.map((p) => (
                <MyAdCard key={p.productId} product={p} highlighted={sameId(p.productId, highlight)} channel={channelFor(p)} />
              ))}
            </div>
          )}
        </>
      )}
    </PageContainer>
  )
}

/* ─────────────────────────── Orders / offers on one ad ─────────────────────────── */

type AdLocationState = { product?: MyListing } & Partial<CardChannel>

export function AdDetailsPage() {
  const { t } = useI18n()
  const { productId = '' } = useParams()
  const location = useLocation()
  const navigate = useNavigate()
  const toast = useToast()
  const queryClient = useQueryClient()
  const { isAuthenticated, session } = useAuth()
  const state = (location.state ?? {}) as AdLocationState

  const listings = useMyListings()
  const product = (state.product && sameId(state.product.productId, productId) ? state.product : null) ?? listings.data?.products.find((p) => sameId(p.productId, productId)) ?? null
  const requestAd = product ? product.productTypeId === 4 || /request/i.test(product.productTypeName ?? '') : false
  const title = requestAd ? t('offersInfo') : t('ordersOnAd')
  usePageTitle(title)

  const ordersKey = ['ad-orders', session?.id, productId]
  const orders = useInfiniteQuery({
    queryKey: ordersKey,
    initialPageParam: 1,
    enabled: isAuthenticated && !!productId,
    queryFn: ({ pageParam, signal }) => fetchAdOrders(productId, pageParam, signal),
    getNextPageParam: (last) => (last.page < last.totalPages && last.items.length > 0 ? last.page + 1 : undefined),
  })
  const items = orders.data?.pages.flatMap((p) => p.items) ?? []
  const totalCount = orders.data?.pages[0]?.totalCount ?? 0
  const sentinel = useInfiniteSentinel(() => void orders.fetchNextPage(), orders.hasNextPage && !orders.isFetchingNextPage, items.length, 200)

  const [pending, setPending] = useState<{ orderId: number; action: OfferAction } | null>(null)
  const controller = useRef<AbortController | null>(null)
  useEffect(() => () => controller.current?.abort(), [])

  const decide = async (order: AdOrder, action: OfferAction) => {
    if (pending) return
    const abort = new AbortController()
    controller.current = abort
    setPending({ orderId: order.orderId, action })
    try {
      await updateOrderStatus(order.orderId, action === 'accept' ? 2 : 6, abort.signal)
      queryClient.setQueryData<InfiniteData<OrdersPage<AdOrder>>>(ordersKey, (old) =>
        old
          ? { ...old, pages: old.pages.map((page) => ({ ...page, items: page.items.map((o) => (o.orderId === order.orderId ? { ...o, statusId: action === 'accept' ? 2 : 6, canAccept: false, canReject: false } : o)) })) }
          : old,
      )
      void queryClient.invalidateQueries({ queryKey: ['ad-orders'] })
      void queryClient.invalidateQueries({ queryKey: [MY_LISTINGS_KEY] })
    } catch (error) {
      if (!abort.signal.aborted) toast.error(errorText(error, t('unexpectedError')))
    } finally {
      if (controller.current === abort) controller.current = null
      setPending(null)
    }
  }

  const cancel = () => {
    controller.current?.abort()
    controller.current = null
    setPending(null)
  }

  if (!isAuthenticated) {
    return (
      <Screen title={title} fallback="/my-ads">
        <LoginPrompt message={t('pleaseLoginToContinue')} />
      </Screen>
    )
  }
  if (!productId) {
    return (
      <Screen title={title} fallback="/my-ads">
        <MessageView icon="info" title={t('productIdMissing')} />
      </Screen>
    )
  }

  const emptyText = product && requiresAdminOrderModeration(product) ? t('noVisibleOrdersPendingAdmin') : requestAd ? t('noOffersOnAd') : t('noOrdersOnAd')

  return (
    <Screen title={title} fallback="/my-ads">
      <div className="space-y-4">
        {product ? (
          <AdInfoCard product={product} preferRetail={!!state.preferRetail} preferCategory={!!state.preferCategory} showBothChannels={!!state.showBoth} />
        ) : (
          listings.isPending && <div className="shimmer h-[62px] rounded-lg" />
        )}

        <div className="flex items-center gap-3 px-1 pt-1">
          <h2 className="flex-1 text-base font-semibold text-black">{requestAd ? t('receivedOffers') : t('receivedOrders')}</h2>
          <span className="text-sm font-medium text-[#3A7DC5]">{requestAd ? t('offersAvailable', { count: totalCount }) : t('ordersAvailable', { count: totalCount })}</span>
        </div>

        {orders.isPending ? (
          <div className="space-y-3">
            <OfferCardSkeleton />
            <OfferCardSkeleton />
          </div>
        ) : orders.isError && !items.length ? (
          <ErrorView message={errorText(orders.error, t('unexpectedError'))} onRetry={() => void orders.refetch()} />
        ) : !items.length ? (
          <p className="px-6 py-8 text-center text-sm text-[#333333]/70">{emptyText}</p>
        ) : (
          <div className="space-y-3">
            {items.map((offer) => (
              <RequestOfferCard
                key={offer.orderId}
                offer={offer}
                requestAd={requestAd}
                pending={pending?.orderId === offer.orderId ? pending.action : null}
                onAccept={() => void decide(offer, 'accept')}
                onReject={() => void decide(offer, 'reject')}
                onCancel={cancel}
                onTrack={() => navigate(`/orders/${offer.orderId}`)}
              />
            ))}
            <div ref={sentinel} />
            {orders.isFetchingNextPage && <LoadingMore />}
          </div>
        )}
      </div>
    </Screen>
  )
}

/* ─────────────────────────── Change prices ─────────────────────────── */

type PriceEditor = { wholesale: string; retail: string; hasRetail: boolean; originalWholesale: number; originalRetail: number | null }

const parsePrice = (value: string) => {
  const cleaned = value.replace(/,/g, '').trim()
  if (!cleaned) return null
  const parsed = Number(cleaned)
  return Number.isFinite(parsed) ? parsed : null
}
const fmt = (value: number) => (value ? formatNumberInput(String(Math.round(value * 1000) / 1000)) : '')
const same = (a: number | null, b: number | null) => (a === null || b === null ? a === b : Math.abs(a - b) < 0.0001)

function editorFor(p: MyListing): PriceEditor {
  const wholesale = ownerListingPrice(p)
  const hasRetail = p.hasRetailPricing === true || isHybridCategoryRetail(p)
  const retail = hasRetail ? parsePrice(String(p.retailPrice ?? '')) ?? 0 : null
  return { wholesale: fmt(wholesale), retail: retail === null ? '' : fmt(retail), hasRetail, originalWholesale: wholesale, originalRetail: retail }
}

const isDirty = (e?: PriceEditor) => !!e && (!same(parsePrice(e.wholesale), e.originalWholesale) || (e.hasRetail && !same(parsePrice(e.retail), e.originalRetail)))

function PriceField({ value, currency, onChange, label }: { value: string; currency: string; onChange: (v: string) => void; label: string }) {
  return (
    <label className="flex h-10 items-center rounded-[10px] border border-[#E6EEF8] bg-[#F6F9FE] focus-within:border-brand">
      <input
        value={value}
        inputMode="decimal"
        dir="ltr"
        aria-label={label}
        onChange={(e) => onChange(formatNumberInput(e.target.value))}
        className="h-full min-w-0 flex-1 bg-transparent px-2.5 text-end text-[13px] font-bold text-title outline-none"
      />
      <span className="pe-2.5">
        <CurrencyMark currency={currency} size={14} />
      </span>
    </label>
  )
}

export function ChangePricesPage() {
  const { t, isAr } = useI18n()
  const toast = useToast()
  const queryClient = useQueryClient()
  const { isAuthenticated, isCompanyCustomer } = useAuth()
  const [params] = useSearchParams()
  const highlight = params.get('highlight')?.trim() || ''
  const title = isCompanyCustomer ? t('changeTargetPrices') : t('changePrices')
  usePageTitle(title)

  const query = useMyListings()
  const products = useMemo(() => query.data?.products ?? [], [query.data])
  const [editors, setEditors] = useState<Record<string, PriceEditor>>({})
  const [search, setSearch] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    setEditors((prev) => {
      const next: Record<string, PriceEditor> = {}
      for (const p of products) next[p.productId] = prev[p.productId] ?? editorFor(p)
      return next
    })
  }, [products])

  const visible = useMemo(() => {
    const q = search.trim().toLowerCase()
    if (!q) return products
    return products.filter((p) => productTitle(p, isAr).toLowerCase().includes(q) || (p.productName ?? '').toLowerCase().includes(q) || (p.productCode ?? '').toLowerCase().includes(q))
  }, [products, search, isAr])
  const dirty = products.filter((p) => isDirty(editors[p.productId]))

  const scrolled = useRef('')
  useEffect(() => {
    if (!highlight || scrolled.current === highlight || !visible.some((p) => sameId(p.productId, highlight))) return
    scrolled.current = highlight
    window.setTimeout(() => document.getElementById(`price-${highlight.toLowerCase()}`)?.scrollIntoView({ behavior: 'smooth', block: 'center' }), 100)
  }, [highlight, visible])

  const update = (id: string, patch: Partial<PriceEditor>) => setEditors((prev) => ({ ...prev, [id]: { ...prev[id], ...patch } }))

  const saveAll = async () => {
    if (!dirty.length || saving) return
    setSaving(true)
    let lastError: string | null = null
    for (const p of dirty) {
      const editor = editors[p.productId]
      const wholesale = parsePrice(editor.wholesale)
      if (wholesale === null || wholesale <= 0) {
        lastError = t('invalidPrice')
        continue
      }
      let retail: number | undefined
      if (editor.hasRetail) {
        const parsed = parsePrice(editor.retail)
        if ((editor.originalRetail ?? 0) > 0 && (parsed === null || parsed <= 0)) {
          lastError = t('invalidPrice')
          continue
        }
        if (parsed !== null && parsed > 0) retail = parsed
      }
      try {
        await updateProductPrice(p.productId, wholesale, retail)
        update(p.productId, { originalWholesale: wholesale, originalRetail: retail ?? editor.originalRetail })
      } catch (error) {
        lastError = errorText(error, t('unexpectedError'))
      }
    }
    setSaving(false)
    if (lastError) toast.error(lastError)
    else toast.success(t('pricesUpdated'))
    void queryClient.invalidateQueries({ queryKey: [MY_LISTINGS_KEY] })
  }

  if (!isAuthenticated) {
    return (
      <Screen title={title} fallback="/my-ads">
        <LoginPrompt message={t('pleaseLoginToContinue')} />
      </Screen>
    )
  }

  const footer = (
    <PrimaryButton onClick={saveAll} disabled={!dirty.length || saving} busy={saving} className="w-full">
      {dirty.length ? `${t('saveChanges')} (${dirty.length})` : t('saveChanges')}
    </PrimaryButton>
  )

  return (
    <Screen title={title} fallback="/my-ads" footer={footer}>
      <p className="text-center text-[13px] leading-snug text-subtitle">{isCompanyCustomer ? t('changeTargetPricesSubtitle') : t('changePricesSubtitle')}</p>
      <label className="mt-3 flex h-11 items-center gap-2 rounded-xl border border-[#E6EEF8] bg-white px-3 focus-within:border-brand">
        <Icon name="search" size={18} className="text-subtitle" />
        <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder={t('changePricesSearchHint')} className="h-full min-w-0 flex-1 bg-transparent text-sm text-title outline-none" />
        {search && (
          <button type="button" onClick={() => setSearch('')} className="text-subtitle" aria-label={t('cancel')}>
            <Icon name="close" size={16} />
          </button>
        )}
      </label>

      <div className="mt-4">
        {query.isPending ? (
          <div className="grid place-items-center py-16">
            <Spinner className="size-8 border-[3px] border-brand/25 border-t-brand" />
          </div>
        ) : query.isError && !products.length ? (
          <ErrorView message={errorText(query.error, t('unexpectedError'))} onRetry={() => void query.refetch()} />
        ) : !products.length ? (
          <p className="py-16 text-center text-sm text-subtitle">{t('noAdsToChangePrices')}</p>
        ) : !visible.length ? (
          <p className="py-16 text-center text-sm text-subtitle">{t('noAdsMatchFilter')}</p>
        ) : (
          <div className="space-y-2.5">
            {visible.map((p) => {
              const editor = editors[p.productId]
              if (!editor) return null
              const highlighted = sameId(p.productId, highlight)
              const name = productTitle(p, isAr)
              return (
                <div
                  key={p.productId}
                  id={`price-${p.productId.toLowerCase()}`}
                  className={`flex items-center gap-2.5 rounded-[14px] bg-white px-3 py-2.5 shadow-[0_3px_12px_rgba(22,35,58,0.05)] ${highlighted ? 'outline outline-[1.5px] outline-brand' : ''}`}
                >
                  <MediaThumb product={p} className="size-[52px] rounded-[10px]" />
                  <div className="min-w-0 flex-1">
                    <p className="line-clamp-2 text-[13.5px] font-bold leading-snug text-title">{name || '—'}</p>
                    {p.productTypeName?.trim() && <p className="mt-0.5 truncate text-[11px] text-subtitle">{p.productTypeName}</p>}
                  </div>
                  <div className="w-[118px] shrink-0 space-y-2">
                    <PriceField value={editor.wholesale} currency={wholesaleCurrency(p)} label={name} onChange={(v) => update(p.productId, { wholesale: v })} />
                    {editor.hasRetail && <PriceField value={editor.retail} currency="AED" label={`${name} AED`} onChange={(v) => update(p.productId, { retail: v })} />}
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </Screen>
  )
}

/* ─────────────────────────── Notifications ─────────────────────────── */

function notificationIcon(item: AppNotification) {
  const route = navigationRoute(item)
  if (route.includes('order')) return '/assets/profile/3d_box_fill.svg'
  if (route.includes('offer')) return '/assets/profile/badge-percent.svg'
  return '/assets/profile/message-circle.svg'
}

function NotificationCard({ item, onClick }: { item: AppNotification; onClick: () => void }) {
  const { t } = useI18n()
  const time = relativeTime(item.createdAt, t)
  return (
    <button type="button" onClick={onClick} className="block w-full rounded-lg bg-white px-4 py-3 text-start shadow-[0_0_2px_rgba(0,0,0,0.15)] hover:bg-[#FBFDFF]">
      <div className="flex items-start gap-4">
        <div className="min-w-0 flex-1">
          <div className="flex items-start gap-2">
            {!item.isRead && <span className="mt-2 size-2 shrink-0 rounded-full bg-[#3A7DC5]" />}
            <p dir="auto" className="min-w-0 flex-1 rtl:text-right text-base font-bold leading-normal text-[#333333] [overflow-wrap:anywhere]">
              {item.title}
            </p>
          </div>
          {item.body && (
            <p dir="auto" className="mt-3 rtl:text-right text-sm leading-normal text-subtitle [overflow-wrap:anywhere]">
              {item.body}
            </p>
          )}
        </div>
        <span className="mt-1.5 grid size-12 shrink-0 place-items-center rounded-full bg-[#3A7DC5]">
          <img src={notificationIcon(item)} alt="" className="size-8" />
        </span>
      </div>
      {time && <p className="mt-1 text-end text-xs text-subtitle/60">{time}</p>}
    </button>
  )
}

function NotificationSkeleton() {
  return (
    <div className="flex gap-4 rounded-lg bg-white px-4 py-3 shadow-[0_0_2px_rgba(0,0,0,0.15)]">
      <div className="flex-1 space-y-3">
        <div className="shimmer h-4 w-2/3 rounded" />
        <div className="shimmer h-3 w-full rounded" />
        <div className="shimmer h-3 w-4/5 rounded" />
      </div>
      <div className="shimmer size-12 rounded-full" />
    </div>
  )
}

export function NotificationsPage() {
  const { t } = useI18n()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { isAuthenticated, session } = useAuth()
  usePageTitle(t('notifications'))

  const markedAllRead = useRef(false)
  const query = useInfiniteQuery({
    queryKey: ['notifications', session?.id],
    initialPageParam: 1,
    enabled: isAuthenticated,
    queryFn: async ({ pageParam, signal }): Promise<NotificationsPage> => {
      const page = await fetchNotifications(pageParam, signal)
      if (pageParam === 1 && !markedAllRead.current && (page.unreadCount > 0 || page.items.some((n) => !n.isRead))) {
        try {
          await markAllNotificationsRead()
          markedAllRead.current = true
          queryClient.setQueryData(unreadNotificationsKey(session?.id), 0)
        } catch {
          return page
        }
      }
      return markedAllRead.current ? { ...page, unreadCount: 0, items: page.items.map((n) => ({ ...n, isRead: true })) } : page
    },
    getNextPageParam: (last, pages) => {
      const loaded = pages.reduce((sum, p) => sum + p.items.length, 0)
      return last.items.length > 0 && loaded < last.totalCount ? pages.length + 1 : undefined
    },
  })

  const items = useMemo(() => {
    const seen = new Set<string>()
    return (query.data?.pages.flatMap((p) => p.items) ?? []).filter((n) => (seen.has(n.id) ? false : (seen.add(n.id), true)))
  }, [query.data])
  const sentinel = useInfiniteSentinel(() => void query.fetchNextPage(), query.hasNextPage && !query.isFetchingNextPage, items.length, 200)

  const open = (item: AppNotification) => {
    if (!item.isRead) {
      markNotificationRead(item.id)
        .then(() => queryClient.invalidateQueries({ queryKey: unreadNotificationsKey(session?.id) }))
        .catch(() => undefined)
    }
    const target = notificationTarget(item)
    if (target) navigate(target)
  }

  if (!isAuthenticated) {
    return (
      <Screen title={t('notifications')} fallback="/profile">
        <LoginPrompt message={t('pleaseLoginToContinue')} />
      </Screen>
    )
  }

  return (
    <Screen title={t('notifications')} fallback="/profile">
      {query.isPending ? (
        <div className="space-y-3">
          {Array.from({ length: 6 }, (_, i) => (
            <NotificationSkeleton key={i} />
          ))}
        </div>
      ) : query.isError && !items.length ? (
        <ErrorView message={errorText(query.error, t('unexpectedError'))} onRetry={() => void query.refetch()} />
      ) : !items.length ? (
        <p className="py-12 text-center text-[15px] text-subtitle">{t('noNotificationsYet')}</p>
      ) : (
        <div>
          <h2 className="py-2 text-base font-normal text-[#333333]">{t('notifications')}</h2>
          <div className="space-y-3">
            {items.map((item) => (
              <NotificationCard key={item.id} item={item} onClick={() => open(item)} />
            ))}
          </div>
          <div ref={sentinel} />
          {query.isFetchingNextPage && <LoadingMore />}
        </div>
      )}
    </Screen>
  )
}
