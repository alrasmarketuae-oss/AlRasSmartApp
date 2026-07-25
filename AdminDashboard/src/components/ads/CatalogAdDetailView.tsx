import { useEffect, useMemo, useRef, useState, type ChangeEvent, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { resolveAssetUrl } from '../../lib/assets'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { AdminProductDetail, AdminProductLookups } from '../../types/adminProduct'
import PendingProductEditPanel from './PendingProductEditPanel'
import ProductVideosPanel from './ProductVideosPanel'
import type { Category } from '../../types/category'
import ProductShippingPanel from '../shared/ProductShippingPanel'
import CountryFlag from '../shared/CountryFlag'
import AdminImageBlurModal from '../shared/AdminImageBlurModal'
import ImageGallery from '../ui/ImageGallery'
import { downloadAsset, filenameFromAssetPath } from '../../utils/downloadAsset'
import {
  IconInfoField,
  IconInfoSectionTitle,
  InfoFieldIcons,
} from '../shared/IconInfoField'
import {
  displayAdProductTypeName,
  formatAdAmount,
  formatAdPriceTypeLabel,
  formatPackagingLabel,
  isBookingAd,
  productTypeBadgeClassForProduct,
} from '../../utils/adsDisplay'
import { categoryDisplayName } from '../../utils/categoryDisplay'
import { localizeProductStatusLabel } from '../../utils/localizedLabels'
import { formatOrderQuantityWithUnit } from '../../utils/ordersDisplay'
import { shippingFromProduct } from '../../utils/productShipping'
import {
  hasDomesticShipping,
  hasInternationalShipping,
} from '../../types/productShipping'

function countProductGalleryImages(product: AdminProductDetail): number {
  if (product.images.length > 0) return product.images.length
  if (product.imagePaths?.length) return product.imagePaths.length
  if (product.primaryImagePath?.trim()) return 1
  return 0
}

/** When the ad has only a video (no images), show and play it in the main gallery. */
function shouldAutoShowProductVideo(product: AdminProductDetail): boolean {
  const videos =
    product.videoPaths?.filter((p) => p?.trim()) ??
    (product.videoPath?.trim() ? [product.videoPath] : [])
  return videos.length > 0 && countProductGalleryImages(product) === 0
}

function resolveProductVideoPaths(product: AdminProductDetail): string[] {
  const fromList = (product.videoPaths ?? [])
    .map((p) => p?.trim())
    .filter((p): p is string => Boolean(p))
  if (fromList.length > 0) return fromList
  const primary = product.videoPath?.trim()
  return primary ? [primary] : []
}

export type CatalogAdDetailViewProps = {
  product: AdminProductDetail
  lookups: AdminProductLookups
  categories: Category[]
  backToListPath: string
  isSaving: boolean
  isApproving: boolean
  isRejecting: boolean
  isUploading: boolean
  isReplacingImage?: boolean
  isDeleting?: boolean
  deletingImageId: number | null
  deletingVideoPath?: string | null
  onSave: (payload: {
    nameEn: string
    usdPrice: number
    currency: string
    quantity: number
    descriptionEn: string
    categoryId: number | null
    productTypeName: string
    unitName: string
    supplierNotesEn: string
    isVideoMuted: boolean
  }) => void
  onApprove: (supplierNotesEn: string) => void
  onReject: (payload: { supplierNotesEn: string; supplierNotesAr: string }) => void
  onDelete?: () => void
  onUploadImage: (file: File) => void
  onDeleteImage: (imageId: number) => void
  onDeleteVideo?: (path: string) => void
  onReplaceImage?: (imageId: number, file: File) => Promise<void>
}

function formatPostedAt(value: string, locale: 'ar' | 'en') {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function SidebarCard({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="admin-card overflow-hidden rounded-lg shadow-sm">
      <div className="admin-border border-b px-2.5 py-1.5">
        <h2 className="admin-text text-start text-[11px] font-bold">{title}</h2>
      </div>
      <div className="px-2.5 py-2">{children}</div>
    </section>
  )
}

function StatChip({
  label,
  value,
}: {
  label: string
  value: ReactNode
}) {
  return (
    <div className="flex min-w-[4.5rem] flex-1 flex-col items-center gap-0.5 px-1 py-1 text-center">
      <p className="admin-text-subtle text-[8px] font-semibold uppercase leading-tight">{label}</p>
      <p className="admin-text text-[10px] font-bold leading-tight">{value}</p>
    </div>
  )
}

const denseField = true
const inputDense = 'admin-input mt-0.5 w-full px-2 py-1 text-[11px] font-semibold'
const btnDense =
  'inline-flex h-7 items-center gap-1 rounded-lg px-2.5 text-[10px] font-bold'

function isMissingProductType(
  productTypeName: string | null | undefined,
  productTypeId: number | null | undefined,
): boolean {
  if (productTypeId != null && productTypeId > 0) return false
  const trimmed = productTypeName?.trim()
  return !trimmed || trimmed === '—' || trimmed === '-'
}

function resolveProductTypeSelectValue(
  product: AdminProductDetail,
  productTypes: AdminProductLookups['productTypes'],
): string {
  if (!isMissingProductType(product.productTypeName, product.productTypeId)) {
    return product.productTypeName.trim()
  }
  if (product.productTypeId != null) {
    const match = productTypes.find((type) => type.id === product.productTypeId)
    if (match?.name) return match.name
  }
  return ''
}

export default function CatalogAdDetailView({
  product,
  lookups,
  categories,
  backToListPath,
  isSaving,
  isApproving,
  isRejecting,
  isUploading,
  isReplacingImage = false,
  isDeleting = false,
  deletingImageId,
  deletingVideoPath = null,
  onSave,
  onApprove,
  onReject,
  onDelete,
  onUploadImage,
  onDeleteImage,
  onDeleteVideo,
  onReplaceImage,
}: CatalogAdDetailViewProps) {
  const { t, locale } = useAppPreferences()
  const fileInputRef = useRef<HTMLInputElement>(null)

  const [blurTarget, setBlurTarget] = useState<{ id: number; url: string } | null>(null)
  const [previewIndex, setPreviewIndex] = useState<number | null>(null)

  const [selectedImageIndex, setSelectedImageIndex] = useState(0)
  const [selectedVideoIndex, setSelectedVideoIndex] = useState(0)
  const [showVideo, setShowVideo] = useState(() => shouldAutoShowProductVideo(product))
  const mainVideoRef = useRef<HTMLVideoElement>(null)
  const [nameEn, setNameEn] = useState(product.name)
  const [usdPrice, setUsdPrice] = useState(String(product.priceUsd || ''))
  const [currency, setCurrency] = useState(product.currency || 'AED')
  const [unitName, setUnitName] = useState(product.unitName)
  const [categoryId, setCategoryId] = useState(
    product.categoryId != null ? String(product.categoryId) : '',
  )
  const [productTypeName, setProductTypeName] = useState(() =>
    resolveProductTypeSelectValue(product, lookups.productTypes),
  )
  const [descriptionEn, setDescriptionEn] = useState(product.description ?? '')
  const [supplierNotesEn, setSupplierNotesEn] = useState(product.supplierNotesEn ?? '')
  const [supplierNotesAr, setSupplierNotesAr] = useState('')
  const [isVideoMuted, setIsVideoMuted] = useState(product.isVideoMuted ?? true)

  useEffect(() => {
    setNameEn(product.name)
    setUsdPrice(String(product.priceUsd || ''))
    setCurrency(product.currency || 'AED')
    setUnitName(product.unitName)
    setCategoryId(product.categoryId != null ? String(product.categoryId) : '')
    setProductTypeName(resolveProductTypeSelectValue(product, lookups.productTypes))
    setDescriptionEn(product.description ?? '')
    setSupplierNotesEn(product.supplierNotesEn ?? '')
    setSupplierNotesAr('')
    setIsVideoMuted(product.isVideoMuted ?? true)
    setSelectedImageIndex(0)
    setSelectedVideoIndex(0)
    setShowVideo(shouldAutoShowProductVideo(product))
  }, [product, lookups.productTypes])

  const isRejected = product.statusLabelAr === 'مرفوض'
  const statusLabel = product.isApproved
    ? localizeProductStatusLabel('موافق', locale)
    : isRejected
      ? localizeProductStatusLabel(product.statusLabelAr, locale)
      : product.isEditResubmit
        ? t('ads.editAdRequest')
        : localizeProductStatusLabel(product.statusLabelAr, locale)
  const statusTone = product.isApproved
    ? 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-100'
    : isRejected
      ? 'bg-rose-50 text-rose-700 ring-1 ring-rose-100'
      : 'bg-amber-50 text-amber-700 ring-1 ring-amber-100'
  const isBusy = isSaving || isApproving || isRejecting || isUploading || isDeleting

  const negotiableLabel =
    product.negotiable === true
      ? t('ads.negotiableYes')
      : product.negotiable === false
        ? t('ads.negotiableNo')
        : t('ads.negotiableUnknown')

  const typeName = displayAdProductTypeName(product, locale)
  const quantityLabel = formatOrderQuantityWithUnit(product.quantity, product.unitName)
  const priceLabel = formatAdAmount(
    product.priceFormatted?.trim() ||
      `${Number(product.priceUsd || 0).toFixed(2)} ${product.currency || 'AED'}`,
    locale,
  )
  const priceWithUnit = product.unitName ? `${priceLabel} / ${product.unitName}` : priceLabel
  const showRetailPricing =
    Boolean(product.hasRetailPricing) ||
    (product.retailPrice != null && product.retailPrice > 0)
  const isHybridPricing = showRetailPricing && Boolean(product.categoryId)
  const isBooking = isBookingAd(product)
  const priceTypeLabel = formatAdPriceTypeLabel(product, t)
  const priceTypeFieldLabel = isBooking
    ? t('ads.bookingPriceType')
    : t('ads.requestFulfillment')
  const packagingLabel = formatPackagingLabel(
    product.packaging,
    product.packagingDetails,
    t,
    locale,
  )

  const retailPackagingLabel = formatPackagingLabel(
    product.retailPackaging,
    product.retailPackagingDetails,
    t,
    locale,
  )

  const retailDescriptionValue = (product.retailDescription ?? '').trim()
  // Always show Price Type on catalog ads (Categories / Offers / hybrids).
  const showPriceType = true
  const retailPriceLabel = showRetailPricing
    ? formatAdAmount(
        `${Number(product.retailPrice || 0).toFixed(2)} AED`,
        locale,
      )
    : null
  const retailQuantityLabel =
    product.retailQuantity != null
      ? formatOrderQuantityWithUnit(
          product.retailQuantity,
          product.retailUnitName?.trim() || undefined,
        )
      : null
  const wholesaleUnitLabel = product.unitName?.trim() || '—'
  const retailUnitLabel = product.retailUnitName?.trim() || '—'
  const ownerLabel = product.ownerCompanyName?.trim() || product.ownerName || '—'
  const ownerInitials = ownerLabel.slice(0, 2).toUpperCase()
  const shippingInfo = shippingFromProduct(product)
  const showShippingSection =
    hasInternationalShipping(shippingInfo) || hasDomesticShipping(shippingInfo)

  const galleryImages = useMemo(() => {
    if (product.images.length > 0) return product.images
    const paths = product.imagePaths?.length
      ? product.imagePaths
      : product.primaryImagePath
        ? [product.primaryImagePath]
        : []
    return paths.map((path, index) => ({ id: index, path }))
  }, [product.images, product.imagePaths, product.primaryImagePath])

  const videoPaths = useMemo(() => resolveProductVideoPaths(product), [product])
  const activeVideoPath = videoPaths[selectedVideoIndex] ?? videoPaths[0] ?? null
  const videoUrl = activeVideoPath ? resolveAssetUrl(activeVideoPath) : null
  const mainImage = galleryImages[selectedImageIndex] ?? galleryImages[0]
  const mainUrl = mainImage ? resolveAssetUrl(mainImage.path) : null

  useEffect(() => {
    if (!showVideo || !videoUrl) return
    const video = mainVideoRef.current
    if (!video) return
    video.muted = isVideoMuted
    void video.play().catch(() => undefined)
  }, [showVideo, videoUrl, isVideoMuted])

  function handleSave() {
    const price = Number.parseFloat(usdPrice)
    if (!nameEn.trim() || Number.isNaN(price) || price < 0) return
    // Hybrid ads keep CategoryId; sending ProductTypeName=Retail would strip
    // the category on the server and turn the ad into pure Retail.
    const resolvedProductTypeName = isHybridPricing || categoryId
      ? ''
      : productTypeName
    onSave({
      nameEn: nameEn.trim(),
      usdPrice: price,
      currency,
      quantity: product.quantity,
      descriptionEn: descriptionEn.trim(),
      categoryId: categoryId ? Number(categoryId) : null,
      productTypeName: resolvedProductTypeName,
      unitName,
      supplierNotesEn: supplierNotesEn.trim(),
      isVideoMuted,
    })
  }

  function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (file) onUploadImage(file)
    event.target.value = ''
  }

  function handleShare() {
    const url = window.location.href
    if (navigator.share) {
      void navigator.share({ title: product.name, url }).catch(() => undefined)
      return
    }
    void navigator.clipboard?.writeText(url)
  }

  async function handleDownload(url: string, path: string) {
    if (!url) return
    try {
      await downloadAsset(url, filenameFromAssetPath(path))
    } catch {
      window.alert(t('ads.downloadError'))
    }
  }

  async function handleBlurSave(file: File) {
    if (!blurTarget || !onReplaceImage) return
    try {
      await onReplaceImage(blurTarget.id, file)
      setBlurTarget(null)
    } catch {
      // Parent shows error message.
    }
  }

  const canBlurMainImage =
    !showVideo &&
    mainImage != null &&
    typeof mainImage.id === 'number' &&
    Boolean(mainUrl) &&
    Boolean(onReplaceImage)

  return (
    <div className="space-y-2 print:space-y-1" style={{ zoom: 0.82 }}>
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="min-w-0 text-start">
          <p className="admin-text-muted text-[10px] leading-tight">
            <Link to="/" className="hover:text-[#2563eb]">
              {t('nav.dashboard')}
            </Link>
            <span className="mx-1 opacity-50">›</span>
            <Link to={backToListPath} className="hover:text-[#2563eb]">
              {t('nav.ads')}
            </Link>
            <span className="mx-1 opacity-50">›</span>
            <span>{t('ads.adDetails')}</span>
          </p>

          <div className="mt-1 flex flex-wrap items-center gap-1.5">
            <Link
              to={backToListPath}
              className="admin-text-muted inline-flex items-center gap-1 text-[11px] font-semibold transition hover:text-[#2563eb]"
            >
              <span aria-hidden>←</span>
              {t('ads.backToAds')}
            </Link>
            <h1 className="admin-text text-sm font-bold tracking-tight">
              {t('ads.detailTitle', { name: product.name })}
            </h1>
            <span className={`inline-flex rounded-full px-1.5 py-0.5 text-[9px] font-bold ${statusTone}`}>
              {statusLabel}
            </span>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-1 print:hidden">
          <button
            type="button"
            onClick={handleShare}
            className={`admin-border border bg-white text-slate-600 transition hover:bg-slate-50 ${btnDense}`}
          >
            {t('ads.share')}
          </button>
          <button
            type="button"
            onClick={() => window.print()}
            className={`admin-border border bg-white text-slate-600 transition hover:bg-slate-50 ${btnDense}`}
          >
            {t('ads.downloadPdf')}
          </button>
          {!product.isApproved && !isRejected ? (
            <button
              type="button"
              disabled={isBusy}
              onClick={() => onApprove(supplierNotesEn.trim())}
              className={`keep-white bg-[#619D51] text-white disabled:opacity-60 ${btnDense}`}
            >
              {isApproving ? t('approving') : t('ads.approve')}
            </button>
          ) : null}
          {!isRejected ? (
            <button
              type="button"
              disabled={isBusy}
              onClick={() =>
                onReject({
                  supplierNotesEn: supplierNotesEn.trim(),
                  supplierNotesAr: supplierNotesAr.trim(),
                })
              }
              className={`border border-red-200 bg-white text-red-600 disabled:opacity-60 ${btnDense}`}
            >
              {isRejecting ? t('ads.rejecting') : t('ads.rejectAd')}
            </button>
          ) : null}
          {onDelete ? (
            <button
              type="button"
              disabled={isBusy}
              onClick={onDelete}
              className={`border border-red-300 bg-red-600 text-white disabled:opacity-60 ${btnDense}`}
            >
              {isDeleting ? t('ads.deleting') : t('ads.deleteAd')}
            </button>
          ) : null}
        </div>
      </div>

      {product.pendingEdit && !product.isApproved && !isRejected ? (
        <PendingProductEditPanel pendingEdit={product.pendingEdit} />
      ) : product.isEditResubmit && !product.isApproved && !isRejected ? (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-2.5 py-1.5 text-start print:hidden dark:border-amber-800/50 dark:bg-amber-950/40">
          <p className="text-[11px] font-bold text-amber-900 dark:text-amber-200">
            {t('ads.editAdRequest')}
          </p>
          <p className="mt-0.5 text-[10px] leading-snug text-amber-800 dark:text-amber-300/90">
            {t('ads.editAdHint')}
          </p>
        </div>
      ) : null}

      <div className="grid grid-cols-1 gap-2 xl:grid-cols-[minmax(0,1fr)_minmax(200px,240px)]">
        <div className="space-y-2">
          {/* Gallery */}
          <section className="admin-card rounded-lg p-2 shadow-sm">
            <div className="mx-auto w-full max-w-[11rem] overflow-hidden rounded-lg bg-slate-100 ring-1 ring-slate-200">
              {showVideo && videoUrl ? (
                <video
                  key={videoUrl}
                  ref={mainVideoRef}
                  controls
                  autoPlay
                  playsInline
                  muted={isVideoMuted}
                  preload="metadata"
                  className="aspect-[4/3] max-h-28 w-full bg-black object-contain"
                  src={videoUrl}
                />
              ) : mainUrl ? (
                <button
                  type="button"
                  onClick={() => setPreviewIndex(selectedImageIndex)}
                  className="block w-full cursor-zoom-in"
                  title={t('ads.preview')}
                >
                  <img
                    src={mainUrl}
                    alt={product.name}
                    className="aspect-[4/3] max-h-28 w-full object-cover"
                  />
                </button>
              ) : (
                <div className="flex aspect-[4/3] max-h-28 items-center justify-center text-[10px] text-slate-400">
                  {t('categories.noImage')}
                </div>
              )}
            </div>

            {!showVideo && mainUrl && mainImage ? (
              <div className="mt-1.5 flex flex-wrap gap-1 print:hidden">
                <button
                  type="button"
                  disabled={isBusy}
                  onClick={() => setPreviewIndex(selectedImageIndex)}
                  className="admin-border rounded border px-2 py-0.5 text-[10px] font-semibold"
                >
                  {t('ads.preview')}
                </button>
                <button
                  type="button"
                  disabled={isBusy}
                  onClick={() => void handleDownload(mainUrl, mainImage.path)}
                  className="admin-border rounded border px-2 py-0.5 text-[10px] font-semibold text-[#2563eb]"
                >
                  {t('ads.downloadImage')}
                </button>
                {canBlurMainImage ? (
                  <button
                    type="button"
                    disabled={isBusy || isReplacingImage}
                    onClick={() =>
                      setBlurTarget({ id: mainImage.id as number, url: mainUrl })
                    }
                    className="admin-border rounded border px-2 py-0.5 text-[10px] font-semibold"
                  >
                    {t('ads.blurImage')}
                  </button>
                ) : null}
              </div>
            ) : null}

            {showVideo && videoUrl && activeVideoPath ? (
              <div className="mt-1.5 print:hidden">
                <button
                  type="button"
                  disabled={isBusy}
                  onClick={() => void handleDownload(videoUrl, activeVideoPath)}
                  className="admin-border rounded border px-2 py-0.5 text-[10px] font-semibold text-[#2563eb]"
                >
                  {t('ads.downloadVideo')}
                </button>
              </div>
            ) : null}

            <div className="mt-1.5 flex flex-wrap gap-1">
              {galleryImages.map((image, index) => {
                const url = resolveAssetUrl(image.path)
                const selected = !showVideo && selectedImageIndex === index
                const isDeleting = deletingImageId === image.id
                return (
                  <div key={`${image.id}-${image.path}`} className="relative">
                    <button
                      type="button"
                      onClick={() => {
                        setShowVideo(false)
                        setSelectedImageIndex(index)
                      }}
                      className={`h-8 w-8 overflow-hidden rounded ring-2 transition ${
                        selected ? 'ring-[#2563eb]' : 'ring-transparent hover:ring-slate-300'
                      }`}
                    >
                      {url ? (
                        <img src={url} alt="" className="h-full w-full object-cover" />
                      ) : (
                        <span className="block h-full w-full bg-slate-200" />
                      )}
                    </button>
                    <button
                      type="button"
                      disabled={isBusy || isDeleting || typeof image.id !== 'number'}
                      onClick={() => {
                        if (typeof image.id === 'number') onDeleteImage(image.id)
                      }}
                      className="absolute -end-0.5 -top-0.5 flex h-3.5 w-3.5 items-center justify-center rounded-full bg-red-500 text-[8px] font-bold text-white disabled:opacity-40"
                      title={t('ads.deleteAd')}
                    >
                      ×
                    </button>
                  </div>
                )
              })}
              {videoPaths.map((path, index) => {
                const selected = showVideo && selectedVideoIndex === index
                return (
                  <button
                    key={`video-${path}-${index}`}
                    type="button"
                    onClick={() => {
                      setSelectedVideoIndex(index)
                      setShowVideo(true)
                    }}
                    className={`flex h-8 w-8 items-center justify-center rounded bg-slate-900 text-[10px] text-white ring-2 ${
                      selected ? 'ring-[#2563eb]' : 'ring-transparent'
                    }`}
                    title={`${t('ads.productVideo')} ${index + 1}`}
                  >
                    ▶{videoPaths.length > 1 ? (
                      <span className="ms-0.5 text-[8px] font-bold">{index + 1}</span>
                    ) : null}
                  </button>
                )
              })}
              <button
                type="button"
                disabled={isBusy}
                onClick={() => fileInputRef.current?.click()}
                className="admin-border admin-text-muted flex h-8 w-8 flex-col items-center justify-center rounded border border-dashed text-[8px] font-bold transition hover:border-[#3B7FC7] hover:text-[#3B7FC7] disabled:opacity-60"
              >
                <span className="text-sm leading-none">+</span>
                {isUploading ? '…' : t('ads.addMore')}
              </button>
            </div>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/png,image/jpeg,image/jpg,image/webp"
              className="hidden"
              onChange={handleFileChange}
            />
          </section>

          {/* Basic info (editable — same IconInfoField design as Order Information) */}
          <section className="admin-card rounded-lg p-2.5 shadow-sm">
            <IconInfoSectionTitle
              dense={denseField}
              title={t('ads.basicInfo')}
              icon={InfoFieldIcons.clipboard}
              iconClass="bg-[#eff6ff] text-[#2563eb]"
            />
            <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
              <IconInfoField
                dense={denseField}
                label={t('ads.productName')}
                icon={InfoFieldIcons.document}
                iconClass="bg-rose-50 text-rose-500"
                className="sm:col-span-2 lg:col-span-3"
                value={
                  <input
                    value={nameEn}
                    onChange={(e) => setNameEn(e.target.value)}
                    className={inputDense}
                  />
                }
              />
              <IconInfoField
                dense={denseField}
                label={isHybridPricing ? t('ads.wholesalePrice') : t('ads.price')}
                icon={InfoFieldIcons.lock}
                iconClass="bg-blue-50 text-blue-600"
                value={
                  <div className="mt-0.5 flex flex-wrap items-center gap-1">
                    <input
                      type="number"
                      min={0}
                      step="0.01"
                      value={usdPrice}
                      onChange={(e) => setUsdPrice(e.target.value)}
                      className="admin-input w-20 px-2 py-1 text-[11px] font-semibold"
                    />
                    <select
                      value={`${currency}|${unitName}`}
                      onChange={(e) => {
                        const [nextCurrency, nextUnit] = e.target.value.split('|')
                        setCurrency(nextCurrency)
                        setUnitName(nextUnit)
                      }}
                      className="admin-input appearance-none rounded-full bg-sky-50 px-2 py-0.5 text-[9px] font-bold text-sky-700"
                    >
                      {lookups.units.map((unit) => (
                        <option key={unit.id} value={`AED|${unit.name}`}>
                          {locale === 'ar' ? `درهم / ${unit.name}` : `AED / ${unit.name}`}
                        </option>
                      ))}
                      {lookups.units.map((unit) => (
                        <option key={`usd-${unit.id}`} value={`USD|${unit.name}`}>
                          {locale === 'ar' ? `دولار / ${unit.name}` : `USD / ${unit.name}`}
                        </option>
                      ))}
                    </select>
                  </div>
                }
              />
              <IconInfoField
                dense={denseField}
                label={isHybridPricing ? t('ads.wholesaleQuantity') : t('ads.quantity')}
                icon={InfoFieldIcons.calendar}
                iconClass="bg-sky-50 text-sky-600"
                value={quantityLabel}
              />
              {isHybridPricing ? (
                <IconInfoField
                  dense={denseField}
                  label={t('ads.wholesaleUnit')}
                  icon={InfoFieldIcons.tag}
                  iconClass="bg-sky-50 text-sky-600"
                  value={wholesaleUnitLabel}
                />
              ) : null}
              <IconInfoField
                dense={denseField}
                label={t('ads.category')}
                icon={InfoFieldIcons.bowl}
                iconClass="bg-orange-50 text-orange-500"
                value={
                  <select
                    value={categoryId}
                    onChange={(e) => setCategoryId(e.target.value)}
                    className={`${inputDense} appearance-none`}
                  >
                    <option value="">{t('ads.allCategories')}</option>
                    {categories.map((cat) => (
                      <option key={cat.categoryId} value={String(cat.categoryId)}>
                        {categoryDisplayName(cat, locale)}
                      </option>
                    ))}
                  </select>
                }
              />
              {showPriceType ? (
                <IconInfoField
                  dense={denseField}
                  label={priceTypeFieldLabel}
                  icon={InfoFieldIcons.search}
                  iconClass="bg-indigo-50 text-indigo-600"
                  value={priceTypeLabel}
                />
              ) : null}
              {packagingLabel ? (
                <IconInfoField
                  dense={denseField}
                  label={t('ads.packagingType')}
                  icon={InfoFieldIcons.tag}
                  iconClass="bg-amber-50 text-amber-600"
                  value={packagingLabel}
                />
              ) : null}
              <IconInfoField
                dense={denseField}
                label={t('ads.negotiable')}
                icon={InfoFieldIcons.search}
                iconClass="bg-emerald-50 text-emerald-600"
                value={negotiableLabel}
              />
              {!isHybridPricing ? (
                <IconInfoField
                  dense={denseField}
                  label={t('ads.adType')}
                  icon={InfoFieldIcons.tag}
                  iconClass="bg-violet-50 text-violet-600"
                  value={
                    <select
                      value={productTypeName}
                      onChange={(e) => setProductTypeName(e.target.value)}
                      className={`${inputDense} appearance-none`}
                    >
                      <option value="">{t('ads.noAdType')}</option>
                      {lookups.productTypes.map((type) => (
                        <option key={type.id} value={type.name}>
                          {type.name}
                        </option>
                      ))}
                    </select>
                  }
                />
              ) : null}
              <IconInfoField
                dense={denseField}
                label={t('ads.productDescription')}
                icon={InfoFieldIcons.note}
                iconClass="bg-amber-50 text-amber-600"
                className="sm:col-span-2 lg:col-span-3"
                value={
                  <textarea
                    value={descriptionEn}
                    onChange={(e) => setDescriptionEn(e.target.value)}
                    rows={2}
                    className="admin-input mt-0.5 w-full resize-y px-2 py-1 text-[11px] font-semibold leading-snug"
                  />
                }
              />
            </div>
            <div className="mt-2 flex justify-end">
              <button
                type="button"
                disabled={isBusy}
                onClick={handleSave}
                className="keep-white rounded-lg bg-[#3B7FC7] px-3 py-1 text-[11px] font-bold text-white disabled:opacity-60"
              >
                {isSaving ? t('ads.saving') : t('ads.saveChanges')}
              </button>
            </div>
          </section>

          {showRetailPricing ? (
            <section className="admin-card rounded-lg p-2.5 shadow-sm">
              <IconInfoSectionTitle
                dense={denseField}
                title={t('ads.retailPricing')}
                icon={InfoFieldIcons.lock}
                iconClass="bg-emerald-50 text-emerald-600"
              />
              <div className="grid gap-2 sm:grid-cols-3">
                <IconInfoField
                  dense={denseField}
                  label={t('ads.retailPrice')}
                  icon={InfoFieldIcons.lock}
                  iconClass="bg-emerald-50 text-emerald-600"
                  value={
                    retailUnitLabel !== '—'
                      ? `${retailPriceLabel} / ${retailUnitLabel}`
                      : retailPriceLabel
                  }
                />
                <IconInfoField
                  dense={denseField}
                  label={t('ads.retailUnit')}
                  icon={InfoFieldIcons.tag}
                  iconClass="bg-sky-50 text-sky-600"
                  value={retailUnitLabel}
                />
                <IconInfoField
                  dense={denseField}
                  label={t('ads.retailQuantity')}
                  icon={InfoFieldIcons.calendar}
                  iconClass="bg-violet-50 text-violet-600"
                  value={retailQuantityLabel || '—'}
                />
              </div>

              {(isHybridPricing &&
                (retailPackagingLabel || retailDescriptionValue)) ? (
                <div className="mt-2 grid gap-2 sm:grid-cols-2">
                  {retailPackagingLabel ? (
                    <IconInfoField
                      dense={denseField}
                      label={t('ads.retailPackagingType')}
                      icon={InfoFieldIcons.package}
                      iconClass="bg-amber-50 text-amber-600"
                      value={retailPackagingLabel}
                    />
                  ) : (
                    <IconInfoField
                      dense={denseField}
                      label={t('ads.retailPackagingType')}
                      icon={InfoFieldIcons.package}
                      iconClass="bg-amber-50 text-amber-600"
                      value={'—'}
                    />
                  )}

                  <IconInfoField
                    dense={denseField}
                    label={t('ads.retailProductDescription')}
                    icon={InfoFieldIcons.note}
                    iconClass="bg-amber-50 text-amber-600"
                    className="sm:col-span-2"
                    value={
                      retailDescriptionValue ? (
                        <div className="whitespace-pre-line leading-snug">
                          {retailDescriptionValue}
                        </div>
                      ) : (
                        ''
                      )
                    }
                  />
                </div>
              ) : null}
            </section>
          ) : null}

          {/* Stats bar */}
          <section className="admin-card flex flex-wrap items-stretch justify-between gap-1 rounded-lg px-1.5 py-1 shadow-sm">
            {!isHybridPricing ? (
              <StatChip
                label={t('ads.adType')}
                value={
                  <span className={`rounded px-1.5 py-0.5 text-[9px] font-bold ${productTypeBadgeClassForProduct(product)}`}>
                    {typeName}
                  </span>
                }
              />
            ) : null}
            <StatChip
              label={priceTypeFieldLabel}
              value={
                <span className="rounded bg-indigo-50 px-1.5 py-0.5 text-[9px] font-bold text-indigo-700 ring-1 ring-indigo-100">
                  {priceTypeLabel}
                </span>
              }
            />
            <StatChip label={t('ads.postedBy')} value={ownerLabel} />
            <StatChip
              label={t('ads.adCreatedAt')}
              value={formatPostedAt(product.createdAt, locale)}
            />
            <StatChip label={t('ads.views')} value={String(product.viewsCount ?? 0)} />
            <StatChip
              label={t('ads.currentStatus')}
              value={<span className={`rounded-full px-1.5 py-0.5 text-[9px] font-bold ${statusTone}`}>{statusLabel}</span>}
            />
          </section>

          {showShippingSection ? (
            <section className="admin-card rounded-lg p-2.5 shadow-sm">
              <h2 className="admin-text mb-1.5 text-start text-xs font-bold">
                {t('ads.shippingDetails')}
              </h2>
              <ProductShippingPanel shipping={shippingInfo} compact />
            </section>
          ) : null}

          {product.documents?.length ? (
            <section className="admin-card rounded-lg p-2.5 shadow-sm">
              <h2 className="admin-text mb-1.5 text-start text-xs font-bold">
                {t('ads.productDocuments')}
              </h2>
              <ul className="space-y-1">
                {product.documents.map((doc) => {
                  const url = resolveAssetUrl(doc.path)
                  const filename = doc.path.split(/[/\\]/).pop() || doc.path
                  return (
                    <li key={doc.id}>
                      <div className="admin-surface-muted flex items-center justify-between gap-2 rounded-lg px-2 py-1 text-[11px] font-semibold">
                        <a
                          href={url}
                          target="_blank"
                          rel="noreferrer"
                          className="min-w-0 flex-1 truncate text-[#2563eb]"
                        >
                          <span dir="ltr">{filename}</span>
                        </a>
                        <div className="flex shrink-0 items-center gap-1.5">
                          <button
                            type="button"
                            onClick={() => void handleDownload(url, doc.path)}
                            className="text-[10px] font-bold text-slate-600 hover:text-[#2563eb]"
                          >
                            {t('ads.downloadFile')}
                          </button>
                          <a
                            href={url}
                            target="_blank"
                            rel="noreferrer"
                            className="text-[10px] text-[#2563eb]"
                          >
                            {t('ads.openDocument')}
                          </a>
                        </div>
                      </div>
                    </li>
                  )
                })}
              </ul>
            </section>
          ) : null}

          {/* Additional info */}
          <section className="admin-card rounded-lg p-2.5 shadow-sm">
            <h2 className="admin-text mb-1.5 text-start text-xs font-bold">
              {t('ads.additionalInfo')}
            </h2>
            <div className="grid gap-1.5 sm:grid-cols-2 lg:grid-cols-3">
              {!isHybridPricing ? (
                <div className="text-start">
                  <p className="admin-text-subtle text-[9px] font-semibold uppercase">{t('ads.adType')}</p>
                  <p className="admin-text mt-0.5 text-[11px] font-semibold">{typeName}</p>
                </div>
              ) : null}
              <div className="text-start">
                <p className="admin-text-subtle text-[9px] font-semibold uppercase">{t('ads.currentStatus')}</p>
                <p className="admin-text mt-0.5 text-[11px] font-semibold">{statusLabel}</p>
              </div>
              <div className="text-start">
                <p className="admin-text-subtle text-[9px] font-semibold uppercase">{t('ads.postedBy')}</p>
                <p className="admin-text mt-0.5 text-[11px] font-semibold">{ownerLabel}</p>
              </div>
              <div className="text-start">
                <p className="admin-text-subtle text-[9px] font-semibold uppercase">{t('ads.adCreatedAt')}</p>
                <p className="admin-text mt-0.5 text-[11px] font-semibold">
                  {formatPostedAt(product.createdAt, locale)}
                </p>
              </div>
              <div className="text-start">
                <p className="admin-text-subtle text-[9px] font-semibold uppercase">{t('ads.lastUpdated')}</p>
                <p className="admin-text mt-0.5 text-[11px] font-semibold">
                  {formatPostedAt(product.updatedAt || product.createdAt, locale)}
                </p>
              </div>
              <div className="text-start">
                <p className="admin-text-subtle text-[9px] font-semibold uppercase">{t('ads.price')}</p>
                <p className="admin-text mt-0.5 text-[11px] font-semibold">{priceWithUnit}</p>
              </div>
            </div>
          </section>
        </div>

        <aside className="space-y-2 print:hidden">
          <SidebarCard title={t('ads.adStatusCard')}>
            <div className="space-y-2 text-start">
              <div className="flex items-center gap-2">
                <span
                  className={`flex h-7 w-7 items-center justify-center rounded-full text-xs ${
                    product.isApproved
                      ? 'bg-emerald-100 text-emerald-700'
                      : isRejected
                        ? 'bg-rose-100 text-rose-700'
                        : 'bg-amber-100 text-amber-700'
                  }`}
                >
                  {product.isApproved ? '✓' : isRejected ? '✕' : '!'}
                </span>
                <div>
                  <p className="admin-text-subtle text-[10px]">{t('ads.currentStatus')}</p>
                  <p
                    className={`text-[11px] font-bold ${
                      product.isApproved
                        ? 'text-emerald-600'
                        : isRejected
                          ? 'text-red-600'
                          : 'text-amber-600'
                    }`}
                  >
                    {statusLabel}
                  </p>
                </div>
              </div>
              <div className="admin-border flex justify-between border-t pt-1.5 text-[11px]">
                <span className="admin-text-muted">{t('ads.views')}</span>
                <span className="font-bold text-emerald-600">{product.viewsCount ?? 0}</span>
              </div>
              <div className="admin-border flex justify-between border-t pt-1.5 text-[11px]">
                <span className="admin-text-muted">{t('ads.adCreatedAt')}</span>
                <span className="admin-text font-semibold">
                  {formatPostedAt(product.createdAt, locale)}
                </span>
              </div>
            </div>
          </SidebarCard>

          <SidebarCard title={t('ads.supplierInfo')}>
            <div className="space-y-2 text-start">
              <div className="flex items-center gap-2">
                <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#eff6ff] text-[10px] font-bold text-[#2563eb]">
                  {ownerInitials}
                </span>
                <div className="min-w-0">
                  <p className="admin-text text-[11px] font-bold">{ownerLabel}</p>
                  {product.ownerName && product.ownerCompanyName ? (
                    <p className="admin-text-muted text-[10px]">{product.ownerName}</p>
                  ) : null}
                </div>
              </div>
              <div className="admin-border space-y-1.5 border-t pt-1.5 text-[11px]">
                <p className="flex items-center gap-1.5" dir="ltr">
                  <CountryFlag phone={product.ownerPhone} city={product.ownerCity} size={20} />
                  <span className="admin-text font-semibold">
                    {product.ownerPhone?.trim() || '—'}
                  </span>
                </p>
                <p className="admin-text break-all">{product.ownerEmail || '—'}</p>
                <p className="flex items-center gap-1.5">
                  <CountryFlag city={product.ownerCity} phone={product.ownerPhone} size={20} />
                  <span className="admin-text font-semibold">
                    {product.ownerCity?.trim() || '—'}
                  </span>
                </p>
              </div>
            </div>
          </SidebarCard>

          <SidebarCard title={t('ads.productVideo')}>
            <ProductVideosPanel
              videoPaths={videoPaths}
              selectedIndex={selectedVideoIndex}
              onSelectedIndexChange={setSelectedVideoIndex}
              isVideoMuted={isVideoMuted}
              onMuteChange={setIsVideoMuted}
              muteLabel={t('ads.muteVideoInApp')}
              muteHint={t('ads.muteVideoInAppHint')}
              emptyLabel={t('ads.noVideo')}
              isBusy={isBusy}
              className="space-y-1.5"
              onDeleteVideo={onDeleteVideo}
              deleteLabel={t('ads.deleteVideo')}
              deletingPath={deletingVideoPath}
            />
            {videoPaths.length > 0 &&
            product.videoDurationSeconds != null &&
            product.videoDurationSeconds > 0 ? (
              <p className="admin-text-muted mt-1.5 text-[10px]">
                {t('ads.videoDuration', { seconds: Math.round(product.videoDurationSeconds) })}
              </p>
            ) : null}
          </SidebarCard>

          <SidebarCard title={t('ads.adminNotes')}>
            <div className="space-y-1.5">
              <div>
                <p className="admin-text-muted mb-0.5 text-[10px] font-medium">
                  {t('ads.rejectReasonEn')}
                </p>
                <textarea
                  value={supplierNotesEn}
                  onChange={(e) => setSupplierNotesEn(e.target.value)}
                  rows={2}
                  placeholder={t('ads.rejectReasonEnPlaceholder')}
                  className="admin-input w-full resize-y px-2 py-1 text-[11px]"
                />
              </div>
              <div>
                <p className="admin-text-muted mb-0.5 text-[10px] font-medium">
                  {t('ads.rejectReasonAr')}
                </p>
                <textarea
                  value={supplierNotesAr}
                  onChange={(e) => setSupplierNotesAr(e.target.value)}
                  rows={2}
                  placeholder={t('ads.rejectReasonArPlaceholder')}
                  className="admin-input w-full resize-y px-2 py-1 text-[11px]"
                />
              </div>
            </div>
          </SidebarCard>
        </aside>
      </div>

      <AdminImageBlurModal
        open={blurTarget != null}
        imageUrl={blurTarget?.url ?? ''}
        isSaving={isReplacingImage}
        onClose={() => setBlurTarget(null)}
        onSave={handleBlurSave}
      />
      <ImageGallery
        images={galleryImages.map((image) => image.path)}
        initialIndex={previewIndex ?? 0}
        open={previewIndex != null}
        onClose={() => setPreviewIndex(null)}
      />
    </div>
  )
}
