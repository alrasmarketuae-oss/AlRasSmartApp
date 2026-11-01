import { api } from '../lib/api'
import { parseLoginResponse, type LoginResponse } from './loginResponse'

export type LoginProvider = 'local' | 'google'

export type RegisterAddress = {
  countryId: number
  cityId?: string
  cityName: string
  addressLine1: string
  addressTypeId: number
  area?: string
  street?: string
  contactPerson?: string
  latitude: number
  longitude: number
}

export type RegisterCompanyBody = {
  fullName: string
  companyName: string
  email: string
  password: string
  phoneNumber: string
  landNumber: string
  licenseNumber: string
  licencePath: string
  imgPath?: string
  companyImagePaths: string[]
  commercialRegister: string
  taxNumber: string
  website: string
  isCustomer: boolean
  preferredLanguage: string
  address?: RegisterAddress
}

export async function loginRequest(params: {
  email: string
  password: string
  provider: LoginProvider
  token?: string
  preferredLanguage: string
}): Promise<LoginResponse> {
  const data = await api.post<Record<string, unknown>>(
    '/Auth/login',
    {
      loginProviderName: params.provider,
      email: params.email,
      password: params.password,
      token: params.token ?? '',
      fcmToken: '',
      preferredLanguage: params.preferredLanguage,
    },
    { auth: false },
  )
  const response = parseLoginResponse(data ?? {})
  if (response.isRejected) {
    throw new Error(response.rejectionReason || 'Your account registration was rejected.')
  }
  return response
}

export async function verifyEmailOtp(email: string, otp: string): Promise<LoginResponse> {
  const data = await api.post<Record<string, unknown>>('/Auth/verify-email-otp', { email, otp }, { auth: false })
  return parseLoginResponse(data ?? {})
}

export const sendEmailOtp = (email: string) => api.post('/Auth/send-email-otp', { email }, { auth: false })

export const registerCompany = (body: RegisterCompanyBody) =>
  api.post<Record<string, unknown>>('/Auth/register-company', { ...body, fcmToken: '' }, { auth: false })

export async function forgotPasswordRequest(email: string) {
  const data = await api.post<{ message?: string }>(
    '/Auth/forgot-password/request',
    { providerName: 'Email', destination: email.trim().toLowerCase() },
    { auth: false },
  )
  return data?.message
}

export async function forgotPasswordReset(email: string, code: string, newPassword: string) {
  const data = await api.post<{ message?: string }>(
    '/Auth/forgot-password/reset',
    { providerName: 'Email', destination: email.trim().toLowerCase(), code: code.trim(), newPassword },
    { auth: false },
  )
  return data?.message
}

export type ApprovalStatus = {
  isApproved?: boolean
  token?: string
  id?: string
  email?: string
  name?: string
  roleName?: string
  phone?: string
  isVerified?: boolean
  isCompanyAccount?: boolean
  isShippingCompanyAccount?: boolean
  isCustomer?: boolean
}

/** The backend's message-localization filter may return this body in PascalCase. */
export async function getApprovalStatus(email: string): Promise<ApprovalStatus> {
  const data = await api.get<Record<string, unknown>>('/Auth/account-approval-status', { query: { email }, auth: false })
  const normalized: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(data ?? {})) normalized[key.charAt(0).toLowerCase() + key.slice(1)] = value
  return normalized as ApprovalStatus
}

function pickUploadedPath(data: unknown, keys: string[]): string {
  if (typeof data === 'string') return data
  if (data && typeof data === 'object') {
    const record = data as Record<string, unknown>
    for (const key of keys) {
      const value = record[key]
      if (typeof value === 'string' && value) return value
    }
  }
  return ''
}

async function uploadFile(path: string, file: File, keys: string[]) {
  const form = new FormData()
  form.append('File', file, file.name)
  const data = await api.upload<unknown>(path, form, { auth: false })
  const uploaded = pickUploadedPath(data, keys)
  if (!uploaded) throw new Error('Invalid upload response')
  return uploaded
}

export const uploadCompanyLicence = (file: File) =>
  uploadFile('/CompanyLicence/upload', file, ['licencePath', 'LicencePath', 'imagePath', 'ImagePath', 'imageUrl', 'ImageUrl', 'path'])

export const uploadCompanyImage = (file: File) =>
  uploadFile('/CompanyImages/upload', file, ['imagePath', 'ImagePath', 'licencePath', 'LicencePath', 'imageUrl', 'ImageUrl', 'path'])

export const uploadCompanyProfileLogo = (file: File) =>
  uploadFile('/CompanyImages/upload-profile', file, ['imgPath', 'ImgPath', 'imagePath', 'ImagePath', 'path'])
