import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { useGetGeoCountriesQuery, useGetGeoPortsByCountryQuery } from '../../store'
import type { Category } from '../../types/category'
import type {
  AdminProductDetail,
  AdminProductLookupItem,
  AdminUpdateProductPayload,
} from '../../types/adminProduct'
import { isBookingAd, isOffersAd } from '../../utils/adsDisplay'

type AdEditDialogProps = {
  open: boolean
  product: AdminProductDetail
  categories: Category[]
  units: AdminProductLookupItem[]
  isSaving: boolean
  onClose: () => void
  onSubmit: (payload: AdminUpdateProductPayload) => void
}

const REQUEST_TYPE_OPTIONS = ['Local', 'Reexport'] as const
const BOOKING_PRICE_TYPE_OPTIONS = ['FOB', 'CNF', 'CIF'] as const

function toNumberOrUndefined(value: string): number | undefined {
  const trimmed = value.trim()
  if (!trimmed) return undefined
  const parsed = Number(trimmed)
  return Number.isFinite(parsed) ? parsed : undefined
}

function normalizeRequestType(value: string | null | undefined): string {
  const key = (value ?? '').trim().toLowerCase()
  if (!key) return ''
  if (key.includes('local')) return 'Local'
  return 'Reexport'
}

function normalizeBookingType(value: string | null | undefined): string {
  const key = (value ?? '').trim().toUpperCase()
  return (BOOKING_PRICE_TYPE_OPTIONS as readonly string[]).includes(key) ? key : ''
}

/** Best-effort match of a (possibly localized) country name to its canonical English name. */
function resolveCountryEn(
  displayName: string | null | undefined,
  countries: { countryNameEn: string; countryNameAr?: string | null }[],
): string {
  const name = (displayName ?? '').trim()
  if (!name) return ''
  const match = countries.find(
    (c) =>
      c.countryNameEn.trim().toLowerCase() === name.toLowerCase() ||
      (c.countryNameAr ?? '').trim().toLowerCase() === name.toLowerCase(),
  )
  return match?.countryNameEn ?? name
}

function Field({
  label,
  children,
  hint,
}: {
  label: string
  children: ReactNode
  hint?: string
}) {
  return (
    <label className="block text-start">
      <span className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">
        {label}
      </span>
      <div className="mt-1">{children}</div>
      {hint ? <span className="admin-text-subtle mt-1 block text-[10px]">{hint}</span> : null}
    </label>
  )
}

const inputClass = 'admin-input w-full rounded-lg px-2.5 py-1.5 text-sm font-semibold'

