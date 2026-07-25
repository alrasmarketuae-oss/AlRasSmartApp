import { useEffect } from 'react'

/** Stops the browser from navigating/opening files dropped outside a handled zone. */
export function usePreventBrowserFileDrop() {
  useEffect(() => {
    function onDragOver(event: DragEvent) {
      event.preventDefault()
    }

    function onDrop(event: DragEvent) {
      event.preventDefault()
    }

    window.addEventListener('dragover', onDragOver)
    window.addEventListener('drop', onDrop)

    return () => {
      window.removeEventListener('dragover', onDragOver)
      window.removeEventListener('drop', onDrop)
    }
  }, [])
}

function isImageFile(file: File) {
  return file.type.startsWith('image/') || /\.(jpe?g|png|gif|webp|bmp|svg)$/i.test(file.name)
}

export function extractDroppedImageFile(dataTransfer: DataTransfer): File | null {
  if (dataTransfer.files?.length) {
    for (let i = 0; i < dataTransfer.files.length; i++) {
      const file = dataTransfer.files[i]
      if (isImageFile(file)) return file
    }
  }

  if (dataTransfer.items?.length) {
    for (let i = 0; i < dataTransfer.items.length; i++) {
      const item = dataTransfer.items[i]
      if (item.kind !== 'file') continue
      const file = item.getAsFile()
      if (file && isImageFile(file)) return file
    }
  }

  return null
}
