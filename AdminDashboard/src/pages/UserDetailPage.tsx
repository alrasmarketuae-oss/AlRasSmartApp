import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import UserDetailView from '../components/users/UserDetailView'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useReturnToListPath } from '../hooks/useReturnToListPath'
import {
  useApproveCompanyMutation,
  useDeleteAdminUserMutation,
  useGetAdminUserDetailQuery,
  useRejectCompanyMutation,
  useSetUserActiveMutation,
} from '../store'
import { getRtkErrorMessage } from '../utils/rtkError'

export default function UserDetailPage() {
  const { userId = '' } = useParams()
  const navigate = useNavigate()
  const { t } = useAppPreferences()
  const backToListPath = useReturnToListPath('/users')
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const { data: user, error, isLoading } = useGetAdminUserDetailQuery(userId, {
    skip: !userId,
  })

  const [approveCompany, { isLoading: isApproving }] = useApproveCompanyMutation()
  const [rejectCompany, { isLoading: isRejecting }] = useRejectCompanyMutation()
  const [setUserActive, { isLoading: isDeactivating }] = useSetUserActiveMutation()
  const [deleteAdminUser, { isLoading: isDeleting }] = useDeleteAdminUserMutation()

  if (!userId) {
    navigate('/users', { replace: true })
    return null
  }

  async function handleApprove() {
    const confirmed = window.confirm(t('users.approveConfirm'))
    if (!confirmed) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      const result = await approveCompany(userId).unwrap()
      setSuccessMessage(result.message || t('users.approveSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('users.approveError')))
    }
  }

  async function handleReject(reason: string) {
    const confirmed = window.confirm(t('users.rejectConfirm'))
    if (!confirmed) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      const result = await rejectCompany({ companyUserId: userId, reason }).unwrap()
      setSuccessMessage(result.message || t('users.rejectSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('users.rejectError')))
    }
  }

  async function handleDeactivate() {
    const confirmed = window.confirm(t('users.deactivateConfirm'))
    if (!confirmed) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      const result = await setUserActive({ userId, isActive: false }).unwrap()
      setSuccessMessage(result.message || t('users.deactivateSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('users.deactivateError')))
    }
  }

  async function handleActivate() {
    setActionError(null)
    setSuccessMessage(null)

    try {
      const result = await setUserActive({ userId, isActive: true }).unwrap()
      setSuccessMessage(result.message || t('users.activateSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('users.activateError')))
    }
  }

  async function handleDelete() {
    const confirmed = window.confirm(t('users.deleteAccountConfirm'))
    if (!confirmed) return

    setActionError(null)
    setSuccessMessage(null)

    try {
      const result = await deleteAdminUser(userId).unwrap()
      setSuccessMessage(result.message || t('users.deleteAccountSuccess'))
      navigate(backToListPath)
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('users.deleteAccountError')))
    }
  }

  return (
    <div className="space-y-6">
      <Link
        to={backToListPath}
        className="admin-text-muted inline-flex items-center gap-2 text-sm font-semibold transition hover:text-[#3B7FC7]"
      >
        ← {t('users.backToList')}
      </Link>

      {successMessage ? (
        <div className="admin-alert-success">{successMessage}</div>
      ) : null}
      {actionError ? <div className="admin-alert-error">{actionError}</div> : null}

      {isLoading ? (
        <p className="admin-text-subtle py-16 text-center">{t('loading')}</p>
      ) : error || !user ? (
        <div className="admin-card px-6 py-16 text-center">
          <p className="text-sm text-red-600 dark:text-red-400">
            {getRtkErrorMessage(error as never, t('users.loadError'))}
          </p>
        </div>
      ) : (
        <UserDetailView
          user={user}
          isApproving={isApproving}
          isRejecting={isRejecting}
          isDeactivating={isDeactivating}
          isDeleting={isDeleting}
          onApprove={handleApprove}
          onReject={handleReject}
          onDeactivate={handleDeactivate}
          onActivate={handleActivate}
          onDelete={handleDelete}
        />
      )}
    </div>
  )
}
