import { useEffect, useMemo, useState } from 'react'
import type { FormEvent } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { hasPermission, PERMISSIONS } from '../lib/permissions'
import {
  useGetAdminUserDetailQuery,
  useUpdateAdminUserMutation,
} from '../store'
import type { UpdateAdminUserPayload } from '../store/adminApi'
import type { AdminUserDetail } from '../types/adminUserDetail'
import { getRtkErrorMessage } from '../utils/rtkError'

type FormState = {
  fullName: string
  companyName: string
  email: string
  password: string
  phoneNumber: string
  landNumber: string
  licenseNumber: string
  commercialRegister: string
  taxNumber: string
  website: string
  preferredLanguage: 'en' | 'ar'
}

type EditableAccountType = 'person' | 'supplier' | 'companyCustomer' | 'shippingCompany'

function resolveAccountType(user: AdminUserDetail): EditableAccountType | null {
  if (user.roleId === 3) return 'person'
  if (user.roleId === 5) return 'shippingCompany'
  if (user.roleId === 2) return user.isCustomer ? 'companyCustomer' : 'supplier'
  return null
}

function formFromUser(user: AdminUserDetail): FormState {
  return {
    fullName: user.fullName?.trim() || '',
    companyName: user.companyName?.trim() || '',
    email: user.email?.trim() || '',
    password: '',
    phoneNumber: user.phoneNumber?.trim() || '',
    landNumber: user.landNumber?.trim() || '',
    licenseNumber: user.licenseNumber?.trim() || '',
    commercialRegister: user.commercialRegister?.trim() || '',
    taxNumber: user.taxNumber?.trim() || '',
    website: user.website?.trim() || '',
    preferredLanguage: user.preferredLanguage?.trim().toLowerCase() === 'ar' ? 'ar' : 'en',
  }
}

