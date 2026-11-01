import { useQuery, useQueryClient, type QueryClient } from '@tanstack/react-query'
import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { useLocation, useNavigate, useParams, useSearchParams, type NavigateFunction } from 'react-router-dom'
import { AddressDialog } from '../address/AddressDialog'
import { fetchAddresses, type SavedAddress } from '../address/addressApi'
import { useAuth } from '../auth/AuthProvider'
import {
  abortLatestCheckout,
  addCartItem,
  cartTotals,
  checkoutCart,
  createStripeCheckout,
  DEFAULT_EMIRATE,
  fetchCart,
  fetchCheckoutStatus,
  fetchShippingQuote,
  matchEmirate,
  readPendingPayment,
  reduceCartItem,
  removeCartItem,
  shippingFee,
  writePendingPayment,
  type Cart,
  type CartItem,
  type PaymentMethod,
  type PendingPayment,
} from '../cart/cartApi'
import {
  CART,
  CartItemCard,
  CheckoutBar,
  DeliveryAddressSection,
  DeliveryMethodSection,
  infoBoxClass,
  MessageState,
  OrderSummarySection,
  PaymentMethodSection,
} from '../cart/CartParts'
import { useI18n } from '../i18n/I18nProvider'
import type { StringKey } from '../i18n/strings'
import { PageContainer } from '../layout/MainLayout'
import { OutlineButton, PrimaryButton, Screen } from '../layout/ScreenLayout'
import { ApiError } from '../lib/api'
import { usePageTitle } from '../lib/usePageTitle'
import { parseUtc } from '../products/productRules'
import { OldestHeader, OrderCard, RequestOfferCard, withOldestSection } from '../orders/OrderParts'
import {
  canCancelOrder,
  canRequestReturn,
  fetchIncomingOrders,
  fetchMyOrders,
  fetchOrder,
  hasRefundId,
  isOnlinePayment,
  isRequestProductOffer,
  requestOrderReturn,
  updateOrderStatus,
  type MyOrder,
  type RequestOffer,
} from '../orders/ordersApi'
import { buildTimeline, OrderStatus } from '../orders/orderStatus'
import { ConfirmDialog, CustomerServiceCard, RefundIdCard, RefundNoticeCard, ReturnDialog, TimelineCard, TrackSummaryCard } from '../orders/TrackOrderParts'
import { useGate } from '../ui/GateProvider'
import { Icon, type IconName } from '../ui/Icon'
import { useToast } from '../ui/Toast'

const errorText = (error: unknown, t: (key: StringKey) => string) => (error instanceof ApiError ? error.message : t('unexpectedError'))
const isAbort = (error: unknown) => (error as Error)?.name === 'AbortError'

function Spinner({ className = 'size-8' }: { className?: string }) {
  return <span className={`inline-block animate-spin rounded-full border-[3px] border-brand/25 border-t-brand ${className}`} />
}

function newestOrder(orders: MyOrder[]) {
  const time = (o: MyOrder) => parseUtc(o.createdAt)?.getTime() ?? 0
  return orders.reduce<MyOrder | null>((best, o) => (!best || time(o) > time(best) ? o : best), null)
}

async function openNewestOrder(queryClient: QueryClient, navigate: NavigateFunction) {
  writePendingPayment(null)
  void queryClient.invalidateQueries({ queryKey: ['cart'] })
  void queryClient.invalidateQueries({ queryKey: ['orders'] })
  const latest = newestOrder(await fetchMyOrders().catch(() => []))
  if (latest) navigate(`/orders/${latest.id}`, { replace: true })
  return latest
}

