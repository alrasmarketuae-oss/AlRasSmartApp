import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useEffect, useMemo, useRef, useState } from 'react'
import { Link, Navigate, useLocation, useNavigate, useSearchParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { Spinner } from '../auth/components'
import {
  AD_TYPE_LABEL,
  AD_TYPES,
  alwaysShowsPrice,
  BOOKING_PRICE_TYPES,
  buildProductForm,
  confirmAssetsBatch,
  confirmVideo,
  createProduct,
  daysOnly,
  deleteRemoteImage,
  EMPTY_AD_FORM,
  num,
  packingValue,
  submitForReview,
  supportsFulfillment,
  updateProduct,
  withType,
  type AdForm,
  type AdType,
  type BookingPriceType,
} from '../createAd/createAdApi'
import {
  CountryField,
  CurrencySelect,
  ERROR_BORDER,
  FormField,
  FulfillmentRadio,
  HeroBanner,
  InfoDialog,
  intInput,
  MediaSection,
  NegotiationCards,
  PackingSection,
  PortField,
  priceInput,
  PublishButton,
  SectionCard,
  SectionTitle,
  ShowPriceToggle,
  SpecsField,
  Switch,
  UnitSelect,
} from '../createAd/AdFormParts'
import { listingMediaPaths, prefillFromListing, type EditPrefill } from '../createAd/editPrefill'
import { useAdMedia } from '../createAd/useAdMedia'
import { categoryName, useCategories } from '../home/CategoriesStrip'
import { useI18n } from '../i18n/I18nProvider'
import { useGoBack } from '../layout/ScreenLayout'
import { ApiError } from '../lib/api'
import { usePageTitle } from '../lib/usePageTitle'
import { unitLabel } from '../products/units'
import { MY_LISTINGS_KEY } from '../seller/MyAdCard'
import { fetchMyListings, type MyListing } from '../seller/sellerApi'
import { Select, TextArea, TextInput } from '../ui/Form'
import { Icon } from '../ui/Icon'
import { Modal } from '../ui/Modal'
import { useToast } from '../ui/Toast'

type Errors = Partial<Record<string, string>>

function playPublishSound() {
  try {
    void new Audio('/assets/sounds/publish_success.mpeg').play().catch(() => undefined)
  } catch {
    // Audio is optional.
  }
}

function scrollToFirstError(errors: Errors, order: string[]) {
  const key = order.find((k) => errors[k])
  if (!key) return
  window.setTimeout(() => document.getElementById(`f-${key}`)?.scrollIntoView({ behavior: 'smooth', block: 'center' }), 30)
}

const sameId = (a?: string | null, b?: string | null) => !!a && !!b && a.toLowerCase() === b.toLowerCase()

function CenterSpinner() {
  return (
    <div className="grid min-h-[50vh] place-items-center">
      <Spinner className="size-9 border-[3px] border-brand/25 border-t-brand" />
    </div>
  )
}

function Notice({ text }: { text: string }) {
  const { t } = useI18n()
  return (
    <div className="mx-auto max-w-md py-20 text-center">
      <span className="mx-auto mb-4 grid size-16 place-items-center rounded-full bg-[#EAF2FB] text-[#3A7DC5]">
        <Icon name="info" size={28} />
      </span>
      <p className="mb-5 text-[15px] font-semibold text-title">{text}</p>
      <Link to="/" className="rounded-xl bg-brand px-5 py-2.5 text-sm font-bold text-white">
        {t('goHome')}
      </Link>
    </div>
  )
}

function useFormState(initial: AdForm) {
  const [form, setForm] = useState<AdForm>(initial)
  const [errors, setErrors] = useState<Errors>({})
  const set = (changes: Partial<AdForm>, clear: string[] = Object.keys(changes)) => {
    setForm((current) => ({ ...current, ...changes }))
    if (clear.some((k) => errors[k])) setErrors((current) => Object.fromEntries(Object.entries(current).filter(([k]) => !clear.includes(k))))
  }
  return { form, setForm, set, errors, setErrors }
}

function errorMessage(error: unknown, fallback: string) {
  return error instanceof Error && error.message ? error.message : fallback
}

/* ─────────── Create / edit ad ─────────── */

export function CreateAdPage() {
  const { t } = useI18n()
  const [params] = useSearchParams()
  const location = useLocation()
  const { isAuthenticated, isCompanyCustomer, isPersonalCustomer, session } = useAuth()
  const editId = params.get('edit')?.trim() || ''
  const seeded = (location.state as { product?: MyListing } | null)?.product
  const seed = seeded && sameId(seeded.productId, editId) ? seeded : undefined
  const listings = useQuery({
    queryKey: [MY_LISTINGS_KEY, session?.id],
    queryFn: fetchMyListings,
    enabled: isAuthenticated && !!editId && !seed,
  })
  usePageTitle(t(editId ? 'editAdTitle' : 'createAd'))

  if (!isAuthenticated) return <Navigate to="/login" replace />
  if (!editId && isCompanyCustomer) return <Navigate to="/create-order" replace />
  if (!editId && isPersonalCustomer) return <Notice text={t('onlySuppliersCreateAds')} />
  if (!editId) return <AdEditor key="new" />

  const listing = seed ?? listings.data?.products.find((p) => sameId(p.productId, editId))
  if (!listing) return listings.isPending ? <CenterSpinner /> : <Notice text={t('adNotFoundForEdit')} />
  return <AdEditor key={listing.productId} listing={listing} />
}

const ERROR_ORDER = ['media', 'name', 'type', 'category', 'bookingPriceType', 'originCountry', 'price', 'beforeDiscount', 'afterDiscount', 'quantity', 'fulfillment', 'days', 'deliveryDate', 'packing', 'retailPrice', 'retailQuantity', 'retailPacking', 'retailSpecs']

function AdEditor({ listing }: { listing?: MyListing }) {
  const { t, isAr, lang } = useI18n()
  const toast = useToast()
  const navigate = useNavigate()
  const goBack = useGoBack('/my-ads')
  const queryClient = useQueryClient()
  const { isSupplier, isUaePhone, isCompanyCustomer } = useAuth()
  const categories = useCategories()
  const media = useAdMedia()
  const isEdit = !!listing
  const overseas = isSupplier && !isUaePhone

  const prefill = useMemo<EditPrefill | null>(() => (listing ? prefillFromListing(listing) : null), [listing])
  const { form, setForm, set, errors, setErrors } = useFormState(prefill?.form ?? (overseas ? withType(EMPTY_AD_FORM, 'Booking') : EMPTY_AD_FORM))
  const [busy, setBusy] = useState(false)
  const [progress, setProgress] = useState('')
  const [retailInfo, setRetailInfo] = useState(false)
  const [copyAsk, setCopyAsk] = useState(false)
  const createdId = useRef('')
  const { setRemote } = media

  useEffect(() => {
    if (listing) setRemote(listingMediaPaths(listing))
  }, [listing, setRemote])

  const typeOptions: readonly AdType[] = isCompanyCustomer ? ['Requests'] : overseas ? ['Booking'] : AD_TYPES
  const type = form.type
  const isRequest = type === 'Requests'
  const isOffers = type === 'Offers'
  const isBooking = type === 'Booking'
  const isRetail = type === 'Retail'
  const isCategories = type === 'Categories'
  const fob = isBooking && form.bookingPriceType === 'FOB'
  const unitText = unitLabel(form.unit, t)

  const copyWholesale = () =>
    set({
      retailPrice: form.price,
      retailUnit: form.unit,
      retailPackingKg: form.packingKg,
      retailOtherPacking: form.otherPacking,
      retailPackingOther: form.packingOther,
      retailSpecs: form.specs,
    })

  const validate = (): Errors => {
    const e: Errors = {}
    const required = t('thisFieldIsRequired')
    if (!media.items.length) e.media = t('productImagesRequired')
    if (!form.name.trim()) e.name = required
    if (!type) e.type = t('selectAnOption')
    else if (overseas && type !== 'Booking') e.type = t('selectAnOption')
    if (isCategories && !form.categoryId) e.category = t('selectCategory')
    if (type && !isRequest) {
      if (isOffers) {
        if (num(form.afterDiscount) <= 0 && num(form.beforeDiscount) <= 0) e.afterDiscount = t('enterValidPrice')
      } else if (num(form.price) <= 0) e.price = t('enterValidPrice')
      if (num(form.quantity) <= 0) e.quantity = required
    }
    if (!isEdit && supportsFulfillment(type) && !form.fulfillment) e.fulfillment = t('selectRequestFulfillment')
    if (isBooking && !form.originCountry.trim()) e.originCountry = t('completeOriginDestination')
    if (!isEdit && (isOffers || isBooking || isRetail) && !form.days.trim()) e.days = required
    if (!form.otherPacking && form.packingKg && packingValue(form.packingKg) === null) e.packing = t('packingRangeError')
    if (isCategories && form.retailEnabled) {
      if (num(form.retailPrice) <= 0) e.retailPrice = t('enterValidPrice')
      if (num(form.retailQuantity) <= 0) e.retailQuantity = required
      if (!form.retailSpecs.trim()) e.retailSpecs = t('retailSpecificationsRequired')
      if (!form.retailOtherPacking && form.retailPackingKg && packingValue(form.retailPackingKg) === null) e.retailPacking = t('packingRangeError')
    }
    return e
  }

  const finishCreate = async (productId: string, extraVideos: { path: string; duration: number }[]) => {
    for (const video of extraVideos) {
      setProgress(t('publishStepUploadingVideo'))
      await confirmVideo(productId, video)
    }
    setProgress(t('publishStepFinishing'))
    await submitForReview(productId)
  }

  const submit = async () => {
    if (busy) return
    const found = validate()
    setErrors(found)
    const firstKey = ERROR_ORDER.find((k) => found[k])
    if (firstKey) {
      scrollToFirstError(found, ERROR_ORDER)
      return toast.error(found[firstKey]!)
    }

    setBusy(true)
    try {
      setProgress(t('preparingMedia'))
      if (!(await media.settle())) {
        toast.error(t('mediaUploadFailed'))
        return
      }
      const payload = media.payload()
      if (!listing) {
        setProgress(t('publishStepCreatingAd'))
        if (!createdId.current) {
          const created = await createProduct(buildProductForm(form, payload, { isEdit: false, lang }))
          if (!created.productId) throw new Error(created.message || t('somethingWentWrong'))
          createdId.current = created.productId
          media.markConfirmed()
        }
        await finishCreate(createdId.current, payload.draftVideos.slice(1))
        const productId = createdId.current
        void queryClient.invalidateQueries({ queryKey: [MY_LISTINGS_KEY] })
        playPublishSound()
        toast.success(t('adSubmittedForReview'))
        media.reset()
        navigate(`/my-ads?highlight=${encodeURIComponent(productId)}`, { replace: true })
        return
      }

      setProgress(t('publishingEllipsis'))
      const productId = listing.productId
      const updated = await updateProduct(
        productId,
        buildProductForm(form, payload, {
          isEdit: true,
          lang,
          canonicalName: prefill?.canonicalName,
          loadedName: prefill?.loadedName,
          canonicalSpecs: prefill?.canonicalSpecs,
          loadedSpecs: prefill?.loadedSpecs,
        }),
      )
      for (const path of payload.removedRemoteImages) {
        try {
          await deleteRemoteImage(productId, path)
        } catch (error) {
          if (!(error instanceof ApiError && error.status === 404)) throw error
        }
      }
      const [firstVideo, ...moreVideos] = payload.draftVideos
      if (payload.draftImages.length || firstVideo) {
        setProgress(t('publishStepUploadingImages'))
        await confirmAssetsBatch(productId, payload.draftImages, firstVideo)
        for (const video of moreVideos) await confirmVideo(productId, video)
      }
      media.markConfirmed()
      const mediaChanged = payload.draftImages.length > 0 || payload.draftVideos.length > 0 || payload.removedRemoteImages.length > 0
      if (updated.requiresAdminReview || mediaChanged) {
        setProgress(t('publishStepFinishing'))
        await submitForReview(productId)
      }
      void queryClient.invalidateQueries({ queryKey: [MY_LISTINGS_KEY] })
      playPublishSound()
      toast.success(t('adUpdatedSuccessfully'))
      goBack()
    } catch (error) {
      toast.error(errorMessage(error, t('somethingWentWrong')))
    } finally {
      setBusy(false)
      setProgress('')
    }
  }

  const pricingLabel = isRequest ? t('targetPrice') : isOffers ? t('offerPrice') : t('price')
  const priceHint = isRequest ? t('enterYourTargetPrice') : isCategories ? t('enterProductPrice') : t('pricePerUnitShort', { unit: unitText })
  const quantityLabel = isRequest ? t('requiredQuantityPerUnit', { unit: unitText }) : t('quantityPerUnit', { unit: unitText })

  return (
    <div className="mx-auto w-full max-w-3xl space-y-3 px-3 pb-10 pt-3 sm:px-5 sm:pt-5">
      {isEdit ? (
        <div className="flex items-center gap-2">
          <button type="button" onClick={goBack} className="grid size-10 place-items-center rounded-full text-title hover:bg-black/5" aria-label={t('back')}>
            <Icon name={isAr ? 'arrowForward' : 'arrowBack'} size={22} />
          </button>
          <h1 className="text-lg font-extrabold text-title">{t('editAdTitle')}</h1>
        </div>
      ) : (
        <HeroBanner />
      )}

      <MediaSection media={media} error={errors.media} />

      <SectionCard className="space-y-4">
        <FormField id="name" label={t('productName')} required error={errors.name}>
          <TextInput id="name" value={form.name} maxLength={200} placeholder={t('examplePremiumIranianSaffron')} onChange={(e) => set({ name: e.target.value })} className={errors.name ? ERROR_BORDER : ''} />
        </FormField>

        <FormField id="type" label={t('selection')} required error={errors.type}>
          <Select
            id="type"
            value={type}
            disabled={typeOptions.length === 1 && type === typeOptions[0]}
            onChange={(e) => {
              setForm((current) => withType(current, e.target.value as AdType))
              setErrors({})
            }}
            className={errors.type ? ERROR_BORDER : ''}
          >
            <option value="" disabled>
              {t('selectAnOption')}
            </option>
            {typeOptions.map((option) => (
              <option key={option} value={option}>
                {t(AD_TYPE_LABEL[option])}
              </option>
            ))}
          </Select>
          {overseas && <p className="mt-1.5 text-[11px] font-semibold text-[#B45309]">{t('overseasBookingOnlyNote')}</p>}
        </FormField>

        {isCategories && (
          <FormField id="category" label={t('category')} required error={errors.category}>
            <Select
              id="category"
              value={form.categoryId ?? ''}
              onChange={(e) => set({ categoryId: Number(e.target.value) || null }, ['category'])}
              className={errors.category ? ERROR_BORDER : ''}
            >
              <option value="" disabled>
                {categories.isPending ? '…' : t('selectCategory')}
              </option>
              {(categories.data ?? []).map((c) => (
                <option key={c.categoryId} value={c.categoryId}>
                  {categoryName(c, isAr)}
                </option>
              ))}
            </Select>
          </FormField>
        )}
      </SectionCard>

      {type && (
        <SectionCard className="space-y-4">
          <SectionTitle icon="tag">{isCategories ? t('wholesaleDetails') : t(AD_TYPE_LABEL[type])}</SectionTitle>

          {isBooking && (
            <>
              <FormField id="bookingPriceType" label={t('bookingPriceTypeLabel')}>
                <Select
                  id="bookingPriceType"
                  value={form.bookingPriceType}
                  onChange={(e) => {
                    const value = e.target.value as BookingPriceType
                    set(value === 'FOB' ? { bookingPriceType: value, originPort: '', destinationCountry: '', destinationPort: '' } : { bookingPriceType: value })
                  }}
                >
                  <option value="">{t('selectPriceType')}</option>
                  {BOOKING_PRICE_TYPES.map((p) => (
                    <option key={p} value={p}>
                      {p}
                    </option>
                  ))}
                </Select>
              </FormField>
              <div className="grid gap-4 sm:grid-cols-2">
                <CountryField id="originCountry" label={t('countryOfOrigin')} required value={form.originCountry} error={errors.originCountry} onChange={(value) => set({ originCountry: value, originPort: '' }, ['originCountry'])} />
                {!fob && <PortField id="originPort" label={t('loadingPort')} country={form.originCountry} value={form.originPort} onChange={(value) => set({ originPort: value })} />}
              </div>
              {!fob && (
                <div className="grid gap-4 sm:grid-cols-2">
                  <CountryField id="destinationCountry" label={t('destinationCountry')} value={form.destinationCountry} onChange={(value) => set({ destinationCountry: value, destinationPort: '' })} />
                  <PortField id="destinationPort" label={t('destinationPort')} country={form.destinationCountry} value={form.destinationPort} onChange={(value) => set({ destinationPort: value })} />
                </div>
              )}
            </>
          )}

          {isOffers ? (
            <>
              <div className="grid grid-cols-2 gap-3">
                <FormField id="beforeDiscount" label={t('beforeDiscount')} error={errors.beforeDiscount}>
                  <TextInput id="beforeDiscount" inputMode="decimal" dir="ltr" value={form.beforeDiscount} placeholder={t('pricePerUnitShort', { unit: unitText })} onChange={(e) => set({ beforeDiscount: priceInput(e.target.value) }, ['beforeDiscount', 'afterDiscount'])} />
                </FormField>
                <FormField id="afterDiscount" label={t('offerPrice')} required error={errors.afterDiscount}>
                  <TextInput id="afterDiscount" inputMode="decimal" dir="ltr" value={form.afterDiscount} placeholder={t('pricePerUnitShort', { unit: unitText })} onChange={(e) => set({ afterDiscount: priceInput(e.target.value) }, ['beforeDiscount', 'afterDiscount'])} className={errors.afterDiscount ? ERROR_BORDER : ''} />
                </FormField>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <FormField id="currency" label={t('currency')}>
                  <CurrencySelect id="currency" value={form.currency} onChange={(value) => set({ currency: value })} />
                </FormField>
                <FormField id="unit" label={t('unitLabel')}>
                  <UnitSelect id="unit" value={form.unit} onChange={(value) => set({ unit: value })} />
                </FormField>
              </div>
            </>
          ) : (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-[1fr_130px_150px]">
              <FormField id="price" label={pricingLabel} required={!isRequest} error={errors.price} className="col-span-2 sm:col-span-1">
                <TextInput id="price" inputMode="decimal" dir="ltr" value={form.price} placeholder={priceHint} onChange={(e) => set({ price: priceInput(e.target.value) })} className={errors.price ? ERROR_BORDER : ''} />
              </FormField>
              <FormField id="currency" label={t('currency')}>
                <CurrencySelect id="currency" value={isBooking ? 'USD' : isRetail ? 'AED' : form.currency} locked={isBooking || isRetail} onChange={(value) => set({ currency: value })} />
              </FormField>
              <FormField id="unit" label={t('unitLabel')}>
                <UnitSelect id="unit" value={form.unit} onChange={(value) => set({ unit: value })} />
              </FormField>
            </div>
          )}

          <FormField id="quantity" label={quantityLabel} required={!isRequest} error={errors.quantity}>
            <TextInput id="quantity" inputMode="numeric" dir="ltr" value={form.quantity} placeholder={t('quantity')} onChange={(e) => set({ quantity: intInput(e.target.value) })} className={errors.quantity ? ERROR_BORDER : ''} />
          </FormField>

          {!alwaysShowsPrice(type) && <ShowPriceToggle value={form.showPrice} onChange={(value) => set({ showPrice: value })} />}
          {!isRetail && <NegotiationCards value={form.negotiable} onChange={(value) => set({ negotiable: value })} />}
          {supportsFulfillment(type) && <FulfillmentRadio value={form.fulfillment} error={errors.fulfillment} onChange={(value) => set({ fulfillment: value })} />}

          {(isOffers || isBooking || isRetail) && (
            <FormField id="days" label={t(isOffers ? 'offerDuration' : isBooking ? 'shippingDurationDays' : 'deliveryTimeDays')} required error={errors.days}>
              <TextInput
                id="days"
                inputMode="numeric"
                dir="ltr"
                value={form.days}
                placeholder={t(isOffers ? 'enterOfferDurationInDays' : isBooking ? 'enterShippingDurationInDays' : 'enterDeliveryTimeInDays')}
                onChange={(e) => set({ days: daysOnly(e.target.value) })}
                className={errors.days ? ERROR_BORDER : ''}
              />
            </FormField>
          )}
          {isRequest && (
            <FormField id="deliveryDate" label={t('requiredDeliveryDate')}>
              <TextInput id="deliveryDate" type="date" dir="ltr" min={new Date().toISOString().slice(0, 10)} max="2101-12-31" value={form.deliveryDate} placeholder={t('enterDate')} onChange={(e) => set({ deliveryDate: e.target.value })} />
            </FormField>
          )}

          <PackingSection
            id="packing"
            label={t(isCategories && form.retailEnabled ? 'wholesalePackingOptional' : 'packingOptional')}
            kg={form.packingKg}
            other={form.packingOther}
            isOther={form.otherPacking}
            error={errors.packing}
            onChange={(c) => set({ ...(c.kg !== undefined && { packingKg: c.kg }), ...(c.other !== undefined && { packingOther: c.other }), ...(c.isOther !== undefined && { otherPacking: c.isOther }) }, ['packing'])}
          />
          <SpecsField
            id="specs"
            label={t(isCategories && form.retailEnabled ? 'wholesaleSpecifications' : 'specifications')}
            hint={t('specifyRequiredSpecifications')}
            value={form.specs}
            onChange={(value) => set({ specs: value })}
          />
        </SectionCard>
      )}

      {isCategories && (
        <SectionCard className="space-y-4">
          <div className="flex items-center justify-between gap-3">
            <span className="flex min-w-0 flex-wrap items-center gap-1.5 text-[13px] font-bold text-title">
              {t('addRetailPriceQuestion')}
              <span className="rounded-full bg-[#DCFAE6] px-2 py-0.5 text-[10px] font-bold text-[#17B26A]">{t('recommendedBadge')}</span>
              <button type="button" onClick={() => setRetailInfo(true)} className="grid size-5 place-items-center rounded-full text-[#3A7DC5] hover:bg-[#EAF2FB]" aria-label={t('retailPricingInfoTitle')}>
                <Icon name="info" size={15} />
              </button>
            </span>
            <Switch
              checked={form.retailEnabled}
              label={t('addRetailPriceQuestion')}
              onChange={(value) => {
                if (isEdit && !value && listing?.hasRetailPricing) return
                set({ retailEnabled: value }, ['retailPrice', 'retailQuantity', 'retailSpecs', 'retailPacking'])
                if (value) setCopyAsk(true)
              }}
            />
          </div>

          {form.retailEnabled && (
            <>
              <SectionTitle
                icon="cart"
                action={
                  <button type="button" onClick={copyWholesale} className="flex items-center gap-1 rounded-full border border-[#3A7DC5]/40 px-3 py-1 text-[11px] font-bold text-[#3A7DC5] hover:bg-[#EAF2FB]">
                    <Icon name="copy" size={13} />
                    {t('copyWholesaleToRetailAction')}
                  </button>
                }
              >
                {t('retailDetails')}
              </SectionTitle>
              <div className="grid grid-cols-2 gap-3 sm:grid-cols-[1fr_130px_150px]">
                <FormField id="retailPrice" label={t('retailPriceLabel')} required error={errors.retailPrice} className="col-span-2 sm:col-span-1">
                  <TextInput id="retailPrice" inputMode="decimal" dir="ltr" value={form.retailPrice} placeholder={t('pricePerUnitShort', { unit: unitLabel(form.retailUnit, t) })} onChange={(e) => set({ retailPrice: priceInput(e.target.value) })} className={errors.retailPrice ? ERROR_BORDER : ''} />
                </FormField>
                <FormField id="retailCurrency" label={t('currency')}>
                  <CurrencySelect id="retailCurrency" value="AED" locked onChange={() => undefined} />
                </FormField>
                <FormField id="retailUnit" label={t('unitLabel')}>
                  <UnitSelect id="retailUnit" value={form.retailUnit} onChange={(value) => set({ retailUnit: value })} />
                </FormField>
              </div>
              <FormField id="retailQuantity" label={t('quantityPerUnit', { unit: unitLabel(form.retailUnit, t) })} required error={errors.retailQuantity}>
                <TextInput id="retailQuantity" inputMode="numeric" dir="ltr" value={form.retailQuantity} placeholder={t('quantity')} onChange={(e) => set({ retailQuantity: intInput(e.target.value) })} className={errors.retailQuantity ? ERROR_BORDER : ''} />
              </FormField>
              <PackingSection
                id="retailPacking"
                label={t('retailPackingOptional')}
                kg={form.retailPackingKg}
                other={form.retailPackingOther}
                isOther={form.retailOtherPacking}
                error={errors.retailPacking}
                onChange={(c) => set({ ...(c.kg !== undefined && { retailPackingKg: c.kg }), ...(c.other !== undefined && { retailPackingOther: c.other }), ...(c.isOther !== undefined && { retailOtherPacking: c.isOther }) }, ['retailPacking'])}
              />
              <SpecsField id="retailSpecs" label={t('retailSpecifications')} hint={t('retailSpecificationsHint')} required value={form.retailSpecs} error={errors.retailSpecs} onChange={(value) => set({ retailSpecs: value })} />
            </>
          )}
        </SectionCard>
      )}

      <div className="pt-2">
        <PublishButton
          busy={busy}
          label={isEdit ? t('saveChanges') : t('publish')}
          subtitle={isEdit ? undefined : t('publishSubtitle')}
          progress={busy ? progress || t('publishingEllipsis') : media.uploading ? t('preparingMedia') : ''}
          onClick={submit}
        />
      </div>

      <InfoDialog open={retailInfo} onClose={() => setRetailInfo(false)} title={t('retailPricingInfoTitle')} body={t('retailPricingInfoBody')} />
      <Modal open={copyAsk} onClose={() => setCopyAsk(false)} title={t('copyWholesaleToRetailTitle')}>
        <p className="text-sm leading-relaxed text-subtitle">{t('copyWholesaleToRetailBody')}</p>
        <div className="mt-5 flex flex-col gap-2">
          <button
            type="button"
            onClick={() => {
              copyWholesale()
              setCopyAsk(false)
            }}
            className="h-11 rounded-xl bg-brand text-sm font-bold text-white hover:brightness-110"
          >
            {t('copyWholesaleToRetailAccept')}
          </button>
          <button type="button" onClick={() => setCopyAsk(false)} className="h-11 rounded-xl border border-line text-sm font-bold text-title hover:bg-page">
            {t('copyWholesaleToRetailDecline')}
          </button>
        </div>
      </Modal>
    </div>
  )
}

/* ─────────── Create order (company customer request) ─────────── */

const ORDER_ERROR_ORDER = ['media', 'name', 'specs', 'quantity']

export function CreateOrderPage() {
  const { t } = useI18n()
  const { isAuthenticated, isCompanyCustomer, isSupplier } = useAuth()
  usePageTitle(t('createOrder'))
  if (!isAuthenticated) return <Navigate to="/login" replace />
  if (isSupplier) return <Navigate to="/create-ad" replace />
  if (!isCompanyCustomer) return <Notice text={t('onlySuppliersCreateAds')} />
  return <OrderRequestForm />
}

function OrderRequestForm() {
  const { t, lang } = useI18n()
  const toast = useToast()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const media = useAdMedia()
  const { form, set, errors, setErrors } = useFormState({ ...EMPTY_AD_FORM, type: 'Requests', fulfillment: 'Local' })
  const [notes, setNotes] = useState('')
  const [busy, setBusy] = useState(false)
  const [progress, setProgress] = useState('')
  const createdId = useRef('')
  const unitText = unitLabel(form.unit, t)

  const submit = async () => {
    if (busy) return
    const found: Errors = {}
    if (!media.items.length) found.media = t('productImagesRequired')
    if (!form.name.trim()) found.name = t('thisFieldIsRequired')
    if (!form.specs.trim()) found.specs = t('thisFieldIsRequired')
    if (form.quantity.trim() && num(form.quantity) <= 0) found.quantity = t('enterValidQuantity')
    setErrors(found)
    const firstKey = ORDER_ERROR_ORDER.find((k) => found[k])
    if (firstKey) {
      scrollToFirstError(found, ORDER_ERROR_ORDER)
      return toast.error(found[firstKey]!)
    }

    setBusy(true)
    try {
      setProgress(t('preparingMedia'))
      if (!(await media.settle())) {
        toast.error(t('mediaUploadFailed'))
        return
      }
      const payload = media.payload()
      if (!createdId.current) {
        setProgress(t('publishStepCreatingAd'))
        const specs = notes.trim() ? `${form.specs.trim()}\n\n${notes.trim()}` : form.specs.trim()
        const created = await createProduct(buildProductForm({ ...form, specs }, payload, { isEdit: false, lang }))
        if (!created.productId) throw new Error(created.message || t('somethingWentWrong'))
        createdId.current = created.productId
        media.markConfirmed()
      }
      for (const video of payload.draftVideos.slice(1)) {
        setProgress(t('publishStepUploadingVideo'))
        await confirmVideo(createdId.current, video)
      }
      setProgress(t('publishStepFinishing'))
      await submitForReview(createdId.current)
      void queryClient.invalidateQueries({ queryKey: [MY_LISTINGS_KEY] })
      playPublishSound()
      media.reset()
      navigate('/request-published', { replace: true, state: { productId: createdId.current } })
    } catch (error) {
      toast.error(errorMessage(error, t('somethingWentWrong')))
    } finally {
      setBusy(false)
      setProgress('')
    }
  }

  return (
    <div className="mx-auto w-full max-w-3xl space-y-3 px-3 pb-10 pt-3 sm:px-5 sm:pt-5">
      <h1 className="px-1 text-xl font-extrabold text-title">{t('createOrder')}</h1>

      <MediaSection media={media} error={errors.media} />

      <SectionCard className="space-y-4">
        <SectionTitle icon="box">{t('productInformation')}</SectionTitle>
        <FormField id="name" label={t('productName')} required error={errors.name}>
          <TextInput id="name" value={form.name} maxLength={200} placeholder={t('examplePremiumIranianSaffron')} onChange={(e) => set({ name: e.target.value })} className={errors.name ? ERROR_BORDER : ''} />
        </FormField>
        <FormField id="specs" label={t('requiredSpecifications')} required error={errors.specs}>
          <TextArea id="specs" rows={4} maxLength={500} value={form.specs} placeholder={t('enterTheRequiredSpecificationsInDetail')} onChange={(e) => set({ specs: e.target.value })} className={errors.specs ? ERROR_BORDER : ''} />
        </FormField>
      </SectionCard>

      <SectionCard className="space-y-4">
        <SectionTitle icon="tag">{t('requests')}</SectionTitle>
        <FormField id="quantity" label={t('requiredQuantity')} error={errors.quantity}>
          <TextInput id="quantity" inputMode="numeric" dir="ltr" value={form.quantity} placeholder={t('enterQuantity')} onChange={(e) => set({ quantity: intInput(e.target.value) })} className={errors.quantity ? ERROR_BORDER : ''} />
        </FormField>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-[1fr_130px_150px]">
          <FormField id="price" label={t('targetPrice')} className="col-span-2 sm:col-span-1">
            <TextInput id="price" inputMode="decimal" dir="ltr" value={form.price} placeholder={t('enterYourTargetPrice')} onChange={(e) => set({ price: priceInput(e.target.value) })} />
          </FormField>
          <FormField id="currency" label={t('currency')}>
            <CurrencySelect id="currency" value={form.currency} onChange={(value) => set({ currency: value })} />
          </FormField>
          <FormField id="unit" label={t('unitLabel')}>
            <UnitSelect id="unit" value={form.unit} onChange={(value) => set({ unit: value })} />
          </FormField>
        </div>
        <p className="-mt-2 text-[11px] text-subtitle">{t('requiredQuantityPerUnit', { unit: unitText })}</p>
        <NegotiationCards simple value={form.negotiable} onChange={(value) => set({ negotiable: value })} />
        <ShowPriceToggle value={form.showPrice} onChange={(value) => set({ showPrice: value })} />
        <FulfillmentRadio value={form.fulfillment} onChange={(value) => set({ fulfillment: value })} />
      </SectionCard>

      <SectionCard className="space-y-4">
        <SectionTitle icon="truck">{t('delivery')}</SectionTitle>
        <FormField id="deliveryDate" label={t('pickupDateOptional')}>
          <TextInput id="deliveryDate" type="date" dir="ltr" min={new Date().toISOString().slice(0, 10)} max={`${new Date().getFullYear() + 2}-12-31`} value={form.deliveryDate} onChange={(e) => set({ deliveryDate: e.target.value })} />
        </FormField>
        <FormField id="notes" label={t('additionalNotes')}>
          <TextArea id="notes" rows={3} value={notes} placeholder={t('addAnyNotesOrSpecialRequirementsOptional')} onChange={(e) => setNotes(e.target.value)} />
        </FormField>
      </SectionCard>

      <div className="flex gap-2.5 rounded-[14px] border border-[#BFD3EA] bg-[#EEF5FD] p-3.5 text-[12px] font-medium leading-relaxed text-[#2F5B8F]">
        <Icon name="info" size={18} className="mt-0.5 shrink-0" />
        {t('yourRequestWillBePublishedAndApprovedSuppliersCanSubmitTheirOffersYouWillReceiveANotificationWhenOffersArrive')}
      </div>

      <PublishButton busy={busy} label={t('publishRequest')} progress={busy ? progress || t('publishingEllipsis') : media.uploading ? t('preparingMedia') : ''} onClick={submit} />
    </div>
  )
}

/* ─────────── Request published ─────────── */

export function RequestPublishedPage() {
  const { t } = useI18n()
  const location = useLocation()
  const productId = (location.state as { productId?: string } | null)?.productId ?? ''
  usePageTitle(t('requestPublishedSuccessfully'))
  return (
    <div className="grid min-h-dvh place-items-center bg-page px-5">
      <div className="w-full max-w-md rounded-3xl border border-line bg-white p-8 text-center shadow-[0_18px_40px_rgba(15,23,42,0.08)]">
        <span className="mx-auto mb-5 grid size-24 place-items-center rounded-full bg-[#E8F5EC] text-[#1f8f4e]">
          <Icon name="check" size={48} strokeWidth={2.4} />
        </span>
        <h1 className="text-xl font-extrabold text-title">{t('requestPublishedSuccessfully')}</h1>
        <p className="mt-2 text-sm leading-relaxed text-subtitle">{t('yourRequestWillBePublishedAndApprovedSuppliersCanSubmitTheirOffersYouWillReceiveANotificationWhenOffersArrive')}</p>
        <div className="mt-6 flex flex-col gap-2.5">
          <Link to={productId ? `/my-ads?highlight=${encodeURIComponent(productId)}` : '/my-ads'} replace className="rounded-xl bg-gradient-to-r from-brand-dark to-brand-light py-3 text-sm font-bold text-white">
            {t('showAllRequests')}
          </Link>
          <Link to="/" replace className="rounded-xl border border-line py-3 text-sm font-bold text-title">
            {t('backToHome')}
          </Link>
        </div>
      </div>
    </div>
  )
}
