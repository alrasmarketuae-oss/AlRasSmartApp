import { useMemo, useRef, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import AdDetailView from '../components/ads/AdDetailView'
import AdEditDialog from '../components/ads/AdEditDialog'
import RejectAdReasonDialog from '../components/ads/RejectAdReasonDialog'
import type { AdminUpdateProductPayload } from '../types/adminProduct'
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
  useUploadAdminProductVideoMutation,
} from '../store'
import AdminVideoTrimModal from '../components/shared/AdminVideoTrimModal'
import { getRtkErrorMessage } from '../utils/rtkError'

export default function AdDetailPage() {
  const { productId = '' } = useParams()
  const navigate = useNavigate()
  const { t, locale } = useAppPreferences()
  const backToListPath = useReturnToListPath('/ads')

  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [deletingImageId, setDeletingImageId] = useState<number | null>(null)
  const [deletingVideoPath, setDeletingVideoPath] = useState<string | null>(null)
  const [trimTarget, setTrimTarget] = useState<{
    path: string
    durationSeconds?: number | null
  } | null>(null)
  const queuedTrimRef = useRef<{
    path: string
    durationSeconds?: number | null
  } | null>(null)
  const [backgroundTrimPath, setBackgroundTrimPath] = useState<string | null>(null)
  const [isReplacingImage, setIsReplacingImage] = useState(false)
  const [showEdit, setShowEdit] = useState(false)
  const [rejectDialogOpen, setRejectDialogOpen] = useState(false)
  const [rejectDraft, setRejectDraft] = useState({
    supplierNotesEn: '',
    supplierNotesAr: '',
  })

  const { data: product, error, isLoading } = useGetAdminProductDetailQuery(
    { productId, lang: locale },
    { skip: !productId },
  )
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
  const [uploadProductVideo, { isLoading: isTrimmingVideo }] =
    useUploadAdminProductVideoMutation()
  const [deleteProduct, { isLoading: isDeleting }] = useDeleteProductMutation()

  if (!productId) {
    navigate('/ads', { replace: true })
    return null
  }

  async function handleSave(payload: AdminUpdateProductPayload): Promise<boolean> {
    setActionError(null)
    setSuccessMessage(null)

    try {
      await updateProduct({ productId, body: payload }).unwrap()
      setSuccessMessage(t('ads.saveSuccess'))
      return true
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.saveError')))
      return false
    }
  }

  async function handleFullEditSubmit(payload: AdminUpdateProductPayload) {
    const ok = await handleSave(payload)
    if (ok) setShowEdit(false)
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

  function openRejectDialog(input: { supplierNotesEn: string; supplierNotesAr: string }) {
    setRejectDraft({
      supplierNotesEn: input.supplierNotesEn.trim(),
      supplierNotesAr: input.supplierNotesAr.trim(),
    })
    setRejectDialogOpen(true)
  }

  async function handleReject(input: { supplierNotesEn: string; supplierNotesAr: string }) {
    const reasonEn = input.supplierNotesEn.trim()
    const reasonAr = input.supplierNotesAr.trim()
    if (!reasonEn && !reasonAr) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      const result = await rejectProduct({
        productId,
        supplierNotesEn: reasonEn || null,
        supplierNotesAr: reasonAr || null,
      }).unwrap()
      setRejectDialogOpen(false)
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

  function handleTrimQueued() {
    queuedTrimRef.current = trimTarget
    setBackgroundTrimPath(trimTarget?.path ?? null)
    setActionError(null)
    setSuccessMessage(t('ads.trimVideoProcessing'))
  }

  function handleTrimFailed(message: string) {
    queuedTrimRef.current = null
    setBackgroundTrimPath(null)
    setSuccessMessage(null)
    setActionError(message)
  }

  async function handleTrimSave(file: File, durationSeconds: number) {
    const target = queuedTrimRef.current
    if (!target) return

    setActionError(null)

    try {
      await uploadProductVideo({
        productId,
        file,
        videoDurationSeconds: durationSeconds,
        replaceVideoPath: target.path,
      }).unwrap()
      setSuccessMessage(t('ads.trimVideoSaveSuccess'))
    } catch (err) {
      setSuccessMessage(null)
      setActionError(getRtkErrorMessage(err as never, t('ads.trimVideoSaveError')))
    } finally {
      queuedTrimRef.current = null
      setBackgroundTrimPath(null)
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
        <>
        <div className="flex justify-end">
          <button
            type="button"
            onClick={() => setShowEdit(true)}
            className="keep-white inline-flex items-center gap-1.5 rounded-xl bg-[#3B7FC7] px-4 py-2 text-sm font-semibold text-white"
          >
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8} aria-hidden>
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M16.862 4.487l1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Z"
              />
            </svg>
            {t('ads.editFull')}
          </button>
        </div>
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
          onReject={openRejectDialog}
          onUploadImage={(file) => void handleUploadImage(file)}
          onDeleteImage={(imageId) => void handleDeleteImage(imageId)}
          onDeleteVideo={(path) => void handleDeleteVideo(path)}
          onTrimVideo={(path) => {
            if (backgroundTrimPath) return
            const match = product?.videos.find((video) => video.path === path)
            setTrimTarget({
              path,
              durationSeconds:
                match?.durationSeconds ?? product?.videoDurationSeconds ?? null,
            })
          }}
          trimmingVideoPath={backgroundTrimPath}
          onReplaceImage={(imageId, file) => handleReplaceImage(imageId, file)}
        />
        <AdEditDialog
          open={showEdit}
          product={product}
          categories={categories}
          units={lookups?.units ?? []}
          isSaving={isSaving}
          onClose={() => setShowEdit(false)}
          onSubmit={(payload) => void handleFullEditSubmit(payload)}
        />
        </>
      )}

      <RejectAdReasonDialog
        open={rejectDialogOpen}
        busy={isRejecting}
        initialReasonEn={rejectDraft.supplierNotesEn}
        initialReasonAr={rejectDraft.supplierNotesAr}
        onCancel={() => setRejectDialogOpen(false)}
        onConfirm={(payload) => void handleReject(payload)}
      />
      <AdminVideoTrimModal
        open={trimTarget != null}
        videoPath={trimTarget?.path ?? ''}
        knownDurationSeconds={trimTarget?.durationSeconds}
        isSaving={isTrimmingVideo}
        onClose={() => setTrimTarget(null)}
        onQueued={handleTrimQueued}
        onFailed={handleTrimFailed}
        onSave={handleTrimSave}
      />
    </div>
  )
}
