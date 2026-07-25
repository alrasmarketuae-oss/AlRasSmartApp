export const LIST_PAGE_PARAM = 'page'

export type ListReturnState = {
  from?: string
}

export function readListPage(params: URLSearchParams): number {
  const raw = params.get(LIST_PAGE_PARAM)
  if (!raw) return 1
  const parsed = Number.parseInt(raw, 10)
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 1
}

export function buildListReturnState(pathname: string, search: string): ListReturnState {
  return { from: `${pathname}${search}` }
}

export function resolveReturnToListPath(
  fallbackPath: string,
  locationState: unknown,
): string {
  const from = (locationState as ListReturnState | null)?.from
  if (typeof from === 'string' && from.startsWith('/') && !from.includes('://')) {
    return from
  }
  return fallbackPath
}
