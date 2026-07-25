import { useEffect, useMemo, useState, type FormEvent, type ReactNode } from 'react'
import { changePassword } from '../api/auth'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { categoryDisplayName } from '../utils/categoryDisplay'
import { resolveAssetUrl } from '../lib/assets'
import {
  useGetCategoriesQuery,
  useGetInternalDomesticShippingQuery,
  useGetSystemSettingsQuery,
  useUpdateInternalDomesticShippingMutation,
  useUpdateSystemSettingsMutation,
} from '../store'
import type { CategoryCommission, SystemSettings, UpdateSystemSettingsPayload } from '../types/adminSettings'
import type { InternalDomesticShippingRate } from '../types/internalDomesticShipping'
import type { Category } from '../types/category'
import { getRtkErrorMessage } from '../utils/rtkError'

type CommissionField =
  | 'retailCommissionPercent'
  | 'bookingCommissionPercent'
  | 'requestsCommissionPercent'
  | 'offersCommissionPercent'
  | 'shippingCommissionPercent'

type SettingsSection =
  | 'commissions'
  | 'categories'
  | 'appInfo'
  | 'ads'
  | 'shipping'
  | 'security'

const COMMISSION_FIELDS: {
  key: CommissionField
  labelKey: string
  icon: string
}[] = [
  { key: 'bookingCommissionPercent', labelKey: 'settingsPage.booking', icon: '📋' },
  { key: 'requestsCommissionPercent', labelKey: 'settingsPage.requests', icon: '📄' },
  { key: 'offersCommissionPercent', labelKey: 'settingsPage.offers', icon: '🏷️' },
  { key: 'retailCommissionPercent', labelKey: 'settingsPage.retail', icon: '🏪' },
  { key: 'shippingCommissionPercent', labelKey: 'settingsPage.shipping', icon: '🚢' },
]

const SETTINGS_SECTIONS: {
  id: SettingsSection
  titleKey: string
  descKey: string
  icon: string
  accent: string
}[] = [
  {
    id: 'commissions',
    titleKey: 'settingsPage.commissionsTitle',
    descKey: 'settingsPage.cardCommissionsDesc',
    icon: '💰',
    accent: 'from-amber-50 to-orange-50 dark:from-amber-950/30 dark:to-orange-950/20',
  },
  {
    id: 'categories',
    titleKey: 'settingsPage.categoryCommissionsTitle',
    descKey: 'settingsPage.cardCategoriesDesc',
    icon: '🌿',
    accent: 'from-emerald-50 to-teal-50 dark:from-emerald-950/30 dark:to-teal-950/20',
  },
  {
    id: 'appInfo',
    titleKey: 'settingsPage.appInfoTitle',
    descKey: 'settingsPage.cardAppInfoDesc',
    icon: '📱',
    accent: 'from-sky-50 to-blue-50 dark:from-sky-950/30 dark:to-blue-950/20',
  },
  {
    id: 'ads',
    titleKey: 'settingsPage.adsTitle',
    descKey: 'settingsPage.cardAdsDesc',
    icon: '📢',
    accent: 'from-violet-50 to-purple-50 dark:from-violet-950/30 dark:to-purple-950/20',
  },
  {
    id: 'shipping',
    titleKey: 'settingsPage.domesticShippingTitle',
    descKey: 'settingsPage.cardShippingDesc',
    icon: '🚚',
    accent: 'from-cyan-50 to-sky-50 dark:from-cyan-950/30 dark:to-sky-950/20',
  },
  {
    id: 'security',
    titleKey: 'settingsPage.passwordTitle',
    descKey: 'settingsPage.cardSecurityDesc',
    icon: '🔒',
    accent: 'from-rose-50 to-red-50 dark:from-rose-950/30 dark:to-red-950/20',
  },
]

const SETTINGS_FORM_SECTIONS = new Set<SettingsSection>([
  'commissions',
  'categories',
  'appInfo',
  'ads',
])

function mergeCategoryCommissions(
  fromSettings: CategoryCommission[],
  categories: Category[] | undefined,
): CategoryCommission[] {
  const settingsMap = new Map(fromSettings.map((item) => [item.categoryId, item]))

  if (categories && categories.length > 0) {
    return categories
      .filter((category) => !category.isHide)
      .map((category) => {
        const saved = settingsMap.get(category.categoryId)
        return {
          categoryId: category.categoryId,
          nameEn: category.nameEn,
          nameAr: category.nameAr,
          commissionPercent: saved?.commissionPercent ?? category.commissionPercent ?? 0,
        }
      })
  }

  return fromSettings.map((item) => ({ ...item }))
}

