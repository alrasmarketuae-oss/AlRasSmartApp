import type { ListReturnState } from './listPageParams'

/**
 * Which sidebar `to` should appear active for the current location.
 * Detail pages under /ads or /orders keep "Reqs & Offers" active when opened from there.
 */
export function resolveActiveNavTo(
  pathname: string,
  search: string,
  locationState: unknown,
): string {
  const from =
    typeof (locationState as ListReturnState | null)?.from === 'string'
      ? (locationState as ListReturnState).from!
      : ''
  const fromPath = from.split('?')[0] || ''

  const fromQuery = from.includes('?')
    ? new URLSearchParams(from.slice(from.indexOf('?') + 1))
    : null

  // Request ad / offer detail opened from Reqs & Offers
  if (
    fromPath === '/reqs-offers' &&
    (pathname.startsWith('/ads/') || pathname.startsWith('/orders/'))
  ) {
    return fromQuery?.get('nav') === 'orders' ? '/orders/all' : '/ads'
  }

  if (pathname === '/reqs-offers' || pathname.startsWith('/reqs-offers/')) {
    const params = new URLSearchParams(search.startsWith('?') ? search.slice(1) : search)
    if (params.get('nav') === 'orders') return '/orders/all'
    return '/ads'
  }

  if (pathname === '/ads' || pathname.startsWith('/ads/')) {
    const params = new URLSearchParams(search.startsWith('?') ? search.slice(1) : search)
    if (params.get('adEdits') === '1' || fromQuery?.get('adEdits') === '1') {
      return '/ads?adEdits=1'
    }
    return '/ads'
  }

  if (pathname === '/orders' || pathname.startsWith('/orders/')) {
    return '/orders/all'
  }

  if (pathname === '/users' || pathname.startsWith('/users/')) {
    const params = new URLSearchParams(search.startsWith('?') ? search.slice(1) : search)
    const fromParams = from.includes('?')
      ? new URLSearchParams(from.slice(from.indexOf('?') + 1))
      : null
    if (params.get('profileEdits') === '1' || fromParams?.get('profileEdits') === '1') {
      return '/users?profileEdits=1'
    }
    return '/users'
  }

  if (pathname === '/shipping' || pathname.startsWith('/shipping/')) {
    return '/shipping'
  }

  if (pathname === '/' || pathname === '') {
    return '/'
  }

  // Exact section roots for the rest
  const section = `/${pathname.split('/').filter(Boolean)[0] ?? ''}`
  return section === '/' ? pathname : section
}

export function isSidebarNavActive(
  itemTo: string,
  pathname: string,
  search: string,
  locationState: unknown,
): boolean {
  const active = resolveActiveNavTo(pathname, search, locationState)
  if (itemTo === '/ads' || itemTo === '/reqs-offers') return active === '/ads'
  if (itemTo === '/orders/all' || itemTo.startsWith('/reqs-offers?nav=orders')) {
    return active === '/orders/all'
  }
  return active === itemTo
}
