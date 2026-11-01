export type LoginResponse = {
  token: string | null
  id: string | null
  email: string | null
  name: string | null
  imgPath: string | null
  companyName: string | null
  roleName: string | null
  roleId: string | null
  phone: string | null
  isCompanyAccount: boolean | null
  isShippingCompanyAccount: boolean | null
  isApproved: boolean | null
  isVerified: boolean | null
  isCustomer: boolean | null
  isRejected: boolean | null
  rejectionReason: string | null
}

type Json = Record<string, unknown>

const str = (value: unknown): string | null => {
  if (value === null || value === undefined) return null
  const text = String(value)
  return text ? text : null
}

const bool = (value: unknown): boolean | null => {
  if (value === null || value === undefined) return null
  if (typeof value === 'boolean') return value
  if (typeof value === 'number') return value !== 0
  const text = String(value).trim().toLowerCase()
  if (['true', '1', 'yes'].includes(text)) return true
  if (['false', '0', 'no'].includes(text)) return false
  return null
}

const pick = (json: Json, ...keys: string[]) => {
  for (const key of keys) if (json[key] !== undefined && json[key] !== null) return json[key]
  return undefined
}

function decodeJwtPayload(token: string): Json {
  const parts = token.split('.')
  if (parts.length !== 3) throw new Error('Invalid JWT')
  const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/')
  const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4)
  const bytes = Uint8Array.from(atob(padded), (c) => c.charCodeAt(0))
  return JSON.parse(new TextDecoder().decode(bytes)) as Json
}

/** Backend RoleIds: Admin=1, Seller=2, Buyer=3, ShippingCompany=5. */
function resolveRoleId(roleName: string | null, isCompany: boolean | null, isShipping: boolean | null) {
  const role = (roleName ?? '').trim().toLowerCase()
  if (role === 'admin') return '1'
  if (role === 'shippingcompany' || isShipping === true) return '5'
  if (role === 'seller' || isCompany === true) return '2'
  if (role === 'buyer') return '3'
  return null
}

export function parseLoginResponse(json: Json): LoginResponse {
  const rawToken = pick(json, 'token', 'Token', 'accessToken')
  const token = typeof rawToken === 'string' && rawToken ? rawToken : null

  let id = str(pick(json, 'id', 'Id', 'personId', 'PersonId'))
  let email = str(pick(json, 'email', 'Email'))
  let name = str(pick(json, 'name', 'Name', 'fullName', 'FullName'))
  let roleName = str(pick(json, 'roleName', 'RoleName', 'role', 'Role'))
  let roleId = str(pick(json, 'roleId', 'RoleId'))
  const isCompanyAccount = bool(pick(json, 'isCompanyAccount', 'IsCompanyAccount'))
  const isShippingCompanyAccount =
    bool(pick(json, 'isShippingCompanyAccount', 'IsShippingCompanyAccount')) ??
    (roleName?.toLowerCase() === 'shippingcompany' ? true : null)

  if (token) {
    try {
      const payload = decodeJwtPayload(token)
      id ??= str(payload.sub ?? payload.EntityId)
      email ??= str(payload.email)
      name ??= str(payload.fullName)
      roleName ??= str(payload.role ?? payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'])
      roleId ??= str(payload.roleId)
    } catch {
      // Body fields are enough when the JWT cannot be decoded.
    }
  }
  roleId ??= resolveRoleId(roleName, isCompanyAccount, isShippingCompanyAccount)

  return {
    token,
    id,
    email,
    name,
    imgPath: str(pick(json, 'imgPath', 'ImgPath')),
    companyName: str(pick(json, 'companyName', 'CompanyName')),
    roleName,
    roleId,
    phone: str(pick(json, 'phone', 'Phone', 'phoneNumber', 'PhoneNumber')),
    isCompanyAccount,
    isShippingCompanyAccount,
    isApproved: bool(pick(json, 'isApproved', 'IsApproved')),
    isVerified: bool(pick(json, 'isVerified', 'IsVerified')),
    isCustomer: bool(pick(json, 'isCustomer', 'IsCustomer')),
    isRejected: bool(pick(json, 'isRejected', 'IsRejected')),
    rejectionReason: str(pick(json, 'rejectionReason', 'RejectionReason')),
  }
}

export const isPendingAdminApproval = (r: LoginResponse) =>
  (r.isCompanyAccount === true || r.isShippingCompanyAccount === true) && r.isApproved !== true

export function isPendingApprovalMessage(message: string) {
  const normalized = message.toLowerCase()
  return (
    normalized.includes('not been approved') ||
    normalized.includes('pending admin approval') ||
    normalized.includes('pending approval') ||
    message.includes('قيد موافقة') ||
    message.includes('لم تتم الموافقة')
  )
}

export function isVerifyEmailMessage(message: string) {
  const normalized = message.toLowerCase()
  return (
    normalized.includes('verify your email') ||
    normalized.includes('verify email') ||
    message.includes('تحقق') ||
    message.includes('تأكيد بريد') ||
    message.includes('فعّل بريد') ||
    message.includes('فعّل البريد')
  )
}
