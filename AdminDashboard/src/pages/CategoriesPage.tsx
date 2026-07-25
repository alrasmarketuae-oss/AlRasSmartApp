import { useState, type FormEvent } from 'react'
import CategoryCard from '../components/categories/CategoryCard'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import {
  useCreateCategoryMutation,
  useDeleteCategoryMutation,
  useGetCategoriesQuery,
  useSetCategoryVisibilityMutation,
  useUpdateCategoryMutation,
  useUploadCategoryImageMutation,
} from '../store'
import { queryViewState } from '../store/queryView'
import type { Category } from '../types/category'
import { getRtkErrorMessage } from '../utils/rtkError'
import { categoryDisplayName } from '../utils/categoryDisplay'
import { usePreventBrowserFileDrop } from '../utils/fileDrop'

type FormMode = 'create' | 'edit' | null

export default function CategoriesPage() {
  const { t, locale } = useAppPreferences()
  usePreventBrowserFileDrop()
  const [formMode, setFormMode] = useState<FormMode>(null)
  const [editing, setEditing] = useState<Category | null>(null)
  const [nameEn, setNameEn] = useState('')
  const [nameAr, setNameAr] = useState('')
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [formError, setFormError] = useState<string | null>(null)
  const [uploadError, setUploadError] = useState<string | null>(null)
  const [uploadingCategoryId, setUploadingCategoryId] = useState<number | null>(null)

  const { data, error, isLoading, isFetching } = useGetCategoriesQuery()
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({
    isLoading,
    isFetching,
  })
  const [createCategory, { isLoading: isCreating }] = useCreateCategoryMutation()
  const [updateCategory, { isLoading: isUpdating }] = useUpdateCategoryMutation()
  const [uploadCategoryImage] = useUploadCategoryImageMutation()
  const [deleteCategory] = useDeleteCategoryMutation()
  const [setCategoryVisibility] = useSetCategoryVisibilityMutation()
  const [deletingCategoryId, setDeletingCategoryId] = useState<number | null>(null)
  const [togglingVisibilityId, setTogglingVisibilityId] = useState<number | null>(null)
  const [imageVersions, setImageVersions] = useState<Record<number, number>>({})

  const categories = data?.items ?? []
  const submitting = isCreating || isUpdating

  function openCreate() {
    setFormMode('create')
    setEditing(null)
    setNameEn('')
    setNameAr('')
    setImageFile(null)
    setFormError(null)
  }

  function openEdit(category: Category) {
    setFormMode('edit')
    setEditing(category)
    setNameEn(category.nameEn)
    setNameAr(category.nameAr)
    setFormError(null)
  }

  function closeForm() {
    setFormMode(null)
    setEditing(null)
    setNameEn('')
    setNameAr('')
    setImageFile(null)
    setFormError(null)
  }

  async function handleImageUpload(categoryId: number, file: File) {
    setUploadError(null)
    setUploadingCategoryId(categoryId)

    try {
      await uploadCategoryImage({ categoryId, file }).unwrap()
      setImageVersions((prev) => ({ ...prev, [categoryId]: Date.now() }))
    } catch (err) {
      setUploadError(getRtkErrorMessage(err as never, t('categories.uploadError')))
    } finally {
      setUploadingCategoryId(null)
    }
  }

  async function handleDelete(category: Category) {
    const confirmed = window.confirm(
      t('categories.deleteConfirm').replace(
        '{name}',
        categoryDisplayName(category, locale),
      ),
    )
    if (!confirmed) return

    setUploadError(null)
    setDeletingCategoryId(category.categoryId)

    try {
      await deleteCategory(category.categoryId).unwrap()
    } catch (err) {
      setUploadError(getRtkErrorMessage(err as never, t('categories.deleteError')))
    } finally {
      setDeletingCategoryId(null)
    }
  }

  async function handleToggleVisibility(category: Category) {
    const nextHidden = !category.isHide
    const confirmKey = nextHidden
      ? 'categories.hideConfirm'
      : 'categories.showConfirm'
    const confirmed = window.confirm(
      t(confirmKey).replace('{name}', categoryDisplayName(category, locale)),
    )
    if (!confirmed) return

    setUploadError(null)
    setTogglingVisibilityId(category.categoryId)

    try {
      await setCategoryVisibility({
        categoryId: category.categoryId,
        isHide: nextHidden,
      }).unwrap()
    } catch (err) {
      setUploadError(
        getRtkErrorMessage(err as never, t('categories.visibilityError')),
      )
    } finally {
      setTogglingVisibilityId(null)
    }
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    setFormError(null)

    try {
      if (formMode === 'create') {
        const created = await createCategory({
          nameEn: nameEn.trim(),
          nameAr: nameAr.trim(),
        }).unwrap()
        if (imageFile) {
          await uploadCategoryImage({
            categoryId: created.categoryId,
            file: imageFile,
          }).unwrap()
          setImageVersions((prev) => ({ ...prev, [created.categoryId]: Date.now() }))
        }
      } else if (formMode === 'edit' && editing) {
        await updateCategory({
          categoryId: editing.categoryId,
          nameEn: nameEn.trim(),
          nameAr: nameAr.trim(),
          imgPath: editing.imgPath,
        }).unwrap()
      }
      closeForm()
    } catch (err) {
      setFormError(getRtkErrorMessage(err as never, t('categories.formError')))
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="admin-text text-xl font-bold">{t('categories.title')}</h1>
          <p className="admin-text-muted mt-0.5 text-xs">{t('categories.description')}</p>
          <p className="admin-text-subtle mt-1 text-xs">{t('categories.dropImageHint')}</p>
          <p className="admin-text-muted mt-1 text-xs">{t('categories.imageSizeHint')}</p>
        </div>
        <button
          type="button"
          onClick={openCreate}
          className="keep-white rounded-lg bg-[#3B7FC7] px-4 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-[#2f6ab0]"
        >
          {t('categories.add')}
        </button>
      </div>

      {error ? (
        <div className="admin-alert-error">
          {getRtkErrorMessage(error, t('categories.loadError'))}
        </div>
      ) : null}

      {uploadError ? (
        <div className="admin-alert-error">{uploadError}</div>
      ) : null}

      {showInitialLoader ? (
        <div className="flex justify-center py-12">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
        </div>
      ) : (
        <>
          {showBackgroundUpdate ? (
            <p className="admin-text-subtle text-center text-xs">
              {t('categories.updating')}
            </p>
          ) : null}

          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6">
            {categories.map((cat) => (
              <CategoryCard
                key={cat.categoryId}
                category={cat}
                imageVersion={imageVersions[cat.categoryId]}
                isUploading={uploadingCategoryId === cat.categoryId}
                isDeleting={deletingCategoryId === cat.categoryId}
                isTogglingVisibility={togglingVisibilityId === cat.categoryId}
                onEdit={openEdit}
                onDelete={handleDelete}
                onToggleVisibility={handleToggleVisibility}
                onImageUpload={handleImageUpload}
              />
            ))}
          </div>
        </>
      )}

      {formMode ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <form
            onSubmit={handleSubmit}
            className="admin-card w-full max-w-md rounded-2xl p-6 shadow-xl"
          >
            <h2 className="admin-text text-lg font-bold">
              {formMode === 'create'
                ? t('categories.newCategory')
                : t('categories.editCategory')}
            </h2>

            {formError ? (
              <p className="admin-alert-error mt-3 px-3 py-2">{formError}</p>
            ) : null}

            <label className="mt-4 block">
              <span className="admin-text-muted text-sm font-medium">
                {t('categories.nameEn')}
              </span>
              <input
                value={nameEn}
                onChange={(e) => setNameEn(e.target.value)}
                required
                className="admin-input mt-1 w-full px-3 py-2 text-sm"
              />
            </label>

            <label className="mt-4 block">
              <span className="admin-text-muted text-sm font-medium">
                {t('categories.nameAr')}
              </span>
              <input
                value={nameAr}
                onChange={(e) => setNameAr(e.target.value)}
                required
                dir="rtl"
                className="admin-input mt-1 w-full px-3 py-2 text-sm"
              />
            </label>

            {formMode === 'create' ? (
              <label className="mt-4 block">
                <span className="admin-text-muted text-sm font-medium">
                  {t('categories.categoryImage')}
                </span>
                <input
                  type="file"
                  accept="image/*"
                  onChange={(e) => setImageFile(e.target.files?.[0] ?? null)}
                  className="admin-text mt-1 w-full text-sm"
                />
              </label>
            ) : (
              <>
                <p className="admin-text-muted mt-4 text-xs">{t('categories.dropImageHint')}</p>
                <p className="admin-text-muted mt-1 text-xs">{t('categories.imageSizeHint')}</p>
              </>
            )}

            <div className="mt-6 flex gap-2">
              <button
                type="submit"
                disabled={submitting}
                className="keep-white flex-1 rounded-xl bg-[#3B7FC7] py-2.5 text-sm font-semibold text-white disabled:opacity-60"
              >
                {submitting ? t('categories.saving') : t('save')}
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
