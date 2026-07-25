/**
 * RTK Query cache policy for the admin dashboard.
 *
 * Default: cache-first — revisiting a page uses Redux cache (no network)
 * until a mutation invalidates tags or the entry expires.
 *
 * Live surfaces (chat, badges) opt into shorter TTL / focus refetch at the
 * endpoint or hook level.
 */

/** How long unused query results stay in Redux after leaving a page. */
export const CACHE_TTL_SECONDS = 60 * 60 // 1 hour

/** Rarely changing reference data (geo, permissions). */
export const STATIC_CACHE_TTL_SECONDS = 60 * 60 * 6 // 6 hours

/** Chat threads / inbox — short retention, still cache-friendly while open. */
export const LIVE_CACHE_TTL_SECONDS = 60

/** Unread badges and live nav counts. */
export const BADGE_CACHE_TTL_SECONDS = 30

export const defaultCachePolicy = {
  keepUnusedDataFor: CACHE_TTL_SECONDS,
  /** Use cached data when revisiting; mutations invalidate tags to refresh. */
  refetchOnMountOrArgChange: false as const,
  /** Avoid refetching every time the browser tab gains focus. */
  refetchOnFocus: false as const,
  /** Refresh after network recovery. */
  refetchOnReconnect: true as const,
}

/** Hook options for chat / realtime screens. */
export const liveQueryOptions = {
  refetchOnFocus: true as const,
  refetchOnReconnect: true as const,
}
