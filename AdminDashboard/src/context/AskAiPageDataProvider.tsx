import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  type ReactNode,
} from 'react'

type AskAiPageDataContextValue = {
  /** Register structured data for the current screen (replaced on each call). */
  setPageData: (data: unknown) => void
  clearPageData: () => void
  getPageData: () => unknown
}

const AskAiPageDataContext = createContext<AskAiPageDataContextValue | null>(null)

export function AskAiPageDataProvider({ children }: { children: ReactNode }) {
  const dataRef = useRef<unknown>(null)

  const setPageData = useCallback((data: unknown) => {
    dataRef.current = data
  }, [])

  const clearPageData = useCallback(() => {
    dataRef.current = null
  }, [])

  const getPageData = useCallback(() => dataRef.current, [])

  const value = useMemo(
    () => ({ setPageData, clearPageData, getPageData }),
    [setPageData, clearPageData, getPageData],
  )

  return (
    <AskAiPageDataContext.Provider value={value}>
      {children}
    </AskAiPageDataContext.Provider>
  )
}

export function useAskAiPageData(): AskAiPageDataContextValue {
  const ctx = useContext(AskAiPageDataContext)
  if (!ctx) {
    throw new Error('useAskAiPageData must be used within AskAiPageDataProvider')
  }
  return ctx
}
