import { useEffect, useMemo, useState, type FormEvent } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { apiUrl } from '../config/api.js'
import { getAuthToken } from '../lib/authStorage'
import {
  useGetAdminUserDetailQuery,
  useGetAdminProductLookupsQuery,
  useGetCategoriesQuery,
  useUploadAdminProductImageMutation,
} from '../store'
import { getRtkErrorMessage } from '../utils/rtkError'

type AdTypeOption = 'Booking' | 'Inquiry' | 'Retail' | 'Offers' | 'Categories'

const UNITS = ['Ton', 'Kilogram', 'Carton', 'Bag', 'Box', 'Piece', 'Dozen'] as const

export default function CreateCompanyAdPage() {
  const { userId = '' } = useParams()
  const navigate = useNavigate()
  const { t, locale } = useAppPreferences()
  const { data: user, isLoading: userLoading, error: userError } =
    useGetAdminUserDetailQuery(userId, { skip: !userId })
  const { data: lookups } = useGetAdminProductLookupsQuery()
  const { data: categoriesData } = useGetCategoriesQuery()
  const [uploadImage] = useUploadAdminProductImageMutation()

  const isCompanyCustomer = user?.roleId === 2 && user?.isCustomer === true
  const isSupplier = user?.roleId === 2 && user?.isCustomer !== true
  const companyTitle =
    user?.companyName?.trim() ||
    user?.fullName?.trim() ||
    userId

  const allowedTypes = useMemo((): AdTypeOption[] => {
    if (isCompanyCustomer) return ['Inquiry']
    if (isSupplier) return ['Booking', 'Inquiry', 'Retail', 'Offers', 'Categories']
    return []
  }, [isCompanyCustomer, isSupplier])

  const [productType, setProductType] = useState<AdTypeOption>('Booking')
  const [nameEn, setNameEn] = useState('')
  const [descriptionEn, setDescriptionEn] = useState('')
  const [usdPrice, setUsdPrice] = useState('')
  const [quantity, setQuantity] = useState('1')
  const [unitName, setUnitName] = useState('Ton')
  const [currency, setCurrency] = useState('USD')
  const [negotiable, setNegotiable] = useState(false)
  const [requestTypeName, setRequestTypeName] = useState('Local')
  const [bookingPriceTypeName, setBookingPriceTypeName] = useState('FOB')
  const [originCountryName, setOriginCountryName] = useState('')
  const [shippingDuration, setShippingDuration] = useState('')
  const [categoryId, setCategoryId] = useState('')
  const [discountPercentage, setDiscountPercentage] = useState('10')
  const [discountDays, setDiscountDays] = useState('7')
  const [priceBefore, setPriceBefore] = useState('')
  const [images, setImages] = useState<File[]>([])
  const [video, setVideo] = useState<File | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (allowedTypes.length > 0 && !allowedTypes.includes(productType)) {
      setProductType(allowedTypes[0]!)
    }
  }, [allowedTypes, productType])

  const categories = categoriesData?.items ?? []
  const unitOptions =
    lookups?.units?.map((u) => u.name).filter(Boolean) ?? [...UNITS]

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    if (!userId || busy) return
    setError(null)
    setBusy(true)

    try {
      const form = new FormData()
      form.append('OwnerId', userId)
      form.append('NameEn', nameEn.trim())
      form.append('ProductTypeName', productType)
      form.append('DescriptionEn', descriptionEn.trim())
      form.append('Quantity', String(Number(quantity) || 1))
      form.append('UnitName', unitName)
      form.append('Negotiable', String(negotiable))
      form.append('CreatedLanguage', locale === 'ar' ? 'ar' : 'en')
      form.append('ShowPrice', 'false')

      if (productType === 'Booking') {
        form.append('Currency', 'USD')
        form.append('USDPrice', String(Number(usdPrice) || 0))
        form.append('BookingPriceTypeName', bookingPriceTypeName)
        form.append('OriginCountryName', originCountryName.trim())
        if (shippingDuration.trim()) {
          form.append('ShippingDuration', shippingDuration.trim())
        }
      } else if (productType === 'Retail') {
        form.append('Currency', 'AED')
        form.append('USDPrice', String(Number(usdPrice) || 0))
      } else if (productType === 'Offers') {
        form.append('Currency', currency)
        const after = Number(usdPrice) || 0
        const before = Number(priceBefore) || after
        form.append('USDPrice', String(after))
        form.append('DiscountPercentage', String(Number(discountPercentage) || 10))
        form.append('DiscountDays', String(Number(discountDays) || 7))
        form.append('OfferDuration', String(Number(discountDays) || 7))
        form.append('RequestTypeName', requestTypeName)
        // Backend derives discount from before/after via MCP; for form API use discount %
        void before
      } else if (productType === 'Inquiry') {
        form.append('Currency', currency)
        if (usdPrice.trim()) form.append('USDPrice', String(Number(usdPrice) || 0))
        else form.append('USDPrice', '0')
        form.append('RequestTypeName', requestTypeName)
      } else if (productType === 'Categories') {
        form.append('Currency', currency)
        form.append('USDPrice', String(Number(usdPrice) || 0))
        form.append('RequestTypeName', requestTypeName)
        if (categoryId) form.append('CategoryId', categoryId)
      }

      if (video) {
        form.append('ProductVideoFile', video)
      }

      const token = getAuthToken()
      const createRes = await fetch(apiUrl('/api/Products'), {
        method: 'POST',
        headers: token ? { Authorization: `Bearer ${token}` } : {},
        body: form,
      })
      const createData = (await createRes.json().catch(() => ({}))) as {
        message?: string
        productId?: string
        ProductId?: string
        id?: string
        Id?: string
      }
      if (!createRes.ok) {
        throw new Error(createData.message || t('users.createAdFailed'))
      }

      const productId =
        createData.productId ||
        createData.ProductId ||
        createData.id ||
        createData.Id
      if (!productId) {
        throw new Error(t('users.createAdFailed'))
      }

      for (const file of images) {
        await uploadImage({ productId, file }).unwrap()
      }

      await fetch(
        apiUrl(`/api/Products/${productId}/submit-for-review?ownerId=${encodeURIComponent(userId)}`),
        {
          method: 'POST',
          headers: token ? { Authorization: `Bearer ${token}` } : {},
        },
      )

      navigate(`/ads/${productId}`, { replace: true })
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : getRtkErrorMessage(err as never, t('users.createAdFailed')),
      )
    } finally {
      setBusy(false)
    }
  }

  if (!userId) {
    navigate('/users', { replace: true })
    return null
  }

  if (userLoading) {
    return (
      <div className="flex justify-center py-24">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
      </div>
    )
  }

  if (userError || !user || allowedTypes.length === 0) {
    return (
      <div className="admin-alert-error">
        {t('users.createAdNotAllowed')}
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <p className="admin-text-muted text-sm">
            <Link to={`/users/${userId}/ads`} className="hover:text-[#2563eb]">
              {companyTitle}
            </Link>
            <span className="mx-1.5 opacity-50">›</span>
            <span>{t('users.createAdManual')}</span>
          </p>
          <h1 className="admin-text mt-1 text-2xl font-extrabold">
            {t('users.createAdTitle', { name: companyTitle })}
          </h1>
        </div>
        <Link to={`/users/${userId}/ads`} className="admin-btn-ghost text-sm font-semibold">
          {t('users.backToList')}
        </Link>
      </div>

      <form onSubmit={onSubmit} className="admin-card space-y-4 rounded-2xl p-5 shadow-sm sm:p-6">
        {error ? <div className="admin-alert-error">{error}</div> : null}

        <label className="block">
          <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.adType')}</span>
          <select
            className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
            value={productType}
            onChange={(e) => setProductType(e.target.value as AdTypeOption)}
          >
            {allowedTypes.map((type) => (
              <option key={type} value={type}>
                {type}
              </option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.adName')}</span>
          <input
            required
            className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
            value={nameEn}
            onChange={(e) => setNameEn(e.target.value)}
          />
        </label>

        <label className="block">
          <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.adSpecs')}</span>
          <textarea
            required
            rows={3}
            className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
            value={descriptionEn}
            onChange={(e) => setDescriptionEn(e.target.value)}
          />
        </label>

        <div className="grid gap-3 sm:grid-cols-3">
          <label className="block sm:col-span-1">
            <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.adPrice')}</span>
            <input
              type="number"
              min={0}
              step="0.01"
              className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
              value={usdPrice}
              onChange={(e) => setUsdPrice(e.target.value)}
              required={productType !== 'Inquiry'}
            />
          </label>
          <label className="block">
            <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.adQty')}</span>
            <input
              type="number"
              min={1}
              required={productType !== 'Inquiry'}
              className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
              value={quantity}
              onChange={(e) => setQuantity(e.target.value)}
            />
          </label>
          <label className="block">
            <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.adUnit')}</span>
            <select
              className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
              value={unitName}
              onChange={(e) => setUnitName(e.target.value)}
            >
              {unitOptions.map((u) => (
                <option key={u} value={u}>
                  {u}
                </option>
              ))}
            </select>
          </label>
        </div>

        {productType === 'Booking' ? (
          <div className="grid gap-3 sm:grid-cols-2">
            <label className="block">
              <span className="admin-text-subtle text-xs font-bold uppercase">Incoterm</span>
              <select
                className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
                value={bookingPriceTypeName}
                onChange={(e) => setBookingPriceTypeName(e.target.value)}
              >
                {['FOB', 'CNF', 'CIF'].map((x) => (
                  <option key={x} value={x}>
                    {x}
                  </option>
                ))}
              </select>
            </label>
            <label className="block">
              <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.originCountry')}</span>
              <input
                required
                className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
                value={originCountryName}
                onChange={(e) => setOriginCountryName(e.target.value)}
              />
            </label>
            <label className="block sm:col-span-2">
              <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.shippingDays')}</span>
              <input
                className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
                value={shippingDuration}
                onChange={(e) => setShippingDuration(e.target.value)}
                placeholder="7"
              />
            </label>
          </div>
        ) : null}

        {productType === 'Offers' ? (
          <div className="grid gap-3 sm:grid-cols-3">
            <label className="block">
              <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.priceBefore')}</span>
              <input
                type="number"
                className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
                value={priceBefore}
                onChange={(e) => setPriceBefore(e.target.value)}
              />
            </label>
            <label className="block">
              <span className="admin-text-subtle text-xs font-bold uppercase">%</span>
              <input
                type="number"
                className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
                value={discountPercentage}
                onChange={(e) => setDiscountPercentage(e.target.value)}
              />
            </label>
            <label className="block">
              <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.offerDays')}</span>
              <input
                type="number"
                className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
                value={discountDays}
                onChange={(e) => setDiscountDays(e.target.value)}
              />
            </label>
          </div>
        ) : null}

        {(productType === 'Inquiry' ||
          productType === 'Offers' ||
          productType === 'Categories') && (
          <div className="grid gap-3 sm:grid-cols-2">
            <label className="block">
              <span className="admin-text-subtle text-xs font-bold uppercase">Local / Reexport</span>
              <select
                className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
                value={requestTypeName}
                onChange={(e) => setRequestTypeName(e.target.value)}
              >
                <option value="Local">Local</option>
                <option value="Reexport">Reexport</option>
              </select>
            </label>
            {productType !== 'Inquiry' ? (
              <label className="block">
                <span className="admin-text-subtle text-xs font-bold uppercase">Currency</span>
                <select
                  className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
                  value={currency}
                  onChange={(e) => setCurrency(e.target.value)}
                >
                  <option value="USD">USD</option>
                  <option value="AED">AED</option>
                </select>
              </label>
            ) : null}
          </div>
        )}

        {productType === 'Categories' ? (
          <label className="block">
            <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.category')}</span>
            <select
              required
              className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm font-semibold"
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
            >
              <option value="">—</option>
              {categories.map((c) => (
                <option key={c.categoryId} value={String(c.categoryId)}>
                  {c.nameEn || c.nameAr || c.categoryId}
                </option>
              ))}
            </select>
          </label>
        ) : null}

        <label className="inline-flex items-center gap-2 text-sm font-semibold">
          <input
            type="checkbox"
            checked={negotiable}
            onChange={(e) => setNegotiable(e.target.checked)}
          />
          {t('users.negotiable')}
        </label>

        {productType !== 'Offers' && productType !== 'Retail' ? (
          <p className="rounded-lg bg-amber-50 px-3 py-2 text-xs font-medium text-amber-800 dark:bg-amber-950/40 dark:text-amber-200">
            {locale === 'ar'
              ? 'ملاحظة: الأسعار لن تظهر للمشترين إلا عند الطلب.'
              : 'Note: Prices will only appear to buyers upon request.'}
          </p>
        ) : null}

        <label className="block">
          <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.adImages')}</span>
          <input
            type="file"
            accept="image/*"
            multiple
            className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm"
            onChange={(e) => setImages(Array.from(e.target.files ?? []))}
          />
        </label>

        <label className="block">
          <span className="admin-text-subtle text-xs font-bold uppercase">{t('users.adVideo')}</span>
          <input
            type="file"
            accept="video/*"
            className="admin-input mt-1 w-full rounded-lg px-3 py-2 text-sm"
            onChange={(e) => setVideo(e.target.files?.[0] ?? null)}
          />
        </label>

        <button
          type="submit"
          disabled={busy}
          className="keep-white inline-flex items-center justify-center rounded-xl bg-[#3B7FC7] px-5 py-2.5 text-sm font-bold text-white disabled:opacity-60"
        >
          {busy ? t('saving') : t('users.publishAd')}
        </button>
      </form>
    </div>
  )
}
