export type LoginRequest = {
  loginProviderName: string
  email: string
  password: string
  fcmToken?: string
  /** Cloudflare Turnstile token from the dashboard login widget. */
  turnstileToken?: string
  /** Identifies the admin web app so the API can require Turnstile. */
  clientApp?: 'AdminDashboard'
}

export type LoginResponse = {
  token: string
  id: string
  email: string
  name: string
  imgPath: string | null
  companyName: string | null
  roleName: string
  phone: string | null
  isCompanyAccount: boolean
  permissions?: string[]
}

export type ApiErrorBody = {
  message?: string
}
