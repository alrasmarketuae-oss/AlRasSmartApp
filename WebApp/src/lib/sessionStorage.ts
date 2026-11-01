export type Session = {
  token: string
  id: string
  email: string
  name: string
  companyName: string
  roleName: string
  roleId: string
  phone: string
  imgPath: string
  isCompanyAccount: boolean
  isShippingCompanyAccount: boolean
  isApproved: boolean | null
  isVerified: boolean | null
  isCustomer: boolean | null
}

const KEY = 'alras_web_session'

export function readStoredSession(): Session | null {
  try {
    const raw = localStorage.getItem(KEY)
    return raw ? (JSON.parse(raw) as Session) : null
  } catch {
    return null
  }
}

export function writeStoredSession(session: Session | null) {
  if (session) localStorage.setItem(KEY, JSON.stringify(session))
  else localStorage.removeItem(KEY)
}
