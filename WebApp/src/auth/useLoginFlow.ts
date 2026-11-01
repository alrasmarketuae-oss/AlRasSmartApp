import { useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { useI18n } from '../i18n/I18nProvider'
import { useToast } from '../ui/Toast'
import { destinationFor, useAuth } from './AuthProvider'
import { sendEmailOtp, type LoginProvider } from './authApi'
import { isPendingAdminApproval, isPendingApprovalMessage, isVerifyEmailMessage, type LoginResponse } from './loginResponse'

/** Ports `AuthCubit._handleLoginSuccess` + the login error branches + `whereToGo`. */
export function useLoginFlow() {
  const { saveFromLogin, savePending } = useAuth()
  const navigate = useNavigate()
  const toast = useToast()
  const { t } = useI18n()

  const onSuccess = useCallback(
    async (response: LoginResponse, emailFallback: string, provider: LoginProvider) => {
      const email = response.email ?? emailFallback
      if (!response.token) {
        if (isPendingAdminApproval(response)) {
          savePending({
            token: '',
            id: response.id ?? '',
            email,
            name: response.name ?? '',
            companyName: response.companyName ?? '',
            roleName: response.roleName ?? '',
            isCompanyAccount: response.isCompanyAccount === true,
            isShippingCompanyAccount: response.isShippingCompanyAccount === true,
            isCustomer: response.isCustomer,
            phone: response.phone ?? '',
            isApproved: false,
            isVerified: true,
          })
          navigate('/under-review', { replace: true })
          return
        }
        if (response.isVerified !== true) {
          savePending({ token: '', email, isVerified: false, isApproved: false })
          navigate(`/verify-otp?email=${encodeURIComponent(email)}`, { replace: true })
          return
        }
        toast.error(t('loginError'))
        return
      }

      const session = saveFromLogin(response, emailFallback)
      if (response.isVerified !== true && provider === 'local' && email) {
        try {
          await sendEmailOtp(email)
        } catch (error) {
          toast.error((error as Error).message)
          return
        }
      }
      toast.success(t('loginSuccess'))
      navigate(destinationFor(session), { replace: true })
    },
    [navigate, saveFromLogin, savePending, t, toast],
  )

  const onError = useCallback(
    (message: string, email: string) => {
      if (isPendingApprovalMessage(message)) {
        savePending({ token: '', email, isCompanyAccount: true, isApproved: false, isVerified: true })
        toast.error(message)
        navigate('/under-review', { replace: true })
        return
      }
      if (isVerifyEmailMessage(message)) {
        savePending({ token: '', email, isApproved: false, isVerified: false })
        toast.error(message)
        navigate(`/verify-otp?email=${encodeURIComponent(email)}`, { replace: true })
        return
      }
      toast.error(message ? `${t('loginError')}: ${message}` : t('loginError'))
    },
    [navigate, savePending, t, toast],
  )

  return { onSuccess, onError }
}