export function CartPage() {
  const { t } = useI18n()
  const toast = useToast()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { isAuthenticated, session } = useAuth()
  const { ensureLoggedIn } = useGate()
  usePageTitle(t('cart'))

  const cartKey = useMemo(() => ['cart', session?.id], [session?.id])
  const cartQuery = useQuery({ queryKey: cartKey, queryFn: fetchCart, enabled: isAuthenticated })
  const addressesQuery = useQuery({ queryKey: ['addresses', session?.id], queryFn: fetchAddresses, enabled: isAuthenticated })
  const [editing, setEditing] = useState(true)
  const [selfPickup, setSelfPickup] = useState(false)
  const [payment, setPayment] = useState<PaymentMethod>('Online')
  const [addressId, setAddressId] = useState<string | null>(null)
  const [addOpen, setAddOpen] = useState(false)
  const [confirming, setConfirming] = useState(false)
  const [pending, setPending] = useState<PendingPayment | null>(readPendingPayment)
  const [pollDone, setPollDone] = useState(false)
  const [checking, setChecking] = useState(false)
  const abortRef = useRef<AbortController | null>(null)
  const writeChain = useRef<Promise<void>>(Promise.resolve())
  const pendingWrites = useRef(0)

  const items = cartQuery.data?.items ?? []
  const addresses = addressesQuery.data ?? []
  const selected = addresses.find((a) => a.addressId === addressId) ?? addresses[0] ?? null
  const emirate = selfPickup ? null : selected ? matchEmirate(selected.cityName) : DEFAULT_EMIRATE
  const quoteQuery = useQuery({
    queryKey: ['shipping-quote', emirate],
    queryFn: () => fetchShippingQuote(emirate!),
    enabled: isAuthenticated && !!emirate && items.length > 0,
    staleTime: 600_000,
  })
  const deliveryFee = selfPickup || !emirate ? 0 : shippingFee(items, quoteQuery.data ?? { priceAed: 0, excessKgRateAed: 0, freeWeightKg: 10 })
  const { vat, total } = cartTotals(items, deliveryFee)

  useEffect(() => {
    if (!pending) return
    let attempts = 0
    const id = window.setInterval(async () => {
      if (++attempts > 40) {
        window.clearInterval(id)
        setPollDone(true)
        return
      }
      const status = await fetchCheckoutStatus(pending.sessionId).catch(() => null)
      if (status?.status === 'completed') {
        window.clearInterval(id)
        setPending(null)
        await openNewestOrder(queryClient, navigate)
      }
    }, 3000)
    return () => window.clearInterval(id)
  }, [pending, queryClient, navigate])

  const clearPending = () => {
    if (!pending) return
    writePendingPayment(null)
    setPending(null)
  }

  const mutate = (update: (items: CartItem[]) => CartItem[], call: () => Promise<Cart>) => {
    clearPending()
    queryClient.setQueryData<Cart>(cartKey, (old) => (old ? { ...old, items: update(old.items) } : old))
    pendingWrites.current++
    writeChain.current = writeChain.current.then(async () => {
      try {
        const cart = await call()
        if (pendingWrites.current === 1) queryClient.setQueryData(cartKey, cart)
      } catch (error) {
        toast.error(errorText(error, t))
        void cartQuery.refetch()
      } finally {
        pendingWrites.current--
      }
    })
  }

  const withQuantity = (id: number, quantity: number) => (list: CartItem[]) =>
    list.map((i) => (i.id === id ? { ...i, quantity, totalPriceAed: i.unitPriceAed * quantity } : i))
  const remove = (item: CartItem) => mutate((list) => list.filter((i) => i.id !== item.id), () => removeCartItem(item.id))
  const setQuantity = (item: CartItem, value: number) => {
    if (value <= 0) return remove(item)
    const max = item.availableQuantity
    const capped = max && value > max ? max : value
    const delta = capped - item.quantity
    if (delta === 0) return
    mutate(withQuantity(item.id, capped), () => (delta > 0 ? addCartItem(item.productId, delta, item.unitName) : reduceCartItem(item.id, -delta)))
  }
  const increment = (item: CartItem) => {
    if (item.availableQuantity && item.quantity + 0.0001 >= item.availableQuantity) return
    mutate(withQuantity(item.id, item.quantity + 1), () => addCartItem(item.productId, 1, item.unitName))
  }
  const decrement = (item: CartItem) =>
    item.quantity <= 1 ? remove(item) : mutate(withQuantity(item.id, item.quantity - 1), () => reduceCartItem(item.id, 1))

  const selectAddress = (address: SavedAddress) => {
    clearPending()
    setAddressId(address.addressId)
    if (!matchEmirate(address.cityName)) toast.error(t('selectDeliveryEmirate'))
  }

  const checkPayment = async () => {
    if (!pending) return
    setChecking(true)
    try {
      const status = await fetchCheckoutStatus(pending.sessionId)
      if (status.status === 'completed') {
        setPending(null)
        await openNewestOrder(queryClient, navigate)
      } else if (status.status === 'processing') toast.info(t('paymentReceivedWaitingWebhook'))
      else toast.error(t('paymentNotConfirmedYet'))
    } catch (error) {
      toast.error(errorText(error, t))
    } finally {
      setChecking(false)
    }
  }

  const confirm = async () => {
    if (!ensureLoggedIn() || !items.length) return
    if (!selfPickup && !selected) return toast.error(t('selectDeliveryAddress'))
    if (!selfPickup && !emirate) return toast.error(t('selectDeliveryEmirate'))
    const controller = new AbortController()
    abortRef.current = controller
    setConfirming(true)
    let redirecting = false
    try {
      const result = await checkoutCart(
        {
          paymentMethodName: payment,
          shippingCostAed: selfPickup ? 0 : deliveryFee,
          isSelfPickup: selfPickup,
          ...(selfPickup || !selected || !emirate ? {} : { addressId: selected.addressId, cityName: emirate }),
        },
        controller.signal,
      )
      if (controller.signal.aborted) return
      if (payment === 'CashOnDelivery') {
        queryClient.setQueryData<Cart>(cartKey, { cartId: null, items: [], totalAed: 0 })
        void queryClient.invalidateQueries({ queryKey: ['cart'] })
        void queryClient.invalidateQueries({ queryKey: ['orders'] })
        if (result.firstOrderId) navigate(`/orders/${result.firstOrderId}`, { replace: true })
        return
      }
      if (result.orderGroupId) return toast.error(t('orderCreatedBeforePayment'))
      if (!result.isOnlinePending || !result.pendingOrderId) return toast.error(t('couldNotStartOnlinePayment'))
      const checkout = await createStripeCheckout(result.pendingOrderId)
      if (controller.signal.aborted) return
      if (!checkout.checkoutUrl) return toast.error(t('couldNotStartOnlinePayment'))
      writePendingPayment(checkout)
      redirecting = true
      window.location.href = checkout.checkoutUrl
    } catch (error) {
      if (isAbort(error) || controller.signal.aborted) void abortLatestCheckout()
      else toast.error(errorText(error, t))
    } finally {
      abortRef.current = null
      if (!redirecting) setConfirming(false)
    }
  }

  const cancelConfirm = () => {
    abortRef.current?.abort()
    setConfirming(false)
  }

  if (!isAuthenticated)
    return (
      <PageContainer narrow>
        <MessageState message={t('pleaseLoginToViewYourCart')} action={t('login')} onAction={ensureLoggedIn} />
      </PageContainer>
    )
  if (cartQuery.isPending)
    return (
      <div className="grid min-h-[50vh] place-items-center">
        <Spinner />
      </div>
    )
  if (cartQuery.isError && !cartQuery.data)
    return (
      <PageContainer narrow>
        <MessageState message={errorText(cartQuery.error, t)} action={t('retry')} onAction={() => void cartQuery.refetch()} />
      </PageContainer>
    )
  if (!items.length && !pending)
    return (
      <PageContainer narrow>
        <MessageState message={t('yourCartIsEmpty')} action={t('refresh')} onAction={() => void cartQuery.refetch()} />
      </PageContainer>
    )

  const awaitingText = checking || !pollDone ? t('awaitingStripeConfirmation') : t('paymentSessionStarted')
  return (
    <PageContainer narrow className="pb-4 pt-3" >
      <div className="flex flex-col gap-4 sm:px-2" style={{ color: CART.text }}>
        <div className="flex items-center gap-2">
          <h1 className="text-[22px] font-extrabold">{t('yourCart')}</h1>
          <span className="rounded-full bg-[#3A7DC5]/12 px-2.5 py-1 text-xs font-bold" style={{ color: CART.brand }}>
            {t('cartItemsCount', { count: items.length })}
          </span>
          <button
            type="button"
            onClick={() => setEditing((v) => !v)}
            className="ms-auto inline-flex items-center gap-1.5 rounded-lg px-2 py-1.5 text-[13px] font-bold hover:bg-black/5"
            style={{ color: editing ? CART.brand : CART.muted }}
          >
            <Icon name="edit" size={16} />
            {t('editCart')}
          </button>
        </div>

        {pending && (
          <div className={`p-3.5 ${infoBoxClass}`}>
            <p className="flex items-center gap-2.5 text-sm font-semibold">
              {(checking || !pollDone) && <span className="size-[18px] shrink-0 animate-spin rounded-full border-2 border-[#1D4ED8]/25 border-t-[#1D4ED8]" />}
              {awaitingText}
            </p>
            <p className="mt-2 text-[13px] leading-relaxed text-[#1E40AF]">{t('awaitingStripeWebhookNote')}</p>
          </div>
        )}

        {items.map((item) => (
          <CartItemCard
            key={item.id}
            item={item}
            showDelete={editing}
            onIncrement={() => increment(item)}
            onDecrement={() => decrement(item)}
            onCommit={(value) => setQuantity(item, value)}
            onDelete={() => remove(item)}
          />
        ))}

        {items.length > 0 && (
          <>
            <DeliveryMethodSection
              selfPickup={selfPickup}
              onChange={(value) => {
                clearPending()
                setSelfPickup(value)
              }}
            />
            {!selfPickup && (
              <DeliveryAddressSection
                addresses={addresses}
                selected={selected}
                loading={addressesQuery.isPending}
                onSelect={selectAddress}
                onAdd={() => setAddOpen(true)}
              />
            )}
            <OrderSummarySection items={items} vat={vat} deliveryFee={deliveryFee} total={total} selfPickup={selfPickup} loadingShipping={!!emirate && quoteQuery.isFetching} />
          </>
        )}

        <PaymentMethodSection method={payment} onChange={setPayment} enabled={!pending} />

        <div className="mt-2 flex flex-col gap-3">
          {pending ? (
            <>
              <button
                type="button"
                onClick={() => (window.location.href = pending.checkoutUrl)}
                className="h-12 rounded-[14px] text-[15px] font-bold text-white hover:brightness-110"
                style={{ background: CART.brand }}
              >
                {t('openStripe')}
              </button>
              <button
                type="button"
                disabled={checking}
                onClick={() => void checkPayment()}
                className="flex h-12 items-center justify-center gap-2 rounded-[14px] bg-[#22C55E] text-[15px] font-bold text-white hover:brightness-110 disabled:opacity-70"
              >
                {checking && <span className="size-4 animate-spin rounded-full border-2 border-white/40 border-t-white" />}
                {t('iCompletedPayment')}
              </button>
            </>
          ) : confirming ? (
            <div className="flex gap-2.5">
              <div className="flex-[3]">
                <CheckoutBar label={payment === 'Online' ? t('payWithVisaButton') : t('confirmOrder')} total={total} busy />
              </div>
              <button type="button" onClick={cancelConfirm} className="h-14 flex-[2] rounded-[14px] text-sm font-extrabold text-white hover:brightness-110" style={{ background: CART.danger }}>
                {t('cancel')}
              </button>
            </div>
          ) : (
            <>
              <CheckoutBar label={payment === 'Online' ? t('payWithVisaButton') : t('confirmOrder')} total={total} busy={false} onClick={() => void confirm()} />
              <button
                type="button"
                onClick={() => navigate('/services/retail')}
                className="h-12 rounded-[14px] border text-sm font-bold hover:bg-[#3A7DC5]/5"
                style={{ color: CART.brand, borderColor: 'rgba(58,125,197,0.55)' }}
              >
                {t('continueShopping')}
              </button>
            </>
          )}
        </div>
      </div>

      <AddressDialog
        open={addOpen}
        onClose={() => setAddOpen(false)}
        onSaved={async (saved) => {
          setAddOpen(false)
          const list = await queryClient.fetchQuery({ queryKey: ['addresses', session?.id], queryFn: fetchAddresses, staleTime: 0 })
          const next = (saved && list.find((a) => a.addressId === saved.addressId)) || list[0]
          if (next) selectAddress(next)
        }}
      />
    </PageContainer>
  )
}

