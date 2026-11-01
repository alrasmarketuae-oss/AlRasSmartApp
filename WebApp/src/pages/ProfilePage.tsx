import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { deleteAccount, fetchMyProfile, updateNotificationsPreference, updatePreferredLanguage } from '../account/accountApi'
import { useAuth } from '../auth/AuthProvider'
import { PasswordField, Spinner } from '../auth/components'
import { useI18n } from '../i18n/I18nProvider'
import { PageContainer } from '../layout/MainLayout'
import { MaskIcon } from '../layout/MaskIcon'
import { Avatar, useAccountSubtitle } from '../layout/SiteHeader'
import { ApiError } from '../lib/api'
import { PRIVACY_URL } from '../lib/config'
import { usePageTitle } from '../lib/usePageTitle'
import { useUnreadChatCount } from '../chat/useUnreadChatCount'
import { Icon, type IconName } from '../ui/Icon'
import { Modal } from '../ui/Modal'
import { useToast } from '../ui/Toast'

const BLUE = ['#2E77CC', '#1B5FB8']
const GREEN = ['#23C08B', '#12A874']
const RED = ['#F05B54', '#DE3F38']
const AMBER = ['#F59E0B', '#D97706']

function Card({ children, onClick, className = '' }: { children: ReactNode; onClick?: () => void; className?: string }) {
  const base = `w-full rounded-[14px] bg-white text-start shadow-[0_4px_14px_rgba(22,35,58,0.05)] ${className}`
  return onClick ? (
    <button type="button" onClick={onClick} className={`${base} transition hover:shadow-[0_6px_20px_rgba(22,35,58,0.1)]`}>
      {children}
    </button>
  ) : (
    <div className={base}>{children}</div>
  )
}

function RoundIcon({ icon, asset, colors = BLUE, size = 46 }: { icon?: IconName; asset?: string; colors?: string[]; size?: number }) {
  if (asset?.endsWith('.png')) {
    return (
      <span className="grid shrink-0 place-items-center overflow-hidden rounded-full bg-white" style={{ width: size, height: size, boxShadow: `0 4px 10px ${colors[1]}38` }}>
        <img src={asset} alt="" className="size-full object-contain" />
      </span>
    )
  }
  return (
    <span
      className="grid shrink-0 place-items-center rounded-full text-white"
      style={{ width: size, height: size, background: `linear-gradient(135deg, ${colors[0]}, ${colors[1]})`, boxShadow: `0 4px 10px ${colors[1]}4d` }}
    >
      {asset ? <MaskIcon src={asset} color="#fff" size={size * 0.46} /> : icon && <Icon name={icon} size={size * 0.48} />}
    </span>
  )
}

function Chevron() {
  const { isAr } = useI18n()
  return <Icon name={isAr ? 'chevronLeft' : 'chevronRight'} size={22} className="shrink-0 text-[#2E77CC]" />
}

function Badge({ count }: { count: number }) {
  if (count <= 0) return null
  return <span className="min-w-5 rounded-full bg-[#E53935] px-1.5 py-0.5 text-center text-[10px] font-bold text-white">{count > 99 ? '99+' : count}</span>
}

function SectionTitle({ children }: { children: ReactNode }) {
  return (
    <div className="flex items-center gap-2">
      <span className="h-[18px] w-1 rounded bg-[#2E77CC]" />
      <h2 className="text-[17px] font-bold text-title">{children}</h2>
    </div>
  )
}

function Tile(props: { title: string; subtitle: string; icon?: IconName; asset?: string; colors?: string[]; onClick?: () => void; trailing?: ReactNode }) {
  return (
    <Card onClick={props.trailing ? undefined : props.onClick} className="flex items-center gap-3.5 px-3.5 py-3.5">
      <RoundIcon icon={props.icon} asset={props.asset} colors={props.colors} />
      <span className="min-w-0 flex-1">
        <span className="block text-[14.5px] font-bold leading-snug text-title">{props.title}</span>
        <span className="mt-0.5 block text-[11.5px] leading-snug text-subtitle">{props.subtitle}</span>
      </span>
      {props.trailing ?? <Chevron />}
    </Card>
  )
}

function Switch({ checked, busy, onChange }: { checked: boolean; busy?: boolean; onChange: (value: boolean) => void }) {
  if (busy) return <Spinner className="size-5 border-2 border-brand/25 border-t-brand" />
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className={`relative h-7 w-12 shrink-0 rounded-full transition ${checked ? 'bg-[#2E77CC]' : 'bg-[#D0D5DD]'}`}
    >
      <span className={`absolute top-0.5 size-6 rounded-full bg-white shadow transition-all ${checked ? 'start-[22px]' : 'start-0.5'}`} />
    </button>
  )
}

