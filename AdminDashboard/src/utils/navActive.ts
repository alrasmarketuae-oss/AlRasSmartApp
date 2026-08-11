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
    return fromQuery?.get('nav') === 'orders'
      ? '/reqs-offers?nav=orders'
      : '/reqs-offers'
  }

  if (pathname === '/reqs-offers' || pathname.startsWith('/reqs-offers/')) {
    const params = new URLSearchParams(search.startsWith('?') ? search.slice(1) : search)
    if (params.get('nav') === 'orders') return '/reqs-offers?nav=orders'
    return '/reqs-offers'
  }

  if (pathname === '/ads' || pathname.startsWith('/ads/')) {
    const params = new URLSearchParams(search.startsWith('?') ? search.slice(1) : search)
    if (params.get('adEdits') === '1' || fromQuery?.get('adEdits') === '1') {
      return '/ads?adEdits=1'
    }
    const typeId = params.get('productTypeId') || fromQuery?.get('productTypeId') || ''
    const channel = params.get('channel') || fromQuery?.get('channel') || ''
    if (channel === 'categories') return '/ads?channel=categories'
    if (typeId === '1') return '/ads?productTypeId=1'
    if (typeId === '2') return '/ads?productTypeId=2'
    if (typeId === '3') return '/ads?productTypeId=3'
    return '/ads'
  }

  if (pathname === '/orders' || pathname.startsWith('/orders/')) {
    if (pathname.startsWith('/orders/all')) return '/orders/all'
    if (pathname.startsWith('/orders/retail')) return '/orders/retail'
    if (pathname.startsWith('/orders/booking')) return '/orders/booking'
    if (pathname.startsWith('/orders/offers')) return '/orders/offers'
    if (pathname.startsWith('/orders/categories')) return '/orders/categories'

    if (fromPath.startsWith('/orders/all')) return '/orders/all'
    if (fromPath.startsWith('/orders/retail')) return '/orders/retail'
    if (fromPath.startsWith('/orders/booking')) return '/orders/booking'
    if (fromPath.startsWith('/orders/offers')) return '/orders/offers'
    if (fromPath.startsWith('/orders/categories')) return '/orders/categories'

    return '/orders/retail'
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
  return resolveActiveNavTo(pathname, search, locationState) === itemTo
}