export default function AdEditDialog({
  open,
  product,
  categories,
  units,
  isSaving,
  onClose,
  onSubmit,
}: AdEditDialogProps) {
  const { t, locale } = useAppPreferences()

  const hasCategory = (product.categoryId ?? 0) > 0
  const booking = isBookingAd(product)
  const offers = isOffersAd(product)
  const isRequest =
    product.productTypeId === 4 ||
    product.productTypeName.trim().toLowerCase() === 'requests'
  const showRequestType = offers || isRequest || hasCategory

  const allowedCurrencies = booking ? ['USD'] : hasCategory || offers || isRequest ? ['AED', 'USD'] : ['AED']

  // --- form state ---
  const [nameEn, setNameEn] = useState('')
  const [descriptionEn, setDescriptionEn] = useState('')
  const [price, setPrice] = useState('')
  const [currency, setCurrency] = useState('AED')
  const [unitName, setUnitName] = useState('')
  const [quantity, setQuantity] = useState('')
  const [negotiable, setNegotiable] = useState(false)
  const [packingOther, setPackingOther] = useState(false)
  const [packagingKg, setPackagingKg] = useState('')
  const [packagingDetails, setPackagingDetails] = useState('')
  const [categoryId, setCategoryId] = useState('')
  const [requestType, setRequestType] = useState('')
  const [bookingPriceType, setBookingPriceType] = useState('')
  const [originCountry, setOriginCountry] = useState('')
  const [destinationCountry, setDestinationCountry] = useState('')
  const [loadingPort, setLoadingPort] = useState('')
  const [arrivalPort, setArrivalPort] = useState('')
  const [shippingDurationDays, setShippingDurationDays] = useState('')
  const [offerDurationDays, setOfferDurationDays] = useState('')
  const [discountPercentage, setDiscountPercentage] = useState('')
  const [discountDays, setDiscountDays] = useState('')
  const [requiredDeliveryDate, setRequiredDeliveryDate] = useState('')
  // retail channel
  const [enableRetail, setEnableRetail] = useState(false)
  const [retailPrice, setRetailPrice] = useState('')
  const [retailUnitName, setRetailUnitName] = useState('')
  const [retailQuantity, setRetailQuantity] = useState('')
  const [retailPackingOther, setRetailPackingOther] = useState(false)
  const [retailPackagingKg, setRetailPackagingKg] = useState('')
  const [retailPackagingDetails, setRetailPackagingDetails] = useState('')
  const [retailDescriptionEn, setRetailDescriptionEn] = useState('')

  const { data: countries = [] } = useGetGeoCountriesQuery(undefined, { skip: !open || !booking })
  const { data: originPorts } = useGetGeoPortsByCountryQuery(originCountry, {
    skip: !open || !booking || !originCountry,
  })
  const { data: destinationPorts } = useGetGeoPortsByCountryQuery(destinationCountry, {
    skip: !open || !booking || !destinationCountry,
  })

  useEffect(() => {
    if (!open) return
    setNameEn(product.name ?? '')
    setDescriptionEn(product.description ?? '')
    setPrice(product.priceUsd != null ? String(product.priceUsd) : '')
    setCurrency(product.currency?.trim() || (booking ? 'USD' : 'AED'))
    setUnitName(product.unitName ?? '')
    setQuantity(product.quantity != null ? String(product.quantity) : '')
    setNegotiable(product.negotiable === true)

    const details = product.packagingDetails?.trim() ?? ''
    setPackingOther(details.length > 0)
    setPackagingDetails(details)
    setPackagingKg(product.packaging != null && product.packaging > 0 ? String(product.packaging) : '')

    setCategoryId(product.categoryId != null && product.categoryId > 0 ? String(product.categoryId) : '')
    setRequestType(normalizeRequestType(product.requestTypeName))
    setBookingPriceType(normalizeBookingType(product.bookingPriceTypeName))

    setOriginCountry(product.originCountryName?.trim() ?? '')
    setDestinationCountry(product.destinationCountryName?.trim() ?? '')
    setLoadingPort(product.loadingPortName?.trim() ?? '')
    setArrivalPort(product.arrivalPortName?.trim() ?? '')
    setShippingDurationDays(/^\d+$/.test((product.shippingDuration ?? '').trim()) ? product.shippingDuration!.trim() : '')
    setOfferDurationDays(/^\d+$/.test((product.offerDuration ?? '').trim()) ? product.offerDuration!.trim() : '')
    setDiscountPercentage('')
    setDiscountDays('')
    setRequiredDeliveryDate(
      isRequest && /^\d{4}-\d{2}-\d{2}$/.test((product.shippingDuration ?? '').trim())
        ? product.shippingDuration!.trim()
        : '',
    )

    setEnableRetail(product.hasRetailPricing === true)
    setRetailPrice(product.retailPrice != null ? String(product.retailPrice) : '')
    setRetailUnitName(product.retailUnitName?.trim() ?? '')
    setRetailQuantity(product.retailQuantity != null ? String(product.retailQuantity) : '')
    const retailDetails = product.retailPackagingDetails?.trim() ?? ''
    setRetailPackingOther(retailDetails.length > 0)
    setRetailPackagingDetails(retailDetails)
    setRetailPackagingKg(
      product.retailPackaging != null && product.retailPackaging > 0 ? String(product.retailPackaging) : '',
    )
    setRetailDescriptionEn(product.retailDescription?.trim() ?? '')
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, product.productId])

  // Normalize the prefilled country names to canonical English once the geo list loads.
  useEffect(() => {
    if (!open || !booking || countries.length === 0) return
    setOriginCountry((prev) => resolveCountryEn(prev, countries))
    setDestinationCountry((prev) => resolveCountryEn(prev, countries))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, booking, countries])

  useEffect(() => {
    if (!open) return
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [open, onClose])

  const unitOptions = useMemo(() => units.map((u) => u.name).filter(Boolean), [units])

  if (!open) return null

  const isFob = booking && bookingPriceType === 'FOB'

  function handleSubmit() {
    const trimmedName = nameEn.trim()
    const parsedPrice = toNumberOrUndefined(price)
    if (!trimmedName || parsedPrice == null || parsedPrice < 0) return

    const payload: AdminUpdateProductPayload = {
      nameEn: trimmedName,
      usdPrice: parsedPrice,
      currency,
      quantity: Math.max(0, Math.trunc(toNumberOrUndefined(quantity) ?? 0)),
      descriptionEn: descriptionEn.trim(),
      // Empty type name preserves the existing ad classification on the backend.
      productTypeName: '',
      unitName: unitName.trim(),
      negotiable,
    }

    // Packing: free-text "Other packing" wins over the numeric kg value.
    if (packingOther) {
      payload.packagingDetails = packagingDetails.trim()
    } else {
      const kg = toNumberOrUndefined(packagingKg)
      if (kg != null) payload.packaging = Math.min(255, Math.max(1, Math.trunc(kg)))
    }

    if (hasCategory) {
      const catId = toNumberOrUndefined(categoryId)
      if (catId != null) payload.categoryId = catId
    }

    if (showRequestType && requestType) {
      payload.requestTypeName = requestType
    }

    if (booking) {
      payload.bookingPriceTypeName = bookingPriceType || undefined
      payload.originCountryName = originCountry
      payload.loadingPortName = loadingPort
      // FOB drops destination + arrival; empty string tells the backend to clear them.
      payload.destinationCountryName = isFob ? '' : destinationCountry
      payload.arrivalPortName = isFob ? '' : arrivalPort
      const days = toNumberOrUndefined(shippingDurationDays)
      if (days != null) payload.shippingDuration = String(Math.trunc(days))
    }

    if (offers) {
      const pct = toNumberOrUndefined(discountPercentage)
      if (pct != null) payload.discountPercentage = Math.min(99, Math.max(0, Math.trunc(pct)))
      const dDays = toNumberOrUndefined(discountDays)
      if (dDays != null) payload.discountDays = Math.max(0, Math.trunc(dDays))
      const oDays = toNumberOrUndefined(offerDurationDays)
      if (oDays != null) payload.offerDuration = String(Math.trunc(oDays))
    }

    if (isRequest && requiredDeliveryDate) {
      payload.shippingDuration = requiredDeliveryDate
    }

    if (!booking && !offers && !isRequest && !hasCategory) {
      const days = toNumberOrUndefined(shippingDurationDays)
      if (days != null) payload.shippingDuration = String(Math.trunc(days))
    }

    if (hasCategory) {
      payload.enableRetailPricing = enableRetail
      if (enableRetail) {
        const rPrice = toNumberOrUndefined(retailPrice)
        if (rPrice != null) payload.retailPrice = rPrice
        if (retailUnitName.trim()) payload.retailUnitName = retailUnitName.trim()
        const rQty = toNumberOrUndefined(retailQuantity)
        if (rQty != null) payload.retailQuantity = Math.max(0, Math.trunc(rQty))
        if (retailPackingOther) {
          payload.retailPackagingDetails = retailPackagingDetails.trim()
        } else {
          const rKg = toNumberOrUndefined(retailPackagingKg)
          if (rKg != null) payload.retailPackaging = Math.min(255, Math.max(1, Math.trunc(rKg)))
        }
        if (retailDescriptionEn.trim()) payload.retailDescriptionEn = retailDescriptionEn.trim()
      }
    }

    onSubmit(payload)
  }

  const originPortOptions = originPorts?.ports ?? []
  const destinationPortOptions = destinationPorts?.ports ?? []

  return (
    <div
      className="fixed inset-0 z-[120] flex items-center justify-center bg-black/50 p-4 print:hidden"
      role="dialog"
      aria-modal="true"
      aria-labelledby="ad-edit-dialog-title"
      onClick={onClose}
    >
      <div
        className="admin-card flex max-h-[90vh] w-full max-w-3xl flex-col overflow-hidden rounded-2xl shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="admin-border flex items-start justify-between gap-3 border-b px-5 py-4">
          <div className="min-w-0 text-start">
            <h2 id="ad-edit-dialog-title" className="admin-text text-lg font-bold leading-snug">
              {t('ads.editAdTitle')}
            </h2>
            <p className="admin-text-subtle mt-1 text-xs">{t('ads.editAdHintFull')}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={t('cancel')}
            className="shrink-0 rounded-lg p-1.5 text-slate-500 transition hover:bg-slate-100 hover:text-slate-700 dark:hover:bg-slate-800"
          >
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8} aria-hidden>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="grid gap-3 overflow-y-auto px-5 py-4 sm:grid-cols-2">
          <div className="sm:col-span-2">
            <Field label={t('ads.productName')}>
              <input className={inputClass} value={nameEn} onChange={(e) => setNameEn(e.target.value)} />
            </Field>
          </div>

          {hasCategory ? (
            <Field label={t('ads.category')}>
              <select className={inputClass} value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
                <option value="">{t('ads.selectPlaceholder')}</option>
                {categories.map((c) => (
                  <option key={c.categoryId} value={c.categoryId}>
                    {locale === 'ar' ? c.nameAr || c.nameEn : c.nameEn || c.nameAr}
                  </option>
                ))}
              </select>
            </Field>
          ) : null}

          <Field label={t('ads.quantity')}>
            <input
              type="number"
              min={0}
              className={inputClass}
              value={quantity}
              onChange={(e) => setQuantity(e.target.value)}
            />
          </Field>

          <Field label={t('ads.price')}>
            <input
              type="number"
              min={0}
              step="any"
              className={inputClass}
              value={price}
              onChange={(e) => setPrice(e.target.value)}
            />
          </Field>

          <Field label={t('ads.currency')}>
            <select className={inputClass} value={currency} onChange={(e) => setCurrency(e.target.value)}>
              {allowedCurrencies.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </Field>

          <Field label={t('ads.unit')}>
            <select className={inputClass} value={unitName} onChange={(e) => setUnitName(e.target.value)}>
              {!unitOptions.includes(unitName) && unitName ? (
                <option value={unitName}>{unitName}</option>
              ) : null}
              {unitOptions.map((u) => (
                <option key={u} value={u}>
                  {u}
                </option>
              ))}
            </select>
          </Field>

          {!booking ? (
            <Field label={t('ads.negotiable')}>
              <select
                className={inputClass}
                value={negotiable ? 'yes' : 'no'}
                onChange={(e) => setNegotiable(e.target.value === 'yes')}
              >
                <option value="yes">{t('ads.negotiableYes')}</option>
                <option value="no">{t('ads.negotiableNo')}</option>
              </select>
            </Field>
          ) : null}

          {showRequestType ? (
            <Field label={t('ads.requestFulfillment')}>
              <select className={inputClass} value={requestType} onChange={(e) => setRequestType(e.target.value)}>
                <option value="">{t('ads.selectPlaceholder')}</option>
                {REQUEST_TYPE_OPTIONS.map((o) => (
                  <option key={o} value={o}>
                    {o === 'Local' ? t('ads.requestFulfillmentLocal') : t('ads.requestFulfillmentRexport')}
                  </option>
                ))}
              </select>
            </Field>
          ) : null}

          {/* Packing */}
          <div className="sm:col-span-2">
            <div className="mb-1 flex items-center justify-between">
              <span className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">
                {t('ads.packagingType')}
              </span>
              <label className="flex items-center gap-1.5 text-xs font-semibold">
                <input
                  type="checkbox"
                  checked={packingOther}
                  onChange={(e) => setPackingOther(e.target.checked)}
                />
                {t('ads.otherPacking')}
              </label>
            </div>
            {packingOther ? (
              <input
                className={inputClass}
                value={packagingDetails}
                placeholder={t('ads.otherPackingHint')}
                onChange={(e) => setPackagingDetails(e.target.value)}
              />
            ) : (
              <input
                type="number"
                min={1}
                max={255}
                className={inputClass}
                value={packagingKg}
                onChange={(e) => setPackagingKg(e.target.value)}
              />
            )}
          </div>

          {/* Booking geo */}
          {booking ? (
            <>
              <Field label={t('ads.bookingPriceType')}>
                <select
                  className={inputClass}
                  value={bookingPriceType}
                  onChange={(e) => setBookingPriceType(e.target.value)}
                >
                  <option value="">{t('ads.selectPlaceholder')}</option>
                  {BOOKING_PRICE_TYPE_OPTIONS.map((o) => (
                    <option key={o} value={o}>
                      {o}
                    </option>
                  ))}
                </select>
              </Field>

              <Field label={t('ads.shippingDurationDays')}>
                <input
                  type="number"
                  min={0}
                  className={inputClass}
                  value={shippingDurationDays}
                  onChange={(e) => setShippingDurationDays(e.target.value)}
                />
              </Field>

              <Field label={t('ads.originCountry')}>
                <select
                  className={inputClass}
                  value={originCountry}
                  onChange={(e) => {
                    setOriginCountry(e.target.value)
                    setLoadingPort('')
                  }}
                >
                  <option value="">{t('ads.selectPlaceholder')}</option>
                  {!countries.some((c) => c.countryNameEn === originCountry) && originCountry ? (
                    <option value={originCountry}>{originCountry}</option>
                  ) : null}
                  {countries.map((c) => (
                    <option key={c.id} value={c.countryNameEn}>
                      {locale === 'ar' ? c.countryNameAr || c.countryNameEn : c.countryNameEn}
                    </option>
                  ))}
                </select>
              </Field>

              <Field label={t('ads.loadingPort')}>
                <select className={inputClass} value={loadingPort} onChange={(e) => setLoadingPort(e.target.value)}>
                  <option value="">{t('ads.selectPlaceholder')}</option>
                  {!originPortOptions.some((p) => p.portNameEn === loadingPort) && loadingPort ? (
                    <option value={loadingPort}>{loadingPort}</option>
                  ) : null}
                  {originPortOptions.map((p) => (
                    <option key={p.id} value={p.portNameEn}>
                      {p.portNameEn}
                    </option>
                  ))}
                </select>
              </Field>

              {!isFob ? (
                <>
                  <Field label={t('ads.destinationCountry')}>
                    <select
                      className={inputClass}
                      value={destinationCountry}
                      onChange={(e) => {
                        setDestinationCountry(e.target.value)
                        setArrivalPort('')
                      }}
                    >
                      <option value="">{t('ads.selectPlaceholder')}</option>
                      {!countries.some((c) => c.countryNameEn === destinationCountry) && destinationCountry ? (
                        <option value={destinationCountry}>{destinationCountry}</option>
                      ) : null}
                      {countries.map((c) => (
                        <option key={c.id} value={c.countryNameEn}>
                          {locale === 'ar' ? c.countryNameAr || c.countryNameEn : c.countryNameEn}
                        </option>
                      ))}
                    </select>
                  </Field>

                  <Field label={t('ads.arrivalPort')}>
                    <select className={inputClass} value={arrivalPort} onChange={(e) => setArrivalPort(e.target.value)}>
                      <option value="">{t('ads.selectPlaceholder')}</option>
                      {!destinationPortOptions.some((p) => p.portNameEn === arrivalPort) && arrivalPort ? (
                        <option value={arrivalPort}>{arrivalPort}</option>
                      ) : null}
                      {destinationPortOptions.map((p) => (
                        <option key={p.id} value={p.portNameEn}>
                          {p.portNameEn}
                        </option>
                      ))}
                    </select>
                  </Field>
                </>
              ) : null}
            </>
          ) : null}

          {/* Offers discount + duration */}
          {offers ? (
            <>
              <Field label={t('ads.discountPercentage')}>
                <input
                  type="number"
                  min={0}
                  max={99}
                  className={inputClass}
                  value={discountPercentage}
                  onChange={(e) => setDiscountPercentage(e.target.value)}
                />
              </Field>
              <Field label={t('ads.discountDays')}>
                <input
                  type="number"
                  min={0}
                  className={inputClass}
                  value={discountDays}
                  onChange={(e) => setDiscountDays(e.target.value)}
                />
              </Field>
              <Field label={t('ads.offerDuration')}>
                <input
                  type="number"
                  min={0}
                  className={inputClass}
                  value={offerDurationDays}
                  onChange={(e) => setOfferDurationDays(e.target.value)}
                />
              </Field>
            </>
          ) : null}

          {/* Requests delivery date */}
          {isRequest ? (
            <Field label={t('ads.requiredDeliveryDate')}>
              <input
                type="date"
                className={inputClass}
                value={requiredDeliveryDate}
                onChange={(e) => setRequiredDeliveryDate(e.target.value)}
              />
            </Field>
          ) : null}

          {/* Pure retail delivery days */}
          {!booking && !offers && !isRequest && !hasCategory ? (
            <Field label={t('ads.shippingDurationDays')}>
              <input
                type="number"
                min={0}
                className={inputClass}
                value={shippingDurationDays}
                onChange={(e) => setShippingDurationDays(e.target.value)}
              />
            </Field>
          ) : null}

          <div className="sm:col-span-2">
            <Field label={t('ads.productDescription')}>
              <textarea
                className={`${inputClass} min-h-[70px] resize-y`}
                value={descriptionEn}
                onChange={(e) => setDescriptionEn(e.target.value)}
              />
            </Field>
          </div>

          {/* Retail channel for category ads */}
          {hasCategory ? (
            <div className="admin-border sm:col-span-2 rounded-xl border p-3">
              <label className="flex items-center gap-2 text-sm font-semibold">
                <input type="checkbox" checked={enableRetail} onChange={(e) => setEnableRetail(e.target.checked)} />
                {t('ads.enableRetailPricing')}
              </label>
              {enableRetail ? (
                <div className="mt-3 grid gap-3 sm:grid-cols-2">
                  <Field label={t('ads.retailQuantity')}>
                    <input
                      type="number"
                      min={0}
                      className={inputClass}
                      value={retailQuantity}
                      onChange={(e) => setRetailQuantity(e.target.value)}
                    />
                  </Field>
                  <Field label={t('ads.retailPrice')}>
                    <input
                      type="number"
                      min={0}
                      step="any"
                      className={inputClass}
                      value={retailPrice}
                      onChange={(e) => setRetailPrice(e.target.value)}
                    />
                  </Field>
                  <Field label={t('ads.retailUnit')}>
                    <select
                      className={inputClass}
                      value={retailUnitName}
                      onChange={(e) => setRetailUnitName(e.target.value)}
                    >
                      <option value="">{t('ads.selectPlaceholder')}</option>
                      {!unitOptions.includes(retailUnitName) && retailUnitName ? (
                        <option value={retailUnitName}>{retailUnitName}</option>
                      ) : null}
                      {unitOptions.map((u) => (
                        <option key={u} value={u}>
                          {u}
                        </option>
                      ))}
                    </select>
                  </Field>
                  <div>
                    <div className="mb-1 flex items-center justify-between">
                      <span className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">
                        {t('ads.retailPackagingType')}
                      </span>
                      <label className="flex items-center gap-1.5 text-xs font-semibold">
                        <input
                          type="checkbox"
                          checked={retailPackingOther}
                          onChange={(e) => setRetailPackingOther(e.target.checked)}
                        />
                        {t('ads.otherPacking')}
                      </label>
                    </div>
                    {retailPackingOther ? (
                      <input
                        className={inputClass}
                        value={retailPackagingDetails}
                        placeholder={t('ads.otherPackingHint')}
                        onChange={(e) => setRetailPackagingDetails(e.target.value)}
                      />
                    ) : (
                      <input
                        type="number"
                        min={1}
                        max={255}
                        className={inputClass}
                        value={retailPackagingKg}
                        onChange={(e) => setRetailPackagingKg(e.target.value)}
                      />
                    )}
                  </div>
                  <div className="sm:col-span-2">
                    <Field label={t('ads.retailProductDescription')}>
                      <textarea
                        className={`${inputClass} min-h-[60px] resize-y`}
                        value={retailDescriptionEn}
                        onChange={(e) => setRetailDescriptionEn(e.target.value)}
                      />
                    </Field>
                  </div>
                </div>
              ) : null}
            </div>
          ) : null}
        </div>

        <div className="admin-border flex justify-end gap-2 border-t px-5 py-3">
          <button
            type="button"
            onClick={onClose}
            className="admin-border rounded-xl border bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 dark:bg-slate-900 dark:text-slate-200"
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            onClick={handleSubmit}
            disabled={isSaving}
            className="keep-white rounded-xl bg-[#3B7FC7] px-5 py-2 text-sm font-semibold text-white disabled:opacity-60"
          >
            {isSaving ? t('ads.saving') : t('ads.saveChanges')}
          </button>
        </div>
      </div>
    </div>
  )
}