function DeleteAccountDialog({ open, onClose, hasPassword }: { open: boolean; onClose: () => void; hasPassword: boolean }) {
  const { t } = useI18n()
  const toast = useToast()
  const { logout } = useAuth()
  const navigate = useNavigate()
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)

  const submit = async () => {
    if (hasPassword && !password.trim()) return
    setBusy(true)
    try {
      const res = await deleteAccount(password.trim())
      toast.success(res?.message || t('deleteAccount'))
      logout()
      navigate('/', { replace: true })
    } catch (error) {
      toast.error(error instanceof ApiError ? error.message : t('unexpectedError'))
    } finally {
      setBusy(false)
    }
  }

  return (
    <Modal open={open} onClose={onClose} title={t('deleteAccount')}>
      <p className="mb-4 text-sm text-subtitle">{t('deleteAccountSubtitle')}</p>
      {hasPassword && <PasswordField label={t('password')} value={password} onChange={(e) => setPassword(e.target.value)} placeholder={t('enterYourPassword')} />}
      <div className="mt-5 flex gap-3">
        <button type="button" onClick={onClose} className="flex-1 rounded-xl border border-line py-3 text-sm font-bold text-title">
          {t('cancel')}
        </button>
        <button
          type="button"
          disabled={busy || (hasPassword && !password.trim())}
          onClick={submit}
          className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-[#DE3F38] py-3 text-sm font-bold text-white disabled:opacity-50"
        >
          {busy && <Spinner className="size-4 border-2 border-white/40 border-t-white" />}
          {t('deleteAccount')}
        </button>
      </div>
    </Modal>
  )
}

