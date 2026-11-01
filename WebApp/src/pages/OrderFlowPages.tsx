import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { Link, Navigate, useLocation, useNavigate, useParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { fetchCountries } from '../auth/geo'
import { useI18n } from '../i18n/I18nProvider'
import { PrimaryButton, Screen } from '../layout/ScreenLayout'
import { usePageTitle } from '../lib/usePageTitle'
import { createOrder, fetchPorts, uploadOfferMedia } from '../orders/ordersApi'
import { PriceText } from '../products/details/DetailsUI'
import { productPath } from '../products/productLinks'
import { useViewer } from '../products/ProductGrid'
import {
  amountValue,
  apiUnitName,
  canShowProductPrice,
  currencyCode,
  displayUnit,
  isBookingProduct,
  isProductOwner,
  parseNumber,
  productImages,
  productTitle,
  shippingFacts,
  unitName,
} from '../products/productRules'
import { fetchProduct } from '../products/productsApi'
import type { ApiProduct } from '../products/types'
import { UNIT_OPTIONS, canonicalUnit, unitApiName, unitLabel } from '../products/units'
import { Card, Field, Select, TextArea, TextInput, formatNumberInput } from '../ui/Form'
import { useGate } from '../ui/GateProvider'
import { Icon } from '../ui/Icon'
import { useToast } from '../ui/Toast'

function useRouteProduct() {
  const { id = '' } = useParams()
  const location = useLocation()
  const { session } = useAuth()
  const seed = (location.state as { product?: ApiProduct } | null)?.product
  const query = useQuery({
    queryKey: ['product', id, session?.id ?? 'guest'],
    queryFn: () => fetchProduct(id),
    enabled: !!id,
    initialData: seed && seed.productId === id ? seed : undefined,
    staleTime: seed ? 60_000 : 0,
  })
  return { id, product: query.data, isPending: query.isPending, isError: query.isError }
}

function ProductSummary({ product }: { product: ApiProduct }) {
  const { isAr, t } = useI18n()
  const image = productImages(product)[0]
  return (
    <Card className="flex items-center gap-3">
      <div className="size-16 shrink-0 overflow-hidden rounded-xl bg-[#F2F5F9] sm:size-20">
        {image ? <img src={image} alt="" className="size-full object-cover" /> : <img src="/assets/logo/brand_mark.png" alt="" className="size-full object-contain p-3 opacity-50" />}
      </div>
      <div className="min-w-0">
        <p className="line-clamp-2 text-[15px] font-bold text-title first-letter:uppercase">{productTitle(product, isAr)}</p>
        {product.productCode && (
          <p className="mt-0.5 text-xs text-subtitle" dir="ltr">
            {t('productCode')}: {product.productCode}
          </p>
        )}
      </div>
    </Card>
  )
}

function Guarded({ children, product, isPending, isError }: { children: ReactNode; product?: ApiProduct; isPending: boolean; isError: boolean }) {
  const { t } = useI18n()
  if (isPending)
    return (
      <div className="space-y-3">
        <div className="shimmer h-24 rounded-[14px]" />
        <div className="shimmer h-56 rounded-[14px]" />
      </div>
    )
  if (isError || !product)
    return (
      <div className="py-16 text-center">
        <p className="mb-4 text-auth-body">{t('productUnavailable')}</p>
        <Link to="/" className="rounded-xl bg-brand px-5 py-2.5 text-sm font-bold text-white">
          {t('goHome')}
        </Link>
      </div>
    )
  return <>{children}</>
}

/* ─────────── Purchase order (booking & category) ─────────── */

export function PurchaseOrderPage() {
  const { t, isAr } = useI18n()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const viewer = useViewer()
  const { session } = useAuth()
  const { ensureLoggedIn } = useGate()
  const toast = useToast()
  const { product, isPending, isError } = useRouteProduct()
  usePageTitle(t('purchaseOrder'))

  const [qty, setQty] = useState('1')
  const [notes, setNotes] = useState('')
  const [country, setCountry] = useState('')
  const [port, setPort] = useState('')
  const [busy, setBusy] = useState(false)
  const prefilled = useRef(false)

  const booking = !!product && isBookingProduct(product)
  const countries = useQuery({ queryKey: ['geo-countries'], queryFn: fetchCountries, staleTime: Infinity, enabled: booking })
  const ports = useQuery({ queryKey: ['geo-ports', country], queryFn: () => fetchPorts(country), enabled: booking && !!country, staleTime: 3_600_000 })

  useEffect(() => {
    if (!product || prefilled.current) return
    prefilled.current = true
    const s = shippingFacts(product, false)
    if (s.destination) setCountry(s.destination)
    if (s.arrivalPort) setPort(s.arrivalPort)
  }, [product])

  const content = (() => {
    if (!product) return null
    const amount = amountValue(product, viewer, false)
    const canPrice = canShowProductPrice(product, viewer, false) && amount > 0
    const currency = currencyCode(product, viewer)
    const unit = unitName(product, isAr, false)
    const q = parseNumber(qty) ?? 0

    const submit = async () => {
      if (!ensureLoggedIn()) return
      if (isProductOwner(product, viewer)) return toast.error(t('cannotOrderOwnProduct'))
      if (q <= 0 || amount <= 0) return toast.error(t('enterValidQuantityAndPrice'))
      if (booking && !port.trim()) return toast.error(t('pleaseSelectPort'))
      setBusy(true)
      try {
        const { orderNumber } = await createOrder({
          toUserId: product.ownerId ?? '',
          productId: product.productId,
          supplierEmail: session?.email ?? '',
          unitName: apiUnitName(product, false),
          quantity: q,
          unitPrice: amount,
          totalPrice: amount * q,
          notes: notes.trim(),
          ...(booking ? { addressLine: port.trim(), portName: port.trim(), cityName: country.trim() } : {}),
        })
        queryClient.invalidateQueries({ queryKey: ['orders'] })
        navigate('/order-success', { replace: true, state: { kind: 'order', orderNumber } })
      } catch (error) {
        toast.error(error instanceof Error ? error.message : t('somethingWentWrong'))
      } finally {
        setBusy(false)
      }
    }

    const portOptions = ports.data ?? []
    return {
      submit,
      body: (
        <div className="space-y-3.5">
          <ProductSummary product={product} />
          <Card className="space-y-4">
            <div className="grid grid-cols-[1fr_auto] items-end gap-2">
              <Field label={t('quantity')}>
                <TextInput inputMode="decimal" dir="ltr" value={qty} onChange={(e) => setQty(formatNumberInput(e.target.value))} />
              </Field>
              <span className="mb-0.5 flex h-12 items-center rounded-xl bg-[#EEF4FB] px-4 text-sm font-bold text-[#3A7DC5]">{unit ? displayUnit(unit, 1, isAr) : t('unitLabel')}</span>
            </div>
            <div className="rounded-xl bg-[#F4F8FC] p-3.5">
              {canPrice ? (
                <>
                  <div className="flex items-center justify-between text-sm text-subtitle">
                    <span>{t('unitPrice')}</span>
                    <PriceText amount={amount} currency={currency} size={13} className="font-semibold text-title" />
                  </div>
                  <div className="mt-2 flex items-center justify-between border-t border-line pt-2">
                    <span className="text-sm font-extrabold text-title">{t('totalAmount')}</span>
                    <PriceText amount={amount * q} currency={currency} size={16} className="text-lg font-extrabold text-[#619D50]" />
                  </div>
                </>
              ) : (
                <p className="text-center text-sm font-bold text-title">{t('askForPrice')}</p>
              )}
            </div>
          </Card>
          {booking && (
            <Card className="space-y-4">
              <p className="flex items-center gap-2 text-[15px] font-extrabold text-brand">
                <Icon name="location" size={18} />
                {t('portOfArrival')}
              </p>
              <Field label={t('destinationCountry')}>
                <TextInput
                  list="order-countries"
                  value={country}
                  placeholder={t('searchCountry')}
                  onChange={(e) => {
                    setCountry(e.target.value)
                    setPort('')
                  }}
                />
                <datalist id="order-countries">
                  {(countries.data ?? []).map((c) => (
                    <option key={c.countryId} value={c.countryNameEn}>
                      {isAr ? c.countryNameAr : ''}
                    </option>
                  ))}
                </datalist>
              </Field>
              <Field label={t('destinationPort')}>
                {portOptions.length ? (
                  <Select value={port} onChange={(e) => setPort(e.target.value)}>
                    <option value="">{t('selectPort')}</option>
                    {port && !portOptions.some((p) => p.portNameEn === port) && <option value={port}>{port}</option>}
                    {portOptions.map((p) => (
                      <option key={p.id} value={p.portNameEn}>
                        {(isAr && p.portNameAr) || p.portNameEn}
                        {p.unLocode ? ` (${p.unLocode})` : ''}
                      </option>
                    ))}
                  </Select>
                ) : (
                  <TextInput value={port} placeholder={ports.isFetching ? '…' : t('selectPort')} onChange={(e) => setPort(e.target.value)} />
                )}
              </Field>
            </Card>
          )}
          <Card>
            <Field label={t('additionalNotes')}>
              <TextArea value={notes} placeholder={t('additionalNotesHint')} onChange={(e) => setNotes(e.target.value)} />
            </Field>
          </Card>
        </div>
      ),
    }
  })()

  return (
    <Screen
      title={t('purchaseOrder')}
      fallback={product ? productPath(product) : '/'}
      footer={
        content && (
          <PrimaryButton onClick={content.submit} busy={busy}>
            {t('purchaseOrder')}
          </PrimaryButton>
        )
      }
    >
      <Guarded product={product} isPending={isPending} isError={isError}>
        {content?.body}
      </Guarded>
    </Screen>
  )
}

/* ─────────── Submit offer (requests) ─────────── */

const MAX_MEDIA = 15

export function SubmitOfferPage() {
  const { t } = useI18n()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const viewer = useViewer()
  const { session, isAuthenticated } = useAuth()
  const toast = useToast()
  const { product, isPending, isError } = useRouteProduct()
  usePageTitle(t('submitOffer'))

  const [qty, setQty] = useState('')
  const [price, setPrice] = useState('')
  const [currency, setCurrency] = useState('AED')
  const [unit, setUnit] = useState('')
  const [notes, setNotes] = useState('')
  const [files, setFiles] = useState<File[]>([])
  const [busy, setBusy] = useState(false)
  const [progress, setProgress] = useState('')
  const fileRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (product && !unit) setUnit(canonicalUnit(product.unitNameEn || product.unitName || 'Ton'))
  }, [product, unit])

  const previews = useMemo(() => files.map((f) => ({ file: f, url: URL.createObjectURL(f) })), [files])
  useEffect(() => () => previews.forEach((p) => URL.revokeObjectURL(p.url)), [previews])

  if (!isAuthenticated) return <Navigate to="/login" replace />
  if (viewer.isCompanyCustomer && product) return <Navigate to={productPath(product)} replace />

  const unitOptions = unit && !UNIT_OPTIONS.includes(unit as (typeof UNIT_OPTIONS)[number]) ? [unit, ...UNIT_OPTIONS] : [...UNIT_OPTIONS]

  const submit = async () => {
    if (!product) return
    if (isProductOwner(product, viewer)) return toast.error(t('cannotOrderOwnProduct'))
    const q = parseNumber(qty) ?? 0
    const p = parseNumber(price) ?? 0
    if (q <= 0 || p <= 0) return toast.error(t('enterValidQuantityAndPrice'))
    setBusy(true)
    try {
      const imagePaths: string[] = []
      const videoPaths: string[] = []
      for (const [i, file] of files.entries()) {
        setProgress(`${t('uploadingMedia')} ${i + 1}/${files.length}`)
        const path = await uploadOfferMedia(file)
        if (path) (file.type.startsWith('video/') ? videoPaths : imagePaths).push(path)
      }
      setProgress('')
      await createOrder({
        toUserId: product.ownerId ?? '',
        productId: product.productId,
        supplierEmail: session?.email ?? '',
        unitName: unitApiName(unit),
        quantity: q,
        unitPrice: p,
        totalPrice: p * q,
        notes: notes.trim(),
        imagePaths,
        videoPaths,
      })
      queryClient.invalidateQueries({ queryKey: ['orders'] })
      queryClient.invalidateQueries({ queryKey: ['my-offers'] })
      navigate('/order-success', { replace: true, state: { kind: 'offer' } })
    } catch (error) {
      toast.error(error instanceof Error ? error.message : t('somethingWentWrong'))
    } finally {
      setBusy(false)
      setProgress('')
    }
  }

  return (
    <Screen
      title={t('submitOffer')}
      fallback={product ? productPath(product) : '/'}
      footer={
        product && (
          <PrimaryButton onClick={submit} busy={busy}>
            {progress || t('submitOffer')}
          </PrimaryButton>
        )
      }
    >
      <Guarded product={product} isPending={isPending} isError={isError}>
        {product && (
          <div className="space-y-3.5">
            <ProductSummary product={product} />
            <Card className="space-y-4">
              <div className="grid grid-cols-[1fr_120px] gap-2">
                <Field label={t('availableQuantity')}>
                  <TextInput inputMode="decimal" dir="ltr" value={qty} placeholder="0" onChange={(e) => setQty(formatNumberInput(e.target.value))} />
                </Field>
                <Field label={t('unitLabel')}>
                  <Select value={unit} onChange={(e) => setUnit(e.target.value)}>
                    {unitOptions.map((u) => (
                      <option key={u} value={u}>
                        {unitLabel(u, t)}
                      </option>
                    ))}
                  </Select>
                </Field>
              </div>
              <div className="grid grid-cols-[1fr_120px] gap-2">
                <Field label={t('pricePerUnit', { unit: unitLabel(unit, t) })}>
                  <TextInput inputMode="decimal" dir="ltr" value={price} placeholder={t('enterPrice')} onChange={(e) => setPrice(formatNumberInput(e.target.value, 2))} />
                </Field>
                <Field label={t('currency')}>
                  <Select value={currency} onChange={(e) => setCurrency(e.target.value)}>
                    <option value="AED">AED</option>
                    <option value="USD">USD</option>
                  </Select>
                </Field>
              </div>
              {(parseNumber(qty) ?? 0) > 0 && (parseNumber(price) ?? 0) > 0 && (
                <div className="flex items-center justify-between rounded-xl bg-[#F4F8FC] px-3.5 py-3">
                  <span className="text-sm font-extrabold text-title">{t('totalAmount')}</span>
                  <PriceText amount={(parseNumber(qty) ?? 0) * (parseNumber(price) ?? 0)} currency={currency} size={15} className="font-extrabold text-[#619D50]" />
                </div>
              )}
              <Field label={t('specifications')}>
                <TextArea value={notes} placeholder={t('addAnySpecialInstructionsHere')} onChange={(e) => setNotes(e.target.value)} />
              </Field>
            </Card>
            <Card>
              <div className="mb-3 flex items-center justify-between">
                <p className="text-[15px] font-extrabold text-brand">{t('photosAndVideos')}</p>
                <span className="text-xs text-subtitle" dir="ltr">
                  {files.length}/{MAX_MEDIA}
                </span>
              </div>
              <div className="grid grid-cols-4 gap-2 sm:grid-cols-6">
                {previews.map((p, i) => (
                  <div key={p.url} className="relative aspect-square overflow-hidden rounded-xl bg-[#F2F5F9]">
                    {p.file.type.startsWith('video/') ? <video src={p.url} muted className="size-full object-cover" /> : <img src={p.url} alt="" className="size-full object-cover" />}
                    <button
                      type="button"
                      onClick={() => setFiles((all) => all.filter((_, j) => j !== i))}
                      className="absolute end-1 top-1 grid size-6 place-items-center rounded-full bg-black/60 text-white"
                      aria-label="Remove"
                    >
                      <Icon name="close" size={14} />
                    </button>
                  </div>
                ))}
                {files.length < MAX_MEDIA && (
                  <button
                    type="button"
                    onClick={() => fileRef.current?.click()}
                    className="grid aspect-square place-items-center rounded-xl border-2 border-dashed border-[#BFD3EA] text-[#3A7DC5] hover:bg-[#F4F8FC]"
                  >
                    <span className="flex flex-col items-center gap-1 text-[11px] font-bold">
                      <Icon name="plus" size={22} />
                      {t('addMedia')}
                    </span>
                  </button>
                )}
              </div>
              <input
                ref={fileRef}
                type="file"
                accept="image/*,video/*"
                multiple
                hidden
                onChange={(e) => {
                  const picked = Array.from(e.target.files ?? [])
                  e.target.value = ''
                  setFiles((all) => {
                    const next = [...all, ...picked]
                    if (next.length > MAX_MEDIA) toast.info(t('maxMediaReached', { count: MAX_MEDIA }))
                    return next.slice(0, MAX_MEDIA)
                  })
                }}
              />
            </Card>
          </div>
        )}
      </Guarded>
    </Screen>
  )
}

