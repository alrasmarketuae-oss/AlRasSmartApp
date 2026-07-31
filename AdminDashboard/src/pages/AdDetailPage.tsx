import { useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import AdDetailView from '../components/ads/AdDetailView'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useReturnToListPath } from '../hooks/useReturnToListPath'
import {
  useApproveProductMutation,
  useDeleteAdminProductImageMutation,
  useDeleteAdminProductVideoMutation,
  useDeleteProductMutation,
  useGetAdminProductDetailQuery,
  useGetAdminProductLookupsQuery,
  useGetCategoriesQuery,
  useRejectProductMutation,
  useUpdateAdminProductMutation,
  useUploadAdminProductImageMutation,
} from '../store'
import { getRtkErrorMessage } from '../utils/rtkError'

export default function AdDetailPage() {
  const { productId = '' } = useParams()
  const navigate = useNavigate()
  const { t } = useAppPreferences()
  const backToListPath = useReturnToListPath('/ads')

  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [deletingImageId, setDeletingImageId] = useState<number | null>(null)
  const [deletingVideoPath, setDeletingVideoPath] = useState<string | null>(null)
  const [isReplacingImage, setIsReplacingImage] = useState(false)

  const { data: product, error, isLoading } = useGetAdminProductDetailQuery(productId, {
    skip: !productId,
  })
  const { data: lookups } = useGetAdminProductLookupsQuery()
  const { data: categoriesData } = useGetCategoriesQuery()

  const categories = useMemo(
    () => (categoriesData?.items ?? []).filter((c) => c.categoryId > 0),
    [categoriesData],
  )

  const [updateProduct, { isLoading: isSaving }] = useUpdateAdminProductMutation()
  const [approveProduct, { isLoading: isApproving }] = useApproveProductMutation()
  const [rejectProduct, { isLoading: isRejecting }] = useRejectProductMutation()
  const [uploadImage, { isLoading: isUploading }] = useUploadAdminProductImageMutation()
  const [deleteImage] = useDeleteAdminProductImageMutation()
  const [deleteVideo] = useDeleteAdminProductVideoMutation()
  const [deleteProduct, { isLoading: isDeleting }] = useDeleteProductMutation()

  if (!productId) {
    navigate('/ads', { replace: true })
    return null
  }

  async function handleSave(payload: {
    nameEn: string
    usdPrice: number
    currency: string
    quantity: number
    descriptionEn: string
    categoryId: number | null
    productTypeName: string
    unitName: string
    supplierNotesEn: string
  }) {
    setActionError(null)
    setSuccessMessage(null)

    try {
      await updateProduct({ productId, body: payload }).unwrap()
      setSuccessMessage(t('ads.saveSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.saveError')))
    }
  }

  async function handleApprove(supplierNotesEn: string) {
    const confirmed = window.confirm(t('ads.approveConfirm'))
    if (!confirmed) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      const result = await approveProduct({ productId, supplierNotesEn }).unwrap()
      setSuccessMessage(result.message || t('ads.approveSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.approveError')))
    }
  }

  async function handleReject(input: { supplierNotesEn: string; supplierNotesAr: string }) {
    const reasonEn = input.supplierNotesEn.trim()
    const reasonAr = input.supplierNotesAr.trim()
    if (!reasonEn && !reasonAr) return

    const confirmed = window.confirm(t('ads.rejectConfirm'))
    if (!confirmed) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      const result = await rejectProduct({
        productId,
        supplierNotesEn: reasonEn || null,
        supplierNotesAr: reasonAr || null,
      }).unwrap()
      setSuccessMessage(result.message || t('ads.rejectSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.rejectError')))
    }
  }

  async function handleUploadImage(file: File) {
    setActionError(null)
    setSuccessMessage(null)

    try {
      await uploadImage({ productId, file }).unwrap()
      setSuccessMessage(t('ads.saveSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.uploadImageError')))
    }
  }

  async function handleDeleteImage(imageId: number) {
    if (!window.confirm(t('ads.deleteImageConfirm'))) return

    setDeletingImageId(imageId)
    setActionError(null)
    setSuccessMessage(null)

    try {
      await deleteImage({ productId, imageId }).unwrap()
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.deleteImageError')))
    } finally {
      setDeletingImageId(null)
    }
  }

  async function handleDeleteVideo(path: string) {
    setDeletingVideoPath(path)
    setActionError(null)
    setSuccessMessage(null)

    try {
      await deleteVideo({ productId, path }).unwrap()
      setSuccessMessage(t('ads.deleteVideoSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.deleteVideoError')))
    } finally {
      setDeletingVideoPath(null)
    }
  }

  async function handleDelete() {
    const confirmed = window.confirm(t('ads.deleteConfirm'))
    if (!confirmed) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      await deleteProduct(productId).unwrap()
      navigate(backToListPath, { state: { adsMessage: t('ads.deleteSuccess') } })
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.deleteError')))
    }
  }

  async function handleReplaceImage(imageId: number, file: File) {
    setIsReplacingImage(true)
    setActionError(null)
    setSuccessMessage(null)

    try {
      await uploadImage({ productId, file }).unwrap()
      await deleteImage({ productId, imageId }).unwrap()
      setSuccessMessage(t('ads.blurSaveSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.blurSaveError')))
      throw err
    } finally {
      setIsReplacingImage(false)
    }
  }

  const emptyLookups = { productTypes: [], units: [] }

  return (
    <div className="space-y-2">
      {successMessage ? (
        <div className="admin-alert-success">{successMessage}</div>
      ) : null}
      {actionError ? <div className="admin-alert-error">{actionError}</div> : null}

      {isLoading ? (
        <div className="flex justify-center py-24">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
        </div>
      ) : error || !product ? (
        <div className="admin-card px-6 py-16 text-center">
          <p className="text-sm text-red-600 dark:text-red-400">
            {getRtkErrorMessage(error as never, t('ads.loadDetailError'))}
          </p>
          <Link
            to={backToListPath}
            className="keep-white mt-4 inline-block rounded-xl bg-[#3B7FC7] px-5 py-2.5 text-sm font-semibold text-white"
          >
            {t('ads.backToList')}
          </Link>
        </div>
      ) : (
        <AdDetailView
          product={product}
          lookups={lookups ?? emptyLookups}
          categories={categories}
          backToListPath={backToListPath}
          isSaving={isSaving}
          isApproving={isApproving}
          isRejecting={isRejecting}
          isUploading={isUploading}
          isReplacingImage={isReplacingImage}
          isDeleting={isDeleting}
          deletingImageId={deletingImageId}
          deletingVideoPath={deletingVideoPath}
          onSave={(payload) => void handleSave(payload)}
          onDelete={() => void handleDelete()}
          onApprove={(notes) => void handleApprove(notes)}
          onReject={(payload) => void handleReject(payload)}
          onUploadImage={(file) => void handleUploadImage(file)}
          onDeleteImage={(imageId) => void handleDeleteImage(imageId)}
          onDeleteVideo={(path) => void handleDeleteVideo(path)}
          onReplaceImage={(imageId, file) => handleReplaceImage(imageId, file)}
        />
      )}
    </div>
  )
}
