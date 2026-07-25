import { useMemo, useState } from 'react'
import EmployeePermissionChecklist from '../components/employees/EmployeePermissionChecklist'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import {
  useCreateEmployeeMutation,
  useDeleteEmployeeMutation,
  useGetEmployeesQuery,
  useGetPermissionDefinitionsQuery,
  useUpdateEmployeeMutation,
} from '../store'
import type { AdminEmployee } from '../types/employee'
import { getRtkErrorMessage } from '../utils/rtkError'

type EmployeeFormState = {
  fullName: string
  email: string
  phoneNumber: string
  password: string
  newPassword: string
  isActive: boolean
  permissions: string[]
}

const emptyForm = (): EmployeeFormState => ({
  fullName: '',
  email: '',
  phoneNumber: '',
  password: '',
  newPassword: '',
  isActive: true,
  permissions: [],
})

export default function EmployeesPage() {
  const { t } = useAppPreferences()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [editing, setEditing] = useState<AdminEmployee | null>(null)
  const [isCreating, setIsCreating] = useState(false)
  const [form, setForm] = useState<EmployeeFormState>(emptyForm)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  const { data: definitions = [] } = useGetPermissionDefinitionsQuery(undefined, {
    refetchOnMountOrArgChange: true,
  })
  const { data, isLoading } = useGetEmployeesQuery({ page, pageSize: 20, search: search.trim() || undefined })
  const [createEmployee, { isLoading: isCreatingEmployee }] = useCreateEmployeeMutation()
  const [updateEmployee, { isLoading: isUpdatingEmployee }] = useUpdateEmployeeMutation()
  const [deleteEmployee] = useDeleteEmployeeMutation()

  const employees = data?.items ?? []
  const totalPages = data?.totalPages ?? 1
  const showForm = isCreating || editing !== null
  const isSaving = isCreatingEmployee || isUpdatingEmployee

  const permissionLabels = useMemo(() => {
    const map = new Map<string, string>()
    definitions.forEach((item) => map.set(item.key, item.labelAr))
    return map
  }, [definitions])

  function openCreate() {
    setEditing(null)
    setIsCreating(true)
    setForm(emptyForm())
    setError(null)
    setSuccess(null)
  }

  function openEdit(employee: AdminEmployee) {
    setIsCreating(false)
    setEditing(employee)
    setForm({
      fullName: employee.fullName,
      email: employee.email,
      phoneNumber: employee.phoneNumber ?? '',
      password: '',
      newPassword: '',
      isActive: employee.isActive,
      permissions: [...employee.permissions],
    })
    setError(null)
    setSuccess(null)
  }

  function closeForm() {
    setEditing(null)
    setIsCreating(false)
    setForm(emptyForm())
  }

  async function handleSubmit() {
    setError(null)
    setSuccess(null)

    try {
      if (isCreating) {
        await createEmployee({
          fullName: form.fullName.trim(),
          email: form.email.trim(),
          password: form.password,
          phoneNumber: form.phoneNumber.trim() || undefined,
          permissions: form.permissions,
        }).unwrap()
        setSuccess(t('employees.createSuccess'))
      } else if (editing) {
        await updateEmployee({
          employeeId: editing.id,
          body: {
            fullName: form.fullName.trim(),
            phoneNumber: form.phoneNumber.trim() || undefined,
            isActive: form.isActive,
            permissions: form.permissions,
            newPassword: form.newPassword.trim() || undefined,
          },
        }).unwrap()
        setSuccess(t('employees.updateSuccess'))
      }

      closeForm()
    } catch (err) {
      setError(getRtkErrorMessage(err as never, t('employees.saveError')))
    }
  }

  async function handleDelete(employee: AdminEmployee) {
    if (!window.confirm(t('employees.deleteConfirm', { name: employee.fullName }))) return

    try {
      await deleteEmployee(employee.id).unwrap()
      setSuccess(t('employees.deleteSuccess'))
      if (editing?.id === employee.id) closeForm()
    } catch (err) {
      setError(getRtkErrorMessage(err as never, t('employees.deleteError')))
    }
  }

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="admin-text text-2xl font-bold">{t('employees.title')}</h1>
          <p className="admin-text-muted mt-1 text-sm">{t('employees.subtitle')}</p>
        </div>
        <button type="button" onClick={openCreate} className="admin-btn-primary px-5 py-2.5 text-sm font-bold">
          {t('employees.add')}
        </button>
      </div>

      {success ? <div className="admin-alert-success">{success}</div> : null}
      {error ? <div className="admin-alert-error">{error}</div> : null}

      <div className="admin-card overflow-hidden">
        <div className="admin-border border-b px-4 py-4 sm:px-6">
          <input
            type="search"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            placeholder={t('employees.searchPlaceholder')}
            className="admin-input w-full max-w-md px-4 py-2.5 text-sm"
          />
        </div>

        {isLoading ? (
          <div className="flex justify-center py-20">
            <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
          </div>
        ) : employees.length === 0 ? (
          <p className="admin-text-muted px-6 py-16 text-center text-sm">{t('employees.empty')}</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="admin-data-table min-w-[760px] table-fixed">
              <colgroup>
                <col className="w-[18%]" />
                <col className="w-[22%]" />
                <col className="w-[30%]" />
                <col className="w-[12%]" />
                <col className="w-[18%]" />
              </colgroup>
              <thead>
                <tr>
                  <th>{t('employees.name')}</th>
                  <th>{t('employees.email')}</th>
                  <th>{t('employees.permissions')}</th>
                  <th>{t('users.status')}</th>
                  <th className="admin-table-cell-end">{t('employees.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {employees.map((employee) => (
                  <tr key={employee.id} className="admin-border border-t">
                    <td className="admin-text font-semibold">{employee.fullName}</td>
                    <td className="admin-text-muted">{employee.email}</td>
                    <td>
                      <div className="flex flex-wrap gap-1.5">
                        {employee.permissions.slice(0, 4).map((key) => (
                          <span
                            key={key}
                            className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600 dark:bg-slate-800 dark:text-slate-300"
                          >
                            {permissionLabels.get(key) ?? key}
                          </span>
                        ))}
                        {employee.permissions.length > 4 ? (
                          <span className="admin-text-subtle text-xs">+{employee.permissions.length - 4}</span>
                        ) : null}
                      </div>
                    </td>
                    <td>
                      <span
                        className={`inline-flex rounded-full px-3 py-1 text-xs font-bold ${
                          employee.isActive
                            ? 'bg-emerald-100 text-emerald-700'
                            : 'bg-slate-200 text-slate-600'
                        }`}
                      >
                        {employee.isActive ? t('employees.active') : t('employees.inactive')}
                      </span>
                    </td>
                    <td className="admin-table-cell-end">
                      <div className="inline-flex flex-wrap justify-end gap-2">
                        <button type="button" onClick={() => openEdit(employee)} className="admin-btn-ghost text-xs">
                          {t('employees.edit')}
                        </button>
                        <button
                          type="button"
                          onClick={() => void handleDelete(employee)}
                          className="rounded-xl px-3 py-2 text-xs font-bold text-red-600 transition hover:bg-red-50"
                        >
                          {t('employees.delete')}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {totalPages > 1 ? (
          <div
            dir="ltr"
            className="admin-border flex items-center justify-between gap-3 border-t px-4 py-4 sm:px-6"
          >
            <button type="button" disabled={page <= 1} onClick={() => setPage((p) => p - 1)} className="admin-btn-ghost">
              {t('previous')}
            </button>
            <span className="admin-text-muted text-sm">{t('pageOf', { page, total: totalPages })}</span>
            <button
              type="button"
              disabled={page >= totalPages}
              onClick={() => setPage((p) => p + 1)}
              className="admin-btn-ghost"
            >
              {t('next')}
            </button>
          </div>
        ) : null}
      </div>

      {showForm ? (
        <div className="admin-card p-5 sm:p-6">
          <div className="mb-5 flex items-center justify-between gap-3">
            <h2 className="admin-text text-lg font-bold">
              {isCreating ? t('employees.add') : t('employees.editEmployee')}
            </h2>
            <button type="button" onClick={closeForm} className="admin-btn-ghost text-sm">
              {t('closeMenu')}
            </button>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <label className="block text-start">
              <span className="admin-text mb-2 block text-sm font-medium">{t('employees.name')}</span>
              <input
                className="admin-input w-full px-4 py-3"
                value={form.fullName}
                onChange={(e) => setForm((prev) => ({ ...prev, fullName: e.target.value }))}
              />
            </label>

            <label className="block text-start">
              <span className="admin-text mb-2 block text-sm font-medium">{t('employees.email')}</span>
              <input
                type="email"
                className="admin-input w-full px-4 py-3"
                value={form.email}
                disabled={!isCreating}
                onChange={(e) => setForm((prev) => ({ ...prev, email: e.target.value }))}
              />
            </label>

            <label className="block text-start">
              <span className="admin-text mb-2 block text-sm font-medium">{t('employees.phone')}</span>
              <input
                className="admin-input w-full px-4 py-3"
                value={form.phoneNumber}
                onChange={(e) => setForm((prev) => ({ ...prev, phoneNumber: e.target.value }))}
              />
            </label>

            {isCreating ? (
              <label className="block text-start">
                <span className="admin-text mb-2 block text-sm font-medium">{t('employees.password')}</span>
                <input
                  type="password"
                  className="admin-input w-full px-4 py-3"
                  value={form.password}
                  onChange={(e) => setForm((prev) => ({ ...prev, password: e.target.value }))}
                />
              </label>
            ) : (
              <label className="block text-start">
                <span className="admin-text mb-2 block text-sm font-medium">{t('employees.newPassword')}</span>
                <input
                  type="password"
                  className="admin-input w-full px-4 py-3"
                  value={form.newPassword}
                  onChange={(e) => setForm((prev) => ({ ...prev, newPassword: e.target.value }))}
                  placeholder={t('employees.newPasswordHint')}
                />
              </label>
            )}

            {!isCreating ? (
              <label className="flex items-center gap-3 text-start md:col-span-2">
                <input
                  type="checkbox"
                  className="h-4 w-4 rounded border-slate-300 text-[#3B7FC7]"
                  checked={form.isActive}
                  onChange={(e) => setForm((prev) => ({ ...prev, isActive: e.target.checked }))}
                />
                <span className="admin-text text-sm font-medium">{t('employees.active')}</span>
              </label>
            ) : null}
          </div>

          <div className="mt-6">
            <h3 className="admin-text mb-3 text-base font-bold">{t('employees.permissionsTitle')}</h3>
            <EmployeePermissionChecklist
              definitions={definitions}
              selected={form.permissions}
              onChange={(permissions) => setForm((prev) => ({ ...prev, permissions }))}
            />
          </div>

          <div className="mt-6 flex flex-wrap gap-3">
            <button
              type="button"
              disabled={isSaving}
              onClick={() => void handleSubmit()}
              className="admin-btn-primary px-5 py-2.5 text-sm font-bold disabled:opacity-60"
            >
              {isSaving ? t('saving') : t('employees.save')}
            </button>
            <button type="button" onClick={closeForm} className="admin-btn-ghost px-5 py-2.5 text-sm font-bold">
              {t('cancel')}
            </button>
          </div>
        </div>
      ) : null}
    </div>
  )
}