export default function EditUserPage() {
  const { userId = '' } = useParams()
  const { t, locale } = useAppPreferences()
  const navigate = useNavigate()
  const canManage = hasPermission(PERMISSIONS.usersManage)
  const [form, setForm] = useState<FormState | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [updateUser, { isLoading }] = useUpdateAdminUserMutation()

  const { data: user, isLoading: isLoadingUser, error: loadError } = useGetAdminUserDetailQuery(
    userId,
    { skip: !userId || !canManage, refetchOnMountOrArgChange: true },
  )

  const accountType = useMemo(
    () => (user ? resolveAccountType(user) : null),
    [user],
  )

  useEffect(() => {
    if (user) setForm(formFromUser(user))
  }, [user])

  const showCompanyFields =
    accountType === 'supplier' ||
    accountType === 'companyCustomer' ||
    accountType === 'shippingCompany'
  const showPersonName =
    accountType === 'person' ||
    accountType === 'supplier' ||
    accountType === 'companyCustomer'
  const phoneRequired = accountType === 'shippingCompany'

  function patchForm(patch: Partial<FormState>) {
    setForm((prev) => (prev ? { ...prev, ...patch } : prev))
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    if (!canManage || !accountType || !form || !userId) return
    setError(null)
    setSuccess(null)

    const payload: UpdateAdminUserPayload = {
      email: form.email.trim(),
      phoneNumber: form.phoneNumber.trim() || undefined,
      preferredLanguage: form.preferredLanguage,
      fullName: form.fullName.trim() || undefined,
      companyName: form.companyName.trim() || undefined,
      landNumber: form.landNumber.trim() || undefined,
      licenseNumber: form.licenseNumber.trim() || undefined,
      commercialRegister: form.commercialRegister.trim() || undefined,
      taxNumber: form.taxNumber.trim() || undefined,
      website: form.website.trim() || undefined,
    }

    const password = form.password.trim()
    if (password) payload.password = password

    try {
      const result = await updateUser({ userId, body: payload }).unwrap()
      setSuccess(result.message || t('users.editUserSuccess'))
      window.setTimeout(() => {
        navigate(`/users/${userId}`)
      }, 700)
    } catch (err) {
      setError(getRtkErrorMessage(err, t('users.editUserError')))
    }
  }

  if (!canManage) {
    return (
      <div className="admin-card space-y-3 p-6">
        <p className="admin-text font-semibold">{t('users.editUserDenied')}</p>
        <Link to="/users" className="text-sm font-semibold text-[#3B7FC7] hover:underline">
          {t('users.backToList')}
        </Link>
      </div>
    )
  }

  if (!userId) {
    navigate('/users', { replace: true })
    return null
  }

  if (isLoadingUser || !form) {
    return <p className="admin-text-subtle py-16 text-center">{t('loading')}</p>
  }

  if (loadError || !user || !accountType) {
    return (
      <div className="admin-card space-y-3 px-6 py-10 text-center">
        <p className="text-sm text-red-600 dark:text-red-400">
          {getRtkErrorMessage(loadError as never, t('users.loadError'))}
        </p>
        <Link to="/users" className="text-sm font-semibold text-[#3B7FC7] hover:underline">
          {t('users.backToList')}
        </Link>
      </div>
    )
  }

  const accountTypeLabel =
    accountType === 'person'
      ? t('users.client')
      : accountType === 'companyCustomer'
        ? t('users.companyCustomer')
        : accountType === 'supplier'
          ? t('users.supplier')
          : t('users.shippingCompany')

  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="admin-text text-2xl font-bold">{t('users.editUserTitle')}</h1>
          <p className="admin-text-muted mt-2 text-sm leading-relaxed">
            {t('users.editUserDescription')}
          </p>
        </div>
        <Link
          to={`/users/${userId}`}
          className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-800"
        >
          {t('users.backToDetail')}
        </Link>
      </div>

      <div className="admin-card space-y-5 p-5 sm:p-6">
        <p className="rounded-lg bg-slate-50 px-3 py-2 text-xs font-medium text-slate-700 dark:bg-slate-800/60 dark:text-slate-200">
          {t('users.accountTypeLocked')}: <strong>{accountTypeLabel}</strong>
        </p>

        <form className="space-y-4" onSubmit={handleSubmit}>
          <div className="grid gap-3 sm:grid-cols-2">
            {showPersonName ? (
              <label className="block text-sm">
                <span className="admin-text-muted mb-1 block font-semibold">
                  {accountType === 'person' ? t('users.fullName') : t('users.ownerName')}
                </span>
                <input
                  required={accountType === 'person'}
                  value={form.fullName}
                  onChange={(e) => patchForm({ fullName: e.target.value })}
                  className="admin-input w-full"
                />
              </label>
            ) : null}

            {showCompanyFields ? (
              <label className="block text-sm">
                <span className="admin-text-muted mb-1 block font-semibold">
                  {t('users.companyName')}
                </span>
                <input
                  required
                  value={form.companyName}
                  onChange={(e) => patchForm({ companyName: e.target.value })}
                  className="admin-input w-full"
                />
              </label>
            ) : null}

            <label className="block text-sm">
              <span className="admin-text-muted mb-1 block font-semibold">{t('users.email')}</span>
              <input
                required
                type="email"
                value={form.email}
                onChange={(e) => patchForm({ email: e.target.value })}
                className="admin-input w-full"
                dir="ltr"
              />
            </label>

            <label className="block text-sm">
              <span className="admin-text-muted mb-1 block font-semibold">
                {t('users.passwordOptional')}
              </span>
              <input
                type="password"
                minLength={6}
                value={form.password}
                onChange={(e) => patchForm({ password: e.target.value })}
                className="admin-input w-full"
                dir="ltr"
                placeholder={t('users.passwordLeaveBlank')}
                autoComplete="new-password"
              />
            </label>

            <label className="block text-sm">
              <span className="admin-text-muted mb-1 block font-semibold">
                {t('users.phone')}
                {phoneRequired ? ' *' : ''}
              </span>
              <input
                required={phoneRequired}
                value={form.phoneNumber}
                onChange={(e) => patchForm({ phoneNumber: e.target.value })}
                className="admin-input w-full"
                dir="ltr"
              />
            </label>

            <label className="block text-sm">
              <span className="admin-text-muted mb-1 block font-semibold">
                {t('users.preferredLanguage')}
              </span>
              <select
                value={form.preferredLanguage}
                onChange={(e) =>
                  patchForm({
                    preferredLanguage: e.target.value === 'ar' ? 'ar' : 'en',
                  })
                }
                className="admin-input w-full"
              >
                <option value="en">{locale === 'ar' ? 'الإنجليزية' : 'English'}</option>
                <option value="ar">{locale === 'ar' ? 'العربية' : 'Arabic'}</option>
              </select>
            </label>
          </div>

          {showCompanyFields ? (
            <div className="grid gap-3 sm:grid-cols-2">
              <label className="block text-sm">
                <span className="admin-text-muted mb-1 block font-semibold">
                  {t('users.landLine')}
                </span>
                <input
                  value={form.landNumber}
                  onChange={(e) => patchForm({ landNumber: e.target.value })}
                  className="admin-input w-full"
                />
              </label>
              {accountType !== 'shippingCompany' ? (
                <label className="block text-sm">
                  <span className="admin-text-muted mb-1 block font-semibold">
                    {t('users.licenseNumber')}
                  </span>
                  <input
                    value={form.licenseNumber}
                    onChange={(e) => patchForm({ licenseNumber: e.target.value })}
                    className="admin-input w-full"
                  />
                </label>
              ) : null}
              <label className="block text-sm">
                <span className="admin-text-muted mb-1 block font-semibold">
                  {t('users.commercialRegister')}
                </span>
                <input
                  value={form.commercialRegister}
                  onChange={(e) => patchForm({ commercialRegister: e.target.value })}
                  className="admin-input w-full"
                />
              </label>
              <label className="block text-sm">
                <span className="admin-text-muted mb-1 block font-semibold">
                  {t('users.taxNumber')}
                </span>
                <input
                  value={form.taxNumber}
                  onChange={(e) => patchForm({ taxNumber: e.target.value })}
                  className="admin-input w-full"
                />
              </label>
              <label className="block text-sm sm:col-span-2">
                <span className="admin-text-muted mb-1 block font-semibold">
                  {t('users.website')}
                </span>
                <input
                  value={form.website}
                  onChange={(e) => patchForm({ website: e.target.value })}
                  className="admin-input w-full"
                  dir="ltr"
                  placeholder="https://"
                />
              </label>
            </div>
          ) : null}

          {error ? (
            <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/40 dark:text-red-200">
              {error}
            </p>
          ) : null}
          {success ? (
            <p className="rounded-lg bg-emerald-50 px-3 py-2 text-sm text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-200">
              {success}
            </p>
          ) : null}

          <div className="flex flex-wrap gap-3">
            <button
              type="submit"
              disabled={isLoading}
              className="rounded-lg bg-[#3B7FC7] px-4 py-2.5 text-sm font-semibold text-white hover:bg-[#326ea9] disabled:opacity-60"
            >
              {isLoading ? t('users.savingUser') : t('users.saveUser')}
            </button>
            <Link
              to={`/users/${userId}`}
              className="rounded-lg border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-200"
            >
              {t('cancel')}
            </Link>
          </div>
        </form>
      </div>
    </div>
  )
}