export default function ProfilePage() {
  const { t, lang, toggleLang } = useI18n()
  usePageTitle(t('profile'))
  const navigate = useNavigate()
  const toast = useToast()
  const queryClient = useQueryClient()
  const { isAuthenticated, session, displayName, logout, isSupplier, isCompanyCustomer } = useAuth()
  const roleLabel = useAccountSubtitle()
  const unread = useUnreadChatCount()
  const [notifBusy, setNotifBusy] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)

  const profileQuery = useQuery({ queryKey: ['profile', session?.id], queryFn: fetchMyProfile, enabled: isAuthenticated })
  const profile = profileQuery.data
  const requireAuth = (path: string) => () => navigate(isAuthenticated ? path : '/login')

  const toggleNotifications = async (value: boolean) => {
    setNotifBusy(true)
    try {
      const enabled = await updateNotificationsPreference(value)
      queryClient.setQueryData(['profile', session?.id], (old: typeof profile) => (old ? { ...old, isNotificationsOn: enabled } : old))
    } catch (error) {
      toast.error(error instanceof ApiError ? error.message : t('unexpectedError'))
    } finally {
      setNotifBusy(false)
    }
  }

  const switchLanguage = () => {
    const next = lang === 'ar' ? 'en' : 'ar'
    toggleLang()
    if (isAuthenticated) updatePreferredLanguage(next).catch(() => undefined)
  }

  return (
    <PageContainer narrow className="py-4">
      <Card className="p-4">
        <div className="flex items-start gap-3">
          <div className="min-w-0 flex-1">
            <p className="text-[17px] font-bold leading-snug text-title first-letter:uppercase">
              {isAuthenticated ? profile?.companyName || profile?.fullName || displayName : t('signInToContinue')}
            </p>
            {isAuthenticated && roleLabel && <span className="mt-2 inline-block rounded-md bg-[#E8F1FC] px-2.5 py-1 text-[11px] font-semibold text-[#2E77CC]">{t(roleLabel)}</span>}
            {isAuthenticated ? (
              <div className="mt-3 space-y-2 text-[13px] font-medium text-[#44526B]">
                <p className="flex items-center gap-2">
                  <Icon name="mail" size={16} className="text-[#2E77CC]" />
                  <span dir="ltr" className="truncate">{profile?.email || session?.email}</span>
                </p>
                <p className="flex items-center gap-2">
                  <Icon name="phone" size={16} className="text-[#2E77CC]" />
                  <span dir="ltr" className="truncate">{profile?.phoneNumber || session?.phone || '—'}</span>
                </p>
              </div>
            ) : (
              <p className="mt-2 text-[13px] leading-snug text-[#7B8794]">{t('loginRequiredMessage')}</p>
            )}
          </div>
          <button type="button" onClick={requireAuth('/profile/edit')} className="relative shrink-0">
            <Avatar size={66} />
            {isAuthenticated && (
              <span className="absolute -bottom-0.5 -end-0.5 grid size-6 place-items-center rounded-full border-2 border-white bg-[#2E77CC] text-white">
                <Icon name="edit" size={11} />
              </span>
            )}
          </button>
        </div>
        <button
          type="button"
          onClick={requireAuth('/profile/edit')}
          className="mt-4 flex h-[46px] w-full items-center justify-center gap-2 rounded-xl bg-[#2E77CC] text-[15px] font-bold text-white hover:brightness-110"
        >
          <Icon name={isAuthenticated ? 'edit' : 'login'} size={18} />
          {isAuthenticated ? t('editProfile') : t('login')}
        </button>
      </Card>

      <div className="mt-3.5 grid grid-cols-2 gap-3">
        <Card onClick={() => navigate('/ai-assistant')} className="flex items-center gap-2.5 px-3 py-3.5">
          <RoundIcon asset="/assets/profile/ai_agent.png" size={52} />
          <span className="min-w-0 flex-1">
            <span className="block truncate text-[13px] font-bold text-title">{t('aiAssistantTitle')}</span>
            <span className="mt-0.5 line-clamp-2 block text-[10.5px] leading-snug text-[#7B8794]">{t('aiAssistantCardSubtitle')}</span>
          </span>
          <Chevron />
        </Card>
        <Card onClick={requireAuth('/chat')} className="flex items-center gap-2.5 px-3 py-3.5">
          <RoundIcon asset="/assets/profile/message.svg" size={42} />
          <span className="min-w-0 flex-1">
            <span className="block truncate text-[13px] font-bold text-title">{t('liveChat')}</span>
            <span className="mt-0.5 line-clamp-2 block text-[10.5px] leading-snug text-[#7B8794]">{t('liveChatSubtitle')}</span>
          </span>
          <Badge count={unread} />
          <Chevron />
        </Card>
      </div>

      <div className="mt-6">
        <SectionTitle>{t('account')}</SectionTitle>
      </div>
      <div className="mt-3 space-y-3">
        <Tile title={t('cart')} subtitle={t('cartSubtitle')} icon="bag" onClick={requireAuth('/cart')} />
        <Tile title={t('personalInformation')} subtitle={t('personalInformationSubtitle')} asset="/assets/nav/profileb.svg" onClick={requireAuth('/profile/edit')} />
        <Tile title={t('changePassword')} subtitle={t('changePasswordSubtitle')} asset="/assets/profile/Lock_alt_fill.svg" onClick={requireAuth('/profile/change-password')} />
        <Tile title={t('savedAddresses')} subtitle={t('savedAddressesSubtitle')} asset="/assets/profile/Location.svg" onClick={requireAuth('/profile/addresses')} />
        <Tile title={t('savedAds')} subtitle={t('savedAdsSubtitle')} asset="/assets/profile/ADS.svg" onClick={requireAuth('/saved-ads')} />
        {isAuthenticated && (isSupplier || isCompanyCustomer) && (
          <>
            <Tile title={t('myAds')} subtitle={t('myAdsSubtitle')} asset="/assets/profile/ADS.svg" onClick={() => navigate('/my-ads')} />
            <Tile
              title={isCompanyCustomer ? t('changeTargetPrices') : t('changePrices')}
              subtitle={isCompanyCustomer ? t('changeTargetPricesSubtitle') : t('changePricesSubtitle')}
              icon="tag"
              colors={AMBER}
              onClick={() => navigate('/change-prices')}
            />
          </>
        )}
        <div className="flex items-center gap-3 rounded-2xl bg-[#EAF2FE] px-3.5 py-4">
          <Icon name="shield" size={30} className="text-[#2E77CC]" />
          <span className="min-w-0 flex-1">
            <span className="block text-[13.5px] font-bold text-[#1B5FB8]">{t('dataSafeTitle')}</span>
            <span className="mt-0.5 block text-[11.5px] leading-snug text-[#6C7C93]">{t('dataSafeSubtitle')}</span>
          </span>
          <Icon name="lock" size={32} className="text-[#2E77CC]/25" />
        </div>
      </div>

      <div className="mt-6">
        <SectionTitle>{t('settings')}</SectionTitle>
      </div>
      <div className="mt-3 space-y-3">
        {isAuthenticated && (
          <Tile
            title={t('notifications')}
            subtitle={t('notificationsPreferenceSubtitle')}
            asset="/assets/profile/notification.svg"
            trailing={<Switch checked={profile?.isNotificationsOn ?? true} busy={notifBusy || profileQuery.isLoading} onChange={toggleNotifications} />}
          />
        )}
        <Tile title={t('language')} subtitle={t('changeLanguageSubtitle')} asset="/assets/profile/Language.svg" onClick={switchLanguage} />
        <Tile title={t('complaintsSuggestions')} subtitle={t('complaintsSuggestionsSubtitle')} icon="feedback" onClick={requireAuth('/profile/feedback')} />
        <Tile title={t('helpSupport')} subtitle={t('helpSupportSubtitle')} asset="/assets/profile/HelpSupport.svg" onClick={() => navigate('/support')} />
        <Tile
          title={t('policyAndPrivacy')}
          subtitle={t('policyAndPrivacySubtitle')}
          asset="/assets/profile/PrivacyPolicy.svg"
          colors={GREEN}
          onClick={() => window.open(PRIVACY_URL, '_blank', 'noopener,noreferrer')}
        />
        {isAuthenticated && (
          <>
            <Tile title={t('deleteAccount')} subtitle={t('deleteAccountSubtitle')} asset="/assets/profile/u_trash-alt.svg" colors={RED} onClick={() => setDeleteOpen(true)} />
            <Tile
              title={t('logOut')}
              subtitle={t('logOutSubtitle')}
              asset="/assets/profile/log-out.svg"
              colors={RED}
              onClick={() => {
                logout()
                queryClient.clear()
                navigate('/', { replace: true })
              }}
            />
          </>
        )}
      </div>
      <DeleteAccountDialog open={deleteOpen} onClose={() => setDeleteOpen(false)} hasPassword={profile?.hasPassword !== false} />
    </PageContainer>
  )
}
