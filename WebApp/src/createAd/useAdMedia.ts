import { useCallback, useEffect, useRef, useState } from 'react'
import { useI18n } from '../i18n/I18nProvider'
import { uploadDraftImage, uploadDraftVideo, videoDurationSeconds } from '../lib/draftUpload'
import { resolveMediaUrl } from '../lib/media'
import { isVideoPath } from '../orders/ordersApi'
import { useToast } from '../ui/Toast'
import { deleteDraft, type MediaPayload } from './createAdApi'

export const MAX_IMAGES = 15
export const MAX_VIDEOS = 5
export const MAX_VIDEO_MB = 100
export const MAX_VIDEO_SECONDS = 180

const IMAGE_EXT = /\.(jpe?g|png|webp|gif|bmp)$/i
const VIDEO_EXT = /\.(mp4|mov|m4v|webm)$/i
export const MEDIA_ACCEPT = 'image/jpeg,image/png,image/webp,video/mp4,video/quicktime,video/webm,.jpg,.jpeg,.png,.webp,.mp4,.mov,.m4v,.webm'

export type AdMediaItem = {
  id: string
  kind: 'image' | 'video'
  /** Existing server path (edit mode). */
  remotePath?: string
  file?: File
  previewUrl: string
  status: 'ready' | 'uploading' | 'error'
  draftPath?: string
  duration: number
}

let seq = 0
const nextId = () => `m${Date.now().toString(36)}${(seq++).toString(36)}`

const kindOf = (file: File): AdMediaItem['kind'] | null => {
  if (file.type.startsWith('video/') || VIDEO_EXT.test(file.name)) return VIDEO_EXT.test(file.name) || /mp4|quicktime|webm/.test(file.type) ? 'video' : null
  if (file.type.startsWith('image/') || IMAGE_EXT.test(file.name)) return 'image'
  return null
}

