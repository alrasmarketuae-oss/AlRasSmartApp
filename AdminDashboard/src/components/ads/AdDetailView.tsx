import RequestDetailView from './RequestDetailView'
import CatalogAdDetailView, { type CatalogAdDetailViewProps } from './CatalogAdDetailView'
import BookingAdDetailView from './BookingAdDetailView'
import WholesaleAdDetailView from './WholesaleAdDetailView'
import RetailAdDetailView from './RetailAdDetailView'
import OffersAdDetailView from './OffersAdDetailView'
import { isBookingAd, isOffersAd, isRetailAd, isWholesaleAd } from '../../utils/adsDisplay'

export type AdDetailViewProps = CatalogAdDetailViewProps

export default function AdDetailView(props: AdDetailViewProps) {
  const isRequestAd =
    props.product.productTypeName.trim().toLowerCase() === 'requests'

  if (isRequestAd) {
    return <RequestDetailView {...props} />
  }

  if (isBookingAd(props.product)) {
    return <BookingAdDetailView {...props} />
  }

  if (isOffersAd(props.product)) {
    return <OffersAdDetailView {...props} />
  }

  if (isWholesaleAd(props.product)) {
    return <WholesaleAdDetailView {...props} />
  }

  if (isRetailAd(props.product)) {
    return <RetailAdDetailView {...props} />
  }

  return <CatalogAdDetailView {...props} />
}
