import { useEffect, useRef } from 'react'

/**
 * Calls `onReach` when the returned sentinel element is within `margin` px of the viewport.
 * `trigger` (e.g. loaded item count) re-arms the observer so a still-visible sentinel fires again.
 */
export function useInfiniteSentinel(onReach: () => void, enabled: boolean, trigger?: unknown, margin = 320) {
  const ref = useRef<HTMLDivElement | null>(null)
  const callback = useRef(onReach)
  useEffect(() => {
    callback.current = onReach
  })

  useEffect(() => {
    const node = ref.current
    if (!node || !enabled) return
    const observer = new IntersectionObserver((entries) => entries.some((e) => e.isIntersecting) && callback.current(), {
      rootMargin: `0px 0px ${margin}px 0px`,
    })
    observer.observe(node)
    return () => observer.disconnect()
  }, [enabled, margin, trigger])

  return ref
}
