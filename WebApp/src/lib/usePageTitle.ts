import { useEffect } from 'react'
import { useI18n } from '../i18n/I18nProvider'

export function usePageTitle(title?: string) {
  const { t } = useI18n()
  useEffect(() => {
    const app = t('appName')
    document.title = title ? `${title} | ${app}` : app
  }, [title, t])
}
