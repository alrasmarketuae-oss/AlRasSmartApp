import { useCallback, useSyncExternalStore } from 'react'
import { api } from '../lib/api'

const viewed = new Set<string>()

/** Fire-and-forget view ping, once per product per page session (skipped for owners by the caller). */
export function trackProductView(productId: string) {
  if (!productId || viewed.has(productId)) return
  viewed.add(productId)
  api.post(`/Products/${encodeURIComponent(productId)}/increase-view`, {}).catch(() => undefined)
}

export const trackProductShare = (productId: string) => api.post(`/Products/${encodeURIComponent(productId)}/increase-share`, {}).catch(() => undefined)

const SAVED_KEY = 'marketplace.bookmarked.product.ids'
const listeners = new Set<() => void>()

function readSaved(): string[] {
  try {
    const parsed = JSON.parse(localStorage.getItem(SAVED_KEY) ?? '[]')
    return Array.isArray(parsed) ? parsed.filter((id): id is string => typeof id === 'string') : []
  } catch {
    return []
  }
}

let snapshot = readSaved()

function writeSaved(ids: string[]) {
  snapshot = ids
  localStorage.setItem(SAVED_KEY, JSON.stringify(ids))
  listeners.forEach((listener) => listener())
}

window.addEventListener('storage', (event) => {
  if (event.key !== SAVED_KEY) return
  snapshot = readSaved()
  listeners.forEach((listener) => listener())
})

const subscribe = (listener: () => void) => {
  listeners.add(listener)
  return () => listeners.delete(listener)
}

export function useSavedAds() {
  const ids = useSyncExternalStore(subscribe, () => snapshot)
  const toggle = useCallback((productId: string) => {
    const current = readSaved()
    if (current.includes(productId)) {
      writeSaved(current.filter((id) => id !== productId))
      return false
    }
    writeSaved([productId, ...current])
    api.post(`/Products/${encodeURIComponent(productId)}/increase-favorite`, {}).catch(() => undefined)
    return true
  }, [])
  const remove = useCallback((productId: string) => writeSaved(readSaved().filter((id) => id !== productId)), [])
  return { ids, toggle, remove }
}
