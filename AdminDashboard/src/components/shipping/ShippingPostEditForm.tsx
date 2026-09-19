import { useMemo, useState, type FormEvent } from 'react'
import GeoSearchSelect from '../geo/GeoSearchSelect'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { useGetGeoCountriesQuery, useGetGeoPortsByCountryQuery } from '../../store'
import type { ShippingPostPayload } from '../../types/adminShippingCreate'
import { buildCountryOptions, buildPortOptions } from '../../utils/geoOptions'

type ShippingPostEditFormProps = {
  initialValues: ShippingPostPayload
  submitting: boolean
  onCancel: () => void
  onSubmit: (payload: ShippingPostPayload) => Promise<void>
}

export default function ShippingPostEditForm({
  initialValues,
  submitting,
  onCancel,
  onSubmit,
}: ShippingPostEditFormProps) {
  const { t, locale } = useAppPreferences()
  const [form, setForm] = useState<ShippingPostPayload>(() => ({ ...initialValues }))

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

  function updateField<K extends keyof ShippingPostPayload>(
    key: K,
    value: ShippingPostPayload[K],
  ) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    await onSubmit({
      ...form,
      fromCountryName: form.fromCountryName.trim(),
      fromPortName: form.fromPortName.trim(),
      toCountryName: form.toCountryName.trim(),
      toPortName: form.toPortName.trim(),
      phoneNumber: form.phoneNumber.trim(),
      details: form.details?.trim() || null,
      minDurationDays:
        form.minDurationDays != null && form.minDurationDays > 0
          ? form.minDurationDays
          : null,
      maxDurationDays:
        form.maxDurationDays != null && form.maxDurationDays > 0
          ? form.maxDurationDays
          : null,
    })
  }

  const countriesHint = t('shippingPage.geoCountriesHint').replace(
    '{count}',
    String(countries.length),
  )

  return (
    <form onSubmit={handleSubmit} className="admin-border space-y-4 border-t px-4 py-5 sm:px-6">
      <h3 className="admin-text text-base font-bold">{t('shippingPage.editAdTitle')}</h3>
      <p className="admin-text-muted text-sm">{t('shippingPage.editAdHint')}</p>

      <div className="admin-border border-t pt-4">
        <h4 className="admin-text mb-1 text-sm font-semibold">{t('shippingPage.routeSection')}</h4>
        <p className="admin-text-muted mb-3 text-xs">{t('shippingPage.geoSearchHelp')}</p>
        <div className="grid gap-4 md:grid-cols-2">
          <GeoSearchSelect
            label={t('shippingPage.fromCountry')}
            value={form.fromCountryName}
            onChange={(countryNameEn) => {
              setForm((prev) => ({
                ...prev,
                fromCountryName: countryNameEn,
                fromPortName: '',
              }))
            }}
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
            onChange={(countryNameEn) => {
              setForm((prev) => ({
                ...prev,
                toCountryName: countryNameEn,
                toPortName: '',
              }))
            }}
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

      <div className="grid gap-4 md:grid-cols-2">
        <label className="block text-right">
          <span className="admin-text-subtle mb-1 block text-xs font-medium">
            {t('shippingPage.mobile')}
          </span>
          <input
            type="text"
            value={form.phoneNumber}
            onChange={(e) => updateField('phoneNumber', e.target.value)}
            required
            className="admin-input w-full"
            dir="ltr"
          />
        </label>
        <div className="grid grid-cols-2 gap-3">
          <label className="block text-right">
            <span className="admin-text-subtle mb-1 block text-xs font-medium">
              {t('shippingPage.minDurationDays')}
            </span>
            <input
              type="number"
              min={1}
              value={form.minDurationDays ?? ''}
              onChange={(e) =>
                updateField(
                  'minDurationDays',
                  e.target.value === '' ? null : Number(e.target.value),
                )
              }
              className="admin-input w-full"
            />
          </label>
          <label className="block text-right">
            <span className="admin-text-subtle mb-1 block text-xs font-medium">
              {t('shippingPage.maxDurationDays')}
            </span>
            <input
              type="number"
              min={1}
              value={form.maxDurationDays ?? ''}
              onChange={(e) =>
                updateField(
                  'maxDurationDays',
                  e.target.value === '' ? null : Number(e.target.value),
                )
              }
              className="admin-input w-full"
            />
          </label>
        </div>
      </div>

      <div className="admin-border border-t pt-4">
        <h4 className="admin-text mb-3 text-sm font-semibold">{t('shippingPage.pricingSection')}</h4>
        <div className="grid gap-4 md:grid-cols-2">
          <label className="block text-right">
            <span className="admin-text-subtle mb-1 block text-xs font-medium">
              {t('shippingPage.price20ft')}
            </span>
            <input
              type="number"
              min={0}
              step={0.01}
              value={form.container20ftPriceUsd ?? ''}
              onChange={(e) =>
                updateField(
                  'container20ftPriceUsd',
                  e.target.value === '' ? null : Number(e.target.value),
                )
              }
              className="admin-input w-full"
            />
          </label>
          <label className="block text-right">
            <span className="admin-text-subtle mb-1 block text-xs font-medium">
              {t('shippingPage.price40ft')}
            </span>
            <input
              type="number"
              min={0}
              step={0.01}
              value={form.container40ftPriceUsd ?? ''}
              onChange={(e) =>
                updateField(
                  'container40ftPriceUsd',
                  e.target.value === '' ? null : Number(e.target.value),
                )
              }
              className="admin-input w-full"
            />
          </label>
        </div>
      </div>

      <label className="block text-right">
        <span className="admin-text-subtle mb-1 block text-xs font-medium">
          {t('shippingPage.adDetails')}
        </span>
        <textarea
          value={form.details ?? ''}
          onChange={(e) => updateField('details', e.target.value)}
          rows={3}
          className="admin-input w-full resize-y"
        />
      </label>

      <div className="flex flex-wrap gap-3 pt-2">
        <button
          type="submit"
          disabled={submitting || countriesLoading}
          className="keep-white rounded-xl bg-[#3B7FC7] px-5 py-2.5 text-sm font-semibold text-white hover:bg-[#2f6ab0] disabled:opacity-60"
        >
          {submitting ? t('shippingPage.savingCompany') : t('shippingPage.saveChanges')}
        </button>
        <button type="button" onClick={onCancel} className="admin-btn-ghost">
          {t('cancel')}
        </button>
      </div>
    </form>
  )
}
