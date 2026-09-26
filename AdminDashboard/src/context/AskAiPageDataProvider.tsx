import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'

export type AskAiActingCompany = {
  ownerUserId: string
  companyName: string
  /** Seed the chat with a create-ad request when the panel opens. */
  seedMessage?: string
}

type AskAiPageDataContextValue = {
  setPageData: (data: unknown) => void
  clearPageData: () => void
  getPageData: () => unknown
  actingCompany: AskAiActingCompany | null
  setActingCompany: (company: AskAiActingCompany | null) => void
  /** Request the layout to open Ask AI (optionally as a company). */
  requestOpenAskAi: (company?: AskAiActingCompany | null) => void
  consumeOpenAskAiRequest: () => AskAiActingCompany | null | undefined
  /** Increments when Ask AI should open. */
  openTick: number
}

const AskAiPageDataContext = createContext<AskAiPageDataContextValue | null>(null)

export function AskAiPageDataProvider({ children }: { children: ReactNode }) {
  const dataRef = useRef<unknown>(null)
  const openRequestRef = useRef<AskAiActingCompany | null | undefined>(undefined)
  const [actingCompany, setActingCompanyState] = useState<AskAiActingCompany | null>(null)
  const [openTick, setOpenTick] = useState(0)

  const setPageData = useCallback((data: unknown) => {
    dataRef.current = data
  }, [])

  const clearPageData = useCallback(() => {
    dataRef.current = null
  }, [])

  const getPageData = useCallback(() => dataRef.current, [])

  const setActingCompany = useCallback((company: AskAiActingCompany | null) => {
    setActingCompanyState(company)
  }, [])

  const requestOpenAskAi = useCallback((company?: AskAiActingCompany | null) => {
    openRequestRef.current = company === undefined ? null : company
    if (company) {
      setActingCompanyState(company)
    }
    setOpenTick((n) => n + 1)
  }, [])

  const consumeOpenAskAiRequest = useCallback(() => {
    const value = openRequestRef.current
    openRequestRef.current = undefined
    return value
  }, [])

  const value = useMemo(
    () => ({
      setPageData,
      clearPageData,
      getPageData,
      actingCompany,
      setActingCompany,
      requestOpenAskAi,
      consumeOpenAskAiRequest,
      // expose tick so layout can react
      openTick,
    }),
    [
      setPageData,
      clearPageData,
      getPageData,
      actingCompany,
      setActingCompany,
      requestOpenAskAi,
      consumeOpenAskAiRequest,
      openTick,
    ],
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
