import { useEffect, useRef, useState, type DragEvent } from 'react'
import { resolveAssetUrl } from '../../lib/assets'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { Category } from '../../types/category'
import { categoryDisplayName, categoryDisplaySubtitle } from '../../utils/categoryDisplay'
import { extractDroppedImageFile } from '../../utils/fileDrop'

type CategoryCardProps = {
  category: Category
  imageVersion?: number
  isUploading: boolean
  isDeleting?: boolean
  isTogglingVisibility?: boolean
  onEdit: (category: Category) => void
  onDelete: (category: Category) => void
  onToggleVisibility: (category: Category) => void
  onImageUpload: (categoryId: number, file: File) => void
}

function isImageFile(file: File) {
  return file.type.startsWith('image/') || /\.(jpe?g|png|gif|webp|bmp|svg)$/i.test(file.name)
}

export default function CategoryCard({
  category,
  imageVersion = 0,
  isUploading,
  isDeleting = false,
  isTogglingVisibility = false,
  onEdit,
  onDelete,
  onToggleVisibility,
  onImageUpload,
}: CategoryCardProps) {
  const { t, locale } = useAppPreferences()
  const [isDragOver, setIsDragOver] = useState(false)
  const [imageBroken, setImageBroken] = useState(false)
  const dragDepthRef = useRef(0)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const displayName = categoryDisplayName(category, locale)
  const subtitle = categoryDisplaySubtitle(category, locale)
  const imageSrc = category.imgPath
    ? `${resolveAssetUrl(category.imgPath)}${imageVersion ? `?v=${imageVersion}` : ''}`
    : ''

  useEffect(() => {
    setImageBroken(false)
  }, [category.imgPath, imageVersion])

  function handleDragEnter(event: DragEvent<HTMLDivElement>) {
    event.preventDefault()
    event.stopPropagation()
    if (isUploading) return

    dragDepthRef.current += 1
    setIsDragOver(true)
    event.dataTransfer.dropEffect = 'copy'
  }

  function handleDragOver(event: DragEvent<HTMLDivElement>) {
    event.preventDefault()
    event.stopPropagation()
    if (isUploading) return

    event.dataTransfer.dropEffect = 'copy'
    setIsDragOver(true)
  }

  function handleDragLeave(event: DragEvent<HTMLDivElement>) {
    event.preventDefault()
    event.stopPropagation()

    dragDepthRef.current = Math.max(0, dragDepthRef.current - 1)
    if (dragDepthRef.current === 0) {
      setIsDragOver(false)
    }
  }

  function handleDrop(event: DragEvent<HTMLDivElement>) {
    event.preventDefault()
    event.stopPropagation()
    dragDepthRef.current = 0
    setIsDragOver(false)

    if (isUploading) return

    const file = extractDroppedImageFile(event.dataTransfer)
    if (!file) return

    onImageUpload(category.categoryId, file)
  }

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    event.target.value = ''
    if (file && isImageFile(file)) {
      onImageUpload(category.categoryId, file)
    }
  }

  return (
    <article
      className={`admin-card group overflow-hidden rounded-xl border shadow-sm ${
        category.isHide ? 'opacity-75' : ''
      }`}
    >
      <div
        role="button"
        tabIndex={0}
        aria-label={t('categories.dropImageHint')}
        onDragEnter={handleDragEnter}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onKeyDown={(event) => {
          if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault()
            fileInputRef.current?.click()
          }
        }}
        className={`admin-surface-muted relative flex h-28 select-none items-center justify-center transition sm:h-32 ${
          isDragOver ? 'ring-2 ring-[#3B7FC7] ring-offset-1 dark:ring-offset-slate-900' : ''
        } ${isUploading ? 'opacity-70' : ''}`}
      >
        {category.isHide ? (
          <span className="absolute start-2 top-2 z-10 rounded-full bg-slate-800/80 px-2 py-0.5 text-[10px] font-semibold text-white">
            {t('categories.hiddenBadge')}
          </span>
        ) : null}
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={handleFileChange}
        />

        {imageSrc && !imageBroken && !category.imgPath.endsWith('default.jpg') ? (
          <img
            key={imageSrc}
            src={imageSrc}
            alt={displayName}
            draggable={false}
            onDragStart={(event) => event.preventDefault()}
            onError={() => setImageBroken(true)}
            className="pointer-events-none max-h-full max-w-full object-contain p-2"
          />
        ) : (
          <div className="admin-text-subtle pointer-events-none flex h-full items-center justify-center px-2 text-center text-[10px]">
            {t('categories.noImage')}
          </div>
        )}

        {(isDragOver || isUploading) && (
          <div className="pointer-events-none absolute inset-0 flex items-center justify-center bg-[#3B7FC7]/15 px-2 text-center backdrop-blur-[1px]">
            <span className="text-xs font-semibold text-[#3B7FC7]">
              {isUploading ? t('categories.uploadingImage') : t('categories.dropToUpdate')}
            </span>
          </div>
        )}

        {!isDragOver && !isUploading && (
          <div className="pointer-events-none absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/45 to-transparent px-2 py-1.5 opacity-0 transition group-hover:opacity-100">
            <span className="text-[10px] font-medium text-white">{t('categories.dropImageHint')}</span>
          </div>
        )}
      </div>

      <div className="p-2.5">
        <h3 className="admin-text truncate text-sm font-bold" title={displayName}>
          {displayName}
        </h3>
        {subtitle ? (
          <p className="admin-text-subtle truncate text-xs" title={subtitle}>
            {subtitle}
          </p>
        ) : null}
        <div className="mt-1.5 flex flex-wrap items-center gap-3">
          <button
            type="button"
            onClick={() => onEdit(category)}
            className="text-xs font-semibold text-[#3B7FC7] hover:underline"
          >
            {t('categories.editName')}
          </button>
          <button
            type="button"
            onClick={() => onToggleVisibility(category)}
            disabled={isTogglingVisibility}
            className="text-xs font-semibold text-amber-700 hover:underline disabled:opacity-60 dark:text-amber-400"
          >
            {isTogglingVisibility
              ? t('categories.updatingVisibility')
              : category.isHide
                ? t('categories.showInApp')
                : t('categories.hideFromApp')}
          </button>
          <button
            type="button"
            onClick={() => onDelete(category)}
            disabled={isDeleting}
            className="text-xs font-semibold text-red-600 hover:underline disabled:opacity-60"
          >
            {isDeleting ? t('categories.deleting') : t('categories.delete')}
          </button>
        </div>
      </div>
    </article>
  )
}
