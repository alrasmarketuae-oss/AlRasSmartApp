import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { destinationFor, useAuth } from '../auth/AuthProvider'
import { getApprovalStatus } from '../auth/authApi'
import { AuthLayout, AuthTopBar, Spinner } from '../auth/components'
import { useI18n } from '../i18n/I18nProvider'
import { SUPPORT_PHONE_DISPLAY, SUPPORT_PHONE_TEL } from '../lib/config'
import { usePageTitle } from '../lib/usePageTitle'
import { Icon } from '../ui/Icon'

const POLL_MS = 15_000

export default function UnderReviewPage() {
  const { t } = useI18n()
  usePageTitle(t('underReview'))
  const navigate = useNavigate()
  const { session, savePending, logout } = useAuth()
  const email = session?.email ?? ''
  const [checking, setChecking] = useState(false)

  const check = useCallback(async () => {
    if (!email) return
    setChecking(true)
    try {
      const status = await getApprovalStatus(email)
      if (status?.isApproved === true && status.token) {
        const next = savePending({
          token: status.token,
          id: status.id ?? session?.id ?? '',
          email: status.email ?? email,
          name: status.name ?? session?.name ?? '',
          roleName: status.roleName ?? session?.roleName ?? '',
          phone: status.phone ?? session?.phone ?? '',
          isApproved: true,
          isVerified: status.isVerified ?? true,
          isCompanyAccount: status.isCompanyAccount ?? session?.isCompanyAccount ?? false,
          isShippingCompanyAccount: status.isShippingCompanyAccount ?? session?.isShippingCompanyAccount ?? false,
          isCustomer: status.isCustomer ?? session?.isCustomer ?? null,
        })
        navigate(destinationFor(next), { replace: true })
      }
    } catch {
      // Keep polling quietly; the screen already explains the wait.
    } finally {
      setChecking(false)
    }
  }, [email, navigate, savePending, session])

  useEffect(() => {
    void check()
    const id = window.setInterval(() => void check(), POLL_MS)
    return () => window.clearInterval(id)
  }, [check])

  return (
    <AuthLayout>
      <AuthTopBar showBack={false} />
      <div className="flex flex-1 flex-col items-center justify-center py-8 text-center">
        <img src="/assets/images/review_image.png" alt="" className="w-[220px] max-w-[70%] sm:w-[260px]" />
        <h1 className="mt-6 text-2xl font-extrabold text-auth-title">{t('underReview')}</h1>
        <p className="mt-3 max-w-sm text-sm leading-relaxed text-auth-body">{t('underReviewMessage')}</p>
        {email && (
          <p dir="ltr" className="mt-2 text-sm font-semibold text-auth-title">
            {email}
          </p>
        )}

        <button
          type="button"
          onClick={() => void check()}
          disabled={checking || !email}
          className="mt-6 inline-flex items-center gap-2 text-sm font-bold text-brand disabled:opacity-60"
        >
          {checking ? <Spinner className="size-4 border-brand/30 border-t-brand" /> : <Icon name="refresh" size={18} />}
          {t('checkAgain')}
        </button>

        <div className="mt-8 flex w-full flex-col gap-3">
          <a
            href={`tel:${SUPPORT_PHONE_TEL}`}
            className="flex h-[50px] items-center justify-center gap-2 rounded-[10px] bg-brand text-base font-bold text-white hover:brightness-110"
          >
            <Icon name="headset" size={20} />
            {t('contactSupport')}
            <span dir="ltr" className="text-sm font-semibold opacity-90">
              {SUPPORT_PHONE_DISPLAY}
            </span>
          </a>
          <button
            type="button"
            onClick={() => {
              logout()
              navigate('/login', { replace: true })
            }}
            className="flex h-[50px] items-center justify-center gap-2 rounded-[10px] border border-[#d92d20]/40 bg-white text-base font-bold text-[#d92d20] hover:bg-red-50"
          >
            <Icon name="logout" size={20} />
            {t('logout')}
          </button>
        </div>
      </div>
    </AuthLayout>
  )
}
