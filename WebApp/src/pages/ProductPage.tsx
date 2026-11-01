import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { Link, useLocation, useNavigate, useParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { addCartItem, fetchCart } from '../cart/cartApi'
import { useI18n } from '../i18n/I18nProvider'
import { IconAction, OutlineButton, PrimaryButton, Screen } from '../layout/ScreenLayout'
import { ApiError } from '../lib/api'
import { useHead } from '../lib/seo'
import { usePageTitle } from '../lib/usePageTitle'
import { createOrder } from '../orders/ordersApi'
import { CatalogBody, OfferBody, QuantityAndTotal, RequestBody, RetailBody, type DetailsCtx } from '../products/details/DetailBodies'
import { MediaPreview } from '../products/details/MediaViewer'
import { trackProductShare, trackProductView, useSavedAds } from '../products/engagement'
import { askForPriceMessage, productPath, productUrl } from '../products/productLinks'
import { useViewer } from '../products/ProductGrid'
import {
  amountValue,
  apiUnitName,
  availableQuantity,
  canShowProductPrice,
  categoryLabel,
  currencyCode,
  detailsLayout,
  formatAmount,
  isBookingProduct,
  isProductOwner,
  isSoldOut,
  parseNumber,
  productDescription,
  productImages,
  productMedia,
  productTitle,
  shouldShowAskForPrice,
} from '../products/productRules'
import { fetchProduct } from '../products/productsApi'
import type { ApiProduct } from '../products/types'
import { useGate } from '../ui/GateProvider'
import { Icon } from '../ui/Icon'
import { useToast } from '../ui/Toast'

function productJsonLd(p: ApiProduct, url: string, price: number, currency: string, soldOut: boolean) {
  const images = productImages(p)
  return {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: p.nameEn || p.productName || p.nameAr,
    description: (p.descriptionEn || p.description || p.descriptionAr || '').slice(0, 5000) || undefined,
    image: images.length ? images : undefined,
    sku: p.productCode || p.productId,
    category: p.categoryNameEn || p.categoryName || undefined,
    url,
    offers:
      price > 0
        ? {
            '@type': 'Offer',
            url,
            price: price.toFixed(2),
            priceCurrency: currency,
            availability: soldOut ? 'https://schema.org/OutOfStock' : 'https://schema.org/InStock',
          }
        : undefined,
  }
}

function DetailsSkeleton() {
  return (
    <div className="space-y-3.5">
      <div className="flex gap-3">
        <div className="shimmer h-[140px] w-[120px] rounded-[14px] sm:h-[220px] sm:w-[200px]" />
        <div className="flex-1 space-y-2 pt-1">
          <div className="shimmer h-4 w-24 rounded-full" />
          <div className="shimmer h-6 w-3/4 rounded" />
          <div className="shimmer h-4 w-full rounded" />
          <div className="shimmer h-4 w-2/3 rounded" />
        </div>
      </div>
      <div className="shimmer h-44 rounded-[14px]" />
      <div className="shimmer h-28 rounded-[14px]" />
    </div>
  )
}

export default function ProductPage() {
  const { t, isAr } = useI18n()
  const { id = '', slug } = useParams()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const viewer = useViewer()
  const { session } = useAuth()
  const { ensureLoggedIn } = useGate()
  const toast = useToast()
  const saved = useSavedAds()
  const [previewIndex, setPreviewIndex] = useState<number | null>(null)
  const [qty, setQty] = useState('')
  const [busy, setBusy] = useState(false)

  const location = useLocation()
  const navState = location.state as { seed?: ApiProduct; retail?: boolean } | null
  const seed = navState?.seed
  const preferRetail = navState?.retail === true || new URLSearchParams(location.search).get('channel') === 'retail'
  const base = useQuery({
    queryKey: ['product', id, session?.id ?? 'guest'],
    queryFn: () => fetchProduct(id),
    enabled: !!id,
    placeholderData: seed && seed.productId === id ? seed : undefined,
  })
  const wantsRetail = !!base.data && detailsLayout(base.data, viewer, preferRetail) === 'retail' && (preferRetail || viewer.isPersonalCustomer)
  const retailQuery = useQuery({
    queryKey: ['product', id, session?.id ?? 'guest', 'retail'],
    queryFn: () => fetchProduct(id, true),
    enabled: wantsRetail,
  })
  const product = (wantsRetail && retailQuery.data) || base.data

  const layout = product ? detailsLayout(product, viewer, preferRetail) : null
  const retail = layout === 'retail'
  const owner = product ? isProductOwner(product, viewer) : false
  const soldOut = product ? isSoldOut(product, retail) : false
  const amount = product ? amountValue(product, viewer, retail) : 0
  const currency = product ? (retail && product.hasRetailPricing ? 'AED' : currencyCode(product, viewer)) : 'USD'
  const canPrice = product ? canShowProductPrice(product, viewer, retail) : false
  const showAsk = product ? shouldShowAskForPrice(product, viewer, retail) : false
  const media = useMemo(() => (product ? productMedia(product) : []), [product])
  const title = product ? productTitle(product, isAr) : ''
  const canonical = product ? productUrl(product) : ''
  const shareUrl = product ? productUrl(product, retail) : ''

  usePageTitle(title || t('productDetails'))
  const jsonLd = useMemo(
    () => (product ? productJsonLd(product, canonical, canPrice ? amount : 0, currency, soldOut) : null),
    [product, canonical, canPrice, amount, currency, soldOut],
  )
  useHead({
    title,
    description: product ? productDescription(product, isAr, retail).replace(/\s+/g, ' ').slice(0, 160) || categoryLabel(product, isAr) : '',
    canonical,
    image: media.find((m) => m.kind === 'image')?.url,
    type: 'product',
    jsonLd,
  })

  useEffect(() => {
    if (!product) return
    const path = productPath(product, preferRetail)
    const current = `/product/${encodeURIComponent(id)}${slug ? `/${slug}` : ''}${location.search}`
    if (decodeURIComponent(path) !== decodeURIComponent(current)) navigate(path, { replace: true, state: location.state })
  }, [product, id, slug, navigate, preferRetail, location.search, location.state])

  useEffect(() => {
    if (product && !owner) trackProductView(product.productId)
  }, [product, owner])

  if (base.isPending) {
    return (
      <Screen title={t('productDetails')}>
        <DetailsSkeleton />
      </Screen>
    )
  }

  if (base.isError || !product || !layout) {
    return (
      <Screen title={t('productDetails')}>
        <div className="flex flex-col items-center gap-4 py-20 text-center">
          <Icon name="box" size={42} className="text-subtitle" />
          <p className="text-auth-body">{t('productUnavailable')}</p>
          <Link to="/" className="rounded-xl bg-brand px-5 py-2.5 text-sm font-bold text-white">
            {t('goHome')}
          </Link>
        </div>
      </Screen>
    )
  }

  const ctx: DetailsCtx = { p: product, retail, isAr, t, viewer, amount, currency, canPrice, showAsk, soldOut, media, openMedia: setPreviewIndex }
  const isSaved = saved.ids.includes(product.productId)

  const share = async () => {
    const code = product.productCode?.trim()
    const name = title ? title.charAt(0).toUpperCase() + title.slice(1) : 'Product'
    const text = [name, code ? `${t('productCode')}: ${code}` : t('shareProductHint')].join('\n')
    try {
      if (navigator.share) {
        await navigator.share({ title: name, text, url: shareUrl })
      } else {
        await navigator.clipboard.writeText(`${text}\n${shareUrl}`)
        toast.success(t('linkCopied'))
      }
      trackProductShare(product.productId)
    } catch {
      /* share sheet dismissed */
    }
  }

  const toggleSave = () => {
    const nowSaved = saved.toggle(product.productId)
    toast.info(t(nowSaved ? 'saved' : 'removedFromSaved'))
  }

  const askForPrice = () => {
    if (!ensureLoggedIn()) return
    navigate('/chat/support', { state: { initialMessage: askForPriceMessage(product) } })
  }

  const quantityError = (q: number): string => {
    if (!qty.trim()) return t('enterQuantity')
    if (q <= 0) return t('enterValidQuantity')
    const available = availableQuantity(product, retail)
    if (available !== null && available > 0 && q > available)
      return t('requestedQuantityExceedsAvailable', { requested: formatAmount(q), available: formatAmount(available) })
    const max = parseNumber(product.maximumOrderQuantity)
    if (max && q > max) return t('maximumOrderQuantityIs', { quantity: formatAmount(max) })
    const min = parseNumber(product.minimumOrderQuantity)
    if (min && q < min) return t('minimumOrderQuantityIs', { quantity: formatAmount(min) })
    return ''
  }

  const validateQuantity = (): number | null => {
    const q = parseNumber(qty) ?? 0
    const error = quantityError(q)
    if (!error) return q
    toast.error(error)
    return null
  }

  const errorText = (error: unknown) => (error instanceof ApiError || error instanceof Error ? error.message : t('somethingWentWrong'))

  const addToCart = async () => {
    if (!ensureLoggedIn()) return
    const q = validateQuantity()
    if (q === null) return
    setBusy(true)
    try {
      const cart = await fetchCart()
      const inCart = cart.items.filter((i) => i.productId.toLowerCase() === product.productId.toLowerCase()).reduce((s, i) => s + i.quantity, 0)
      const available = availableQuantity(product, true)
      if (available !== null && available > 0 && inCart + q > available) {
        toast.error(t('cartMaxAvailableInStock', { quantity: formatAmount(available) }))
        navigate('/cart')
        return
      }
      const updated = await addCartItem(product.productId, q, apiUnitName(product, true))
      queryClient.setQueryData(['cart', session?.id], updated)
      navigate('/cart')
    } catch (error) {
      toast.error(errorText(error))
    } finally {
      setBusy(false)
    }
  }

  const orderOffer = async () => {
    if (!ensureLoggedIn()) return
    const q = validateQuantity()
    if (q === null) return
    if (amount <= 0) return toast.error(t('enterValidQuantityAndPrice'))
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
      })
      queryClient.invalidateQueries({ queryKey: ['orders'] })
      navigate('/order-success', { replace: true, state: { kind: 'order', orderNumber } })
    } catch (error) {
      toast.error(errorText(error))
    } finally {
      setBusy(false)
    }
  }

  const openPurchaseOrder = () => navigate(`/product/${encodeURIComponent(product.productId)}/order`, { state: { product } })
  const openSubmitOffer = () => ensureLoggedIn() && navigate(`/product/${encodeURIComponent(product.productId)}/offer`, { state: { product } })

  let footer: ReactNode = null
  if (owner) {
    footer = soldOut ? null : (
      <div className="flex items-center gap-2 rounded-xl bg-[#FFF4E5] px-4 py-3 text-sm font-bold text-[#B45309]">
        <Icon name="info" size={18} />
        {t('cannotOrderOwnProduct')}
      </div>
    )
  } else if (layout === 'request') {
    footer = viewer.isCompanyCustomer ? null : <PrimaryButton onClick={openSubmitOffer}>{t('submitOffer')}</PrimaryButton>
  } else if (!soldOut) {
    const priceVisible = canPrice && amount > 0
    if (layout === 'retail') {
      footer = (
        <div className="flex gap-3">
          {!priceVisible && <OutlineButton onClick={askForPrice}>{t('askForPrice')}</OutlineButton>}
          <PrimaryButton onClick={addToCart} busy={busy}>
            <Icon name="cart" size={18} />
            {t('addToCart')}
          </PrimaryButton>
        </div>
      )
    } else if (layout === 'offer') {
      footer = (
        <div className="flex gap-3">
          {!viewer.isAuthenticated && <OutlineButton onClick={askForPrice}>{t('askForPrice')}</OutlineButton>}
          <PrimaryButton onClick={orderOffer} busy={busy}>
            {t('purchaseOrder')}
          </PrimaryButton>
        </div>
      )
    } else {
      footer = (
        <div className="flex gap-3">
          {showAsk && <OutlineButton onClick={askForPrice}>{t('askForPrice')}</OutlineButton>}
          <PrimaryButton onClick={openPurchaseOrder}>{t('purchaseOrder')}</PrimaryButton>
        </div>
      )
    }
  }

  const showQuantity = !owner && !soldOut && (layout === 'retail' || layout === 'offer')

  return (
    <Screen
      title={t('productDetails')}
      actions={
        <>
          <IconAction icon="share" label={t('shareProduct')} onClick={share} />
          <IconAction icon="bookmark" label={t('save')} onClick={toggleSave} active={isSaved} />
        </>
      }
      footer={footer}
    >
      {layout === 'retail' && (
        <RetailBody ctx={ctx}>{showQuantity && <QuantityAndTotal ctx={ctx} qty={qty} onQty={setQty} showTotal={canPrice && amount > 0} />}</RetailBody>
      )}
      {layout === 'offer' && (
        <OfferBody ctx={ctx}>{showQuantity && <QuantityAndTotal ctx={ctx} qty={qty} onQty={setQty} showTotal={canPrice && amount > 0} />}</OfferBody>
      )}
      {(layout === 'category' || layout === 'booking') && <CatalogBody ctx={ctx} booking={layout === 'booking' || isBookingProduct(product)} />}
      {layout === 'request' && <RequestBody ctx={ctx} />}
      {previewIndex !== null && <MediaPreview media={media} index={previewIndex} onClose={() => setPreviewIndex(null)} />}
    </Screen>
  )
}