/** Draft uploads start as soon as a file is picked, like the app; publish only sends the draft paths. */
export function useAdMedia() {
  const { t } = useI18n()
  const toast = useToast()
  const [items, setItems] = useState<AdMediaItem[]>([])
  const itemsRef = useRef(items)
  itemsRef.current = items
  const removedRemote = useRef<string[]>([])
  const confirmed = useRef(false)
  const abandoned = useRef(false)
  const inFlight = useRef(new Map<string, Promise<void>>())

  /** Keeps the ref in sync immediately so `settle`/`payload` never read a stale render. */
  const patch = useCallback((id: string, changes: Partial<AdMediaItem>) => {
    const apply = (all: AdMediaItem[]) => all.map((item) => (item.id === id ? { ...item, ...changes } : item))
    itemsRef.current = apply(itemsRef.current)
    setItems(apply)
  }, [])

  const upload = useCallback(
    (item: AdMediaItem): Promise<void> => {
      if (!item.file) return Promise.resolve()
      const running = inFlight.current.get(item.id)
      if (running) return running
      const file = item.file
      patch(item.id, { status: 'uploading' })
      const task = (async () => {
        try {
          const path = item.kind === 'video' ? await uploadDraftVideo(file) : await uploadDraftImage(file)
          if (abandoned.current || !itemsRef.current.some((i) => i.id === item.id)) {
            void deleteDraft(path, abandoned.current).catch(() => undefined)
            return
          }
          patch(item.id, { status: 'ready', draftPath: path })
        } catch {
          if (!abandoned.current) patch(item.id, { status: 'error' })
        } finally {
          inFlight.current.delete(item.id)
        }
      })()
      inFlight.current.set(item.id, task)
      return task
    },
    [patch],
  )

  const add = useCallback(
    async (files: File[]) => {
      let images = itemsRef.current.filter((i) => i.kind === 'image').length
      let videos = itemsRef.current.filter((i) => i.kind === 'video').length
      const accepted: AdMediaItem[] = []
      for (const file of files) {
        const kind = kindOf(file)
        if (!kind) {
          toast.error(t('unsupportedMediaType'))
          continue
        }
        if (kind === 'image') {
          if (images >= MAX_IMAGES) {
            toast.error(t('maxProductImagesExceeded'))
            continue
          }
          images++
          accepted.push({ id: nextId(), kind, file, previewUrl: URL.createObjectURL(file), status: 'uploading', duration: 0 })
          continue
        }
        if (videos >= MAX_VIDEOS) {
          toast.error(t('maxProductVideosExceeded', { maxCount: MAX_VIDEOS }))
          continue
        }
        if (file.size > MAX_VIDEO_MB * 1024 * 1024) {
          toast.error(t('videoSizeExceeded', { sizeMb: (file.size / 1024 / 1024).toFixed(1), maxMb: MAX_VIDEO_MB }))
          continue
        }
        const duration = await videoDurationSeconds(file)
        if (duration <= 0) {
          toast.error(t('videoDurationUnreadable'))
          continue
        }
        if (duration > MAX_VIDEO_SECONDS) {
          toast.error(t('videoMaxDurationSeconds'))
          continue
        }
        videos++
        accepted.push({ id: nextId(), kind, file, previewUrl: URL.createObjectURL(file), status: 'uploading', duration })
      }
      if (!accepted.length) return
      setItems((all) => [...all, ...accepted])
      itemsRef.current = [...itemsRef.current, ...accepted]
      accepted.forEach((item) => void upload(item))
    },
    [t, toast, upload],
  )

  const remove = useCallback((id: string) => {
    const item = itemsRef.current.find((i) => i.id === id)
    if (!item) return
    if (item.file) {
      URL.revokeObjectURL(item.previewUrl)
      if (item.draftPath) void deleteDraft(item.draftPath).catch(() => undefined)
    } else if (item.remotePath && item.kind === 'image') {
      removedRemote.current.push(item.remotePath)
    }
    itemsRef.current = itemsRef.current.filter((i) => i.id !== id)
    setItems((all) => all.filter((i) => i.id !== id))
  }, [])

  const retry = useCallback((id: string) => {
    const item = itemsRef.current.find((i) => i.id === id)
    if (item) void upload(item)
  }, [upload])

  /** Publish waits for in-flight drafts and retries failed ones once, like the app; false = some media still missing. */
  const settle = useCallback(async () => {
    await Promise.all([...inFlight.current.values()])
    const failed = itemsRef.current.filter((i) => i.file && i.status === 'error')
    if (failed.length) await Promise.all(failed.map(upload))
    await Promise.all([...inFlight.current.values()])
    return itemsRef.current.every((i) => !i.file || (i.status === 'ready' && !!i.draftPath))
  }, [upload])

  const setRemote = useCallback((paths: string[]) => {
    removedRemote.current = []
    const remote: AdMediaItem[] = paths.map((path) => ({
      id: nextId(),
      kind: isVideoPath(path) ? 'video' : 'image',
      remotePath: path,
      previewUrl: resolveMediaUrl(path),
      status: 'ready',
      duration: 0,
    }))
    itemsRef.current = remote
    setItems(remote)
  }, [])

  const payload = useCallback((): MediaPayload & { removedRemoteImages: string[] } => {
    const local = itemsRef.current.filter((i) => i.file && i.draftPath)
    return {
      draftImages: local.filter((i) => i.kind === 'image').map((i) => i.draftPath!),
      draftVideos: local.filter((i) => i.kind === 'video').map((i) => ({ path: i.draftPath!, duration: i.duration })),
      removedRemoteImages: [...removedRemote.current],
    }
  }, [])

  const reset = useCallback(() => {
    itemsRef.current.forEach((i) => i.file && URL.revokeObjectURL(i.previewUrl))
    removedRemote.current = []
    itemsRef.current = []
    setItems([])
  }, [])

  /** Once the product exists the drafts belong to it, so the unmount cleanup must leave them alone. */
  const markConfirmed = useCallback(() => {
    confirmed.current = true
  }, [])

  const markDraft = useCallback(() => {
    confirmed.current = false
  }, [])

  /** Leaving the form without publishing (route change) deletes every unconfirmed draft; late uploads delete themselves. */
  useEffect(() => {
    abandoned.current = false
    return () => {
      abandoned.current = true
      for (const item of itemsRef.current) {
        if (!item.file) continue
        URL.revokeObjectURL(item.previewUrl)
        if (item.draftPath && !confirmed.current) void deleteDraft(item.draftPath, true).catch(() => undefined)
      }
    }
  }, [])

  /** Tab close / refresh never unmounts React, so drafts are dropped on `pagehide` and re-uploaded if the page is restored. */
  useEffect(() => {
    const onHide = () => {
      if (confirmed.current) return
      for (const item of itemsRef.current) {
        if (!item.file || !item.draftPath) continue
        void deleteDraft(item.draftPath, true).catch(() => undefined)
        patch(item.id, { draftPath: undefined, status: 'error' })
      }
    }
    const onShow = (event: PageTransitionEvent) => {
      if (!event.persisted) return
      itemsRef.current.filter((i) => i.file && i.status === 'error').forEach((i) => void upload(i))
    }
    window.addEventListener('pagehide', onHide)
    window.addEventListener('pageshow', onShow)
    return () => {
      window.removeEventListener('pagehide', onHide)
      window.removeEventListener('pageshow', onShow)
    }
  }, [patch, upload])

  return {
    items,
    add,
    remove,
    retry,
    settle,
    setRemote,
    payload,
    reset,
    markConfirmed,
    markDraft,
    uploading: items.some((i) => i.status === 'uploading'),
    failed: items.some((i) => i.status === 'error'),
  }
}
