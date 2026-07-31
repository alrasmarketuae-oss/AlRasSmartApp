import { useEffect, useMemo, useRef, useState, type ChangeEvent, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { resolveAssetUrl } from '../../lib/assets'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import PendingProductEditPanel from './PendingProductEditPanel'
import ProductVideosPanel from './ProductVideosPanel'
import CountryFlag from '../shared/CountryFlag'
import AdminImageBlurModal from '../shared/AdminImageBlurModal'
import ImageGallery, { type GalleryMediaItem } from '../ui/ImageGallery'
import { downloadAsset, filenameFromAssetPath } from '../../utils/downloadAsset'
import {
  displayAdProductTypeName,
  formatAdAmount,
  formatAdPriceTypeLabel,
  formatPackagingLabel,
} from '../../utils/adsDisplay'
import { parseProductSpecificationItems } from '../../utils/bookingSpecs'
import { localizeProductStatusLabel } from '../../utils/localizedLabels'
import { formatOrderQuantityWithUnit } from '../../utils/ordersDisplay'
import { shippingFromProduct } from '../../utils/productShipping'
import {
  hasDomesticShipping,
  hasInternationalShipping,
} from '../../types/productShipping'
import { shippingTypeKey } from '../../types/productShipping'
import type { AdminProductDetail } from '../../types/adminProduct'
import { useSetAdminProductVideoMuteMutation } from '../../store/adminApi'
import type { CatalogAdDetailViewProps } from './CatalogAdDetailView'

const C = {
  blue: '#3B82F6',
  blueSoft: '#EFF6FF',
  navy: '#0F172A',
  muted: '#94A3B8',
  label: '#94A3B8',
  border: '#E2E8F0',
  page: '#F8FAFC',
  purple: '#8B5CF6',
  purpleBg: '#F5F3FF',
  amberBorder: '#FCD34D',
  amberBg: '#FFFBEB',
  green: '#10B981',
  greenBg: '#ECFDF5',
  red: '#EF4444',
  orange: '#EA580C',
  orangeBg: '#FFF7ED',
}

function countProductGalleryImages(product: AdminProductDetail): number {
  if (product.images.length > 0) return product.images.length
  if (product.imagePaths?.length) return product.imagePaths.length
  if (product.primaryImagePath?.trim()) return 1
  return 0
}

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

function Svg({ d, className = 'h-3.5 w-3.5', paths }: { d?: string; paths?: string[]; className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75} aria-hidden>
      {paths ? (
        paths.map((p) => <path key={p.slice(0, 24)} strokeLinecap="round" strokeLinejoin="round" d={p} />)
      ) : (
        <path strokeLinecap="round" strokeLinejoin="round" d={d!} />
      )}
    </svg>
  )
}

const I = {
  share: (
    <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.75}>
      <circle cx="18" cy="5" r="2.25" />
      <circle cx="6" cy="12" r="2.25" />
      <circle cx="18" cy="19" r="2.25" />
      <path strokeLinecap="round" d="M8.59 13.51 15.42 17.49M15.41 6.51 8.59 10.49" />
    </svg>
  ),
  pdf: <Svg d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m.75 12h3m-3 3h3m-6.75-9h7.5c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-7.5A1.125 1.125 0 0 1 5.25 18.75V7.5c0-.621.504-1.125 1.125-1.125Z" />,
  reject: <Svg d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />,
  edit: <Svg d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L6.832 19.82a4.5 4.5 0 0 1-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 0 1 1.13-1.897L16.863 4.487Z" />,
  upload: <Svg d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5m-13.5-9L12 3m0 0 4.5 4.5M12 3v13.5" />,
  image: <Svg className="h-7 w-7" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Z" />,
  check: <Svg className="h-4 w-4" d="m4.5 12.75 6 6 9-13.5" />,
  checkSm: <Svg className="h-3 w-3" d="m4.5 12.75 6 6 9-13.5" />,
  info: <Svg d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z" />,
  truck: <Svg d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0H21M3.375 14.25h17.25m0 0V9.375c0-.621-.504-1.125-1.125-1.125H4.5A1.125 1.125 0 0 0 3.375 9.375v4.875Z" />,
  doc: <Svg d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z" />,
  user: <Svg d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z" />,
  calendar: <Svg d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />,
  eye: <Svg paths={['M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z', 'M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z']} />,
  clock: <Svg d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />,
  phone: <Svg d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 0 0 2.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 0 1-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 0 0-1.091-.852H4.5A2.25 2.25 0 0 0 2.25 4.5v2.25Z" />,
  mail: <Svg d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75" />,
  play: <Svg className="h-5 w-5" d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.347a1.125 1.125 0 0 1 0 1.972l-11.54 6.347a1.125 1.125 0 0 1-1.667-.986V5.653Z" />,
  package: <Svg d="m21 7.5-9-5.25L3 7.5m18 0-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9" />,
  tag: <Svg d="M9.568 3H5.25A2.25 2.25 0 0 0 3 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 0 0 5.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 0 0 9.568 3Z" />,
  money: <Svg d="M12 6v12m-3-2.818.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />,
  scale: <Svg d="M12 3v17.25m0 0c-1.472 0-2.882.265-4.185.75M12 20.25c1.472 0 2.882.265 4.185.75M18.75 4.97A48.416 48.416 0 0 0 12 4.5c-2.291 0-4.545.16-6.75.47m13.5 0c1.01.143 2.01.317 3 .52m-3-.52 2.62 10.726c.122.499-.106 1.028-.589 1.202a15.933 15.933 0 0 1-8.085 0c-.483-.174-.711-.703-.59-1.202L18.75 4.971Zm-7.5 10.925a2.25 2.25 0 1 0 0-4.5 2.25 2.25 0 0 0 0 4.5Z" />,
}

function Card({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <section className={`overflow-hidden rounded-lg border bg-white shadow-sm ${className}`} style={{ borderColor: C.border }}>
      {children}
    </section>
  )
}

