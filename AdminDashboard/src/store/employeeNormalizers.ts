import type { AdminPermissionDefinition, AdminEmployee, AdminEmployeeDetail } from '../types/employee'

function pickString(...values: Array<string | null | undefined>): string {
  for (const value of values) {
    if (value?.trim()) return value.trim()
  }
  return ''
}

export function normalizePermissionDefinition(raw: Record<string, unknown>): AdminPermissionDefinition {
  return {
    key: pickString(raw.key as string, raw.Key as string),
    labelAr: pickString(raw.labelAr as string, raw.LabelAr as string),
    labelEn: pickString(raw.labelEn as string, raw.LabelEn as string),
    groupKey: pickString(raw.groupKey as string, raw.GroupKey as string),
    groupLabelAr: pickString(raw.groupLabelAr as string, raw.GroupLabelAr as string),
    groupLabelEn: pickString(raw.groupLabelEn as string, raw.GroupLabelEn as string),
  }
}

export function normalizeEmployee(raw: Record<string, unknown>): AdminEmployee {
  const permissionsRaw = raw.permissions ?? raw.Permissions
  const permissions = Array.isArray(permissionsRaw)
    ? permissionsRaw.filter((item): item is string => typeof item === 'string')
    : []

  return {
    id: pickString(raw.id as string, raw.Id as string),
    fullName: pickString(raw.fullName as string, raw.FullName as string),
    email: pickString(raw.email as string, raw.Email as string),
    phoneNumber: (raw.phoneNumber ?? raw.PhoneNumber ?? null) as string | null,
    isActive: Boolean(raw.isActive ?? raw.IsActive ?? true),
    permissions,
    createdAt: pickString(raw.createdAt as string, raw.CreatedAt as string),
  }
}

export function normalizeEmployeeDetail(raw: Record<string, unknown>): AdminEmployeeDetail {
  return normalizeEmployee(raw)
}
