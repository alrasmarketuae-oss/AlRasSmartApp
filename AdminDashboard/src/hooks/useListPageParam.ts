import { useCallback } from 'react'
import { useSearchParams } from 'react-router-dom'
import { LIST_PAGE_PARAM, readListPage } from '../utils/listPageParams'

export function useListPageParam() {
  const [searchParams, setSearchParams] = useSearchParams()
  const page = readListPage(searchParams)

  const setPage = useCallback(
    (next: number | ((current: number) => number)) => {
      setSearchParams(
        (prev) => {
          const nextParams = new URLSearchParams(prev)
          const current = readListPage(prev)
          const resolved = typeof next === 'function' ? next(current) : next

          if (resolved <= 1) {
            nextParams.delete(LIST_PAGE_PARAM)
          } else {
            nextParams.set(LIST_PAGE_PARAM, String(resolved))
          }

          return nextParams
        },
        { replace: true },
      )
    },
    [setSearchParams],
  )

  return { page, setPage }
}
