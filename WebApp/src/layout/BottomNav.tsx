import { useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { useUnreadChatCount } from '../chat/useUnreadChatCount'
import { useI18n } from '../i18n/I18nProvider'
import type { StringKey } from '../i18n/strings'
import { useGate } from '../ui/GateProvider'
import { MaskIcon } from './MaskIcon'

const SELECTED = '#3A7DC5'
const UNSELECTED = '#999999'

type Item = { label: StringKey; icon: string; selectedIcon: string; path: string; circle?: boolean; public?: boolean }

const HOME: Item = { label: 'home', icon: '/assets/nav/home.svg', selectedIcon: '/assets/nav/homeb.svg', path: '/', public: true }
const CREATE_AD: Item = { label: 'createAd', icon: '/assets/nav/add_ads.svg', selectedIcon: '/assets/nav/add_adsb.svg', path: '/create-ad' }
const CREATE_ORDER: Item = { label: 'createOrder', icon: '/assets/nav/add_order.svg', selectedIcon: '/assets/nav/add_orderb.svg', path: '/create-order' }
const CART: Item = { label: 'cart', icon: '/assets/nav/cart.svg', selectedIcon: '/assets/nav/cartb.svg', path: '/cart' }
const ORDERS: Item = { label: 'myOrders', icon: '/assets/nav/orders.svg', selectedIcon: '/assets/nav/ordersb.svg', path: '/orders' }
const ACCOUNT: Item = { label: 'account', icon: '/assets/nav/profile.svg', selectedIcon: '/assets/nav/profileb.svg', path: '/my-ads' }
const PROFILE: Item = { label: 'profile', icon: '/assets/nav/profile.svg', selectedIcon: '/assets/nav/profileb.svg', path: '/profile', circle: true, public: true }

/** Same tab sets as the app shells: supplier/guest, company customer and personal customer. */
function useNavItems(): Item[] {
  const { isCompanyCustomer, isPersonalCustomer } = useAuth()
  if (isPersonalCustomer) return [HOME, CART, ORDERS, PROFILE]
  if (isCompanyCustomer) return [HOME, CREATE_ORDER, ORDERS, ACCOUNT, PROFILE]
  return [HOME, CREATE_AD, ORDERS, ACCOUNT, PROFILE]
}

export function BottomNav() {
  const { t } = useI18n()
  const { pathname } = useLocation()
  const navigate = useNavigate()
  const { ensureLoggedIn } = useGate()
  const items = useNavItems()
  const unread = useUnreadChatCount()
  const dense = items.length > 4

  return (
    <nav className="fixed inset-x-0 bottom-0 z-30 bg-white shadow-[0_-2px_12px_rgba(0,0,0,0.08)]" style={{ paddingBottom: 'env(safe-area-inset-bottom)' }}>
      <div className="mx-auto flex max-w-3xl items-stretch justify-around px-1 py-1.5">
        {items.map((item) => {
          const selected = item.path === '/' ? pathname === '/' : pathname.startsWith(item.path)
          const color = selected ? SELECTED : UNSELECTED
          const onClick = () => {
            if (item.path === pathname) {
              window.scrollTo({ top: 0, behavior: 'smooth' })
              return
            }
            if (!item.public && !ensureLoggedIn()) return
            navigate(item.path)
          }
          return (
            <button
              key={item.path}
              type="button"
              onClick={onClick}
              aria-current={selected ? 'page' : undefined}
              className="flex min-w-0 flex-1 flex-col items-center gap-1 rounded-xl px-1 py-1.5 hover:bg-page"
            >
              <span className="relative grid h-7 place-items-center">
                {item === PROFILE && unread > 0 && (
                  <span className="absolute -end-2.5 -top-1.5 z-10 min-w-4 rounded-full border-[1.2px] border-white bg-[#E53935] px-1 text-center text-[9px] font-bold leading-[14px] text-white">
                    {unread > 99 ? '99+' : unread}
                  </span>
                )}
                {item === CREATE_AD && selected ? (
                  <img src={item.selectedIcon} alt="" className="size-6" />
                ) : item.circle ? (
                  <span className="grid size-7 place-items-center rounded-full border-[1.6px]" style={{ borderColor: color }}>
                    <MaskIcon src={selected ? item.selectedIcon : item.icon} color={color} size={17} />
                  </span>
                ) : (
                  <MaskIcon src={selected ? item.selectedIcon : item.icon} color={color} size={24} />
                )}
              </span>
              <span className={`max-w-full truncate ${dense ? 'text-[10px] sm:text-[11px]' : 'text-[11px] sm:text-xs'} ${selected ? 'font-semibold' : 'font-medium'}`} style={{ color }}>
                {t(item.label)}
              </span>
            </button>
          )
        })}
      </div>
    </nav>
  )
}
