import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react'
import { API_BASE_URL } from '../lib/config'
import { readStoredSession, writeStoredSession, type Session } from '../lib/sessionStorage'
import type { LoginResponse } from './loginResponse'

export type AccountFlags = {
  isAuthenticated: boolean
  isGuest: boolean
  isAdmin: boolean
  isSupplier: boolean
  isCompanyCustomer: boolean
  isPersonalCustomer: boolean
  isUaePhone: boolean
  displayName: string
}

type AuthValue = AccountFlags & {
  session: Session | null
  saveFromLogin: (response: LoginResponse, emailFallback: string, overrides?: Partial<Session>) => Session
  savePending: (partial: Partial<Session>) => Session
  logout: () => void
}

const AuthContext = createContext<AuthValue | null>(null)

const EMPTY_SESSION: Session = {
  token: '',
  id: '',
  email: '',
  name: '',
  companyName: '',
  roleName: '',
  roleId: '',
  phone: '',
  imgPath: '',
  isCompanyAccount: false,
  isShippingCompanyAccount: false,
  isApproved: null,
  isVerified: null,
  isCustomer: null,
}

export function computeFlags(session: Session | null): AccountFlags {
  const isAuthenticated = !!session?.token
  const isCompany = session?.isCompanyAccount === true
  const isShipping = session?.isShippingCompanyAccount === true
  const isCustomer = session?.isCustomer === true
  const role = (session?.roleName ?? '').trim().toLowerCase()
  const isAdmin =
    isAuthenticated && (role === 'admin' || (!isCompany && !isShipping && !isCustomer && session?.roleId === '1'))
  const phone = (session?.phone ?? '').replace(/[\s-]/g, '')
  const digits = phone.replace(/\D/g, '')
  const company = session?.companyName?.trim()
  return {
    isAuthenticated,
    isGuest: !isAuthenticated,
    isAdmin,
    isSupplier: isCompany && !isCustomer,
    isCompanyCustomer: isCompany && isCustomer,
    isPersonalCustomer: isAuthenticated && !isCompany && !isAdmin && !isShipping,
    isUaePhone: digits.startsWith('971') || phone.startsWith('+971') || /^0?5\d{8}$/.test(digits),
    displayName: ((isCompany || isShipping) && company ? company : session?.name?.trim()) || '',
  }
}

/** Mirrors the app's `whereToGo()` for the routes that exist on the web. */
export function destinationFor(session: Session | null): string {
  if (!session) return '/'
  const otp = `/verify-otp?email=${encodeURIComponent(session.email)}`
  const waitingApproval =
    (session.isCompanyAccount || session.isShippingCompanyAccount) && session.isApproved !== true
  if (!session.token) {
    if (session.isVerified !== true) return otp
    if (waitingApproval) return '/under-review'
    return '/welcome'
  }
  if (session.isVerified !== true) return otp
  if (computeFlags(session).isAdmin) return '/'
  if (waitingApproval) return '/under-review'
  return '/'
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(readStoredSession)

  const persist = useCallback((next: Session | null) => {
    writeStoredSession(next)
    setSession(next)
  }, [])

  const saveFromLogin = useCallback(
    (response: LoginResponse, emailFallback: string, overrides?: Partial<Session>) => {
      const next: Session = {
        ...EMPTY_SESSION,
        token: response.token ?? '',
        id: response.id ?? '',
        email: response.email ?? emailFallback,
        name: response.name ?? '',
        companyName: response.companyName ?? '',
        roleName: response.roleName ?? '',
        roleId: response.roleId ?? '',
        phone: response.phone ?? '',
        imgPath: response.imgPath ?? '',
        isCompanyAccount: response.isCompanyAccount === true,
        isShippingCompanyAccount: response.isShippingCompanyAccount === true,
        isApproved: response.isApproved,
        isVerified: response.isVerified,
        isCustomer: response.isCustomer,
        ...overrides,
      }
      persist(next)
      return next
    },
    [persist],
  )

  const savePending = useCallback(
    (partial: Partial<Session>) => {
      const next: Session = { ...EMPTY_SESSION, ...readStoredSession(), ...partial }
      persist(next)
      return next
    },
    [persist],
  )

  const logout = useCallback(() => {
    const token = readStoredSession()?.token
    if (token) {
      void fetch(`${API_BASE_URL}/Auth/clear-fcm-token`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: '{}',
        keepalive: true,
      }).catch(() => undefined)
    }
    persist(null)
  }, [persist])

  const value = useMemo<AuthValue>(
    () => ({ session, ...computeFlags(session), saveFromLogin, savePending, logout }),
    [session, saveFromLogin, savePending, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const value = useContext(AuthContext)
  if (!value) throw new Error('useAuth must be used inside AuthProvider')
  return value
}
