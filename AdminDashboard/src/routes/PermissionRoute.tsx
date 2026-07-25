import { Navigate } from 'react-router-dom'
import type { PermissionKey } from '../lib/permissions'
import { getDefaultRoute, hasPermission } from '../lib/permissions'

type PermissionRouteProps = {
  permission?: PermissionKey
  anyOf?: PermissionKey[]
  children: React.ReactNode
}

export default function PermissionRoute({
  permission,
  anyOf,
  children,
}: PermissionRouteProps) {
  const allowed = anyOf?.length
    ? anyOf.some((key) => hasPermission(key))
    : permission
      ? hasPermission(permission)
      : false

  if (!allowed) {
    return <Navigate to={getDefaultRoute()} replace />
  }

  return <>{children}</>
}
