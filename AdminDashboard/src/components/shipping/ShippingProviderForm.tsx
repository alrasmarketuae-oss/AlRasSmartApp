import { useEffect, useMemo, useState, type FormEvent } from 'react'
import GeoSearchSelect from '../geo/GeoSearchSelect'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'
import { useGetGeoCountriesQuery, useGetGeoPortsByCountryQuery } from '../../store'
import type { ShippingProviderPayload } from '../../types/adminShippingCreate'
import { buildCountryOptions, buildPortOptions } from '../../utils/geoOptions'

type ShippingProviderFormProps = {
  mode: 'create' | 'edit'
  initialValues?: Partial<ShippingProviderPayload>
  initialImageUrl?: string | null
  onSubmit: (payload: ShippingProviderPayload, imageFile: File | null) => Promise<void>
  onCancel: () => void
  submitting: boolean
}

const emptyForm: ShippingProviderPayload = {
  companyName: '',
  fullName: '',
  email: '',
  phoneNumber: '',
  fromCountryName: '',
  fromPortName: '',
  toCountryName: '',
  toPortName: '',
  container20ftPriceUsd: 0,
  container40ftPriceUsd: 0,
}

function mergeInitialValues(initialValues?: Partial<ShippingProviderPayload>): ShippingProviderPayload {
  return { ...emptyForm, ...initialValues }
}

