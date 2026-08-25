import { useEffect } from 'react'
import { useAskAiPageData } from '../context/AskAiPageDataProvider'

export function useRegisterAskAiPageData(data: unknown, enabled = true): void {
  const { setPageData, clearPageData } = useAskAiPageData()

  useEffect(() => {
    if (!enabled) {
      clearPageData()
      return
    }
    setPageData(data)
    return () => clearPageData()
  }, [data, enabled, setPageData, clearPageData])
}