/* ─────────── Success ─────────── */

export function OrderSuccessPage() {
  const { t } = useI18n()
  const location = useLocation()
  const state = (location.state ?? {}) as { kind?: 'order' | 'offer'; orderNumber?: string }
  const offer = state.kind === 'offer'
  usePageTitle(t(offer ? 'offerSentSuccessfullyTitle' : 'orderSentSuccessfullyTitle'))
  return (
    <div className="grid min-h-dvh place-items-center bg-page px-5">
      <div className="w-full max-w-md rounded-3xl border border-line bg-white p-8 text-center shadow-[0_18px_40px_rgba(15,23,42,0.08)]">
        <span className="mx-auto mb-5 grid size-20 place-items-center rounded-full bg-[#E8F5EC] text-[#1f8f4e]">
          <Icon name="check" size={40} strokeWidth={2.4} />
        </span>
        <h1 className="whitespace-pre-line text-xl font-extrabold text-title">{t(offer ? 'offerSentSuccessfullyTitle' : 'orderSentSuccessfullyTitle')}</h1>
        <p className="mt-2 text-sm leading-relaxed text-subtitle">{t(offer ? 'offerSentSuccessfullySubtitle' : 'orderSentSuccessfullySubtitle')}</p>
        {state.orderNumber && (
          <p className="mt-4 rounded-xl bg-[#F4F8FC] py-2.5 text-sm font-bold text-title">
            {t('orderNumber')}: <span dir="ltr">#{state.orderNumber}</span>
          </p>
        )}
        <div className="mt-6 flex flex-col gap-2.5">
          <Link to="/orders" replace className="rounded-xl bg-gradient-to-r from-brand-dark to-brand-light py-3 text-sm font-bold text-white">
            {t('viewMyOrders')}
          </Link>
          <Link to="/" replace className="rounded-xl border border-line py-3 text-sm font-bold text-title">
            {t('backToHome')}
          </Link>
        </div>
      </div>
    </div>
  )
}
