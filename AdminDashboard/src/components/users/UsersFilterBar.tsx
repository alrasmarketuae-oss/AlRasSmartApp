import { useAppPreferences } from '../../context/AppPreferencesProvider'

type UsersFilterBarProps = {
  tableSearch: string
  onTableSearchChange: (value: string) => void
  typeFilter: string
  onTypeFilterChange: (value: string) => void
  statusFilter: string
  onStatusFilterChange: (value: string) => void
  joinDate: string
  onJoinDateChange: (value: string) => void
  onApply: () => void
}

const dateInputClass =
  'admin-input h-10 w-full [&::-webkit-calendar-picker-indicator]:absolute [&::-webkit-calendar-picker-indicator]:inset-0 [&::-webkit-calendar-picker-indicator]:h-full [&::-webkit-calendar-picker-indicator]:w-full [&::-webkit-calendar-picker-indicator]:cursor-pointer [&::-webkit-calendar-picker-indicator]:opacity-0'

export default function UsersFilterBar({
  tableSearch,
  onTableSearchChange,
  typeFilter,
  onTypeFilterChange,
  statusFilter,
  onStatusFilterChange,
  joinDate,
  onJoinDateChange,
  onApply,
}: UsersFilterBarProps) {
  const { t, dir } = useAppPreferences()

  return (
    <div
      dir={dir}
      className="grid grid-cols-1 gap-3 px-4 py-4 sm:grid-cols-2 sm:px-6 lg:grid-cols-3 xl:grid-cols-[minmax(0,1fr)_repeat(3,minmax(0,140px))_auto]"
    >
      <div className="w-full sm:col-span-2 xl:col-span-1">
        <input
          type="search"
          dir={dir}
          value={tableSearch}
          onChange={(e) => onTableSearchChange(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && onApply()}
          placeholder={t('search')}
          className="admin-input h-10 w-full [&::-webkit-search-cancel-button]:hidden [&::-webkit-search-decoration]:hidden"
        />
      </div>

      <div className="relative w-full">
        <input
          type="date"
          value={joinDate}
          onChange={(e) => onJoinDateChange(e.target.value)}
          className={`${dateInputClass} ${joinDate ? '' : 'text-transparent'}`}
        />
        {!joinDate ? (
          <span
            dir="ltr"
            className="admin-text-subtle pointer-events-none absolute inset-0 flex items-center px-3 text-[11px]"
          >
            dd / mm / yyyy
          </span>
        ) : null}
      </div>

      <div className="w-full">
        <select
          value={typeFilter}
          onChange={(e) => onTypeFilterChange(e.target.value)}
          className={`admin-input h-10 w-full appearance-none ${!typeFilter ? 'admin-text-subtle' : ''}`}
        >
          <option value="">{t('users.allTypes')}</option>
          <option value="3">{t('users.client')}</option>
          <option value="2">{t('users.supplier')}</option>
          <option value="1">{t('users.admin')}</option>
        </select>
      </div>

      <div className="w-full">
        <select
          value={statusFilter}
          onChange={(e) => onStatusFilterChange(e.target.value)}
          className={`admin-input h-10 w-full appearance-none ${!statusFilter ? 'admin-text-subtle' : ''}`}
        >
          <option value="">{t('users.allStatuses')}</option>
          <option value="complete">{t('users.complete')}</option>
          <option value="incomplete">{t('users.incomplete')}</option>
          <option value="pending">{t('users.pending')}</option>
          <option value="rejected">{t('users.rejected')}</option>
          <option value="suspended">{t('users.suspended')}</option>
        </select>
      </div>

      <button
        type="button"
        onClick={onApply}
        className="keep-white h-10 w-full rounded-xl bg-[#3B7FC7] px-5 text-sm font-semibold text-white transition hover:bg-[#2f6ab0] sm:w-auto sm:justify-self-start xl:justify-self-auto"
      >
        {t('filter')}
      </button>
    </div>
  )
}
