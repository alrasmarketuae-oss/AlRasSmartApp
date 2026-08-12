import ChannelTabs from './ChannelTabs'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { useAdminNotifications } from '../../context/AdminNotificationProvider'
import { useGlobalSearchParam } from '../../hooks/useGlobalSearchParam'
import { hasPermission, PERMISSIONS } from '../../lib/permissions'
import {
  canSeeRequestChannel,
  ordersChannelPath,
  ordersTabCounts,
  type OrdersChannelId,
} from '../../utils/sectionChannels'

const ORDER_CHANNELS: OrdersChannelId[] = [
  'all',
  'retail',
  'booking',
  'offers',
  'categories',
  'requests',
]

const ORDER_LABEL_KEY: Record<OrdersChannelId, string> = {
  all: 'nav.all',
  retail: 'nav.ordersRetail',
  booking: 'nav.ordersBooking',
  offers: 'nav.ordersOffersType',
  categories: 'nav.ordersCategories',
  requests: 'nav.orderRequest',
}

type OrdersChannelTabsProps = {
  activeId: OrdersChannelId
}

export default function OrdersChannelTabs({ activeId }: OrdersChannelTabsProps) {
  const { t } = useAppPreferences()
  const { navCounts } = useAdminNotifications()
  const { urlSearch } = useGlobalSearchParam()
  const counts = ordersTabCounts(navCounts)
  const showRequests = canSeeRequestChannel()
  const showCatalog = hasPermission(PERMISSIONS.ordersView)
  const visibleChannels = ORDER_CHANNELS.filter((id) =>
    id === 'requests' ? showRequests : showCatalog,
  )

  return (
    <ChannelTabs
      accent="orders"
      activeId={activeId}
      items={visibleChannels.map((id) => ({
        id,
        label: t(ORDER_LABEL_KEY[id]),
        to: ordersChannelPath(id, urlSearch),
        count: counts[id],
      }))}
    />
  )
}
