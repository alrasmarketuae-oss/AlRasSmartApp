import type { LoginResponse } from '../types/auth'

const TOKEN_KEY = 'rasalsouq_admin_token'
const USER_KEY = 'rasalsouq_admin_user'
const CHAT_WRAP_SECRET_KEY = 'rasalsouq_chat_wrap_secret'
export const CUSTOMER_TOKEN_KEY = 'rasalsouq_customer_token'

export function saveAuthSession(response: LoginResponse): void {
  localStorage.setItem(TOKEN_KEY, response.token)
  localStorage.setItem(USER_KEY, JSON.stringify(response))
}

export function saveChatWrapSecret(secret: string): void {
  const trimmed = secret.trim()
  if (!trimmed) return
  sessionStorage.setItem(CHAT_WRAP_SECRET_KEY, trimmed)
}

/** @deprecated use saveChatWrapSecret */
export function saveChatKeyPassphrase(passwordOrSecret: string): void {
  saveChatWrapSecret(passwordOrSecret)
}

export function getChatWrapSecret(): string | null {
  return sessionStorage.getItem(CHAT_WRAP_SECRET_KEY)
}

/** @deprecated use getChatWrapSecret */
export function getChatKeyPassphrase(): string | null {
  return getChatWrapSecret()
}

export function clearChatKeyPassphrase(): void {
  sessionStorage.removeItem(CHAT_WRAP_SECRET_KEY)
}

export function getAuthToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function saveCustomerAuthToken(token: string): void {
  localStorage.setItem(CUSTOMER_TOKEN_KEY, token)
}

export function getPaymentAuthToken(): string | null {
  return localStorage.getItem(CUSTOMER_TOKEN_KEY) ?? getAuthToken()
}

export function getAuthUser(): LoginResponse | null {
  const raw = localStorage.getItem(USER_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as LoginResponse
  } catch {
    return null
  }
}

export function clearAuthSession(): void {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(USER_KEY)
  clearChatKeyPassphrase()
}
