import { ACTIVITY_ICON_BY_TYPE, PROJECT_IMAGES } from '../../constants/projectImages'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { ActivityItem } from '../../types/dashboard'
import { formatTimeAgo } from '../../utils/formatTimeAgo'

type LiveActivityFeedProps = {
  items: ActivityItem[]
}

function ActivityIcon({ type }: { type: string }) {
  const src = ACTIVITY_ICON_BY_TYPE[type] ?? PROJECT_IMAGES.activityNewOrder

  return (
    <img
      src={src}
      alt=""
      className="h-10 w-10 shrink-0 object-contain"
    />
  )
}

export default function LiveActivityFeed({ items }: LiveActivityFeedProps) {
  const { t, locale } = useAppPreferences()

  const localizeActivityTitle = (item: ActivityItem): string => {
    if (locale === 'ar') return item.title

    const normalizedTitle = item.title.trim()
    if (normalizedTitle === 'مستخدم جديد' || normalizedTitle === 'مستخدم جديد مسجل') {
      return t('alerts.newUserTitle')
    }
    if (normalizedTitle === 'طلب جديد') {
      return t('alerts.newOrderTitle')
    }
    if (normalizedTitle === 'إعلان شحن جديد بانتظار المراجعة') {
      return t('alerts.newShippingAdTitle')
    }

    switch (item.type) {
      case 'user':
      case 'company':
        return t('alerts.newUserTitle')
      case 'order':
        return t('alerts.newOrderTitle')
      case 'shipping':
        return t('alerts.newShippingAdTitle')
      case 'approval':
        return t('alerts.newAdTitle')
      case 'update':
        return t('alerts.adEditTitle')
      case 'profileEdit':
        return t('alerts.profileEditTitle')
      default:
        return item.title
    }
  }

  return (
    <div className="admin-card rounded-2xl border border-slate-100 p-6 shadow-sm dark:border-slate-300">
      <div className="mb-5 flex items-center justify-between">
        <h2 className="admin-text text-lg font-bold">{t('dashboard.liveActivity')}</h2>
        <span className="admin-badge-live">
          <span className="h-2 w-2 animate-pulse rounded-full bg-emerald-500" />
          {t('dashboard.live')}
        </span>
      </div>
      <ul className="max-h-[28rem] space-y-4 overflow-y-auto pe-1">
        {items.length === 0 ? (
          <li className="admin-text-subtle py-8 text-center text-sm">
            {t('dashboard.noRecentActivity')}
          </li>
        ) : (
          items.map((item, index) => (
            <li
              key={`${item.type}-${item.createdAt}-${index}`}
              className="admin-row-hover flex items-start gap-3 rounded-xl p-2"
            >
              <ActivityIcon type={item.type} />
              <div className="min-w-0 flex-1 text-right">
                <p className="admin-text text-sm font-semibold">{localizeActivityTitle(item)}</p>
                <p className="admin-text-subtle mt-1 text-xs">
                  {formatTimeAgo(item.createdAt, locale) || item.timeAgo}
                </p>
              </div>
            </li>
          ))
        )}
      </ul>
    </div>
  )
}
