import { Link, useNavigate, useParams } from 'react-router-dom'
import UserDetailContainer from '../components/users/UserDetailContainer'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useReturnToListPath } from '../hooks/useReturnToListPath'

export default function UserDetailPage() {
  const { userId = '' } = useParams()
  const navigate = useNavigate()
  const { t } = useAppPreferences()
  const backToListPath = useReturnToListPath('/users')

  if (!userId) {
    navigate('/users', { replace: true })
    return null
  }

  return (
    <div className="space-y-6">
      <Link
        to={backToListPath}
        className="admin-text-muted inline-flex items-center gap-2 text-sm font-semibold transition hover:text-[#3B7FC7]"
      >
        ← {t('users.backToList')}
      </Link>

      <UserDetailContainer key={userId} userId={userId} onDeleted={() => navigate(backToListPath)} />
    </div>
  )
}
