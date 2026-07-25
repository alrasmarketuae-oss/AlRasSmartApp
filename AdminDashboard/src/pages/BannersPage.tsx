import { useMemo, useState, type FormEvent } from 'react'
import BannerCard from '../components/banners/BannerCard'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import {
  useCreateHomeBannerMutation,
  useDeleteHomeBannerMutation,
  useGetHomeBannersQuery,
  useUpdateHomeBannerMutation,
} from '../store'
import { queryViewState } from '../store/queryView'
import type { HomeBanner } from '../types/banner'
import { getRtkErrorMessage } from '../utils/rtkError'

type FormMode = 'create' | 'edit' | null

export default function BannersPage() {
  const { t } = useAppPreferences()
  const [formMode, setFormMode] = useState<FormMode>(null)
  const [editing, setEditing] = useState<HomeBanner | null>(null)
  const [linkUrl, setLinkUrl] = useState('')
  const [displayOrder, setDisplayOrder] = useState(1)
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [formError, setFormError] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [deletingBannerId, setDeletingBannerId] = useState<number | null>(null)

  const { data, error, isLoading, isFetching } = useGetHomeBannersQuery()
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({
    isLoading,
    isFetching,
  })
  const [createBanner, { isLoading: isCreating }] = useCreateHomeBannerMutation()
  const [updateBanner, { isLoading: isUpdating }] = useUpdateHomeBannerMutation()
  const [deleteBanner] = useDeleteHomeBannerMutation()

  const banners = data?.items ?? []
  const submitting = isCreating || isUpdating

  const suggestedOrder = useMemo(() => {
    if (banners.length === 0) return 1
    return Math.max(...banners.map((b) => b.displayOrder)) + 1
  }, [banners])

  function openCreate() {
    setFormMode('create')
    setEditing(null)
    setLinkUrl('')
    setDisplayOrder(suggestedOrder)
    setImageFile(null)
    setFormError(null)
  }

  function openEdit(banner: HomeBanner) {
    setFormMode('edit')
    setEditing(banner)
    setLinkUrl(banner.linkUrl)
    setDisplayOrder(banner.displayOrder)
    setImageFile(null)
    setFormError(null)
  }

  function closeForm() {
    setFormMode(null)
    setEditing(null)
    setLinkUrl('')
    setImageFile(null)
    setFormError(null)
  }

  async function handleDelete(banner: HomeBanner) {
    const confirmed = window.confirm(
      t('banners.deleteConfirm').replace('{order}', String(banner.displayOrder)),
    )
    if (!confirmed) return

    setActionError(null)
    setDeletingBannerId(banner.id)

    try {
      await deleteBanner(banner.id).unwrap()
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('banners.deleteError')))
    } finally {
      setDeletingBannerId(null)
    }
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    setFormError(null)

    const trimmedLink = linkUrl.trim()

    if (formMode === 'create' && !imageFile) {
      setFormError(t('banners.imageRequired'))
      return
    }

    try {
      if (formMode === 'create' && imageFile) {
        await createBanner({
          file: imageFile,
          linkUrl: trimmedLink || null,
          displayOrder,
        }).unwrap()
      } else if (formMode === 'edit' && editing) {
        await updateBanner({
          bannerId: editing.id,
          linkUrl: trimmedLink || null,
          displayOrder,
          file: imageFile,
        }).unwrap()
      }
      closeForm()
    } catch (err) {
      setFormError(getRtkErrorMessage(err as never, t('banners.formError')))
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="admin-text text-xl font-bold">{t('banners.title')}</h1>
          <p className="admin-text-muted mt-0.5 text-xs">{t('banners.description')}</p>
        </div>
        <button
          type="button"
          onClick={openCreate}
          className="keep-white rounded-lg bg-[#3B7FC7] px-4 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-[#2f6ab0]"
        >
          {t('banners.add')}
        </button>
      </div>

      {error ? (
        <div className="admin-alert-error">
          {getRtkErrorMessage(error, t('banners.loadError'))}
        </div>
      ) : null}

      {actionError ? <div className="admin-alert-error">{actionError}</div> : null}

      {showInitialLoader ? (
        <div className="flex justify-center py-12">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
        </div>
      ) : banners.length === 0 ? (
        <div className="admin-card rounded-2xl p-8 text-center">
          <p className="admin-text-muted text-sm">{t('banners.empty')}</p>
        </div>
      ) : (
        <>
          {showBackgroundUpdate ? (
            <p className="admin-text-subtle text-center text-xs">{t('banners.updating')}</p>
          ) : null}

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {banners.map((banner) => (
              <BannerCard
                key={banner.id}
                banner={banner}
                isDeleting={deletingBannerId === banner.id}
                onEdit={openEdit}
                onDelete={handleDelete}
              />
            ))}
          </div>
        </>
      )}

      {formMode ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <form
            onSubmit={handleSubmit}
            className="admin-card max-h-[90vh] w-full max-w-md overflow-y-auto rounded-2xl p-6 shadow-xl"
          >
            <h2 className="admin-text text-lg font-bold">
              {formMode === 'create' ? t('banners.newBanner') : t('banners.editBanner')}
            </h2>

            {formError ? (
              <p className="admin-alert-error mt-3 px-3 py-2">{formError}</p>
            ) : null}

            <label className="mt-4 block">
              <span className="admin-text-muted text-sm font-medium">{t('banners.linkUrl')}</span>
              <input
                value={linkUrl}
                onChange={(e) => setLinkUrl(e.target.value)}
                placeholder="https://"
                className="admin-input mt-1 w-full px-3 py-2 text-sm"
              />
              <span className="admin-text-subtle mt-1 block text-xs">{t('banners.linkOptional')}</span>
            </label>

            <label className="mt-4 block">
              <span className="admin-text-muted text-sm font-medium">{t('banners.displayOrder')}</span>
              <input
                type="number"
                min={1}
                max={32767}
                value={displayOrder}
                onChange={(e) => setDisplayOrder(Number(e.target.value) || 1)}
                required
                className="admin-input mt-1 w-full px-3 py-2 text-sm"
              />
              <span className="admin-text-subtle mt-1 block text-xs">{t('banners.orderHint')}</span>
            </label>

            <label className="mt-4 block">
              <span className="admin-text-muted text-sm font-medium">
                {formMode === 'create' ? t('banners.bannerImage') : t('banners.replaceImage')}
              </span>
              <input
                type="file"
                accept="image/*"
                onChange={(e) => setImageFile(e.target.files?.[0] ?? null)}
                className="admin-text mt-1 w-full text-sm"
              />
              <span className="admin-text-muted mt-1 block text-xs">{t('banners.imageSizeHint')}</span>
            </label>

            <div className="mt-6 flex gap-2">
              <button
                type="submit"
                disabled={submitting}
                className="keep-white flex-1 rounded-xl bg-[#3B7FC7] py-2.5 text-sm font-semibold text-white disabled:opacity-60"
              >
                {submitting ? t('banners.saving') : t('save')}
              </button>
              <button
                type="button"
                onClick={closeForm}
                className="admin-border admin-text-muted rounded-xl border px-4 py-2.5 text-sm"
              >
                {t('cancel')}
              </button>
            </div>
          </form>
        </div>
      ) : null}
    </div>
  )
}