type OrdersSection = 'sales' | 'purchases' | 'incoming'
type PurchaseFilter = 'all' | 'awaitingApproval' | 'completed' | 'cancelled'

const PURCHASE_FILTERS: { key: PurchaseFilter; label: StringKey; icon: IconName; matches: (o: MyOrder) => boolean }[] = [
  { key: 'all', label: 'allOrders', icon: 'box', matches: () => true },
  { key: 'awaitingApproval', label: 'awaitingApproval', icon: 'timer', matches: (o) => (o.statusId === OrderStatus.ordered && !o.isApproved) || o.statusId === OrderStatus.awaitingSellerApproval },
  { key: 'completed', label: 'completedOrders', icon: 'check', matches: (o) => o.statusId === OrderStatus.delivered || o.statusId === OrderStatus.received },
  { key: 'cancelled', label: 'orderCancelledStatus', icon: 'close', matches: (o) => o.statusId === OrderStatus.cancelled },
]

function ListMessage({ text }: { text: string }) {
  return <p className="py-16 text-center text-sm text-[#64748B]">{text}</p>
}

export function OrdersPage() {
  const { t } = useI18n()
  const toast = useToast()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { isAuthenticated, isSupplier, isCompanyCustomer, session } = useAuth()
  const { ensureLoggedIn } = useGate()
  usePageTitle(t('myOrders'))

  const sections: OrdersSection[] = isSupplier ? ['sales', 'purchases', 'incoming'] : isCompanyCustomer ? ['purchases', 'incoming'] : ['purchases']
  const [sectionIndex, setSectionIndex] = useState(0)
  const section = sections[sectionIndex] ?? sections[0]
  const [filter, setFilter] = useState<PurchaseFilter>('all')
  const [busy, setBusy] = useState<{ id: number; action: 'accept' | 'reject'; controller: AbortController } | null>(null)

  const ordersQuery = useQuery({ queryKey: ['orders', 'mine', session?.id], queryFn: fetchMyOrders, enabled: isAuthenticated && section === 'purchases' })
  const incomingQuery = useQuery({ queryKey: ['orders', 'incoming', session?.id], queryFn: fetchIncomingOrders, enabled: isAuthenticated && section !== 'purchases' })

  const decide = async (offer: RequestOffer, action: 'accept' | 'reject') => {
    const controller = new AbortController()
    setBusy({ id: offer.orderId, action, controller })
    try {
      await updateOrderStatus(offer.orderId, action === 'accept' ? OrderStatus.approved : OrderStatus.cancelled, controller.signal)
      await incomingQuery.refetch()
      void queryClient.invalidateQueries({ queryKey: ['order', String(offer.orderId)] })
    } catch (error) {
      if (!isAbort(error)) toast.error(errorText(error, t))
    } finally {
      setBusy(null)
    }
  }

  if (!isAuthenticated)
    return (
      <PageContainer narrow>
        <MessageState message={t('pleaseLoginToViewYourOrders')} action={t('login')} onAction={ensureLoggedIn} />
      </PageContainer>
    )

  const sectionTabs: Record<OrdersSection, { label: StringKey; icon: IconName }> = {
    sales: { label: 'incomingOrders', icon: 'tag' },
    purchases: { label: 'purchases', icon: 'bag' },
    incoming: { label: 'incomingRequestOffersTab', icon: 'download' },
  }

  const renderPurchases = () => {
    const orders = ordersQuery.data ?? []
    if (ordersQuery.isPending) return <OrdersSkeleton />
    if (ordersQuery.isError && !orders.length) return <ListMessage text={errorText(ordersQuery.error, t)} />
    const active = PURCHASE_FILTERS.find((f) => f.key === filter)!
    const visible = orders.filter(active.matches)
    return (
      <>
        {orders.length > 0 && (
          <div className="flex flex-wrap gap-1.5 pb-1 pt-2">
            {PURCHASE_FILTERS.map((f) => {
              const on = f.key === filter
              return (
                <button
                  key={f.key}
                  type="button"
                  onClick={() => setFilter(f.key)}
                  className={`inline-flex items-center gap-1 rounded-2xl border px-2.5 py-1 text-[11px] font-semibold transition ${on ? 'border-brand bg-brand text-white' : 'border-line bg-white text-title hover:border-brand/50'}`}
                >
                  <Icon name={f.icon} size={13} className={on ? 'text-white' : 'text-brand'} />
                  {`${t(f.label)} (${orders.filter(f.matches).length})`}
                </button>
              )
            })}
          </div>
        )}
        {!orders.length ? (
          <ListMessage text={t('noPurchasesYet')} />
        ) : !visible.length ? (
          <ListMessage text={t('noOrdersMatchFilter')} />
        ) : (
          <div className="flex flex-col gap-3.5 pt-2">
            {withOldestSection(visible, (o) => o.createdAt).map((entry, i) =>
              entry.header ? <OldestHeader key="oldest" /> : <OrderCard key={entry.item.id || i} order={entry.item} onTrack={() => navigate(`/orders/${entry.item.id}`)} />,
            )}
          </div>
        )}
      </>
    )
  }

  const renderIncoming = (requestOffers: boolean) => {
    const all = incomingQuery.data ?? []
    if (incomingQuery.isPending) return <OrdersSkeleton />
    if (incomingQuery.isError && !all.length) return <ListMessage text={errorText(incomingQuery.error, t)} />
    const offers = all.filter((o) => isRequestProductOffer(o) === requestOffers)
    return (
      <>
        <p className="pb-2 pt-2 text-[13px] leading-snug text-[#64748B]">{t(requestOffers ? 'incomingRequestOffersSubtitle' : 'incomingOrdersSubtitle')}</p>
        {!offers.length ? (
          <ListMessage text={t(requestOffers ? 'noIncomingRequestOffersYet' : 'noIncomingOrdersYet')} />
        ) : (
          <div className="flex flex-col gap-3 pt-1">
            {withOldestSection(offers, (o) => o.createdAt).map((entry, i) => {
              if (entry.header) return <OldestHeader key="oldest" />
              const offer = entry.item
              return (
                <RequestOfferCard
                  key={offer.orderId || i}
                  offer={offer}
                  useOfferLabels={requestOffers}
                  busy={busy?.id === offer.orderId ? busy.action : null}
                  onTrack={offer.orderId > 0 ? () => navigate(`/orders/${offer.orderId}`, { state: { showBuyerActions: false } }) : undefined}
                  onAccept={offer.canAccept ? () => void decide(offer, 'accept') : undefined}
                  onReject={offer.canReject ? () => void decide(offer, 'reject') : undefined}
                  onCancel={busy?.id === offer.orderId ? () => busy.controller.abort() : undefined}
                />
              )
            })}
          </div>
        )}
      </>
    )
  }

  return (
    <PageContainer narrow className="pt-3">
      <h1 className="text-[26px] font-extrabold leading-tight text-title">{t('myOrders')}</h1>
      <p className="mt-1 text-[13px] leading-snug text-subtitle">{t('myOrdersSubtitle')}</p>
      {sections.length > 1 && (
        <div className="mt-3 flex gap-1.5">
          {sections.map((s, i) => {
            const on = i === sectionIndex
            return (
              <button
                key={s}
                type="button"
                onClick={() => setSectionIndex(i)}
                className={`flex min-w-0 flex-1 items-center justify-center gap-1.5 rounded-[10px] border px-1.5 py-2 text-xs font-bold transition sm:text-sm ${on ? 'border-brand bg-brand text-white' : 'border-brand/30 bg-white text-brand hover:bg-brand/5'}`}
              >
                <Icon name={sectionTabs[s].icon} size={16} className="shrink-0" />
                <span className="truncate">{t(sectionTabs[s].label)}</span>
              </button>
            )
          })}
        </div>
      )}
      <div className="pb-6 pt-1">{section === 'purchases' ? renderPurchases() : renderIncoming(section === 'incoming')}</div>
    </PageContainer>
  )
}

