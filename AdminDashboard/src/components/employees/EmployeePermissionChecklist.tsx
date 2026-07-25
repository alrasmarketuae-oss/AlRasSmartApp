import { useMemo } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { AdminPermissionDefinition } from '../../types/employee'

type EmployeePermissionChecklistProps = {
  definitions: AdminPermissionDefinition[]
  selected: string[]
  onChange: (next: string[]) => void
  disabled?: boolean
}

export default function EmployeePermissionChecklist({
  definitions,
  selected,
  onChange,
  disabled = false,
}: EmployeePermissionChecklistProps) {
  const { locale } = useAppPreferences()

  const groups = useMemo(() => {
    const map = new Map<string, AdminPermissionDefinition[]>()
    for (const item of definitions) {
      const list = map.get(item.groupKey) ?? []
      list.push(item)
      map.set(item.groupKey, list)
    }

    return Array.from(map.entries()).map(([groupKey, items]) => ({
      groupKey,
      label: locale === 'ar' ? items[0]?.groupLabelAr : items[0]?.groupLabelEn,
      items,
    }))
  }, [definitions, locale])

  function toggle(key: string) {
    if (disabled) return
    if (selected.includes(key)) {
      onChange(selected.filter((item) => item !== key))
      return
    }
    onChange([...selected, key])
  }

  return (
    <div className="space-y-4">
      {groups.map((group) => (
        <div key={group.groupKey} className="admin-border rounded-2xl border p-4">
          <h3 className="admin-text mb-3 text-sm font-bold">{group.label}</h3>
          <div className="grid gap-2 sm:grid-cols-2">
            {group.items.map((item) => {
              const checked = selected.includes(item.key)
              const label = locale === 'ar' ? item.labelAr : item.labelEn
              return (
                <label
                  key={item.key}
                  className={`flex cursor-pointer items-start gap-3 rounded-xl border px-3 py-2.5 text-sm transition ${
                    checked
                      ? 'border-[#3B7FC7] bg-[#3B7FC7]/5'
                      : 'admin-border border-slate-200 dark:border-slate-700'
                  } ${disabled ? 'cursor-not-allowed opacity-60' : ''}`}
                >
                  <input
                    type="checkbox"
                    className="mt-0.5 h-4 w-4 rounded border-slate-300 text-[#3B7FC7] focus:ring-[#3B7FC7]"
                    checked={checked}
                    disabled={disabled}
                    onChange={() => toggle(item.key)}
                  />
                  <span className="flex min-w-0 flex-1 flex-col gap-1">
                    <span className="admin-text flex flex-wrap items-center gap-2 font-medium">
                      {label}
                      {item.key === 'users.profile_edits' ||
                      item.key === 'products.ad_edits' ||
                      item.key === 'orders.reqs_offers' ||
                      item.key === 'audit.view' ? (
                        <span className="rounded-md bg-[#3B7FC7]/15 px-1.5 py-0.5 text-[10px] font-semibold text-[#3B7FC7]">
                          {locale === 'ar' ? 'صفحة' : 'page'}
                        </span>
                      ) : null}
                    </span>
                  </span>
                </label>
              )
            })}
          </div>
        </div>
      ))}
    </div>
  )
}