function SectionHead({
  title,
  icon,
  onEdit,
  editLabel,
  extra,
}: {
  title: string
  icon: ReactNode
  onEdit?: () => void
  editLabel?: string
  extra?: ReactNode
}) {
  return (
    <div className="flex items-center justify-between gap-2 border-b px-4 py-2.5" style={{ borderColor: C.border }}>
      <div className="flex min-w-0 flex-wrap items-center gap-2">
        <span
          className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md"
          style={{ backgroundColor: C.blueSoft, color: C.blue }}
        >
          {icon}
        </span>
        <h2 className="text-sm font-bold" style={{ color: C.navy }}>
          {title}
        </h2>
        {extra}
      </div>
      {onEdit ? (
        <button
          type="button"
          onClick={onEdit}
          className="inline-flex items-center gap-1.5 rounded-lg border bg-white px-2.5 py-1 text-[11px] font-bold"
          style={{ borderColor: C.blue, color: C.blue }}
        >
          {I.edit}
          {editLabel}
        </button>
      ) : null}
    </div>
  )
}

function Labeled({
  label,
  children,
  valueColor,
}: {
  label: string
  children: ReactNode
  valueColor?: string
}) {
  return (
    <div className="text-start">
      <p className="text-[12px] font-bold leading-tight" style={{ color: C.navy }}>
        {label}
      </p>
      <div
        className="mt-1 text-[13px] font-normal leading-snug break-words"
        style={{ color: valueColor ?? '#64748B' }}
      >
        {children || '—'}
      </div>
    </div>
  )
}

function Meta({ icon, label, value }: { icon: ReactNode; label: string; value: ReactNode }) {
  return (
    <div className="flex min-w-0 items-center gap-2 text-start">
      <span
        className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full"
        style={{ backgroundColor: C.blueSoft, color: C.blue }}
      >
        {icon}
      </span>
      <div className="min-w-0">
        <p className="text-[11px] font-bold leading-tight" style={{ color: C.navy }}>
          {label}
        </p>
        <p className="truncate text-xs font-normal leading-tight" style={{ color: '#64748B' }}>
          {value}
        </p>
      </div>
    </div>
  )
}

function OverviewTile({
  icon,
  label,
  value,
  bg,
  fg,
}: {
  icon: ReactNode
  label: string
  value: ReactNode
  bg: string
  fg: string
}) {
  return (
    <div
      className="flex min-w-0 flex-1 items-center gap-2.5 rounded-xl border bg-white px-3 py-2.5 shadow-sm"
      style={{ borderColor: C.border }}
    >
      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full" style={{ backgroundColor: bg, color: fg }}>
        {icon}
      </span>
      <div className="min-w-0 text-start">
        <p className="text-[11px] font-bold leading-tight" style={{ color: C.navy }}>
          {label}
        </p>
        <p className="truncate text-xs font-normal leading-tight" style={{ color: '#64748B' }}>
          {value}
        </p>
      </div>
    </div>
  )
}

function OutlineBtn({
  children,
  onClick,
  disabled,
}: {
  children: ReactNode
  onClick?: () => void
  disabled?: boolean
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className="inline-flex h-9 items-center gap-1.5 rounded-lg border bg-white px-3 text-xs font-semibold disabled:opacity-60"
      style={{ borderColor: C.blue, color: C.blue }}
    >
      {children}
    </button>
  )
}

/**
 * Wholesale ad detail — same row structure as BookingAdDetailView.
 */