function OrdersSkeleton() {
  return (
    <div className="flex flex-col gap-3.5 pt-3">
      {[0, 1, 2].map((i) => (
        <div key={i} className="h-52 rounded-2xl border border-line bg-white p-3">
          <div className="flex gap-3">
            <div className="shimmer size-[88px] rounded-xl" />
            <div className="flex-1 space-y-2.5 pt-1">
              <div className="shimmer h-5 w-24 rounded-lg" />
              <div className="shimmer h-4 w-3/4 rounded" />
              <div className="shimmer h-3 w-1/2 rounded" />
            </div>
          </div>
          <div className="shimmer mt-6 h-[42px] rounded-xl" />
        </div>
      ))}
    </div>
  )
}

export function TrackOrderPage() {
  const { t, isAr } = useI18n()
  const toast = useToast()
  const queryClient = useQueryClient()
  const { orderId = '' } = useParams()
  const location = useLocation()
  const { isAuthenticated } = useAuth()
  const showBuyerActions = (location.state as { showBuyerActions?: boolean } | null)?.showBuyerActions !== false
  const [dialog, setDialog] = useState<'cancel' | 'return' | null>(null)
  const [busy, setBusy] = useState(false)
  usePageTitle(t('trackOrder'))

  const orderKey = ['order', orderId]
  const query = useQuery({ queryKey: orderKey, queryFn: () => fetchOrder(orderId), enabled: isAuthenticated && /^\d+$/.test(orderId), refetchInterval: 90_000 })
  const order = query.data

  const cancelOrder = async () => {
    if (!order) return
    setBusy(true)
    try {
      const { refundMessage, refundMessageAr } = await updateOrderStatus(order.id, OrderStatus.cancelled)
      toast.success(isOnlinePayment(order) ? (isAr ? refundMessageAr : refundMessage) || t('orderRefundNotice') : t('orderCancelledSuccess'))
      setDialog(null)
      void query.refetch()
      void queryClient.invalidateQueries({ queryKey: ['orders'] })
    } catch (error) {
      toast.error(errorText(error, t))
    } finally {
      setBusy(false)
    }
  }

  const submitReturn = async (reason: string, files: File[]) => {
    if (!order) return
    setBusy(true)
    try {
      queryClient.setQueryData(orderKey, await requestOrderReturn(order.id, reason, files))
      toast.success(t('orderReturnSuccess'))
      setDialog(null)
      void queryClient.invalidateQueries({ queryKey: ['orders'] })
    } catch (error) {
      toast.error(errorText(error, t))
    } finally {
      setBusy(false)
    }
  }

  const body = () => {
    if (!isAuthenticated) return <p className="py-16 text-center text-sm text-subtitle">{t('pleaseLoginToViewYourOrders')}</p>
    if (query.isPending && query.fetchStatus !== 'idle')
      return (
        <div className="grid min-h-[40vh] place-items-center">
          <Spinner />
        </div>
      )
    if (!order)
      return (
        <div className="flex flex-col items-center gap-4 py-16 text-center">
          <p className="text-sm text-subtitle">{t('couldNotLoadOrderDetails')}</p>
          <button type="button" onClick={() => void query.refetch()} className="text-sm font-bold text-brand hover:underline">
            {t('retry')}
          </button>
        </div>
      )
    const refundCard = showBuyerActions && hasRefundId(order)
    const canReturn = showBuyerActions && canRequestReturn(order)
    const canCancel = showBuyerActions && canCancelOrder(order)
    return (
      <div className="flex flex-col gap-4">
        <TrackSummaryCard order={order} />
        <TimelineCard steps={buildTimeline(order, isAr, t, !showBuyerActions)} />
        {refundCard && <RefundIdCard order={order} />}
        {canReturn && isOnlinePayment(order) && order.statusId !== OrderStatus.cancelled && !refundCard && <RefundNoticeCard />}
        {canReturn && (
          <button type="button" onClick={() => setDialog('return')} className="h-12 w-full rounded-xl border border-[#DC2626] text-[15px] font-bold text-[#DC2626] hover:bg-red-50">
            {t('returnOrder')}
          </button>
        )}
        {canCancel && (
          <button type="button" onClick={() => setDialog('cancel')} className="h-12 w-full rounded-xl border border-[#DC2626] text-[15px] font-bold text-[#DC2626] hover:bg-red-50">
            {t('cancelOrder')}
          </button>
        )}
        <CustomerServiceCard />
        <ConfirmDialog
          open={dialog === 'cancel'}
          title={t('cancelOrderConfirmTitle')}
          message={t('cancelOrderConfirmMessage')}
          confirmLabel={t('cancelOrder')}
          busy={busy}
          onClose={() => setDialog(null)}
          onConfirm={() => void cancelOrder()}
        />
        {dialog === 'return' && <ReturnDialog open busy={busy} onClose={() => setDialog(null)} onSubmit={(reason, files) => void submitReturn(reason, files)} />}
      </div>
    )
  }

  return (
    <Screen title={t('trackOrder')} fallback="/orders">
      {body()}
    </Screen>
  )
}

