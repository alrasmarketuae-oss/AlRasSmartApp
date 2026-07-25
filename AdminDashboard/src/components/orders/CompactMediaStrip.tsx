import { useState } from 'react'
import { resolveAssetUrl } from '../../lib/assets'
import ImageGallery from '../ui/ImageGallery'

type CompactMediaStripProps = {
  paths: string[]
  emptyLabel?: string
  sizeClassName?: string
}

export default function CompactMediaStrip({
  paths,
  emptyLabel,
  sizeClassName = 'h-11 w-11',
}: CompactMediaStripProps) {
  const [galleryIndex, setGalleryIndex] = useState<number | null>(null)
  const imagePaths = paths.filter(Boolean)

  if (imagePaths.length === 0) {
    return emptyLabel ? <p className="admin-text-subtle text-xs">{emptyLabel}</p> : null
  }

  return (
    <>
      <div className="flex flex-wrap gap-1.5">
        {imagePaths.map((path, index) => (
          <button
            key={`${path}-${index}`}
            type="button"
            onClick={() => setGalleryIndex(index)}
            className={`admin-border shrink-0 overflow-hidden rounded-md border bg-white ${sizeClassName}`}
          >
            <img src={resolveAssetUrl(path)} alt="" className="h-full w-full object-cover" />
          </button>
        ))}
      </div>
      <ImageGallery
        images={imagePaths}
        initialIndex={galleryIndex ?? 0}
        open={galleryIndex != null}
        onClose={() => setGalleryIndex(null)}
      />
    </>
  )
}
