import { useAppPreferences } from '../context/AppPreferencesProvider'

type ComingSoonPageProps = {
  titleKey: string
}

export default function ComingSoonPage({ titleKey }: ComingSoonPageProps) {
  const { t } = useAppPreferences()
  const title = t(titleKey)

  return (
    <div className="admin-card flex min-h-[50vh] flex-col items-center justify-center p-10">
      <h1 className="admin-text text-2xl font-bold">
        {t('comingSoon.prefix') ? `${t('comingSoon.prefix')} ${title}` : title}
      </h1>
      <p className="admin-text-muted mt-2 capitalize">{t('comingSoon.suffix')}</p>
    </div>
  )
}