type PaymentState = 'loading' | 'processing' | 'completed' | 'error'

function ResultCard({ icon, title, subtitle, children }: { icon: ReactNode; title: string; subtitle: string; children?: ReactNode }) {
  return (
    <div className="flex min-h-dvh items-center justify-center bg-[#F4F7FA] px-6 py-10">
      <div className="w-full max-w-md rounded-3xl bg-white p-6 text-center shadow-[0_8px_30px_rgba(15,23,42,0.08)] sm:p-8">
        <div className="flex justify-center">{icon}</div>
        <h1 className="mt-7 text-[22px] font-bold leading-snug text-[#333]">{title}</h1>
        <p className="mt-3 text-sm leading-relaxed text-[#333]/65">{subtitle}</p>
        {children}
      </div>
    </div>
  )
}

export function PaymentSuccessPage() {
  const { t } = useI18n()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [params] = useSearchParams()
  const sessionId = params.get('session_id') ?? params.get('sessionId') ?? ''
  const { isAuthenticated } = useAuth()
  const [state, setState] = useState<PaymentState>('loading')
  const [orderGroupId, setOrderGroupId] = useState('')
  const [error, setError] = useState('')
  const [latest, setLatest] = useState<MyOrder | null>(null)
  usePageTitle(t('confirmingPayment'))

  const missing = !sessionId ? t('missingPaymentSession') : !isAuthenticated ? t('signInAgainToConfirmPayment') : ''

  useEffect(() => {
    if (missing) return
    writePendingPayment(null)
    let polls = 0
    let stopped = false
    const poll = async () => {
      if (stopped) return
      polls++
      try {
        const status = await fetchCheckoutStatus(sessionId)
        if (stopped) return
        if (status.status === 'completed') {
          stopped = true
          window.clearInterval(id)
          setState('completed')
          setOrderGroupId(status.orderGroupId)
          setLatest(await openNewestOrder(queryClient, navigate))
          return
        }
        if (status.status === 'processing') return setState('processing')
        if (polls >= 40) {
          stopped = true
          window.clearInterval(id)
          setState('error')
          setError(t('paymentConfirmationDelayed'))
        } else setState('loading')
      } catch (e) {
        stopped = true
        window.clearInterval(id)
        setState('error')
        setError(e instanceof ApiError ? e.message : t('unexpectedError'))
      }
    }
    const id = window.setInterval(() => void poll(), 2000)
    void poll()
    return () => {
      stopped = true
      window.clearInterval(id)
    }
  }, [missing, sessionId, queryClient, navigate, t])

  const shown: PaymentState = missing ? 'error' : state
  const errorMessage = missing || error
  const titles: Record<PaymentState, [StringKey, StringKey]> = {
    loading: ['confirmingPayment', 'confirmingPaymentSubtitle'],
    processing: ['paymentReceived', 'paymentReceivedSubtitle'],
    completed: ['orderSentSuccessfullyTitle', 'orderSentSuccessfullySubtitle'],
    error: ['paymentIssue', 'paymentIssueSubtitle'],
  }
  const icon =
    shown === 'completed' ? (
      <img src="/assets/services/check.svg" alt="" className="size-[88px]" />
    ) : shown === 'error' ? (
      <span className="text-red-400">
        <Icon name="info" size={88} strokeWidth={1.6} />
      </span>
    ) : (
      <Spinner className="size-14" />
    )

  return (
    <ResultCard icon={icon} title={t(titles[shown][0])} subtitle={t(titles[shown][1])}>
      {orderGroupId && (
        <div className="mt-7 rounded-xl bg-[#E9F5EA] px-4 py-[18px]">
          <p className="text-[13px] text-[#333]/55">{t('orderNumber')}</p>
          <p className="mt-1.5 text-xl font-bold text-[#333]">{`#${orderGroupId.slice(0, 8).toUpperCase()}`}</p>
        </div>
      )}
      {errorMessage && <p className="mt-5 text-[13px] text-red-700">{errorMessage}</p>}
      <div className="mt-8 flex flex-col gap-3">
        {shown === 'completed' && <PrimaryButton onClick={() => navigate(latest ? `/orders/${latest.id}` : '/')}>{t('trackOrder')}</PrimaryButton>}
        <OutlineButton onClick={() => navigate('/', { replace: true })}>{t('backToHome')}</OutlineButton>
      </div>
    </ResultCard>
  )
}

export function PaymentCancelPage() {
  const { t } = useI18n()
  const navigate = useNavigate()
  usePageTitle(t('paymentCancelled'))
  useEffect(() => writePendingPayment(null), [])
  return (
    <ResultCard
      icon={
        <span className="grid size-[88px] place-items-center rounded-full bg-[#FFF3E0] text-[#EF6C00]">
          <Icon name="close" size={44} strokeWidth={2.4} />
        </span>
      }
      title={t('paymentCancelled')}
      subtitle={t('paymentCancelledSubtitle')}
    >
      <div className="mt-8 flex flex-col gap-3">
        <PrimaryButton onClick={() => navigate('/cart', { replace: true })}>
          <Icon name="cart" size={18} />
          {t('backToCart')}
        </PrimaryButton>
        <OutlineButton onClick={() => navigate('/', { replace: true })}>{t('backToHome')}</OutlineButton>
      </div>
    </ResultCard>
  )
}