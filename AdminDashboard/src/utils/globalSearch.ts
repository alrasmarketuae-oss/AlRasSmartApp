export const GLOBAL_SEARCH_PARAM = 'search'

export type SearchableAdminRoute = '/ads' | '/users' | '/shipping'

export function getSearchableRoute(pathname: string): SearchableAdminRoute | null {
  if (pathname === '/ads' || pathname.startsWith('/ads/')) return '/ads'
  if (pathname === '/users' || pathname.startsWith('/users/')) return '/users'
  if (pathname === '/shipping' || pathname.startsWith('/shipping/')) {
    return '/shipping'
  }
  return null
}

export function resolveGlobalSearchRoute(
  pathname: string,
  term: string,
): SearchableAdminRoute {
  const current = getSearchableRoute(pathname)
  if (current) return current
  if (term.includes('@')) return '/users'
  return '/ads'
}

export function buildSearchNavigationPath(pathname: string, term: string): string {
  const route = resolveGlobalSearchRoute(pathname, term)
  const params = new URLSearchParams()
  const trimmed = term.trim()
  if (trimmed) params.set(GLOBAL_SEARCH_PARAM, trimmed)
  const qs = params.toString()
  return qs ? `${route}?${qs}` : route
}

export function readGlobalSearchTerm(params: URLSearchParams): string {
  return params.get(GLOBAL_SEARCH_PARAM)?.trim() ?? ''
}