export default function WholesaleAdDetailView({
  product,
  lookups,
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
  const mainVideoRef = useRef<HTMLVideoElement>(null)
  const [blurTarget, setBlurTarget] = useState<{ id: number; url: string } | null>(null)
  const [previewIndex, setPreviewIndex] = useState<number | null>(null)
  const [editingBasic, setEditingBasic] = useState(false)
  const [selectedImageIndex, setSelectedImageIndex] = useState(0)
  const [selectedVideoIndex, setSelectedVideoIndex] = useState(0)
  const [showVideo, setShowVideo] = useState(() => shouldAutoShowProductVideo(product))

  const [nameEn, setNameEn] = useState(product.name)
  const [usdPrice, setUsdPrice] = useState(String(product.priceUsd || ''))
  const [currency, setCurrency] = useState(product.currency || 'AED')
  const [unitName, setUnitName] = useState(product.unitName)
  const [descriptionEn, setDescriptionEn] = useState(product.description ?? '')
  const [supplierNotesEn, setSupplierNotesEn] = useState(product.supplierNotesEn ?? '')
  const [supplierNotesAr, setSupplierNotesAr] = useState('')
  const [setAdminProductVideoMute] = useSetAdminProductVideoMuteMutation()

  useEffect(() => {
    setNameEn(product.name)
    setUsdPrice(String(product.priceUsd || ''))
    setCurrency(product.currency || 'AED')
    setUnitName(product.unitName)
    setDescriptionEn(product.description ?? '')
    setSupplierNotesEn(product.supplierNotesEn ?? '')
    setSupplierNotesAr('')
    setSelectedImageIndex(0)
    setSelectedVideoIndex(0)
    setShowVideo(shouldAutoShowProductVideo(product))
    setEditingBasic(false)
  }, [product])

  const isRejected = product.statusLabelAr === 'مرفوض'
  const statusLabel = product.isApproved
    ? localizeProductStatusLabel('موافق', locale)
    : isRejected
      ? localizeProductStatusLabel(product.statusLabelAr, locale)
      : product.isEditResubmit
        ? t('ads.editAdRequest')
        : localizeProductStatusLabel(product.statusLabelAr, locale)

  const isBusy = isSaving || isApproving || isRejecting || isUploading || isDeleting
  const typeName = displayAdProductTypeName(product, locale)
  const priceTypeLabel = formatAdPriceTypeLabel(product, t)
  const negotiableLabel =
    product.negotiable === true
      ? t('ads.negotiableYes')
      : product.negotiable === false
        ? t('ads.negotiableNo')
        : t('ads.negotiableUnknown')

  const quantityLabel = formatOrderQuantityWithUnit(product.quantity, product.unitName)
  const priceLabel = formatAdAmount(
    product.priceFormatted?.trim() ||
      `${Number(product.priceUsd || 0).toFixed(2)} ${product.currency || 'AED'}`,
    locale,
  )
  const priceWithUnit = product.unitName ? `${priceLabel} / ${product.unitName}` : priceLabel
  const wholesaleUnitLabel = product.unitName?.trim() || '—'
  const packagingLabel =
    formatPackagingLabel(product.packaging, product.packagingDetails, t, locale) || '—'
  const showRetailPricing =
    Boolean(product.hasRetailPricing) ||
    (product.retailPrice != null && product.retailPrice > 0)
  const retailPriceLabel = showRetailPricing
    ? formatAdAmount(`${Number(product.retailPrice || 0).toFixed(2)} AED`, locale)
    : null
  const retailUnitLabel = product.retailUnitName?.trim() || '—'
  const retailPriceWithUnit =
    retailPriceLabel == null
      ? '—'
      : retailUnitLabel !== '—'
        ? `${retailPriceLabel} / ${retailUnitLabel}`
        : retailPriceLabel
  const retailQuantityLabel =
    product.retailQuantity != null
      ? formatOrderQuantityWithUnit(
          product.retailQuantity,
          product.retailUnitName?.trim() || undefined,
        )
      : '—'
  const retailPackagingLabel =
    formatPackagingLabel(product.retailPackaging, product.retailPackagingDetails, t, locale) ||
    '—'
  const retailDescriptionValue = (product.retailDescription ?? '').trim()
  const categoryLabel =
    product.categoryName?.trim() && product.categoryName.trim() !== '—'
      ? product.categoryName
      : t('ads.allCategories')
  const ownerLabel = product.ownerCompanyName?.trim() || product.ownerName || '—'
  const ownerInitials = ownerLabel.slice(0, 2).toUpperCase()
  const shipping = shippingFromProduct(product)
  const shippingKind = shippingTypeKey(shipping)
  const showShippingSection =
    hasInternationalShipping(shipping) || hasDomesticShipping(shipping)
  const specs = useMemo(
    () => parseProductSpecificationItems(product.description),
    [product.description],
  )
  const descriptionDisplay = product.description?.trim() || '—'

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
  const videos = useMemo(
    () =>
      product.videos.length > 0
        ? product.videos
        : videoPaths.map((path, index) => ({ id: index, path, isMuted: true })),
    [product.videos, videoPaths],
  )
  const galleryMedia = useMemo((): GalleryMediaItem[] => {
    const images = galleryImages.map((image) => ({
      src: image.path,
      kind: 'image' as const,
      id: typeof image.id === 'number' ? image.id : undefined,
      path: image.path,
    }))
    const videoMedia = videos.map((video) => ({
      src: video.path,
      kind: 'video' as const,
      path: video.path,
      isMuted: video.isMuted,
    }))
    return [...images, ...videoMedia]
  }, [galleryImages, videos])
  const activeVideoPath = videoPaths[selectedVideoIndex] ?? videoPaths[0] ?? null
  const activeVideoMuted = videos[selectedVideoIndex]?.isMuted ?? videos[0]?.isMuted ?? true
  const videoUrl = activeVideoPath ? resolveAssetUrl(activeVideoPath) : null
  const mainImage = galleryImages[selectedImageIndex] ?? galleryImages[0]
  const mainUrl = mainImage ? resolveAssetUrl(mainImage.path) : null

  useEffect(() => {
    if (!showVideo || !videoUrl) return
    const video = mainVideoRef.current
    if (!video) return
    video.muted = activeVideoMuted
    void video.play().catch(() => undefined)
  }, [showVideo, videoUrl, activeVideoMuted])

  const routeText =
    shipping.shippingRouteSummary?.trim() ||
    (shipping.originCountryName || shipping.destinationCountryName
      ? `From ${shipping.originCountryName || '—'}${
          shipping.loadingPortName ? ` (${shipping.loadingPortName})` : ''
        } -> to ${shipping.destinationCountryName || '—'}${
          shipping.arrivalPortName ? ` (${shipping.arrivalPortName})` : ''
        }`
      : '—')

  const shippingDurationLabel = product.shippingDuration?.trim() || '—'
  const shippingNotesLabel = product.shippingDescription?.trim() || t('ads.none')

  function handleSaveBasic() {
    const price = Number.parseFloat(usdPrice)
    if (!nameEn.trim() || Number.isNaN(price) || price < 0) return
    onSave({
      nameEn: nameEn.trim(),
      usdPrice: price,
      currency,
      quantity: product.quantity,
      descriptionEn: descriptionEn.trim(),
      categoryId: product.categoryId ?? null,
      productTypeName: '',
      unitName,
      supplierNotesEn: supplierNotesEn.trim(),
    })
    setEditingBasic(false)
  }

  function handleMuteChange(path: string, isMuted: boolean) {
    void setAdminProductVideoMute({ productId: product.productId, path, isMuted })
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
      /* parent */
    }
  }

  const canBlurMainImage =
    !showVideo &&
    mainImage != null &&
    typeof mainImage.id === 'number' &&
    Boolean(mainUrl) &&
    Boolean(onReplaceImage)

  const statusCard = (
    <Card className="h-full">
      <div className="border-b px-3 py-2" style={{ borderColor: C.border }}>
        <h2 className="text-start text-xs font-bold" style={{ color: C.navy }}>
          {t('ads.adStatusCard')}
        </h2>
      </div>
      <div className="space-y-2 px-3 py-2.5 text-start">
        <div className="flex items-center gap-2.5">
          <span
            className="flex h-10 w-10 items-center justify-center rounded-full"
            style={{
              backgroundColor: product.isApproved ? C.greenBg : isRejected ? '#FEF2F2' : '#FFFBEB',
              color: product.isApproved ? C.green : isRejected ? C.red : '#D97706',
            }}
          >
            {product.isApproved ? I.check : '!'}
          </span>
          <div>
            <p className="text-[10px]" style={{ color: C.label }}>
              {t('ads.currentStatus')}
            </p>
            <p
              className="text-xs font-bold"
              style={{ color: product.isApproved ? C.green : isRejected ? C.red : '#D97706' }}
            >
              {statusLabel}
            </p>
          </div>
        </div>
        <div className="flex justify-between border-t pt-1.5 text-[10px]" style={{ borderColor: C.border }}>
          <span className="font-bold" style={{ color: C.navy }}>{t('ads.adCreatedAt')}</span>
          <span className="font-normal" style={{ color: '#64748B' }}>
            {formatPostedAt(product.createdAt, locale)}
          </span>
        </div>
        <div className="flex justify-between border-t pt-1.5 text-[10px]" style={{ borderColor: C.border }}>
          <span className="font-bold" style={{ color: C.navy }}>{t('ads.views')}</span>
          <span className="font-normal" style={{ color: '#64748B' }}>
            {product.viewsCount ?? 0}
          </span>
        </div>
      </div>
    </Card>
  )

  const supplierCard = (
    <Card className="h-full">
      <div className="border-b px-3 py-2" style={{ borderColor: C.border }}>
        <h2 className="text-start text-xs font-bold" style={{ color: C.navy }}>
          {t('ads.supplierInfo')}
        </h2>
      </div>
      <div className="space-y-2 px-3 py-2.5 text-start">
        <div className="flex items-center gap-2.5">
          <span
            className="flex h-10 w-10 items-center justify-center rounded-full text-xs font-bold"
            style={{ backgroundColor: C.blueSoft, color: C.blue }}
          >
            {ownerInitials}
          </span>
          <p className="line-clamp-2 text-xs font-normal leading-tight" style={{ color: '#64748B' }}>
            {ownerLabel}
          </p>
        </div>
        <div className="space-y-1.5 border-t pt-2 text-xs" style={{ borderColor: C.border }}>
          <p className="flex items-center gap-1.5" dir="ltr">
            <span style={{ color: C.blue }}>{I.phone}</span>
            <span className="font-normal" style={{ color: '#64748B' }}>
              {product.ownerPhone?.trim() || '—'}
            </span>
          </p>
          <p className="flex items-center gap-1.5 break-all">
            <span style={{ color: C.blue }}>{I.mail}</span>
            <span className="font-normal" style={{ color: '#64748B' }}>
              {product.ownerEmail || '—'}
            </span>
          </p>
          <p className="flex items-center gap-1.5">
            <CountryFlag city={product.ownerCity} phone={product.ownerPhone} size={20} />
            <span className="font-normal" style={{ color: '#64748B' }}>
              {product.ownerCity?.trim() || '—'}
            </span>
          </p>
        </div>
      </div>
    </Card>
  )

  return (
    <div className="wholesale-ad-fit origin-top space-y-3.5">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="min-w-0 text-start">
          <p className="text-[10px] leading-tight" style={{ color: C.muted }}>
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
          <div className="mt-1 flex flex-wrap items-center gap-2.5">
            <Link
              to={backToListPath}
              className="inline-flex items-center gap-1 text-[11px] font-semibold transition hover:text-[#2563eb]"
              style={{ color: C.muted }}
            >
              <span aria-hidden>←</span>
              {t('ads.backToAds')}
            </Link>
            <h1 className="text-xl font-bold tracking-tight" style={{ color: C.navy }}>
              {t('ads.adDetails')} — {product.name}
            </h1>
            <span
              className="inline-flex rounded-full px-2.5 py-1 text-[11px] font-bold"
              style={{
                backgroundColor: product.isApproved ? C.greenBg : isRejected ? '#FEF2F2' : '#FFFBEB',
                color: product.isApproved ? C.green : isRejected ? C.red : '#D97706',
              }}
            >
              {statusLabel}
            </span>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-1.5 print:hidden">
          <OutlineBtn onClick={handleShare}>
            {I.share}
            {t('ads.share')}
          </OutlineBtn>
          <OutlineBtn onClick={() => window.print()}>
            {I.pdf}
            {t('ads.downloadPdf')}
          </OutlineBtn>
          {!product.isApproved && !isRejected ? (
            <button
              type="button"
              disabled={isBusy}
              onClick={() => onApprove(supplierNotesEn.trim())}
              className="inline-flex h-9 items-center gap-1.5 rounded-lg px-3.5 text-xs font-bold text-white disabled:opacity-60"
              style={{ backgroundColor: C.green }}
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
              className="inline-flex h-9 items-center gap-1.5 rounded-lg px-3.5 text-xs font-bold text-white disabled:opacity-60"
              style={{ backgroundColor: C.red }}
            >
              {I.reject}
              {isRejecting ? t('ads.rejecting') : t('ads.rejectAd')}
            </button>
          ) : null}
          {onDelete ? (
            <button
              type="button"
              disabled={isBusy}
              onClick={onDelete}
              className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-red-300 bg-red-600 px-3.5 text-xs font-bold text-white disabled:opacity-60"
            >
              {isDeleting ? t('ads.deleting') : t('ads.deleteAd')}
            </button>
          ) : null}
        </div>
      </div>

      {product.pendingEdit && !product.isApproved && !isRejected ? (
        <PendingProductEditPanel pendingEdit={product.pendingEdit} />
      ) : null}

      {/* ROW 1: Hero (gallery + stats) | Status + Supplier */}
      <div className="grid grid-cols-1 gap-3.5 xl:grid-cols-[minmax(0,1.55fr)_minmax(340px,1fr)]">
        <Card>
          <div className="grid gap-4 p-4 sm:grid-cols-[170px_minmax(0,1fr)]">
            {/* Gallery */}
            <div className="flex flex-col gap-2">
              <div
                className="overflow-hidden rounded-xl border"
                style={{ borderColor: C.border, backgroundColor: C.page }}
              >
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
                      className="pointer-events-none max-h-32 w-full bg-black object-contain"
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
                    <img src={mainUrl} alt={product.name} className="max-h-32 w-full object-cover" />
                  </button>
                ) : (
                  <div className="flex min-h-[120px] flex-col items-center justify-center gap-2 py-4 text-center">
                    <span style={{ color: '#CBD5E1' }}>{I.image}</span>
                    <p className="text-xs font-medium" style={{ color: C.muted }}>
                      {t('ads.noImageUploaded')}
                    </p>
                  </div>
                )}
              </div>

              {!showVideo && mainUrl && mainImage ? (
                <div className="flex flex-wrap gap-1 print:hidden">
                  <button
                    type="button"
                    disabled={isBusy}
                    onClick={() => setPreviewIndex(selectedImageIndex)}
                    className="rounded border px-2 py-0.5 text-[9px] font-semibold"
                    style={{ borderColor: C.border, color: C.navy }}
                  >
                    {t('ads.preview')}
                  </button>
                  <button
                    type="button"
                    disabled={isBusy}
                    onClick={() => void handleDownload(mainUrl, mainImage.path)}
                    className="rounded border px-2 py-0.5 text-[9px] font-semibold"
                    style={{ borderColor: C.border, color: C.blue }}
                  >
                    {t('ads.downloadImage')}
                  </button>
                  {canBlurMainImage ? (
                    <button
                      type="button"
                      disabled={isBusy || isReplacingImage}
                      onClick={() => setBlurTarget({ id: mainImage.id as number, url: mainUrl })}
                      className="rounded border px-2 py-0.5 text-[9px] font-semibold"
                      style={{ borderColor: C.border, color: C.muted }}
                    >
                      {t('ads.blurImage')}
                    </button>
                  ) : null}
                </div>
              ) : null}

              {showVideo && videoUrl && activeVideoPath ? (
                <div className="flex flex-wrap gap-1 print:hidden">
                  <button
                    type="button"
                    disabled={isBusy}
                    onClick={() =>
                      setPreviewIndex(galleryImages.length + selectedVideoIndex)
                    }
                    className="rounded border px-2 py-0.5 text-[9px] font-semibold"
                    style={{ borderColor: C.border, color: C.navy }}
                  >
                    {t('ads.preview')}
                  </button>
                  <button
                    type="button"
                    disabled={isBusy}
                    onClick={() => void handleDownload(videoUrl, activeVideoPath)}
                    className="rounded border px-2 py-0.5 text-[9px] font-semibold"
                    style={{ borderColor: C.border, color: C.blue }}
                  >
                    {t('ads.downloadVideo')}
                  </button>
                </div>
              ) : null}

              <div className="flex flex-wrap gap-1">
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
                        setPreviewIndex(galleryImages.length + index)
                      }}
                      className={`flex h-8 w-8 items-center justify-center rounded bg-slate-900 text-[10px] text-white ring-2 ${
                        selected ? 'ring-[#2563eb]' : 'ring-transparent'
                      }`}
                      title={`${t('ads.productVideo')} ${index + 1}`}
                    >
                      ▶
                      {videoPaths.length > 1 ? (
                        <span className="ms-0.5 text-[8px] font-bold">{index + 1}</span>
                      ) : null}
                    </button>
                  )
                })}
                <button
                  type="button"
                  disabled={isBusy}
                  onClick={() => fileInputRef.current?.click()}
                  className="flex h-8 w-8 flex-col items-center justify-center rounded border border-dashed text-[8px] font-bold transition hover:border-[#3B7FC7] hover:text-[#3B7FC7] disabled:opacity-60"
                  style={{ borderColor: C.border, color: C.muted }}
                >
                  <span className="text-sm leading-none">+</span>
                  {isUploading ? '…' : null}
                </button>
              </div>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/png,image/jpeg,image/jpg,image/webp"
                className="hidden"
                onChange={handleFileChange}
              />
            </div>

            {/* Summary stat cards */}
            <div className="min-w-0 text-start">
              <div className="flex flex-wrap items-center gap-1.5">
                <h2 className="text-xl font-bold" style={{ color: C.navy }}>
                  {product.name}
                </h2>
                <span
                  className="rounded-md px-2 py-0.5 text-[10px] font-bold"
                  style={{ backgroundColor: C.blueSoft, color: C.blue }}
                >
                  {typeName}
                </span>
                {showRetailPricing ? (
                  <span
                    className="rounded-md px-2 py-0.5 text-[10px] font-bold"
                    style={{ backgroundColor: C.greenBg, color: C.green }}
                  >
                    {locale === 'ar' ? 'تجزئة' : 'Retail'}
                  </span>
                ) : null}
                {priceTypeLabel !== '—' ? (
                  <span
                    className="rounded-md px-2 py-0.5 text-[10px] font-bold"
                    style={{ backgroundColor: C.purpleBg, color: C.purple }}
                  >
                    {priceTypeLabel}
                  </span>
                ) : null}
              </div>

              <div className="mt-3 grid gap-x-3 gap-y-2.5 sm:grid-cols-2 lg:grid-cols-3">
                <Meta icon={I.money} label={t('ads.wholesalePrice')} value={priceWithUnit} />
                <Meta icon={I.package} label={t('ads.wholesaleQuantity')} value={quantityLabel} />
                <Meta icon={I.scale} label={t('ads.wholesaleUnit')} value={wholesaleUnitLabel} />
                <Meta icon={I.package} label={t('ads.packagingType')} value={packagingLabel} />
                <Meta icon={I.tag} label={t('ads.requestFulfillment')} value={priceTypeLabel} />
                <Meta icon={I.doc} label={t('ads.category')} value={categoryLabel} />
                <Meta icon={I.checkSm} label={t('ads.negotiable')} value={negotiableLabel} />
              </div>
            </div>
          </div>

          <div
            className="grid gap-2 border-t px-3 py-2 sm:grid-cols-2 lg:grid-cols-4"
            style={{ borderColor: C.border }}
          >
            <Meta icon={I.doc} label={t('ads.adType')} value={typeName} />
            <Meta icon={I.user} label={t('ads.postedBy')} value={ownerLabel} />
            <Meta
              icon={I.calendar}
              label={t('ads.adCreatedAt')}
              value={formatPostedAt(product.createdAt, locale)}
            />
            <Meta icon={I.eye} label={t('ads.views')} value={String(product.viewsCount ?? 0)} />
          </div>
        </Card>

        <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
          {statusCard}
          {supplierCard}
        </div>
      </div>

      {/* ROW 2: Wholesale Info (+ Retail when hybrid) | Video + Admin Notes */}
      <div className="grid grid-cols-1 gap-3.5 xl:grid-cols-[minmax(0,1.55fr)_minmax(340px,1fr)]">
        <div className="flex min-w-0 flex-col gap-3.5">
        <Card>
          <SectionHead
            title={showRetailPricing ? t('ads.wholesalePricing') : t('ads.basicInfo')}
            icon={I.info}
            editLabel={editingBasic ? t('cancel') : t('ads.edit')}
            onEdit={() => {
              if (editingBasic) {
                setNameEn(product.name)
                setUsdPrice(String(product.priceUsd || ''))
                setDescriptionEn(product.description ?? '')
                setUnitName(product.unitName)
                setCurrency(product.currency || 'AED')
              }
              setEditingBasic((v) => !v)
            }}
          />
          <div className="p-4">
            {editingBasic ? (
              <div className="space-y-2">
                <input
                  value={nameEn}
                  onChange={(e) => setNameEn(e.target.value)}
                  className="w-full rounded border px-2 py-1 text-[11px] font-semibold"
                  style={{ borderColor: C.border }}
                  placeholder={t('ads.productName')}
                />
                <textarea
                  value={descriptionEn}
                  onChange={(e) => setDescriptionEn(e.target.value)}
                  rows={2}
                  className="w-full rounded border px-2 py-1 text-[11px] font-semibold"
                  style={{ borderColor: C.border }}
                  placeholder={t('ads.productDescription')}
                />
                <div className="flex gap-2">
                  <input
                    type="number"
                    min={0}
                    step="0.01"
                    value={usdPrice}
                    onChange={(e) => setUsdPrice(e.target.value)}
                    className="w-full rounded border px-2 py-1 text-[11px] font-semibold"
                    style={{ borderColor: C.border }}
                  />
                  <select
                    value={`${currency}|${unitName}`}
                    onChange={(e) => {
                      const [c, u] = e.target.value.split('|')
                      setCurrency(c)
                      setUnitName(u)
                    }}
                    className="rounded border px-1 py-1 text-[10px] font-bold"
                    style={{ borderColor: C.border }}
                  >
                    {lookups.units.map((unit) => (
                      <option key={unit.id} value={`AED|${unit.name}`}>
                        AED / {unit.name}
                      </option>
                    ))}
                    {lookups.units.map((unit) => (
                      <option key={`usd-${unit.id}`} value={`USD|${unit.name}`}>
                        USD / {unit.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="flex justify-end">
                  <button
                    type="button"
                    disabled={isBusy}
                    onClick={handleSaveBasic}
                    className="rounded px-3 py-1 text-[10px] font-bold text-white disabled:opacity-60"
                    style={{ backgroundColor: C.blue }}
                  >
                    {isSaving ? t('ads.saving') : t('ads.saveChanges')}
                  </button>
                </div>
              </div>
            ) : (
              <div className="grid gap-3 lg:grid-cols-[minmax(0,1.5fr)_minmax(150px,0.85fr)]">
                <div className="grid grid-cols-3 gap-x-3 gap-y-2">
                  <div className="space-y-2">
                    <Labeled label={t('ads.productName')}>{product.name}</Labeled>
                    <Labeled label={t('ads.productDescription')}>{descriptionDisplay}</Labeled>
                  </div>
                  <div className="space-y-2">
                    <Labeled label={t('ads.wholesalePrice')}>{priceWithUnit}</Labeled>
                    <Labeled label={t('ads.wholesaleUnit')}>{wholesaleUnitLabel}</Labeled>
                    <Labeled label={t('ads.wholesaleQuantity')}>{quantityLabel}</Labeled>
                    <Labeled label={t('ads.packagingType')}>{packagingLabel}</Labeled>
                  </div>
                  <div className="space-y-2">
                    <Labeled label={t('ads.category')}>{categoryLabel}</Labeled>
                    <Labeled label={t('ads.negotiable')}>
                      <span className="inline-flex items-center gap-0.5">
                        {product.negotiable === true ? (
                          <span style={{ color: C.green }}>{I.checkSm}</span>
                        ) : null}
                        {negotiableLabel}
                      </span>
                    </Labeled>
                    <Labeled label={t('ads.adType')}>{typeName}</Labeled>
                  </div>
                </div>

                <div className="space-y-2">
                  <div className="rounded-lg px-2.5 py-2" style={{ backgroundColor: C.purpleBg }}>
                    <div className="mb-0.5 flex items-center gap-1" style={{ color: C.navy }}>
                      {I.tag}
                      <p className="text-[11px] font-bold">{t('ads.requestFulfillment')}</p>
                    </div>
                    <p className="text-xs font-normal" style={{ color: '#64748B' }}>
                      {priceTypeLabel}
                    </p>
                  </div>
                  <div
                    className="rounded-lg border px-3 py-2.5 text-start"
                    style={{ borderColor: C.amberBorder, backgroundColor: C.amberBg }}
                  >
                    <p className="mb-1.5 text-xs font-bold" style={{ color: C.navy }}>
                      {t('ads.productSpecifications')}
                    </p>
                    {specs.length > 0 ? (
                      <ul className="space-y-1">
                        {specs.map((item, index) =>
                          typeof item === 'string' ? (
                            <li
                              key={`${item}-${index}`}
                              className="text-[11px] font-normal whitespace-pre-wrap"
                              style={{ color: '#64748B' }}
                            >
                              {item}
                            </li>
                          ) : (
                            <li key={`${item.label}-${index}`} className="flex justify-between gap-2 text-[11px]">
                              <span className="font-bold" style={{ color: C.navy }}>
                                {item.label}
                              </span>
                              <span className="font-normal" style={{ color: '#64748B' }}>
                                {item.value}
                              </span>
                            </li>
                          ),
                        )}
                      </ul>
                    ) : (
                      <p className="text-[11px] font-normal whitespace-pre-wrap" style={{ color: '#64748B' }}>
                        {descriptionDisplay}
                      </p>
                    )}
                  </div>
                </div>
              </div>
            )}
          </div>
        </Card>

        {showRetailPricing ? (
          <Card>
            <SectionHead title={t('ads.retailPricing')} icon={I.money} />
            <div className="grid grid-cols-2 gap-3 p-4 sm:grid-cols-3">
              <Labeled label={t('ads.retailPrice')}>{retailPriceWithUnit}</Labeled>
              <Labeled label={t('ads.retailUnit')}>{retailUnitLabel}</Labeled>
              <Labeled label={t('ads.retailQuantity')}>{retailQuantityLabel}</Labeled>
              <Labeled label={t('ads.retailPackagingType')}>{retailPackagingLabel}</Labeled>
              {retailDescriptionValue ? (
                <div className="col-span-full">
                  <Labeled label={t('ads.retailProductDescription')}>
                    {retailDescriptionValue}
                  </Labeled>
                </div>
              ) : null}
            </div>
          </Card>
        ) : null}
        </div>

        <div className="flex flex-col gap-2">
          <Card>
            <div className="border-b px-2.5 py-1.5" style={{ borderColor: C.border }}>
              <h2 className="text-start text-[11px] font-bold" style={{ color: C.navy }}>
                {t('ads.productVideo')}
              </h2>
            </div>
            <ProductVideosPanel
              videos={videos}
              selectedIndex={selectedVideoIndex}
              onSelectedIndexChange={setSelectedVideoIndex}
              onMuteChange={handleMuteChange}
              muteLabel={t('ads.muteVideoInApp')}
              muteHint={t('ads.muteVideoInAppHint')}
              emptyLabel={t('ads.noVideo')}
              isBusy={isBusy}
              onDeleteVideo={onDeleteVideo}
              deleteLabel={t('ads.deleteVideo')}
              deletingPath={deletingVideoPath}
            />
          </Card>

          <Card className="flex-1">
            <div className="border-b px-2.5 py-1.5" style={{ borderColor: C.border }}>
              <h2 className="text-start text-[11px] font-bold" style={{ color: C.navy }}>
                {t('ads.adminNotes')}
              </h2>
            </div>
            <div className="grid gap-1.5 px-2.5 py-2 sm:grid-cols-2">
              <div>
                <p className="mb-0.5 text-[9px] font-medium" style={{ color: C.label }}>
                  {t('ads.rejectReasonEn')}
                </p>
                <textarea
                  value={supplierNotesEn}
                  onChange={(e) => setSupplierNotesEn(e.target.value)}
                  rows={2}
                  placeholder={t('ads.rejectReasonEnPlaceholder')}
                  className="w-full resize-none rounded border px-2 py-1 text-[10px] outline-none"
                  style={{ borderColor: C.border }}
                />
              </div>
              <div>
                <p className="mb-0.5 text-[9px] font-medium" style={{ color: C.label }}>
                  {t('ads.rejectReasonAr')}
                </p>
                <textarea
                  value={supplierNotesAr}
                  onChange={(e) => setSupplierNotesAr(e.target.value)}
                  rows={2}
                  placeholder={t('ads.rejectReasonArPlaceholder')}
                  className="w-full resize-none rounded border px-2 py-1 text-[10px] outline-none"
                  style={{ borderColor: C.border }}
                />
              </div>
            </div>
          </Card>
        </div>
      </div>

      {/* ROW 3: Additional Info | Shipping (optional) */}
      <div
        className={`grid grid-cols-1 gap-3.5 ${
          showShippingSection ? 'xl:grid-cols-[minmax(0,1.55fr)_minmax(340px,1fr)]' : ''
        }`}
      >
        <Card>
          <SectionHead title={t('ads.additionalInfo')} icon={I.doc} editLabel={t('ads.edit')} onEdit={() => undefined} />
          <div className="grid grid-cols-2 gap-3 p-4 sm:grid-cols-3 lg:grid-cols-6">
            <Labeled label={t('ads.adType')}>{typeName}</Labeled>
            <Labeled label={t('ads.currentStatus')}>
              <span style={{ color: product.isApproved ? C.green : isRejected ? C.red : '#D97706' }}>
                {statusLabel}
              </span>
            </Labeled>
            <Labeled label={t('ads.postedBy')}>{ownerLabel}</Labeled>
            <Labeled label={t('ads.adCreatedAt')}>{formatPostedAt(product.createdAt, locale)}</Labeled>
            <Labeled label={t('ads.lastUpdated')}>
              {formatPostedAt(product.updatedAt || product.createdAt, locale)}
            </Labeled>
            <Labeled label={t('ads.wholesalePrice')}>{priceWithUnit}</Labeled>
            {showRetailPricing ? (
              <Labeled label={t('ads.retailPrice')}>{retailPriceWithUnit}</Labeled>
            ) : null}
          </div>
        </Card>

        {showShippingSection ? (
          <Card>
            <SectionHead
              title={t('ads.shippingDetails')}
              icon={I.truck}
              editLabel={t('ads.edit')}
              onEdit={() => undefined}
              extra={
                <span
                  className="rounded-full px-1.5 py-0.5 text-[8px] font-bold"
                  style={{
                    backgroundColor: shippingKind === 'domestic' ? C.greenBg : C.blueSoft,
                    color: shippingKind === 'domestic' ? C.green : C.blue,
                  }}
                >
                  {shippingKind === 'domestic'
                    ? t('sharedShipping.typeDomestic')
                    : t('sharedShipping.typeInternational')}
                </span>
              }
            />
            <div className="space-y-2.5 p-4 text-start">
              <p className="text-xs font-normal leading-snug" style={{ color: '#64748B' }}>
                {routeText}
              </p>
              <div className="flex items-stretch gap-1.5">
                <div
                  className="flex-1 rounded-lg border border-dashed px-2 py-1.5"
                  style={{ borderColor: C.border, backgroundColor: C.page }}
                >
                  <p className="text-[10px] font-bold uppercase" style={{ color: C.navy }}>
                    {t('ads.originCountry')}
                  </p>
                  <p className="mt-0.5 flex items-center gap-1 text-[11px] font-normal" style={{ color: '#64748B' }}>
                    <CountryFlag countryName={shipping.originCountryName} size={20} />
                    {shipping.originCountryName?.trim() || '—'}
                  </p>
                  <p className="mt-1 text-[10px] font-bold uppercase" style={{ color: C.navy }}>
                    {t('ads.loadingPort')}
                  </p>
                  <p className="text-[11px] font-normal" style={{ color: '#64748B' }}>
                    {shipping.loadingPortName?.trim() || '—'}
                  </p>
                </div>
                <span className="self-center text-slate-300 rtl:rotate-180">→</span>
                <div
                  className="flex-1 rounded-lg border border-dashed px-2 py-1.5"
                  style={{ borderColor: C.border, backgroundColor: C.page }}
                >
                  <p className="text-[10px] font-bold uppercase" style={{ color: C.navy }}>
                    {t('ads.destinationCountry')}
                  </p>
                  <p className="mt-0.5 flex items-center gap-1 text-[11px] font-normal" style={{ color: '#64748B' }}>
                    <CountryFlag countryName={shipping.destinationCountryName} size={20} />
                    {shipping.destinationCountryName?.trim() || '—'}
                  </p>
                  <p className="mt-1 text-[10px] font-bold uppercase" style={{ color: C.navy }}>
                    {t('ads.arrivalPort')}
                  </p>
                  <p className="text-[11px] font-normal" style={{ color: '#64748B' }}>
                    {shipping.arrivalPortName?.trim() || '—'}
                  </p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2 border-t pt-1.5" style={{ borderColor: C.border }}>
                <div className="flex items-start gap-1">
                  <span style={{ color: C.muted }}>{I.clock}</span>
                  <div>
                    <p className="text-[10px] font-bold" style={{ color: C.navy }}>
                      {t('ads.shippingDuration')}
                    </p>
                    <p className="text-[11px] font-normal" style={{ color: '#64748B' }}>
                      {shippingDurationLabel}
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-1">
                  <span style={{ color: C.muted }}>{I.package}</span>
                  <div>
                    <p className="text-[10px] font-bold" style={{ color: C.navy }}>
                      {t('ads.shippingNotes')}
                    </p>
                    <p className="text-[11px] font-normal" style={{ color: '#64748B' }}>
                      {shippingNotesLabel}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </Card>
        ) : null}
      </div>

      {/* Quick Overview */}
      <div className="space-y-2">
        <h2 className="text-start text-sm font-bold" style={{ color: C.navy }}>
          {t('ads.quickOverview')}
        </h2>
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 xl:grid-cols-8">
          <OverviewTile
            icon={I.money}
            label={t('ads.wholesalePrice')}
            value={priceWithUnit}
            bg={C.blueSoft}
            fg={C.blue}
          />
          <OverviewTile
            icon={I.package}
            label={t('ads.wholesaleQuantity')}
            value={quantityLabel}
            bg={C.blueSoft}
            fg={C.blue}
          />
          <OverviewTile
            icon={I.scale}
            label={t('ads.wholesaleUnit')}
            value={wholesaleUnitLabel}
            bg={C.orangeBg}
            fg={C.orange}
          />
          <OverviewTile
            icon={I.package}
            label={t('ads.packagingType')}
            value={packagingLabel}
            bg={C.orangeBg}
            fg={C.orange}
          />
          {showRetailPricing ? (
            <>
              <OverviewTile
                icon={I.money}
                label={t('ads.retailPrice')}
                value={retailPriceWithUnit}
                bg={C.greenBg}
                fg={C.green}
              />
              <OverviewTile
                icon={I.scale}
                label={t('ads.retailUnit')}
                value={retailUnitLabel}
                bg={C.greenBg}
                fg={C.green}
              />
              <OverviewTile
                icon={I.package}
                label={t('ads.retailQuantity')}
                value={retailQuantityLabel}
                bg={C.greenBg}
                fg={C.green}
              />
            </>
          ) : null}
          <OverviewTile
            icon={I.tag}
            label={t('ads.requestFulfillment')}
            value={priceTypeLabel}
            bg={C.purpleBg}
            fg={C.purple}
          />
          <OverviewTile icon={I.doc} label={t('ads.category')} value={categoryLabel} bg={C.blueSoft} fg={C.blue} />
          <OverviewTile
            icon={I.checkSm}
            label={t('ads.negotiable')}
            value={negotiableLabel}
            bg={C.greenBg}
            fg={C.green}
          />
          <OverviewTile icon={I.eye} label={t('ads.views')} value={String(product.viewsCount ?? 0)} bg={C.blueSoft} fg={C.blue} />
        </div>
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
        onMuteChange={(item, isMuted) => {
          if (item.path) handleMuteChange(item.path, isMuted)
        }}
        muteLabel="Mute"
        unmuteLabel="Unmute"
        blurLabel={t('ads.blurImage')}
        deleteLabel={t('orders.deleteImage')}
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