function toFormState(
  data: SystemSettings,
  categories: Category[] | undefined,
): UpdateSystemSettingsPayload {
  return {
    retailCommissionPercent: data.retailCommissionPercent,
    bookingCommissionPercent: data.bookingCommissionPercent,
    requestsCommissionPercent: data.requestsCommissionPercent,
    offersCommissionPercent: data.offersCommissionPercent,
    shippingCommissionPercent: data.shippingCommissionPercent,
    categoryCommissions: mergeCategoryCommissions(data.categoryCommissions, categories),
    appName: data.appName,
    supportEmail: data.supportEmail,
    phoneNumber: data.phoneNumber,
    landlineNumber: data.landlineNumber,
    timezone: data.timezone,
    address: data.address,
    featuredAdPriceAed: data.featuredAdPriceAed,
    adDisplayDurationDays: data.adDisplayDurationDays,
  }
}

function SettingsField({
  label,
  value,
  onChange,
  type = 'text',
}: {
  label: string
  value: string
  onChange: (value: string) => void
  type?: 'text' | 'email' | 'number' | 'password'
}) {
  return (
    <label className="block text-right">
      <span className="admin-text-subtle mb-1 block text-xs font-medium">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="admin-input w-full px-4 py-3"
      />
    </label>
  )
}

function SettingsNavCard({
  icon,
  title,
  description,
  accent,
  isActive,
  onClick,
}: {
  icon: string
  title: string
  description: string
  accent: string
  isActive: boolean
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={[
        'admin-card group relative flex h-full flex-col items-stretch rounded-2xl border p-4 text-right transition sm:p-5',
        'hover:-translate-y-0.5 hover:shadow-md focus:outline-none focus-visible:ring-2 focus-visible:ring-[#3B7FC7]/40',
        isActive
          ? 'border-[#3B7FC7] ring-2 ring-[#3B7FC7]/20'
          : 'admin-border border-transparent hover:border-[#3B7FC7]/30',
      ].join(' ')}
    >
      <div
        className={`mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br text-2xl shadow-sm ${accent}`}
      >
        {icon}
      </div>
      <span className="admin-text text-sm font-bold leading-snug sm:text-base">{title}</span>
      <span className="admin-text-muted mt-1.5 text-xs leading-relaxed sm:text-sm">
        {description}
      </span>
      {isActive ? (
        <span className="absolute left-3 top-3 h-2.5 w-2.5 rounded-full bg-[#3B7FC7]" aria-hidden />
      ) : null}
    </button>
  )
}

function SectionPanel({
  title,
  hint,
  action,
  children,
}: {
  title: string
  hint?: string
  action?: ReactNode
  children: ReactNode
}) {
  return (
    <section className="admin-card overflow-hidden">
      <div className="flex flex-col gap-4 border-b border-slate-100 px-5 py-4 dark:border-slate-800 sm:flex-row sm:items-start sm:justify-between sm:px-6 sm:py-5">
        <div className="text-right">
          <h2 className="admin-text text-lg font-bold">{title}</h2>
          {hint ? (
            <p className="admin-text-muted mt-1.5 text-sm leading-relaxed">{hint}</p>
          ) : null}
        </div>
        {action ? <div className="shrink-0 self-start">{action}</div> : null}
      </div>
      <div className="p-5 sm:p-6">{children}</div>
    </section>
  )
}

function RateCard({
  icon,
  imageUrl,
  imageAlt,
  title,
  subtitle,
  value,
  suffix,
  onChange,
  max,
  step = 0.01,
}: {
  icon?: string
  imageUrl?: string
  imageAlt?: string
  title: string
  subtitle?: string
  value: number
  suffix: string
  onChange: (value: number) => void
  max?: number
  step?: number
}) {
  return (
    <label className="admin-surface-muted admin-border flex items-center gap-3 rounded-2xl border p-4">
      <span className="flex h-12 w-12 shrink-0 items-center justify-center overflow-hidden rounded-xl bg-white shadow-sm dark:bg-slate-900">
        {imageUrl ? (
          <img
            src={imageUrl}
            alt={imageAlt ?? title}
            className="h-full w-full object-contain p-1"
          />
        ) : icon ? (
          <span className="text-2xl">{icon}</span>
        ) : null}
      </span>
      <span className="min-w-0 flex-1 text-right">
        <span className="admin-text block text-sm font-semibold">{title}</span>
        {subtitle ? (
          <span className="admin-text-subtle block text-xs">{subtitle}</span>
        ) : null}
        <span className="mt-2 flex items-center justify-end gap-2">
          <input
            type="number"
            min={0}
            max={max ?? (suffix === '%' ? 100 : undefined)}
            step={step}
            value={value}
            onChange={(event) => onChange(Number(event.target.value) || 0)}
            className="admin-input w-28 px-3 py-2 text-center"
          />
          <span className="admin-text-subtle text-sm font-semibold">{suffix}</span>
        </span>
      </span>
    </label>
  )
}

