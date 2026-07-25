import { useAppPreferences } from '../../context/AppPreferencesProvider'
import {
  hasAnyShippingInfo,
  hasInternationalShipping,
  shippingTypeKey,
  type ProductShippingInfo,
} from '../../types/productShipping'
import CountryFlag from './CountryFlag'
import { DetailField } from './DetailSectionCard'

type ProductShippingPanelProps = {
  shipping: ProductShippingInfo
  showOrderPort?: boolean
  compact?: boolean
}

function EmptyValue({ children }: { children: string }) {
  return <span className="admin-text-subtle font-normal">{children}</span>
}

function RouteEndpoint({
  country,
  port,
  countryLabel,
  portLabel,
  compact = false,
}: {
  country?: string
  port?: string
  countryLabel: string
  portLabel: string
  compact?: boolean
}) {
  return (
    <div
      className={`admin-surface-muted flex-1 rounded-lg border border-dashed text-start ${
        compact ? 'p-2' : 'rounded-xl p-4'
      }`}
    >
      <p className="admin-text-subtle text-[10px] font-semibold uppercase tracking-wide">
        {countryLabel}
      </p>
      <p
        className={`admin-text flex items-center gap-1.5 font-bold ${
          compact ? 'mt-0.5 text-[11px]' : 'mt-1 text-sm'
        }`}
      >
        <CountryFlag countryName={country} size={20} />
        <span>{country?.trim() || '—'}</span>
      </p>
      <p
        className={`admin-text-subtle text-[10px] font-semibold uppercase tracking-wide ${
          compact ? 'mt-1.5' : 'mt-3'
        }`}
      >
        {portLabel}
      </p>
      <p className={`admin-text font-semibold ${compact ? 'mt-0.5 text-[11px]' : 'mt-1 text-sm'}`}>
        {port?.trim() || '—'}
      </p>
    </div>
  )
}

function ShippingTypeBadge({ type }: { type: 'international' | 'domestic' | 'none' }) {
  const { t } = useAppPreferences()

  if (type === 'none') {
    return null
  }

  const className =
    type === 'international'
      ? 'bg-sky-100 text-sky-800 dark:bg-sky-950/40 dark:text-sky-300'
      : 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-300'

  return (
    <span className={`rounded-full px-3 py-1 text-xs font-bold ${className}`}>
      {type === 'international'
        ? t('sharedShipping.typeInternational')
        : t('sharedShipping.typeDomestic')}
    </span>
  )
}

export default function ProductShippingPanel({
  shipping,
  showOrderPort = false,
  compact = false,
}: ProductShippingPanelProps) {
  const { t } = useAppPreferences()
  const type = shippingTypeKey(shipping)
  const hasData = hasAnyShippingInfo(shipping)
  const showRoute = hasInternationalShipping(shipping)

  if (!hasData) {
    return null
  }

  return (
    <div className={compact ? 'space-y-2' : 'space-y-4'}>
      <div className="flex flex-wrap items-center justify-start gap-2">
        <ShippingTypeBadge type={type} />
      </div>

      {showRoute ? (
        <div className={compact ? 'space-y-1.5' : 'space-y-3'}>
          {shipping.shippingRouteSummary?.trim() ? (
            <div
              className={`rounded-lg bg-[#3B7FC7]/8 text-start dark:bg-[#3B7FC7]/15 ${
                compact ? 'px-2 py-1.5' : 'rounded-xl px-4 py-3'
              }`}
            >
              <p className="admin-text-subtle text-[10px] font-medium">{t('ads.shippingRoute')}</p>
              <p
                className={`admin-text font-bold leading-snug ${
                  compact ? 'mt-0.5 text-[11px]' : 'mt-1 text-sm leading-relaxed'
                }`}
              >
                {shipping.shippingRouteSummary}
              </p>
            </div>
          ) : null}

          <div
            className={`flex flex-col items-stretch md:flex-row md:items-center ${
              compact ? 'gap-1.5' : 'gap-3'
            }`}
          >
            <RouteEndpoint
              compact={compact}
              country={shipping.originCountryName}
              port={shipping.loadingPortName}
              countryLabel={t('ads.originCountry')}
              portLabel={t('ads.loadingPort')}
            />
            <div className="flex shrink-0 items-center justify-center px-1">
              <span
                className={`admin-text-subtle inline-block font-light rtl:rotate-180 ${
                  compact ? 'text-base' : 'text-2xl'
                }`}
                aria-hidden
              >
                →
              </span>
            </div>
            <RouteEndpoint
              compact={compact}
              country={shipping.destinationCountryName}
              port={shipping.arrivalPortName}
              countryLabel={t('ads.destinationCountry')}
              portLabel={t('ads.arrivalPort')}
            />
          </div>
        </div>
      ) : null}

      <div className={`grid grid-cols-1 ${compact ? 'gap-2' : 'gap-4'} ${compact ? '' : 'sm:grid-cols-2'}`}>
        <DetailField
          label={
            shipping.offerDuration?.trim()
              ? t('ads.offerDuration')
              : t('ads.shippingDuration')
          }
          value={
            shipping.offerDuration?.trim() ? (
              shipping.offerDuration
            ) : shipping.shippingDuration?.trim() ? (
              shipping.shippingDuration
            ) : (
              <EmptyValue>—</EmptyValue>
            )
          }
        />

        {shipping.productAddress?.trim() ? (
          <DetailField label={t('sharedShipping.productAddress')} value={shipping.productAddress} />
        ) : null}

        {showOrderPort ? (
          <DetailField
            label={t('sharedShipping.orderPort')}
            value={
              shipping.orderPortName?.trim() ? (
                shipping.orderPortName
              ) : (
                <EmptyValue>—</EmptyValue>
              )
            }
          />
        ) : null}
      </div>

      <DetailField
        label={t('ads.shippingNotes')}
        value={
          shipping.shippingDescription?.trim() ? (
            <span className="admin-text-muted font-normal leading-relaxed">
              {shipping.shippingDescription}
            </span>
          ) : (
            <EmptyValue>{t('ads.noShippingNotes')}</EmptyValue>
          )
        }
      />
    </div>
  )
}