export default function ShippingProviderForm({
  mode,
  initialValues,
  initialImageUrl,
  onSubmit,
  onCancel,
  submitting,
}: ShippingProviderFormProps) {
  const { t, locale } = useAppPreferences()
  const [form, setForm] = useState(() => mergeInitialValues(initialValues))
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(
    initialImageUrl ? resolveAssetUrl(initialImageUrl) : null,
  )

  useEffect(() => {
    setImagePreview(initialImageUrl ? resolveAssetUrl(initialImageUrl) : null)
    setImageFile(null)
  }, [initialImageUrl, mode])

  useEffect(() => {
    if (!imageFile) return
    const objectUrl = URL.createObjectURL(imageFile)
    setImagePreview(objectUrl)
    return () => URL.revokeObjectURL(objectUrl)
  }, [imageFile])

  const { data: countries = [], isLoading: countriesLoading } = useGetGeoCountriesQuery()
  const { data: fromPortsData, isFetching: fromPortsLoading } = useGetGeoPortsByCountryQuery(
    form.fromCountryName,
    { skip: !form.fromCountryName },
  )
  const { data: toPortsData, isFetching: toPortsLoading } = useGetGeoPortsByCountryQuery(
    form.toCountryName,
    { skip: !form.toCountryName },
  )

  const countryOptions = useMemo(
    () => buildCountryOptions(countries, locale),
    [countries, locale],
  )
  const fromPortOptions = useMemo(
    () => buildPortOptions(fromPortsData?.ports ?? []),
    [fromPortsData],
  )
  const toPortOptions = useMemo(
    () => buildPortOptions(toPortsData?.ports ?? []),
    [toPortsData],
  )

  function updateField<K extends keyof ShippingProviderPayload>(
    key: K,
    value: ShippingProviderPayload[K],
  ) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  function handleFromCountryChange(countryNameEn: string) {
    setForm((prev) => ({
      ...prev,
      fromCountryName: countryNameEn,
      fromPortName: '',
    }))
  }

  function handleToCountryChange(countryNameEn: string) {
    setForm((prev) => ({
      ...prev,
      toCountryName: countryNameEn,
      toPortName: '',
    }))
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    await onSubmit(
      {
        ...form,
        companyName: form.companyName.trim(),
        fullName: form.fullName.trim(),
        email: form.email.trim(),
        phoneNumber: form.phoneNumber.trim(),
        fromCountryName: form.fromCountryName.trim(),
        fromPortName: form.fromPortName.trim(),
        toCountryName: form.toCountryName.trim(),
        toPortName: form.toPortName.trim(),
      },
      imageFile,
    )
  }

  const countriesHint = t('shippingPage.geoCountriesHint').replace(
    '{count}',
    String(countries.length),
  )

  const isCreate = mode === 'create'

  return (
    <form onSubmit={handleSubmit} className="admin-border space-y-4 border-t px-4 py-5 sm:px-6">
      <h3 className="admin-text text-base font-bold">
        {isCreate ? t('shippingPage.addCompanyTitle') : t('shippingPage.editCompanyTitle')}
      </h3>
      <p className="admin-text-muted text-sm">
        {isCreate ? t('shippingPage.addCompanyHint') : t('shippingPage.editCompanyHint')}
      </p>

      <div className="grid gap-4 md:grid-cols-2">
        <Field
          label={t('shippingPage.companyName')}
          value={form.companyName}
          onChange={(v) => updateField('companyName', v)}
          required
        />
        <Field
          label={t('shippingPage.contactName')}
          value={form.fullName}
          onChange={(v) => updateField('fullName', v)}
          required
        />
        <Field
          label={t('shippingPage.email')}
          type="email"
          value={form.email}
          onChange={(v) => updateField('email', v)}
          required
        />
        <Field
          label={t('shippingPage.mobile')}
          value={form.phoneNumber}
          onChange={(v) => updateField('phoneNumber', v)}
          required
        />
      </div>

      <div className="admin-border border-t pt-4">
        <h4 className="admin-text mb-2 text-sm font-semibold">{t('shippingPage.companyImage')}</h4>
        <p className="admin-text-muted mb-3 text-xs">{t('shippingPage.companyImageHint')}</p>
        <div className="flex flex-wrap items-center gap-4">
          <div className="flex h-24 w-24 items-center justify-center overflow-hidden rounded-2xl border border-[#3B7FC7]/20 bg-[#f8fbff] dark:border-slate-700 dark:bg-slate-800">
            {imagePreview ? (
              <img src={imagePreview} alt="" className="h-full w-full object-cover" />
            ) : (
              <span className="admin-text-muted px-2 text-center text-[10px]">
                {t('shippingPage.noCompanyImage')}
              </span>
            )}
          </div>
          <label className="inline-flex cursor-pointer items-center rounded-xl border border-[#3B7FC7]/25 bg-white px-4 py-2.5 text-sm font-semibold text-[#3B7FC7] transition hover:bg-[#3B7FC7]/5 dark:border-slate-600 dark:bg-slate-800 dark:text-[#7eb8ff]">
            {t('shippingPage.chooseCompanyImage')}
            <input
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(event) => setImageFile(event.target.files?.[0] ?? null)}
            />
          </label>
        </div>
      </div>

      <div className="admin-border border-t pt-4">
        <h4 className="admin-text mb-1 text-sm font-semibold">{t('shippingPage.routeSection')}</h4>
        <p className="admin-text-muted mb-3 text-xs">{t('shippingPage.geoSearchHelp')}</p>
        <div className="grid gap-4 md:grid-cols-2">
          <GeoSearchSelect
            label={t('shippingPage.fromCountry')}
            value={form.fromCountryName}
            onChange={handleFromCountryChange}
            options={countryOptions}
            placeholder={t('shippingPage.selectCountry')}
            searchPlaceholder={t('shippingPage.searchCountry')}
            emptyText={t('shippingPage.noGeoResults')}
            resultsHint={countriesHint}
            loading={countriesLoading}
            required
          />
          <GeoSearchSelect
            label={t('shippingPage.fromPort')}
            value={form.fromPortName}
            onChange={(v) => updateField('fromPortName', v)}
            options={fromPortOptions}
            placeholder={
              form.fromCountryName
                ? t('shippingPage.selectPort')
                : t('shippingPage.selectCountryFirst')
            }
            searchPlaceholder={t('shippingPage.searchPort')}
            emptyText={t('shippingPage.noGeoResults')}
            resultsHint={
              form.fromCountryName
                ? t('shippingPage.geoPortsHint').replace('{count}', String(fromPortOptions.length))
                : undefined
            }
            loading={fromPortsLoading}
            disabled={!form.fromCountryName}
            required
          />
          <GeoSearchSelect
            label={t('shippingPage.toCountry')}
            value={form.toCountryName}
            onChange={handleToCountryChange}
            options={countryOptions}
            placeholder={t('shippingPage.selectCountry')}
            searchPlaceholder={t('shippingPage.searchCountry')}
            emptyText={t('shippingPage.noGeoResults')}
            resultsHint={countriesHint}
            loading={countriesLoading}
            required
          />
          <GeoSearchSelect
            label={t('shippingPage.toPort')}
            value={form.toPortName}
            onChange={(v) => updateField('toPortName', v)}
            options={toPortOptions}
            placeholder={
              form.toCountryName
                ? t('shippingPage.selectPort')
                : t('shippingPage.selectCountryFirst')
            }
            searchPlaceholder={t('shippingPage.searchPort')}
            emptyText={t('shippingPage.noGeoResults')}
            resultsHint={
              form.toCountryName
                ? t('shippingPage.geoPortsHint').replace('{count}', String(toPortOptions.length))
                : undefined
            }
            loading={toPortsLoading}
            disabled={!form.toCountryName}
            required
          />
        </div>
      </div>

      <div className="admin-border border-t pt-4">
        <h4 className="admin-text mb-3 text-sm font-semibold">{t('shippingPage.pricingSection')}</h4>
        <div className="grid gap-4 md:grid-cols-2">
          <NumberField
            label={t('shippingPage.price20ft')}
            value={form.container20ftPriceUsd}
            onChange={(v) => updateField('container20ftPriceUsd', v)}
            min={0.01}
            step={0.01}
            required
          />
          <NumberField
            label={t('shippingPage.price40ft')}
            value={form.container40ftPriceUsd}
            onChange={(v) => updateField('container40ftPriceUsd', v)}
            min={0.01}
            step={0.01}
            required
          />
        </div>
      </div>

      <div className="flex flex-wrap gap-3 pt-2">
        <button
          type="submit"
          disabled={submitting || countriesLoading}
          className="keep-white rounded-xl bg-[#3B7FC7] px-5 py-2.5 text-sm font-semibold text-white hover:bg-[#2f6ab0] disabled:opacity-60"
        >
          {submitting
            ? t('shippingPage.savingCompany')
            : isCreate
              ? t('shippingPage.addCompanyButton')
              : t('shippingPage.saveChanges')}
        </button>
        <button type="button" onClick={onCancel} className="admin-btn-ghost">
          {t('cancel')}
        </button>
      </div>
    </form>
  )
}

function Field({
  label,
  value,
  onChange,
  type = 'text',
  required = false,
}: {
  label: string
  value: string
  onChange: (value: string) => void
  type?: string
  required?: boolean
}) {
  return (
    <label className="block text-right">
      <span className="admin-text-subtle mb-1 block text-xs font-medium">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        required={required}
        className="admin-input w-full"
      />
    </label>
  )
}

function NumberField({
  label,
  value,
  onChange,
  min,
  step,
  required = false,
}: {
  label: string
  value: number
  onChange: (value: number) => void
  min?: number
  step?: number
  required?: boolean
}) {
  return (
    <label className="block text-right">
      <span className="admin-text-subtle mb-1 block text-xs font-medium">{label}</span>
      <input
        type="number"
        value={Number.isFinite(value) ? value : ''}
        onChange={(e) => onChange(Number(e.target.value))}
        required={required}
        min={min}
        step={step}
        className="admin-input w-full"
      />
    </label>
  )
}
