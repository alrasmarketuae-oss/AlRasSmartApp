import { useEffect, useMemo, useRef, useState, type ChangeEvent, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { resolveAssetUrl } from '../../lib/assets'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { AdminProductDetail, AdminProductLookups } from '../../types/adminProduct'
import PendingProductEditPanel from './PendingProductEditPanel'
import ProductVideosPanel, { resolveProductVideoPaths } from './ProductVideosPanel'
import type { Category } from '../../types/category'
import CountryFlag from '../shared/CountryFlag'
import RequestOffersPanel from './RequestOffersPanel'
import AdminImageBlurModal from '../shared/AdminImageBlurModal'
import ImageGallery, { type GalleryMediaItem } from '../ui/ImageGallery'
import { downloadAsset, filenameFromAssetPath } from '../../utils/downloadAsset'
import {
  displayAdProductTypeName,
  formatPriceTypeLabel,
  formatPackagingLabel,
  productTypeBadgeClassForProduct,
} from '../../utils/adsDisplay'
import { categoryDisplayName } from '../../utils/categoryDisplay'
import { localizeProductStatusLabel } from '../../utils/localizedLabels'
import { formatOrderQuantityWithUnit } from '../../utils/ordersDisplay'
import { shippingFromProduct } from '../../utils/productShipping'

function countProductGalleryImages(product: AdminProductDetail): number {
  if (product.images.length > 0) return product.images.length
  if (product.imagePaths?.length) return product.imagePaths.length
  if (product.primaryImagePath?.trim()) return 1
  return 0
}

function shouldAutoShowProductVideo(product: AdminProductDetail): boolean {
  return resolveProductVideoPaths(product).length > 0 && countProductGalleryImages(product) === 0
}

type RequestDetailViewProps = {
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
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function shortRequestRef(productId: string): string {
  const digits = productId.replace(/\D/g, '')
  if (digits.length >= 3) return digits.slice(-4)
  return productId.replace(/-/g, '').slice(-4).toUpperCase() || '—'
}

function SidebarCard({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="admin-card overflow-hidden rounded-2xl shadow-sm">
      <div className="admin-border border-b px-5 py-3.5">
        <h2 className="admin-text text-start text-sm font-bold">{title}</h2>
      </div>
      <div className="px-5 py-4">{children}</div>
    </section>
  )
}

function InfoCell({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="text-start">
      <p className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">{label}</p>
      <p className="admin-text mt-1 text-sm font-semibold">{value || '—'}</p>
    </div>
  )
}

function LogisticsItem({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex min-w-[7rem] flex-1 flex-col items-center gap-1.5 px-2 py-2 text-center">
      <span className="flex h-9 w-9 items-center justify-center rounded-full bg-slate-100 text-slate-500">
        <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0H21M3.375 14.25h17.25m0 0V9.375c0-.621-.504-1.125-1.125-1.125H4.5A1.125 1.125 0 0 0 3.375 9.375v4.875Z" />
        </svg>
      </span>
      <p className="admin-text-subtle text-[10px] font-semibold">{label}</p>
      <p className="admin-text text-xs font-bold">{value || '—'}</p>
    </div>
  )
}

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

export default function RequestDetailView({
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
}: RequestDetailViewProps) {
  const { t, locale } = useAppPreferences()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const editSectionRef = useRef<HTMLElement>(null)

  const [blurTarget, setBlurTarget] = useState<{ id: number; url: string } | null>(null)
  const [previewIndex, setPreviewIndex] = useState<number | null>(null)

  const [isEditing, setIsEditing] = useState(false)
  const [offersCount, setOffersCount] = useState(product.pendingOffersCount ?? 0)
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

  const requestFulfillmentLabel = formatPriceTypeLabel(
    product.requestTypeName?.trim() || product.shippingDescription,
    t,
    product.requestTypeId,
  )
  const packagingLabel = formatPackagingLabel(
    product.packaging,
    product.packagingDetails,
    t,
    locale,
  )

  const shipping = shippingFromProduct(product)
  const typeName = displayAdProductTypeName(product, locale)
  const quantityLabel = formatOrderQuantityWithUnit(product.quantity, product.unitName)
  const priceLabel = product.priceFormatted?.trim()
    ? product.priceFormatted
    : `${Number(product.priceUsd || 0).toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US')} ${product.currency || 'AED'}`
  const priceWithUnit = product.unitName
    ? `${priceLabel} / ${product.unitName}`
    : priceLabel
  const ownerLabel = product.ownerCompanyName?.trim() || product.ownerName || '—'
  const ownerInitials = ownerLabel.slice(0, 2).toUpperCase()
  const requestRef = shortRequestRef(product.productId)

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
  const galleryMedia = useMemo((): GalleryMediaItem[] => {
    const images = galleryImages.map((image) => ({
      src: image.path,
      kind: 'image' as const,
      id: typeof image.id === 'number' ? image.id : undefined,
      path: image.path,
    }))
    const videos = videoPaths.map((path) => ({
      src: path,
      kind: 'video' as const,
      path,
    }))
    return [...images, ...videos]
  }, [galleryImages, videoPaths])
  const hasVideo = videoPaths.length > 0
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
  }, [showVideo, videoUrl, isVideoMuted, selectedVideoIndex])

  const categoryLabel = (() => {
    if (product.categoryId != null) {
      const match = categories.find((c) => c.categoryId === product.categoryId)
      if (match) return categoryDisplayName(match, locale)
    }
    return product.categoryName?.trim() || t('ads.allCategories')
  })()

  function handleSave() {
    const price = Number.parseFloat(usdPrice)
    if (!nameEn.trim() || Number.isNaN(price) || price < 0) return
    onSave({
      nameEn: nameEn.trim(),
      usdPrice: price,
      currency,
      quantity: product.quantity,
      descriptionEn: descriptionEn.trim(),
      categoryId: categoryId ? Number(categoryId) : null,
      productTypeName,
      unitName,
      supplierNotesEn: supplierNotesEn.trim(),
      isVideoMuted,
    })
    setIsEditing(false)
  }

  function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (file) onUploadImage(file)
    event.target.value = ''
  }

  function startEdit() {
    setIsEditing(true)
    window.setTimeout(() => {
      editSectionRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }, 80)
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
    <div className="space-y-5 print:space-y-3">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="min-w-0 text-start">
          <p className="admin-text-muted text-xs">
            <Link to={backToListPath} className="hover:text-[#2563eb]">
              {t('reqsOffers.title')}
            </Link>
            <span className="mx-1.5 opacity-50">›</span>
            <span>{t('reqsOffers.requestDetails')}</span>
          </p>

          <Link
            to={backToListPath}
            className="admin-text-muted mt-3 inline-flex items-center gap-1.5 text-sm font-semibold transition hover:text-[#2563eb]"
          >
            <span aria-hidden>←</span>
            {t('reqsOffers.backToRequests')}
          </Link>

          <div className="mt-3 flex flex-wrap items-center gap-2">
            <h1 className="admin-text text-2xl font-bold tracking-tight">
              {t('reqsOffers.requestNumber', { id: requestRef })}
            </h1>
            <span className={`inline-flex rounded-full px-2.5 py-1 text-[11px] font-bold ${statusTone}`}>
              {statusLabel}
            </span>
          </div>
          <p className="admin-text-muted mt-1 text-xs">
            {t('reqsOffers.postedOn', { date: formatPostedAt(product.createdAt, locale) })}
            {offersCount > 0 ? (
              <>
                <span className="mx-1.5">•</span>
                {t('reqsOffers.newOffersCount', { count: offersCount })}
              </>
            ) : null}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2 print:hidden">
          <button
            type="button"
            onClick={() => window.print()}
            className="admin-border inline-flex h-10 items-center gap-1.5 rounded-xl border bg-white px-3 text-xs font-bold text-slate-600 transition hover:bg-slate-50"
          >
            {t('reqsOffers.print')}
          </button>
          <button
            type="button"
            onClick={() => window.print()}
            className="admin-border inline-flex h-10 items-center gap-1.5 rounded-xl border bg-white px-3 text-xs font-bold text-slate-600 transition hover:bg-slate-50"
          >
            {t('reqsOffers.downloadPdf')}
          </button>
          <button
            type="button"
            onClick={startEdit}
            className="keep-white inline-flex h-10 items-center gap-1.5 rounded-xl bg-[#2563eb] px-4 text-xs font-bold text-white shadow-sm transition hover:bg-[#1d4ed8]"
          >
            {t('reqsOffers.editRequest')}
          </button>
          {!product.isApproved && !isRejected ? (
            <button
              type="button"
              disabled={isBusy}
              onClick={() => onApprove(supplierNotesEn.trim())}
              className="keep-white inline-flex h-10 items-center gap-1.5 rounded-xl bg-[#619D51] px-4 text-xs font-bold text-white transition hover:bg-[#528a45] disabled:opacity-60"
            >
              {isApproving ? t('approving') : t('ads.approve')}
            </button>
          ) : null}
          {onDelete ? (
            <button
              type="button"
              disabled={isBusy}
              onClick={onDelete}
              className="inline-flex h-10 items-center gap-1.5 rounded-xl border border-red-300 bg-red-600 px-4 text-xs font-bold text-white transition hover:bg-red-700 disabled:opacity-60"
            >
              {isDeleting ? t('ads.deleting') : t('ads.deleteAd')}
            </button>
          ) : null}
        </div>
      </div>

      {product.pendingEdit && !product.isApproved && !isRejected ? (
        <PendingProductEditPanel pendingEdit={product.pendingEdit} />
      ) : product.isEditResubmit && !product.isApproved && !isRejected ? (
        <div className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-start print:hidden dark:border-amber-800/50 dark:bg-amber-950/40">
          <p className="text-sm font-bold text-amber-900 dark:text-amber-200">
            {t('ads.editAdRequest')}
          </p>
          <p className="mt-1 text-xs leading-relaxed text-amber-800 dark:text-amber-300/90">
            {t('ads.editAdHint')}
          </p>
        </div>
      ) : null}

      <div className="grid grid-cols-1 gap-5 xl:grid-cols-[minmax(0,1fr)_minmax(260px,300px)]">
        <div className="space-y-5">
          <section className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
            <div className="grid gap-6 lg:grid-cols-[auto_minmax(0,1fr)]">
              <div className="w-[140px] shrink-0 sm:w-[160px]">
                <div className="overflow-hidden rounded-xl bg-slate-100 ring-1 ring-slate-200">
                  {showVideo && videoUrl ? (
                    <button
                      type="button"
                      onClick={() =>
                        setPreviewIndex(galleryImages.length + Math.max(selectedVideoIndex, 0))
                      }
                      className="relative block w-full cursor-zoom-in"
                      title={t('ads.preview')}
                    >
                      <video
                        key={videoUrl}
                        ref={mainVideoRef}
                        muted
                        playsInline
                        preload="metadata"
                        className="pointer-events-none aspect-square h-[140px] w-full bg-black object-contain sm:h-[160px]"
                        src={videoUrl}
                      />
                      <span className="pointer-events-none absolute inset-0 flex items-center justify-center bg-black/25 text-2xl text-white">
                        ▶
                      </span>
                    </button>
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
                        className="aspect-square h-[140px] w-full object-cover sm:h-[160px]"
                      />
                    </button>
                  ) : (
                    <div className="flex aspect-square h-[140px] items-center justify-center text-slate-400 sm:h-[160px]">
                      <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Z" />
                      </svg>
                    </div>
                  )}
                </div>

                {!showVideo && mainUrl && mainImage ? (
                  <div className="mt-2 flex flex-wrap gap-1.5 print:hidden">
                    <button
                      type="button"
                      disabled={isBusy}
                      onClick={() => setPreviewIndex(selectedImageIndex)}
                      className="admin-border rounded-lg border px-2 py-1 text-[10px] font-semibold"
                    >
                      {t('ads.preview')}
                    </button>
                    <button
                      type="button"
                      disabled={isBusy}
                      onClick={() => void handleDownload(mainUrl, mainImage.path)}
                      className="admin-border rounded-lg border px-2 py-1 text-[10px] font-semibold text-[#2563eb]"
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
                        className="admin-border rounded-lg border px-2 py-1 text-[10px] font-semibold"
                      >
                        {t('ads.blurImage')}
                      </button>
                    ) : null}
                  </div>
                ) : null}

                {showVideo && videoUrl && activeVideoPath ? (
                  <div className="mt-2 print:hidden">
                    <button
                      type="button"
                      disabled={isBusy}
                      onClick={() => void handleDownload(videoUrl, activeVideoPath)}
                      className="admin-border rounded-lg border px-2 py-1 text-[10px] font-semibold text-[#2563eb]"
                    >
                      {t('ads.downloadVideo')}
                    </button>
                  </div>
                ) : null}

                {galleryImages.length > 0 || hasVideo ? (
                  <div className="mt-2 flex flex-wrap gap-1.5">
                    {galleryImages.map((image, index) => {
                      const url = resolveAssetUrl(image.path)
                      const selected = !showVideo && selectedImageIndex === index
                      return (
                        <button
                          key={`${image.id}-${image.path}`}
                          type="button"
                          onClick={() => {
                            setShowVideo(false)
                            setSelectedImageIndex(index)
                          }}
                          className={`relative h-10 w-10 overflow-hidden rounded-lg ring-2 transition ${
                            selected
                              ? 'ring-[#2563eb]'
                              : 'ring-transparent hover:ring-slate-300'
                          }`}
                        >
                          {url ? (
                            <img src={url} alt="" className="h-full w-full object-cover" />
                          ) : (
                            <span className="block h-full w-full bg-slate-200" />
                          )}
                        </button>
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
                            setPreviewIndex(galleryImages.length + index)
                          }}
                          className={`relative flex h-10 w-10 items-center justify-center overflow-hidden rounded-lg bg-slate-900 text-white ring-2 transition ${
                            selected
                              ? 'ring-[#2563eb]'
                              : 'ring-transparent hover:ring-slate-300'
                          }`}
                          title={`${t('ads.productVideo')} ${index + 1}`}
                        >
                          <svg className="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M8 5.14v14l11-7-11-7Z" />
                          </svg>
                          {videoPaths.length > 1 ? (
                            <span className="absolute bottom-0.5 end-0.5 text-[8px] font-bold">
                              {index + 1}
                            </span>
                          ) : null}
                        </button>
                      )
                    })}
                  </div>
                ) : null}

                {galleryImages.length > 0 || hasVideo ? (
                  <p className="admin-text-muted mt-2 text-[11px]">
                    {t('reqsOffers.mediaCount', {
                      images: galleryImages.length,
                      videos: videoPaths.length,
                    })}
                  </p>
                ) : null}
              </div>

              <div className="min-w-0 text-start">
                <div className="flex flex-wrap items-center gap-2">
                  <h2 className="admin-text text-xl font-bold">{product.name}</h2>
                  <span
                    className={`inline-flex rounded-md px-2 py-0.5 text-[10px] font-bold ${productTypeBadgeClassForProduct(product)}`}
                  >
                    {typeName}
                  </span>
                </div>

                <div className="mt-5 grid gap-4 sm:grid-cols-2">
                  <InfoCell label={t('ads.category')} value={categoryLabel} />
                  <InfoCell label={t('ads.requestFulfillment')} value={requestFulfillmentLabel} />
                  {packagingLabel ? (
                    <InfoCell label={t('ads.packagingType')} value={packagingLabel} />
                  ) : null}
                  <InfoCell label={t('reqsOffers.requiredQuantity')} value={quantityLabel} />
                  <InfoCell label={t('ads.targetPrice')} value={priceWithUnit} />
                  <InfoCell label={t('ads.negotiable')} value={negotiableLabel} />
                  <InfoCell label={t('reqsOffers.postedBy')} value={ownerLabel} />
                  <InfoCell
                    label={t('ads.adCreatedAt')}
                    value={formatPostedAt(product.createdAt, locale)}
                  />
                  <InfoCell label={t('ads.views')} value={String(product.viewsCount ?? 0)} />
                </div>

                <div className="mt-5">
                  <p className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">
                    {t('ads.productDescription')}
                  </p>
                  <p className="admin-text mt-1 text-sm leading-relaxed">
                    {product.description?.trim() || t('ads.noDescription')}
                  </p>
                </div>

                {shipping.shippingDescription?.trim() &&
                shipping.shippingDescription.trim().toLowerCase() !== 'local' &&
                shipping.shippingDescription.trim().toLowerCase() !== 'booking' ? (
                  <div className="mt-4">
                    <p className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">
                      {t('ads.shippingNotes')}
                    </p>
                    <p className="admin-text mt-1 text-sm leading-relaxed">
                      {shipping.shippingDescription}
                    </p>
                  </div>
                ) : shipping.shippingDescription?.trim() ? (
                  <div className="mt-4">
                    <p className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">
                      {t('ads.shippingNotes')}
                    </p>
                    <p className="admin-text mt-1 text-sm leading-relaxed">
                      {requestFulfillmentLabel}
                    </p>
                  </div>
                ) : null}

                <div className="admin-border mt-6 flex flex-wrap justify-between gap-2 border-t pt-4">
                  <LogisticsItem
                    label={t('ads.shippingDuration')}
                    value={shipping.shippingDuration?.trim() || '—'}
                  />
                  <LogisticsItem
                    label={t('ads.loadingPort')}
                    value={shipping.loadingPortName?.trim() || '—'}
                  />
                  <LogisticsItem
                    label={t('ads.arrivalPort')}
                    value={shipping.arrivalPortName?.trim() || '—'}
                  />
                  <LogisticsItem
                    label={t('reqsOffers.paymentTerms')}
                    value="—"
                  />
                  <LogisticsItem label={t('ads.adType')} value={typeName} />
                </div>
              </div>
            </div>
          </section>

          <RequestOffersPanel
            productId={product.productId}
            onOffersCountChange={setOffersCount}
          />

          {(galleryImages.length > 0 || hasVideo || product.documents?.length) ? (
            <section className="admin-card rounded-2xl p-5 shadow-sm sm:p-6">
              <h2 className="admin-text mb-4 text-start text-base font-bold">
                {t('ads.imageManagement')}
              </h2>
              {galleryImages.length > 0 ? (
                <div className="flex flex-wrap gap-2">
                  {galleryImages.map((image, index) => {
                    const url = resolveAssetUrl(image.path)
                    const canBlur =
                      typeof image.id === 'number' && Boolean(url) && Boolean(onReplaceImage)
                    return (
                      <div key={`gallery-${image.id}-${image.path}`} className="space-y-1">
                        <button
                          type="button"
                          onClick={() => {
                            setShowVideo(false)
                            setSelectedImageIndex(index)
                            window.document.querySelector('main')?.scrollTo({ top: 0, behavior: 'smooth' })
                          }}
                          className="h-14 w-14 overflow-hidden rounded-lg ring-1 ring-slate-200 transition hover:ring-[#2563eb]"
                        >
                          {url ? (
                            <img src={url} alt="" className="h-full w-full object-cover" />
                          ) : (
                            <div className="admin-surface-muted h-full w-full" />
                          )}
                        </button>
                        {url ? (
                          <div className="flex flex-wrap gap-1">
                            <button
                              type="button"
                              disabled={isBusy}
                              onClick={() => void handleDownload(url, image.path)}
                              className="text-[10px] font-bold text-[#2563eb] hover:underline"
                            >
                              {t('ads.downloadImage')}
                            </button>
                            {canBlur ? (
                              <button
                                type="button"
                                disabled={isBusy || isReplacingImage}
                                onClick={() =>
                                  setBlurTarget({ id: image.id as number, url })
                                }
                                className="text-[10px] font-bold text-slate-600 hover:underline"
                              >
                                {t('ads.blurImage')}
                              </button>
                            ) : null}
                          </div>
                        ) : null}
                      </div>
                    )
                  })}
                </div>
              ) : (
                <p className="admin-text-muted text-sm">{t('orders.noImages')}</p>
              )}

              {hasVideo ? (
                <div className="mt-5">
                  <p className="admin-text mb-2 text-sm font-bold">{t('ads.productVideo')}</p>
                  <ProductVideosPanel
                    videoPaths={videoPaths}
                    selectedIndex={selectedVideoIndex}
                    onSelectedIndexChange={setSelectedVideoIndex}
                    isVideoMuted={isVideoMuted}
                    onMuteChange={setIsVideoMuted}
                    muteLabel={t('ads.muteVideoInApp')}
                    emptyLabel={t('ads.noVideo')}
                    isBusy={isBusy}
                    className="space-y-2"
                    videoClassName="h-40 w-full max-w-xs rounded-xl bg-black object-contain"
                    onDeleteVideo={onDeleteVideo}
                    deleteLabel={t('ads.deleteVideo')}
                    deletingPath={deletingVideoPath}
                  />
                  {videoUrl && activeVideoPath ? (
                    <button
                      type="button"
                      disabled={isBusy}
                      onClick={() => void handleDownload(videoUrl, activeVideoPath)}
                      className="mt-2 text-xs font-bold text-[#2563eb] hover:underline"
                    >
                      {t('ads.downloadVideo')}
                    </button>
                  ) : null}
                </div>
              ) : null}

              {product.documents?.length ? (
                <div className="mt-5">
                  <p className="admin-text mb-2 text-sm font-bold">{t('ads.productDocuments')}</p>
                  <ul className="space-y-2">
                    {product.documents.map((doc) => {
                      const url = resolveAssetUrl(doc.path)
                      const filename = doc.path.split(/[/\\]/).pop() || doc.path
                      return (
                        <li key={doc.id}>
                          <div className="admin-surface-muted flex items-center justify-between gap-3 rounded-xl px-3 py-2.5 text-sm font-semibold">
                            <a
                              href={url}
                              target="_blank"
                              rel="noreferrer"
                              className="min-w-0 flex-1 truncate text-[#2563eb]"
                            >
                              <span dir="ltr">{filename}</span>
                            </a>
                            <div className="flex shrink-0 items-center gap-2">
                              <button
                                type="button"
                                onClick={() => void handleDownload(url, doc.path)}
                                className="text-xs font-bold text-slate-600 hover:text-[#2563eb]"
                              >
                                {t('ads.downloadFile')}
                              </button>
                              <a
                                href={url}
                                target="_blank"
                                rel="noreferrer"
                                className="text-xs text-[#2563eb]"
                              >
                                {t('ads.openDocument')}
                              </a>
                            </div>
                          </div>
                        </li>
                      )
                    })}
                  </ul>
                </div>
              ) : null}
            </section>
          ) : null}

          {isEditing ? (
            <section
              ref={editSectionRef}
              className="admin-card space-y-5 rounded-2xl p-5 shadow-sm print:hidden sm:p-6"
            >
              <div className="flex flex-wrap items-center justify-between gap-3">
                <h2 className="admin-text text-lg font-bold">{t('reqsOffers.editRequest')}</h2>
                <button
                  type="button"
                  onClick={() => setIsEditing(false)}
                  className="admin-text-muted text-xs font-semibold hover:text-slate-700"
                >
                  {t('cancel')}
                </button>
              </div>

              <div className="space-y-4">
                <label className="block text-start">
                  <span className="admin-text-muted text-sm font-medium">{t('ads.productName')}</span>
                  <input
                    value={nameEn}
                    onChange={(e) => setNameEn(e.target.value)}
                    className="admin-input mt-1.5 w-full px-3 py-2.5 text-sm"
                  />
                </label>

                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <label className="block text-start">
                    <span className="admin-text-muted text-sm font-medium">{t('ads.targetPrice')}</span>
                    <input
                      type="number"
                      min={0}
                      step="0.01"
                      value={usdPrice}
                      onChange={(e) => setUsdPrice(e.target.value)}
                      className="admin-input mt-1.5 w-full px-3 py-2.5 text-sm"
                    />
                  </label>
                  <label className="block text-start">
                    <span className="admin-text-muted text-sm font-medium">{t('ads.unit')}</span>
                    <select
                      value={`${currency}|${unitName}`}
                      onChange={(e) => {
                        const [nextCurrency, nextUnit] = e.target.value.split('|')
                        setCurrency(nextCurrency)
                        setUnitName(nextUnit)
                      }}
                      className="admin-input mt-1.5 w-full appearance-none px-3 py-2.5 text-sm"
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
                  </label>
                  <label className="block text-start">
                    <span className="admin-text-muted text-sm font-medium">{t('ads.category')}</span>
                    <select
                      value={categoryId}
                      onChange={(e) => setCategoryId(e.target.value)}
                      className="admin-input mt-1.5 w-full appearance-none px-3 py-2.5 text-sm"
                    >
                      <option value="">{t('ads.allCategories')}</option>
                      {categories.map((cat) => (
                        <option key={cat.categoryId} value={String(cat.categoryId)}>
                          {categoryDisplayName(cat, locale)}
                        </option>
                      ))}
                    </select>
                  </label>
                  <label className="block text-start">
                    <span className="admin-text-muted text-sm font-medium">{t('ads.adType')}</span>
                    <select
                      value={productTypeName}
                      onChange={(e) => setProductTypeName(e.target.value)}
                      className="admin-input mt-1.5 w-full appearance-none px-3 py-2.5 text-sm"
                    >
                      <option value="">{t('ads.noAdType')}</option>
                      {lookups.productTypes.map((type) => (
                        <option key={type.id} value={type.name}>
                          {type.name}
                        </option>
                      ))}
                    </select>
                  </label>
                </div>

                <label className="block text-start">
                  <span className="admin-text-muted text-sm font-medium">
                    {t('ads.productDescription')}
                  </span>
                  <textarea
                    value={descriptionEn}
                    onChange={(e) => setDescriptionEn(e.target.value)}
                    rows={4}
                    className="admin-input mt-1.5 w-full resize-y px-3 py-2.5 text-sm leading-relaxed"
                  />
                </label>

                <div>
                  <p className="admin-text mb-3 text-sm font-bold">{t('ads.imageManagement')}</p>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/png,image/jpeg,image/jpg,image/webp"
                    className="hidden"
                    onChange={handleFileChange}
                  />
                  <button
                    type="button"
                    disabled={isBusy}
                    onClick={() => fileInputRef.current?.click()}
                    className="admin-border admin-text-muted flex w-full flex-col items-center justify-center rounded-2xl border-2 border-dashed px-4 py-8 text-center transition hover:border-[#3B7FC7] hover:bg-[#3B7FC7]/5 disabled:opacity-60"
                  >
                    <span className="text-sm font-semibold">
                      {isUploading ? t('ads.uploading') : t('ads.uploadImages')}
                    </span>
                  </button>
                  {product.images.length > 0 ? (
                    <div className="mt-4 flex flex-wrap gap-2">
                      {product.images.map((image) => {
                        const url = resolveAssetUrl(image.path)
                        const isDeleting = deletingImageId === image.id
                        const canBlur = Boolean(url) && Boolean(onReplaceImage)
                        return (
                          <div
                            key={`${image.id}-${image.path}`}
                            className="admin-border group relative space-y-1"
                          >
                            <div className="relative h-14 w-14 overflow-hidden rounded-lg border">
                              {url ? (
                                <img src={url} alt="" className="h-full w-full object-cover" />
                              ) : (
                                <div className="admin-surface-muted h-full w-full" />
                              )}
                              <button
                                type="button"
                                disabled={isBusy || isDeleting}
                                onClick={() => onDeleteImage(image.id)}
                                className="absolute -end-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-[#ef4444] text-[10px] text-white shadow disabled:opacity-60"
                                title={t('ads.deleteAd')}
                              >
                                ×
                              </button>
                            </div>
                            {url ? (
                              <div className="flex flex-wrap gap-1">
                                <button
                                  type="button"
                                  disabled={isBusy}
                                  onClick={() => void handleDownload(url, image.path)}
                                  className="text-[10px] font-bold text-[#2563eb] hover:underline"
                                >
                                  {t('ads.downloadImage')}
                                </button>
                                {canBlur ? (
                                  <button
                                    type="button"
                                    disabled={isBusy || isReplacingImage}
                                    onClick={() => setBlurTarget({ id: image.id, url })}
                                    className="text-[10px] font-bold text-slate-600 hover:underline"
                                  >
                                    {t('ads.blurImage')}
                                  </button>
                                ) : null}
                              </div>
                            ) : null}
                          </div>
                        )
                      })}
                    </div>
                  ) : null}
                </div>

                {videoPaths.length > 0 ? (
                  <div>
                    <p className="admin-text mb-2 text-sm font-bold">{t('ads.productVideo')}</p>
                    <ProductVideosPanel
                      videoPaths={videoPaths}
                      selectedIndex={selectedVideoIndex}
                      onSelectedIndexChange={setSelectedVideoIndex}
                      isVideoMuted={isVideoMuted}
                      onMuteChange={setIsVideoMuted}
                      muteLabel={t('ads.muteVideoInApp')}
                      emptyLabel={t('ads.noVideo')}
                      isBusy={isBusy}
                      className="space-y-2"
                      videoClassName="w-full max-w-md rounded-xl bg-black"
                      onDeleteVideo={onDeleteVideo}
                      deleteLabel={t('ads.deleteVideo')}
                      deletingPath={deletingVideoPath}
                    />
                  </div>
                ) : null}

                <div className="grid gap-3 sm:grid-cols-2">
                  <label className="block text-start">
                    <span className="admin-text-muted text-xs font-medium">
                      {t('ads.rejectReasonEn')}
                    </span>
                    <textarea
                      value={supplierNotesEn}
                      onChange={(e) => setSupplierNotesEn(e.target.value)}
                      rows={3}
                      className="admin-input mt-1 w-full resize-y px-3 py-2 text-sm"
                    />
                  </label>
                  <label className="block text-start">
                    <span className="admin-text-muted text-xs font-medium">
                      {t('ads.rejectReasonAr')}
                    </span>
                    <textarea
                      value={supplierNotesAr}
                      onChange={(e) => setSupplierNotesAr(e.target.value)}
                      rows={3}
                      className="admin-input mt-1 w-full resize-y px-3 py-2 text-sm"
                    />
                  </label>
                </div>

                <div className="flex flex-wrap justify-end gap-2 pt-2">
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
                      className="inline-flex h-10 items-center rounded-xl border-2 border-red-200 bg-white px-4 text-sm font-bold text-red-600 disabled:opacity-60"
                    >
                      {isRejecting ? t('ads.rejecting') : t('ads.reject')}
                    </button>
                  ) : null}
                  <button
                    type="button"
                    disabled={isBusy}
                    onClick={handleSave}
                    className="keep-white rounded-xl bg-[#3B7FC7] px-6 py-2.5 text-sm font-bold text-white disabled:opacity-60"
                  >
                    {isSaving ? t('ads.saving') : t('ads.saveChanges')}
                  </button>
                </div>
              </div>
            </section>
          ) : null}
        </div>

        <aside className="space-y-4 print:hidden">
          <SidebarCard title={t('reqsOffers.requesterBuyer')}>
            <div className="space-y-4 text-start">
              <div className="flex items-start gap-3">
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-[#eff6ff] text-sm font-bold text-[#2563eb]">
                  {ownerInitials}
                </span>
                <div className="min-w-0">
                  <p className="admin-text text-sm font-bold">{ownerLabel}</p>
                  {product.isApproved ? (
                    <span className="mt-1 inline-flex rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] font-bold text-emerald-700">
                      {t('reqsOffers.verified')}
                    </span>
                  ) : null}
                </div>
              </div>
              <div className="admin-border space-y-3 border-t pt-3 text-sm">
                <p className="flex items-center gap-2" dir="ltr">
                  <CountryFlag phone={product.ownerPhone} city={product.ownerCity} size={20} />
                  <span className="admin-text break-all">
                    {product.ownerPhone?.trim() || '—'}
                  </span>
                </p>
                <p className="admin-text break-all">{product.ownerEmail || '—'}</p>
                <p className="flex items-center gap-2">
                  <CountryFlag city={product.ownerCity} phone={product.ownerPhone} size={20} />
                  <span className="admin-text-muted">{product.ownerCity?.trim() || '—'}</span>
                </p>
              </div>
            </div>
          </SidebarCard>

          <SidebarCard title={t('reqsOffers.requestStatus')}>
            <div className="space-y-3 text-start">
              <p
                className={`text-base font-bold ${
                  product.isApproved
                    ? 'text-emerald-600'
                    : isRejected
                      ? 'text-red-600'
                      : 'text-amber-600'
                }`}
              >
                {statusLabel}
              </p>
              <p className="admin-text-muted text-xs leading-relaxed">
                {product.isApproved
                  ? t('reqsOffers.requestActiveHint')
                  : isRejected
                    ? t('reqsOffers.requestRejectedHint')
                    : t('reqsOffers.requestPendingHint')}
              </p>
              <div className="admin-border space-y-2 border-t pt-3 text-xs">
                <div className="flex justify-between gap-2">
                  <span className="admin-text-muted">{t('reqsOffers.posted')}</span>
                  <span className="admin-text font-semibold">
                    {formatPostedAt(product.createdAt, locale)}
                  </span>
                </div>
                <div className="flex justify-between gap-2">
                  <span className="admin-text-muted">{t('reqsOffers.lastUpdated')}</span>
                  <span className="admin-text font-semibold">
                    {formatPostedAt(product.updatedAt || product.createdAt, locale)}
                  </span>
                </div>
              </div>
            </div>
          </SidebarCard>

          <SidebarCard title={t('reqsOffers.requestSummary')}>
            <dl className="space-y-3 text-start text-sm">
              <div className="flex justify-between gap-3">
                <dt className="admin-text-muted">{t('ads.quantity')}</dt>
                <dd className="admin-text font-semibold">{quantityLabel}</dd>
              </div>
              <div className="flex justify-between gap-3">
                <dt className="admin-text-muted">{t('ads.targetPrice')}</dt>
                <dd className="admin-text font-semibold">{priceWithUnit}</dd>
              </div>
              <div className="flex justify-between gap-3">
                <dt className="admin-text-muted">{t('ads.negotiable')}</dt>
                <dd className="admin-text font-semibold">{negotiableLabel}</dd>
              </div>
              <div className="flex justify-between gap-3">
                <dt className="admin-text-muted">{t('ads.adType')}</dt>
                <dd className="admin-text font-semibold">{typeName}</dd>
              </div>
              <div className="flex justify-between gap-3">
                <dt className="admin-text-muted">{t('ads.category')}</dt>
                <dd className="admin-text font-semibold">{categoryLabel}</dd>
              </div>
              <div>
                <dt className="admin-text-muted">{t('ads.productDescription')}</dt>
                <dd className="admin-text mt-1 text-xs leading-relaxed">
                  {product.description?.trim() || t('ads.noDescription')}
                </dd>
              </div>
            </dl>
            <button
              type="button"
              onClick={() =>
                window.document.querySelector('main')?.scrollTo({ top: 0, behavior: 'smooth' })
              }
              className="mt-4 text-xs font-bold text-[#2563eb] hover:underline"
            >
              {t('reqsOffers.viewFullDetails')}
            </button>
          </SidebarCard>

          <SidebarCard title={t('ads.adminNotes')}>
            <div className="space-y-3 text-start">
              <div>
                <p className="admin-text-muted mb-1 text-xs font-medium">
                  {t('ads.rejectReasonEn')}
                </p>
                <textarea
                  value={supplierNotesEn}
                  onChange={(e) => setSupplierNotesEn(e.target.value)}
                  rows={3}
                  placeholder={t('ads.rejectReasonEnPlaceholder')}
                  className="admin-input w-full resize-y px-3 py-2.5 text-sm leading-relaxed"
                />
              </div>
              <div>
                <p className="admin-text-muted mb-1 text-xs font-medium">
                  {t('ads.rejectReasonAr')}
                </p>
                <textarea
                  value={supplierNotesAr}
                  onChange={(e) => setSupplierNotesAr(e.target.value)}
                  rows={3}
                  placeholder={t('ads.rejectReasonArPlaceholder')}
                  className="admin-input w-full resize-y px-3 py-2.5 text-sm leading-relaxed"
                />
              </div>
              {product.supplierNotesEn?.trim() ? (
                <p className="admin-text-muted text-[11px] leading-relaxed">
                  {t('ads.adminNotes')}: {product.supplierNotesEn}
                </p>
              ) : null}
            </div>
          </SidebarCard>

          <section className="admin-card space-y-2 rounded-2xl p-4 shadow-sm">
            <p className="admin-text mb-1 text-sm font-bold">{t('reqsOffers.requestActions')}</p>
            {!isRejected ? (
              <button
                type="button"
                disabled={isBusy}
                onClick={() =>
                  onReject({
                    supplierNotesEn: supplierNotesEn.trim() || 'Closed by admin',
                    supplierNotesAr: supplierNotesAr.trim() || 'تم إغلاق الطلب من الإدارة',
                  })
                }
                className="inline-flex h-10 w-full items-center justify-center rounded-xl border border-red-200 bg-white text-sm font-bold text-red-600 transition hover:bg-red-50 disabled:opacity-60"
              >
                {isRejecting ? t('ads.rejecting') : t('reqsOffers.closeRequest')}
              </button>
            ) : null}
            {!product.isApproved && !isRejected ? (
              <button
                type="button"
                disabled={isBusy}
                onClick={() => onApprove(supplierNotesEn.trim())}
                className="keep-white inline-flex h-10 w-full items-center justify-center rounded-xl bg-[#619D51] text-sm font-bold text-white transition hover:bg-[#528a45] disabled:opacity-60"
              >
                {isApproving ? t('approving') : t('ads.approve')}
              </button>
            ) : null}
            <button
              type="button"
              onClick={startEdit}
              className="admin-border inline-flex h-10 w-full items-center justify-center rounded-xl border bg-white text-sm font-bold text-slate-700 transition hover:bg-slate-50"
            >
              {t('reqsOffers.editRequest')}
            </button>
          </section>
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
        media={galleryMedia}
        initialIndex={previewIndex ?? 0}
        open={previewIndex != null}
        onClose={() => setPreviewIndex(null)}
        isVideoMuted={isVideoMuted}
        onMuteChange={setIsVideoMuted}
        muteLabel="Mute"
        unmuteLabel="Unmute"
        blurLabel={t('ads.blurImage')}
        deleteLabel={t('ads.deleteAd')}
        onBlur={(item) => {
          if (typeof item.id !== 'number') return
          setPreviewIndex(null)
          setBlurTarget({
            id: item.id,
            url: resolveAssetUrl(item.src),
          })
        }}
        onDelete={
          onDeleteImage
            ? (item) => {
                if (typeof item.id !== 'number') return
                onDeleteImage(item.id)
                setPreviewIndex(null)
              }
            : undefined
        }
      />
    </div>
  )
}
