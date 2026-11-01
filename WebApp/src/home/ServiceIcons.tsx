import { useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { useI18n } from '../i18n/I18nProvider'
import type { StringKey } from '../i18n/strings'
import { useGate } from '../ui/GateProvider'

type Service = { key: string; label: StringKey; icon: string; path?: string }

export function ServiceIcons() {
  const { t } = useI18n()
  const navigate = useNavigate()
  const { showAppOnly } = useGate()
  const { isCompanyCustomer, isSupplier, isUaePhone } = useAuth()
  const hideRetail = isCompanyCustomer || (isSupplier && !isUaePhone)

  const services: Service[] = [
    ...(!isCompanyCustomer ? [{ key: 'requests', label: 'requests' as const, icon: '/assets/services/orders.svg', path: '/services/requests' }] : []),
    { key: 'offers', label: 'offers', icon: '/assets/services/tag.svg', path: '/services/offers' },
    { key: 'booking', label: 'booking', icon: '/assets/services/list.svg', path: '/services/booking' },
    ...(!hideRetail ? [{ key: 'retail', label: 'retail' as const, icon: '/assets/services/Shop.svg', path: '/services/retail' }] : []),
    { key: 'shipping', label: 'shippingPrice', icon: '/assets/services/ship.svg' },
  ]

  return (
    <div className="grid gap-2 sm:gap-3" style={{ gridTemplateColumns: `repeat(${services.length}, minmax(0, 1fr))` }}>
      {services.map((service) => (
        <button
          key={service.key}
          type="button"
          onClick={() => (service.path ? navigate(service.path) : showAppOnly())}
          className="flex flex-col items-center justify-center rounded-xl border border-line bg-white px-1 pb-2 pt-2.5 shadow-[0_2px_8px_rgba(0,0,0,0.08)] transition hover:-translate-y-0.5 hover:border-brand/40 sm:py-3.5 lg:flex-row lg:gap-3 lg:px-4 lg:py-4"
        >
          <img src={service.icon} alt="" className="size-7 object-contain sm:size-8 lg:size-9" />
          <span className="mt-1.5 max-w-full truncate text-[10px] font-semibold leading-tight text-title sm:text-xs lg:mt-0 lg:text-[15px]">{t(service.label)}</span>
        </button>
      ))}
    </div>
  )
}
