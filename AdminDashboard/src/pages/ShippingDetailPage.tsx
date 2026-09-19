import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import ShippingProviderForm from '../components/shipping/ShippingProviderForm'
import ShippingPostEditForm from '../components/shipping/ShippingPostEditForm'
import ShippingProviderDetailView from '../components/shipping/ShippingProviderDetailView'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import {
  useApproveShippingPostMutation,
  useDeleteShippingProviderMutation,
  useGetShippingProviderDetailQuery,
  useRejectShippingPostMutation,
  useSetShippingProviderActiveMutation,
  useUpdateShippingPostMutation,
  useUpdateShippingProviderMutation,
  useUploadShippingProviderImageMutation,
} from '../store'
import type { ShippingPostPayload, ShippingProviderPayload } from '../types/adminShippingCreate'
import { getRtkErrorMessage } from '../utils/rtkError'

function mapDeleteError(message: string, t: (key: string) => string) {
  if (message.includes('shipments')) return t('shippingPage.deleteBlockedShipments')
  if (message.includes('product listings')) return t('shippingPage.deleteBlockedProducts')
  return message
}

export default function ShippingDetailPage() {
  const { providerId = '' } = useParams()
  const navigate = useNavigate()
  const [searchParams, setSearchParams] = useSearchParams()
  const { t } = useAppPreferences()
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [editingPostId, setEditingPostId] = useState<number | null>(null)
  const [moderatingPostId, setModeratingPostId] = useState<number | null>(null)

  const { data: provider, error, isLoading } = useGetShippingProviderDetailQuery(providerId, {
    skip: !providerId,
  })

  const [setProviderActive, { isLoading: isUpdatingActive }] = useSetShippingProviderActiveMutation()
  const [updateProvider, { isLoading: isSaving }] = useUpdateShippingProviderMutation()
  const [updatePost, { isLoading: isSavingPost }] = useUpdateShippingPostMutation()
  const [uploadProviderImage] = useUploadShippingProviderImageMutation()
  const [deleteProvider, { isLoading: isDeleting }] = useDeleteShippingProviderMutation()
  const [approveShippingPost, { isLoading: isApprovingPost }] = useApproveShippingPostMutation()
  const [rejectShippingPost, { isLoading: isRejectingPost }] = useRejectShippingPostMutation()

  useEffect(() => {
    if (searchParams.get('edit') !== '1') return
    setIsEditing(true)
    setEditingPostId(null)
    const next = new URLSearchParams(searchParams)
    next.delete('edit')
    setSearchParams(next, { replace: true })
  }, [providerId, searchParams, setSearchParams])

  async function handleToggleActive() {
    if (!provider) return

    const disabling = provider.isActive
    if (disabling) {
      const confirmed = window.confirm(t('shippingPage.disableConfirm'))
      if (!confirmed) return
    }

    setActionError(null)
    setSuccessMessage(null)

    try {
      await setProviderActive({
        providerId: provider.id,
        isActive: !provider.isActive,
      }).unwrap()
      setSuccessMessage(
        provider.isActive ? t('shippingPage.disableSuccess') : t('shippingPage.enableSuccess'),
      )
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('shippingPage.actionError')))
    }
  }

  async function handleUpdateProvider(payload: ShippingProviderPayload, imageFile: File | null) {
    if (!provider) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      await updateProvider({ providerId: provider.id, ...payload }).unwrap()
      if (imageFile) {
        await uploadProviderImage({ providerId: provider.id, file: imageFile }).unwrap()
      }
      setIsEditing(false)
      setSuccessMessage(t('shippingPage.updateSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('shippingPage.updateError')))
    }
  }

  async function handleUpdatePost(payload: ShippingPostPayload) {
    if (!provider || !editingPostId) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      await updatePost({
        postId: editingPostId,
        providerId: provider.id,
        ...payload,
      }).unwrap()
      setEditingPostId(null)
      setSuccessMessage(t('shippingPage.updateAdSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('shippingPage.updateAdError')))
    }
  }

  async function handleDeleteProvider() {
    if (!provider) return

    const confirmed = window.confirm(t('shippingPage.deleteConfirm'))
    if (!confirmed) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      await deleteProvider(provider.id).unwrap()
      navigate('/users', {
        replace: true,
        state: { shippingMessage: t('shippingPage.deleteSuccess') },
      })
    } catch (err) {
      setActionError(mapDeleteError(getRtkErrorMessage(err as never, t('shippingPage.deleteError')), t))
    }
  }

  async function handleApprovePost(postId: number) {
    if (!postId) return
    setActionError(null)
    setSuccessMessage(null)
    setModeratingPostId(postId)
    try {
      await approveShippingPost(postId).unwrap()
      setSuccessMessage(t('shippingPage.approveShippingAdSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('shippingPage.actionError')))
    } finally {
      setModeratingPostId(null)
    }
  }

  async function handleRejectPost(postId: number) {
    if (!postId) return
    const confirmed = window.confirm(t('shippingPage.rejectShippingAdConfirm'))
    if (!confirmed) return
    const reason = window.prompt(t('shippingPage.rejectReasonOptional')) ?? ''
    setActionError(null)
    setSuccessMessage(null)
    setModeratingPostId(postId)
    try {
      await rejectShippingPost({ postId, reason }).unwrap()
      setSuccessMessage(t('shippingPage.rejectShippingAdSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('shippingPage.actionError')))
    } finally {
      setModeratingPostId(null)
    }
  }

  function handleQuickAction(action: 'notify' | 'update' | 'block') {
    if (action === 'update') {
      setActionError(null)
      setSuccessMessage(null)
      setEditingPostId(null)
      setIsEditing(true)
      return
    }

    if (action === 'block') {
      void handleToggleActive()
      return
    }

    window.alert(t('shippingPage.actionSoon'))
  }

  if (!providerId) {
    navigate('/shipping', { replace: true })
    return null
  }

  const editingPost =
    editingPostId && provider
      ? provider.posts.find((p) => p.id === editingPostId) ??
        (provider.latestPostId === editingPostId
          ? {
              id: provider.latestPostId,
              fromCountryName: provider.fromCountryName,
              fromPortName: provider.fromPortName,
              toCountryName: provider.toCountryName,
              toPortName: provider.toPortName,
              container20ftPriceUsd: provider.container20ftPriceUsd,
              container40ftPriceUsd: provider.container40ftPriceUsd,
              phoneNumber: provider.phoneNumber,
              details: null as string | null,
              minDurationDays: null as number | null,
              maxDurationDays: null as number | null,
            }
          : null)
      : null

  return (
    <div className="space-y-6">
      <Link
        to={`/users/${providerId}`}
        className="admin-text-muted inline-flex items-center gap-2 text-sm font-semibold transition hover:text-[#3B7FC7]"
      >
        ← {t('users.title')}
      </Link>

      {successMessage ? (
        <div className="admin-alert-success">{successMessage}</div>
      ) : null}
      {actionError ? <div className="admin-alert-error">{actionError}</div> : null}

      {isLoading ? (
        <p className="admin-text-subtle py-16 text-center">{t('loading')}</p>
      ) : error || !provider ? (
        <div className="admin-card px-6 py-16 text-center">
          <p className="text-sm text-red-600 dark:text-red-400">
            {getRtkErrorMessage(error as never, t('shippingPage.loadError'))}
          </p>
          <Link
            to={`/users/${providerId}`}
            className="keep-white mt-4 inline-block rounded-xl bg-[#3B7FC7] px-5 py-2.5 text-sm font-semibold text-white"
          >
            {t('users.title')}
          </Link>
        </div>
      ) : isEditing ? (
        <div className="admin-card">
          <ShippingProviderForm
            mode="edit"
            initialValues={{
              companyName: provider.companyName,
              fullName: provider.fullName,
              email: provider.email,
              phoneNumber: provider.phoneNumber ?? '',
              fromCountryName: provider.fromCountryName,
              fromPortName: provider.fromPortName,
              toCountryName: provider.toCountryName,
              toPortName: provider.toPortName,
              container20ftPriceUsd: provider.container20ftPriceUsd,
              container40ftPriceUsd: provider.container40ftPriceUsd,
            }}
            initialImageUrl={provider.imgPath}
            submitting={isSaving}
            onCancel={() => {
              setIsEditing(false)
              setActionError(null)
            }}
            onSubmit={handleUpdateProvider}
          />
        </div>
      ) : editingPost ? (
        <div className="admin-card">
          <ShippingPostEditForm
            initialValues={{
              fromCountryName: editingPost.fromCountryName,
              fromPortName: editingPost.fromPortName,
              toCountryName: editingPost.toCountryName,
              toPortName: editingPost.toPortName,
              phoneNumber: editingPost.phoneNumber ?? provider.phoneNumber ?? '',
              container20ftPriceUsd: editingPost.container20ftPriceUsd,
              container40ftPriceUsd: editingPost.container40ftPriceUsd,
              details: editingPost.details,
              minDurationDays: editingPost.minDurationDays,
              maxDurationDays: editingPost.maxDurationDays,
            }}
            submitting={isSavingPost}
            onCancel={() => {
              setEditingPostId(null)
              setActionError(null)
            }}
            onSubmit={handleUpdatePost}
          />
        </div>
      ) : (
        <ShippingProviderDetailView
          provider={provider}
          isUpdating={isUpdatingActive}
          isDeleting={isDeleting}
          isModeratingPost={isApprovingPost || isRejectingPost}
          moderatingPostId={moderatingPostId}
          onEdit={() => handleQuickAction('update')}
          onEditPost={(postId) => {
            setIsEditing(false)
            setEditingPostId(postId)
            setActionError(null)
            setSuccessMessage(null)
          }}
          onDelete={() => void handleDeleteProvider()}
          onToggleActive={() => void handleToggleActive()}
          onApprovePost={(postId) => void handleApprovePost(postId)}
          onRejectPost={(postId) => void handleRejectPost(postId)}
          onQuickAction={handleQuickAction}
        />
      )}
    </div>
  )
}
