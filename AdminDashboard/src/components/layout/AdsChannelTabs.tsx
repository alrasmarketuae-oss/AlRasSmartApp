import ChannelTabs from './ChannelTabs'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { useAdminNotifications } from '../../context/AdminNotificationProvider'
import { useGlobalSearchParam } from '../../hooks/useGlobalSearchParam'
import { hasPermission, PERMISSIONS } from '../../lib/permissions'
import {
  adsChannelPath,
  adsTabCounts,
  canSeeRequestChannel,
  type AdsChannelId,
} from '../../utils/sectionChannels'

const ADS_CHANNELS: AdsChannelId[] = [
  'all',
  'retail',
  'booking',
  'offers',
  'categories',
  'requests',
]

const ADS_LABEL_KEY: Record<AdsChannelId, string> = {
  all: 'nav.all',
  retail: 'ads.typeRetail',
  booking: 'ads.typeBooking',
  offers: 'ads.typeOffers',
  categories: 'ads.typeCategories',
  requests: 'ads.typeRequests',
}

type AdsChannelTabsProps = {
  activeId: AdsChannelId
}

export default function AdsChannelTabs({ activeId }: AdsChannelTabsProps) {
  const { t } = useAppPreferences()
  const { navCounts } = useAdminNotifications()
  const { urlSearch } = useGlobalSearchParam()
  const counts = adsTabCounts(navCounts)
  const showRequests = canSeeRequestChannel()
  const showCatalog = hasPermission(PERMISSIONS.productsView)
  const visibleChannels = ADS_CHANNELS.filter((id) =>
    id === 'requests' ? showRequests : showCatalog,
  )

  return (
    <ChannelTabs
      accent="ads"
      activeId={activeId}
      items={visibleChannels.map((id) => ({
        id,
        label: t(ADS_LABEL_KEY[id]),
        to: adsChannelPath(id, urlSearch),
        count: counts[id],
      }))}
    />
  )
}
