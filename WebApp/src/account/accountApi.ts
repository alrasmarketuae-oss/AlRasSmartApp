import { api } from '../lib/api'

export type CompanyImage = { id: number; imagePath: string; isPrimary: boolean }

export type UserProfile = {
  fullName: string
  email: string
  phoneNumber?: string | null
  companyName?: string | null
  commercialRegister?: string | null
  taxNumber?: string | null
  landNumber?: string | null
  website?: string | null
  licenseNumber?: string | null
  licencePath?: string | null
  companyImages: CompanyImage[]
  imgPath?: string | null
  birthDate?: string | null
  roleName: string
  isCompanyAccount: boolean
  isShippingCompanyAccount: boolean
  isRejected: boolean
  rejectionReason?: string | null
  hasPendingProfileChanges: boolean
  pendingLicencePath?: string | null
  pendingCompanyImagesChanged: boolean
  pendingCompanyImagePaths: string[]
  hasPassword?: boolean | null
  loginProviderName?: string | null
  isNotificationsOn: boolean
}

type Raw = Record<string, unknown>
const pick = (raw: Raw, key: string) => raw[key] ?? raw[key.charAt(0).toUpperCase() + key.slice(1)]
const str = (raw: Raw, key: string) => {
  const value = pick(raw, key)
  return value === undefined || value === null ? null : String(value)
}

export function parseProfile(raw: Raw): UserProfile {
  const images = pick(raw, 'companyImages')
  const pending = (pick(raw, 'pendingProfileChanges') as Raw | null | undefined) ?? null
  const pendingPaths = pending ? pick(pending, 'companyImagePaths') : null
  return {
    fullName: str(raw, 'fullName') ?? '',
    email: str(raw, 'email') ?? '',
    phoneNumber: str(raw, 'phoneNumber'),
    companyName: str(raw, 'companyName'),
    commercialRegister: str(raw, 'commercialRegister'),
    taxNumber: str(raw, 'taxNumber'),
    landNumber: str(raw, 'landNumber'),
    website: str(raw, 'website'),
    licenseNumber: str(raw, 'licenseNumber'),
    licencePath: str(raw, 'licencePath'),
    companyImages: Array.isArray(images)
      ? images.map((item: Raw) => ({ id: Number(pick(item, 'id') ?? 0), imagePath: str(item, 'imagePath') ?? '', isPrimary: pick(item, 'isPrimary') === true }))
      : [],
    imgPath: str(raw, 'imgPath'),
    birthDate: str(raw, 'birthDate'),
    roleName: str(raw, 'roleName') ?? '',
    isCompanyAccount: pick(raw, 'isCompanyAccount') === true,
    isShippingCompanyAccount: pick(raw, 'isShippingCompanyAccount') === true,
    isRejected: pick(raw, 'isRejected') === true,
    rejectionReason: str(raw, 'rejectionReason'),
    hasPendingProfileChanges: pick(raw, 'hasPendingProfileChanges') === true || !!pending,
    pendingLicencePath: pending ? str(pending, 'licencePath') : null,
    pendingCompanyImagesChanged: pending ? pick(pending, 'companyImagesChanged') === true : false,
    pendingCompanyImagePaths: Array.isArray(pendingPaths) ? pendingPaths.map(String) : [],
    hasPassword: (pick(raw, 'hasPassword') as boolean | undefined) ?? null,
    loginProviderName: str(raw, 'loginProviderName'),
    isNotificationsOn: pick(raw, 'isNotificationsOn') !== false,
  }
}

export const fetchMyProfile = async () => parseProfile(await api.get<Raw>('/users/me'))

export const updateMyProfile = async (body: Record<string, unknown>) => parseProfile(await api.put<Raw>('/users/me', body))

export async function uploadProfileFile(kind: 'image' | 'licence' | 'company-image', file: File) {
  const form = new FormData()
  form.append('File', file)
  const raw =
    kind === 'company-image'
      ? await api.upload<Raw>('/users/me/company-images', form)
      : await api.putUpload<Raw>(kind === 'image' ? '/users/me/image' : '/users/me/licence', form)
  return parseProfile(raw)
}

export const deleteCompanyImage = async (id: number) => parseProfile(await api.delete<Raw>(`/users/me/company-images/${id}`))

export const deletePendingCompanyImage = async (path: string) =>
  parseProfile(await api.delete<Raw>(`/users/me/company-images/pending?path=${encodeURIComponent(path)}`))

export type FeedbackBody = { type: 'Complaint' | 'Suggestion'; subject: string; message: string; orderReference?: string; language: 'ar' | 'en'; source: 'profile' }

export const submitFeedback = (body: FeedbackBody) => api.post<{ message?: string; Message?: string }>('/user-feedback', body)

export async function updateNotificationsPreference(isNotificationsOn: boolean) {
  const data = await api.put<Raw>('/UserPreferences/notifications', { isNotificationsOn })
  return data ? pick(data, 'isNotificationsOn') !== false : isNotificationsOn
}

export const updatePreferredLanguage = (language: 'ar' | 'en') => api.put('/UserPreferences/language', { Language: language })

export const deleteAccount = (password: string) => api.post<{ message?: string }>('/Auth/delete-account', { password, Password: password })

export const changePassword = (currentPassword: string, newPassword: string) =>
  api.post<{ message?: string }>('/Auth/change-password', { currentPassword, newPassword, CurrentPassword: currentPassword, NewPassword: newPassword })
