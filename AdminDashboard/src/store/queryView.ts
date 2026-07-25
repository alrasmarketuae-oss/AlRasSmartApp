/**
 * Maps RTK Query flags to UI states.
 * - initial load: no cached data yet → full-page spinner
 * - background: cache shown, optional subtle "updating" indicator
 */
export function queryViewState(query: {
  isLoading: boolean
  isFetching: boolean
}) {
  return {
    showInitialLoader: query.isLoading,
    showBackgroundUpdate: query.isFetching && !query.isLoading,
  }
}
