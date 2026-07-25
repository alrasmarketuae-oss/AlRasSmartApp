import { useCallback } from 'react'
import { useSearchParams } from 'react-router-dom'
import { GLOBAL_SEARCH_PARAM, readGlobalSearchTerm } from '../utils/globalSearch'

export function useGlobalSearchParam() {
  const [searchParams, setSearchParams] = useSearchParams()
  const urlSearch = readGlobalSearchTerm(searchParams)

  const setUrlSearch = useCallback(
    (term: string, replace = true) => {
      setSearchParams(
        (prev) => {
          const next = new URLSearchParams(prev)
          const trimmed = term.trim()
          if (trimmed) next.set(GLOBAL_SEARCH_PARAM, trimmed)
          else next.delete(GLOBAL_SEARCH_PARAM)
          return next
        },
        { replace },
      )
    },
    [setSearchParams],
  )

  return { urlSearch, setUrlSearch }
}