export default function SettingsPage() {
  const { t, locale } = useAppPreferences()
  const { data, error, isLoading } = useGetSystemSettingsQuery()
  const { data: categoriesData } = useGetCategoriesQuery()
  const {
    data: domesticShippingData,
    error: domesticShippingError,
    isLoading: isDomesticShippingLoading,
  } = useGetInternalDomesticShippingQuery()
  const [updateSettings, { isLoading: isSaving }] = useUpdateSystemSettingsMutation()
  const [updateDomesticShipping, { isLoading: isSavingDomesticShipping }] =
    useUpdateInternalDomesticShippingMutation()

  const [activeSection, setActiveSection] = useState<SettingsSection>('commissions')
  const [form, setForm] = useState<UpdateSystemSettingsPayload | null>(null)
  const [domesticShippingRates, setDomesticShippingRates] = useState<
    InternalDomesticShippingRate[] | null
  >(null)
  const [excessKgRateAed, setExcessKgRateAed] = useState(0)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [domesticShippingSuccessMessage, setDomesticShippingSuccessMessage] = useState<
    string | null
  >(null)
  const [actionError, setActionError] = useState<string | null>(null)
  const [domesticShippingActionError, setDomesticShippingActionError] = useState<string | null>(
    null,
  )

  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [passwordMessage, setPasswordMessage] = useState<string | null>(null)
  const [passwordError, setPasswordError] = useState<string | null>(null)
  const [isChangingPassword, setIsChangingPassword] = useState(false)

  const categoryImageById = useMemo(
    () => new Map((categoriesData?.items ?? []).map((category) => [category.categoryId, category.imgPath])),
    [categoriesData],
  )

  useEffect(() => {
    if (data) {
      setForm(toFormState(data, categoriesData?.items))
    }
  }, [data, categoriesData])

  useEffect(() => {
    if (domesticShippingData?.items) {
      setDomesticShippingRates(domesticShippingData.items)
      setExcessKgRateAed(
        Math.min(255, Math.max(0, Math.round(domesticShippingData.excessKgRateAed ?? 0))),
      )
    }
  }, [domesticShippingData])

  function updateField<K extends keyof UpdateSystemSettingsPayload>(
    key: K,
    value: UpdateSystemSettingsPayload[K],
  ) {
    setForm((prev) => (prev ? { ...prev, [key]: value } : prev))
  }

  function updateCategoryCommission(categoryId: number, commissionPercent: number) {
    setForm((prev) =>
      prev
        ? {
            ...prev,
            categoryCommissions: prev.categoryCommissions.map((item) =>
              item.categoryId === categoryId ? { ...item, commissionPercent } : item,
            ),
          }
        : prev,
    )
  }

  function updateDomesticShippingRate(id: number, priceAed: number) {
    setDomesticShippingRates((prev) =>
      prev
        ? prev.map((item) => (item.id === id ? { ...item, priceAed } : item))
        : prev,
    )
  }

  async function handleSaveDomesticShipping(event: FormEvent) {
    event.preventDefault()
    if (!domesticShippingRates) return

    setDomesticShippingSuccessMessage(null)
    setDomesticShippingActionError(null)

    try {
      await updateDomesticShipping({
        rates: domesticShippingRates.map((item) => ({
          id: item.id,
          priceAed: item.priceAed,
        })),
        excessKgRateAed: Math.min(255, Math.max(0, Math.round(excessKgRateAed))),
      }).unwrap()
      setDomesticShippingSuccessMessage(t('settingsPage.domesticShippingSaveSuccess'))
    } catch (err) {
      setDomesticShippingActionError(
        getRtkErrorMessage(err as never, t('settingsPage.domesticShippingSaveError')),
      )
    }
  }

  async function handleSaveSettings(event: FormEvent) {
    event.preventDefault()
    if (!form) return

    setSuccessMessage(null)
    setActionError(null)

    try {
      await updateSettings(form).unwrap()
      setSuccessMessage(t('settingsPage.saveSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('settingsPage.saveError')))
    }
  }

  async function handleChangePassword(event: FormEvent) {
    event.preventDefault()
    setPasswordMessage(null)
    setPasswordError(null)

    if (newPassword.length < 6) {
      setPasswordError(t('settingsPage.passwordTooShort'))
      return
    }

    if (newPassword !== confirmPassword) {
      setPasswordError(t('settingsPage.passwordMismatch'))
      return
    }

    setIsChangingPassword(true)
    try {
      const result = await changePassword({ currentPassword, newPassword })
      setPasswordMessage(result.message || t('settingsPage.passwordSuccess'))
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
    } catch (err) {
      setPasswordError(
        err instanceof Error ? err.message : t('settingsPage.passwordError'),
      )
    } finally {
      setIsChangingPassword(false)
    }
  }

  if (isLoading || !form || isDomesticShippingLoading || !domesticShippingRates) {
    return (
      <div className="flex justify-center py-24">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
      </div>
    )
  }

  const saveSettingsButton = (
    <button
      type="submit"
      form="settings-form"
      disabled={isSaving}
      className="keep-white inline-flex items-center justify-center gap-2 rounded-xl bg-[#3B7FC7] px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-[#2f6eb3] disabled:opacity-60"
    >
      <span aria-hidden>💾</span>
      {isSaving ? t('settingsPage.saving') : t('settingsPage.saveData')}
    </button>
  )

  const saveShippingButton = (
    <button
      type="submit"
      form="domestic-shipping-form"
      disabled={isSavingDomesticShipping}
      className="keep-white inline-flex items-center justify-center gap-2 rounded-xl bg-[#3B7FC7] px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-[#2f6eb3] disabled:opacity-60"
    >
      <span aria-hidden>💾</span>
      {isSavingDomesticShipping
        ? t('settingsPage.saving')
        : t('settingsPage.domesticShippingSave')}
    </button>
  )

  return (
    <div className="space-y-6">
      <div className="text-right">
        <h1 className="admin-text text-2xl font-bold">{t('settingsPage.title')}</h1>
        <p className="admin-text-muted mt-2 max-w-2xl text-sm leading-relaxed">
          {t('settingsPage.description')}
        </p>
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-3">
        {SETTINGS_SECTIONS.map((section) => (
          <SettingsNavCard
            key={section.id}
            icon={section.icon}
            title={t(section.titleKey)}
            description={t(section.descKey)}
            accent={section.accent}
            isActive={activeSection === section.id}
            onClick={() => setActiveSection(section.id)}
          />
        ))}
      </div>

      {SETTINGS_FORM_SECTIONS.has(activeSection) && successMessage ? (
        <div className="admin-alert-success">{successMessage}</div>
      ) : null}
      {SETTINGS_FORM_SECTIONS.has(activeSection) && (error || actionError) ? (
        <div className="admin-alert-error">
          {actionError ?? getRtkErrorMessage(error, t('settingsPage.loadError'))}
        </div>
      ) : null}

      {activeSection === 'shipping' && domesticShippingSuccessMessage ? (
        <div className="admin-alert-success">{domesticShippingSuccessMessage}</div>
      ) : null}
      {activeSection === 'shipping' && (domesticShippingError || domesticShippingActionError) ? (
        <div className="admin-alert-error">
          {domesticShippingActionError ??
            getRtkErrorMessage(domesticShippingError, t('settingsPage.domesticShippingLoadError'))}
        </div>
      ) : null}

      {activeSection === 'security' && passwordMessage ? (
        <div className="admin-alert-success">{passwordMessage}</div>
      ) : null}
      {activeSection === 'security' && passwordError ? (
        <div className="admin-alert-error">{passwordError}</div>
      ) : null}

      <form id="settings-form" onSubmit={handleSaveSettings}>
        {activeSection === 'commissions' ? (
          <SectionPanel
            title={t('settingsPage.commissionsTitle')}
            hint={t('settingsPage.commissionsHint')}
            action={saveSettingsButton}
          >
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              {COMMISSION_FIELDS.map((field) => (
                <RateCard
                  key={field.key}
                  icon={field.icon}
                  title={t(field.labelKey)}
                  value={form[field.key]}
                  suffix="%"
                  onChange={(value) => updateField(field.key, value)}
                />
              ))}
            </div>
          </SectionPanel>
        ) : null}

        {activeSection === 'categories' ? (
          <SectionPanel
            title={t('settingsPage.categoryCommissionsTitle')}
            hint={t('settingsPage.categoryCommissionsHint')}
            action={saveSettingsButton}
          >
            {form.categoryCommissions.length === 0 ? (
              <p className="admin-text-muted text-right text-sm">
                {t('settingsPage.categoryCommissionsLoading')}
              </p>
            ) : (
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
                {form.categoryCommissions.map((category) => {
                  const imgPath = categoryImageById.get(category.categoryId)
                  const imageUrl = imgPath ? resolveAssetUrl(imgPath) : undefined
                  const title = categoryDisplayName(category, locale)

                  return (
                    <RateCard
                      key={category.categoryId}
                      imageUrl={imageUrl}
                      imageAlt={title}
                      title={title}
                      value={category.commissionPercent}
                      suffix="%"
                      onChange={(value) =>
                        updateCategoryCommission(category.categoryId, value)
                      }
                    />
                  )
                })}
              </div>
            )}
          </SectionPanel>
        ) : null}

        {activeSection === 'appInfo' ? (
          <SectionPanel
            title={t('settingsPage.appInfoTitle')}
            action={saveSettingsButton}
          >
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <SettingsField
                label={t('settingsPage.appName')}
                value={form.appName}
                onChange={(value) => updateField('appName', value)}
              />
              <SettingsField
                label={t('settingsPage.supportEmail')}
                type="email"
                value={form.supportEmail ?? ''}
                onChange={(value) => updateField('supportEmail', value || null)}
              />
              <SettingsField
                label={t('settingsPage.phoneNumber')}
                value={form.phoneNumber ?? ''}
                onChange={(value) => updateField('phoneNumber', value || null)}
              />
              <SettingsField
                label={t('settingsPage.landlineNumber')}
                value={form.landlineNumber ?? ''}
                onChange={(value) => updateField('landlineNumber', value || null)}
              />
              <SettingsField
                label={t('settingsPage.timezone')}
                value={form.timezone ?? ''}
                onChange={(value) => updateField('timezone', value || null)}
              />
              <SettingsField
                label={t('settingsPage.address')}
                value={form.address ?? ''}
                onChange={(value) => updateField('address', value || null)}
              />
            </div>
          </SectionPanel>
        ) : null}

        {activeSection === 'ads' ? (
          <SectionPanel title={t('settingsPage.adsTitle')} action={saveSettingsButton}>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <SettingsField
                label={t('settingsPage.featuredAdPrice')}
                type="number"
                value={String(form.featuredAdPriceAed)}
                onChange={(value) => updateField('featuredAdPriceAed', Number(value) || 0)}
              />
              <SettingsField
                label={t('settingsPage.adDisplayDays')}
                type="number"
                value={String(form.adDisplayDurationDays)}
                onChange={(value) =>
                  updateField('adDisplayDurationDays', Number(value) || 0)
                }
              />
            </div>
          </SectionPanel>
        ) : null}
      </form>

      {activeSection === 'shipping' ? (
        <SectionPanel
          title={t('settingsPage.domesticShippingTitle')}
          hint={t('settingsPage.domesticShippingHint')}
          action={saveShippingButton}
        >
          <form id="domestic-shipping-form" onSubmit={handleSaveDomesticShipping}>
            <div className="mb-4 max-w-md">
              <RateCard
                icon="⚖️"
                title={t('settingsPage.domesticShippingExcessKgRate')}
                subtitle={t('settingsPage.domesticShippingExcessKgRateHint')}
                value={excessKgRateAed}
                suffix="AED/kg"
                max={255}
                step={1}
                onChange={(value) =>
                  setExcessKgRateAed(Math.min(255, Math.max(0, Math.round(value))))
                }
              />
            </div>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              {domesticShippingRates.map((rate) => (
                <RateCard
                  key={rate.id}
                  icon="🏙️"
                  title={rate.emirateNameAr}
                  subtitle={rate.emirateNameEn}
                  value={rate.priceAed}
                  suffix="AED"
                  onChange={(value) => updateDomesticShippingRate(rate.id, value)}
                />
              ))}
            </div>
          </form>
        </SectionPanel>
      ) : null}

      {activeSection === 'security' ? (
        <SectionPanel title={t('settingsPage.passwordTitle')}>
          <form
            onSubmit={handleChangePassword}
            className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3"
          >
            <SettingsField
              label={t('settingsPage.currentPassword')}
              type="password"
              value={currentPassword}
              onChange={setCurrentPassword}
            />
            <SettingsField
              label={t('settingsPage.newPassword')}
              type="password"
              value={newPassword}
              onChange={setNewPassword}
            />
            <SettingsField
              label={t('settingsPage.confirmPassword')}
              type="password"
              value={confirmPassword}
              onChange={setConfirmPassword}
            />
            <div className="md:col-span-2 xl:col-span-3">
              <button
                type="submit"
                disabled={isChangingPassword}
                className="admin-btn-primary px-6 py-3 disabled:opacity-60"
              >
                {isChangingPassword
                  ? t('settingsPage.changingPassword')
                  : t('settingsPage.changePassword')}
              </button>
            </div>
          </form>
        </SectionPanel>
      ) : null}
    </div>
  )
}
