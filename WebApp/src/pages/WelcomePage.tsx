import { useNavigate } from 'react-router-dom'
import { AuthLayout } from '../auth/components'
import { useAuth } from '../auth/AuthProvider'
import { useI18n } from '../i18n/I18nProvider'
import { usePageTitle } from '../lib/usePageTitle'
import { BrandDotDivider, ColoredBrandTitle, LanguagePill } from '../ui/Brand'
import { Icon } from '../ui/Icon'

export default function WelcomePage() {
  const { t, isAr } = useI18n()
  usePageTitle()
  const navigate = useNavigate()
  const { logout } = useAuth()

  return (
    <AuthLayout>
      <div className="pt-2">
        <LanguagePill />
      </div>
      <div className="flex flex-1 flex-col items-center justify-center py-6">
        <img src="/assets/logo/logo.png" alt="Merge Spice" className="w-[132px] sm:w-[150px]" />
        <div className="mt-2.5">
          <ColoredBrandTitle includeAppWord={false} className="text-[26px] sm:text-[30px]" />
        </div>
        <div className="mt-3.5">
          <BrandDotDivider />
        </div>
        <p className="mt-3.5 px-2 text-center text-[13px] font-medium leading-relaxed text-[#6B7280] sm:text-sm" style={{ fontFamily: 'Cairo' }}>
          {t('welcomeTagline')}
        </p>

        <button
          type="button"
          onClick={() => navigate('/register')}
          dir="ltr"
          className="mt-6 flex w-full items-center rounded-2xl bg-gradient-to-r from-[#0B4FD1] to-[#1E6BE8] p-3 text-white shadow-[0_6px_14px_rgba(0,87,217,0.32)] transition hover:brightness-110"
        >
          <span className="grid size-11 place-items-center rounded-xl border border-white/35 bg-white/18">
            <Icon name="personAdd" size={22} />
          </span>
          <span className="flex-1 text-center" style={{ fontFamily: 'Cairo' }}>
            <span className="block text-[17px] font-extrabold">{t('createAccount')}</span>
            <span className="block text-[11px] font-medium text-white/90">{t('joinUs')}</span>
          </span>
          <span className="w-11" />
        </button>

        <button
          type="button"
          onClick={() => navigate('/login')}
          dir="ltr"
          className="mt-[18px] flex w-full items-center gap-3 rounded-2xl border border-brand-blue/12 bg-[#F4F7FB] p-3 transition hover:bg-[#EAF0F8]"
        >
          <span className="grid size-[50px] shrink-0 place-items-center rounded-[14px] bg-brand-blue text-white shadow-[0_4px_10px_rgba(0,87,217,0.3)]">
            <Icon name="login" size={26} />
          </span>
          <span className="flex-1 text-center" style={{ fontFamily: 'Cairo' }} dir={isAr ? 'rtl' : 'ltr'}>
            <span className="block text-base font-extrabold text-brand-blue">{t('quickLogin')}</span>
            <span className="mt-0.5 block text-[11.5px] font-medium leading-snug text-[#8A94A6]">{t('quickLoginSubtitle')}</span>
          </span>
          <Icon name="chevronRight" size={24} className="text-brand-blue/85" />
        </button>

        <div className="mt-4 flex w-full items-center">
          <span className="h-px flex-1 bg-brand-blue/20" />
          <button
            type="button"
            onClick={() => {
              logout()
              navigate('/')
            }}
            className="flex items-center gap-1.5 rounded-full px-3 py-1.5 text-sm font-bold text-brand-blue hover:bg-white/70"
            style={{ fontFamily: 'Cairo' }}
          >
            {t('loginAsGuest')}
            <Icon name="person" size={18} />
          </button>
          <span className="h-px flex-1 bg-brand-blue/20" />
        </div>
      </div>
    </AuthLayout>
  )
}
