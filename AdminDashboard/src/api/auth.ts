import { apiRequest } from '../lib/http'
import type { LoginRequest, LoginResponse } from '../types/auth'

type RawLoginResponse = LoginResponse & {
  Token?: string
  RoleName?: string
  Id?: string | number
  Email?: string
  Name?: string
  ImgPath?: string | null
  CompanyName?: string | null
  Phone?: string | null
  IsCompanyAccount?: boolean
}

function pickString(...values: Array<string | number | null | undefined>): string {
  for (const value of values) {
    if (value === null || value === undefined) continue
    const text = String(value).trim()
    if (text) return text
  }
  return ''
}

export async function login(payload: LoginRequest): Promise<LoginResponse> {
  const data = await apiRequest<RawLoginResponse>('/api/Auth/login', {
    method: 'POST',
    body: payload,
  })

  const token = pickString(data.token, data.Token)
  const roleName = pickString(data.roleName, data.RoleName)
  const permissionsRaw = data.permissions ?? (data as { Permissions?: string[] }).Permissions
  const permissions = Array.isArray(permissionsRaw)
    ? permissionsRaw.filter((item): item is string => typeof item === 'string')
    : []

  if (!token) {
    throw new Error('السيرفر لم يرجع token. تحقق من إعدادات JWT على الاستضافة.')
  }

  return {
    token,
    id: pickString(data.id, data.Id),
    email: pickString(data.email, data.Email),
    name: pickString(data.name, data.Name),
    imgPath: data.imgPath ?? data.ImgPath ?? null,
    companyName: data.companyName ?? data.CompanyName ?? null,
    roleName,
    phone: data.phone ?? data.Phone ?? null,
    isCompanyAccount:
      data.isCompanyAccount ??
      data.IsCompanyAccount ??
      false,
    permissions,
  }
}

export function isAdminRole(roleName: string): boolean {
  return roleName.trim().toLowerCase() === 'admin'
}

export { canAccessDashboard } from '../lib/permissions'

export async function changePassword(payload: {
  currentPassword: string
  newPassword: string
}): Promise<{ message: string }> {
  return apiRequest<{ message: string }>('/api/Auth/change-password', {
    method: 'POST',
    body: payload,
    auth: true,
  })
}
