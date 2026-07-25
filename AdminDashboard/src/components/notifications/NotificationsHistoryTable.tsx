import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { AdminPushNotificationItem } from '../../types/adminNotification'

type NotificationsHistoryTableProps = {
  items: AdminPushNotificationItem[]
  audienceLabel: (value: string, targetUserName?: string | null) => string
}

function AudienceBadge({ label }: { label: string }) {
  return (
    <span className="inline-block rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700 dark:bg-blue-950/40 dark:text-blue-300">
      {label}
    </span>
  )
}

function CountBadge({
  value,
  tone,
}: {
  value: number
  tone: 'success' | 'danger'
}) {
  const classes =
    tone === 'success'
      ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300'
      : 'bg-red-50 text-red-700 dark:bg-red-950/40 dark:text-red-300'

  return (
    <span className={`inline-flex min-w-[2.5rem] justify-center rounded-lg px-2.5 py-1 text-xs font-bold ${classes}`}>
      {value}
    </span>
  )
}

function NotificationMobileCard({
  item,
  audienceLabel,
  formattedDate,
}: {
  item: AdminPushNotificationItem
  audienceLabel: (value: string, targetUserName?: string | null) => string
  formattedDate: string
}) {
  const { t } = useAppPreferences()

  return (
    <article className="admin-border space-y-3 rounded-xl border p-4">
      <div className="flex flex-wrap items-start justify-between gap-2">
        <AudienceBadge label={audienceLabel(item.audience, item.targetUserName)} />
        <span className="admin-text-subtle text-xs">{formattedDate}</span>
      </div>
      <div className="text-right">
        <h3 className="admin-text font-semibold">{item.title}</h3>
        <p className="admin-text-muted mt-1 text-sm leading-relaxed">{item.body}</p>
      </div>
      <div className="flex flex-wrap items-center justify-end gap-4 text-sm">
        <span className="admin-text-muted">
          {t('notificationsPage.sent')}: <CountBadge value={item.sentCount} tone="success" />
        </span>
        <span className="admin-text-muted">
          {t('notificationsPage.failed')}: <CountBadge value={item.failedCount} tone="danger" />
        </span>
      </div>
    </article>
  )
}

export default function NotificationsHistoryTable({
  items,
  audienceLabel,
}: NotificationsHistoryTableProps) {
  const { t, locale } = useAppPreferences()

  const dateFormatter = new Intl.DateTimeFormat(locale === 'ar' ? 'ar-AE' : 'en-AE', {
    dateStyle: 'medium',
    timeStyle: 'short',
  })

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center px-6 py-16 text-center">
        <p className="admin-text font-medium">{t('noData')}</p>
        <p className="admin-text-subtle mt-2 text-sm">{t('notificationsPage.emptyHistory')}</p>
      </div>
    )
  }

  return (
    <>
      <div className="space-y-3 p-4 lg:hidden">
        {items.map((item) => (
          <NotificationMobileCard
            key={item.id}
            item={item}
            audienceLabel={audienceLabel}
            formattedDate={dateFormatter.format(new Date(item.createdAt))}
          />
        ))}
      </div>

      <div className="hidden overflow-x-auto lg:block">
        <table className="admin-data-table min-w-[880px] table-fixed">
          <colgroup>
            <col className="w-[34%]" />
            <col className="w-[18%]" />
            <col className="w-[10%]" />
            <col className="w-[10%]" />
            <col className="w-[28%]" />
          </colgroup>
          <thead>
            <tr>
              <th>{t('notificationsPage.notificationTitle')}</th>
              <th>{t('notificationsPage.audience')}</th>
              <th className="admin-table-cell-center">{t('notificationsPage.sent')}</th>
              <th className="admin-table-cell-center">{t('notificationsPage.failed')}</th>
              <th className="admin-table-cell-end">{t('notificationsPage.date')}</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item) => (
              <tr key={item.id} className="admin-border border-t admin-row-hover">
                <td className="align-top">
                  <p className="admin-text font-semibold">{item.title}</p>
                  <p className="admin-text-muted mt-1 text-xs leading-relaxed">{item.body}</p>
                  {item.type ? (
                    <p className="admin-text-subtle mt-2 text-[11px]">{item.type}</p>
                  ) : null}
                </td>
                <td>
                  <AudienceBadge label={audienceLabel(item.audience, item.targetUserName)} />
                </td>
                <td className="admin-table-cell-center">
                  <CountBadge value={item.sentCount} tone="success" />
                </td>
                <td className="admin-table-cell-center">
                  <CountBadge value={item.failedCount} tone="danger" />
                </td>
                <td className="admin-table-cell-end">
                  <span className="admin-text-muted whitespace-nowrap">
                    {dateFormatter.format(new Date(item.createdAt))}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  )
}
