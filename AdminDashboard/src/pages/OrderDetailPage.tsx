import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import OffersOrderDetailView from '../components/orders/OffersOrderDetailView'
import RequestOfferDetailView from '../components/orders/RequestOfferDetailView'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useReturnToListPath } from '../hooks/useReturnToListPath'
import { useGetAdminOrderDetailQuery, useUpdateOrderStatusMutation } from '../store'
import {
  resolveOrderListFallbackPath,
  resolveOrderListTitleKey,
} from '../utils/orderChannel'
import { getRtkErrorMessage } from '../utils/rtkError'

export default function OrderDetailPage() {
  const { orderId = '' } = useParams()
  const navigate = useNavigate()
  const { t } = useAppPreferences()
  const parsedId = Number(orderId)

  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const { data: order, error, isLoading } = useGetAdminOrderDetailQuery(parsedId, {
    skip: !Number.isFinite(parsedId) || parsedId <= 0,
  })

  const fallbackListPath = resolveOrderListFallbackPath(order)
  const backToListPath = useReturnToListPath(fallbackListPath)
  const listTitleKey = resolveOrderListTitleKey(backToListPath)

  const [updateOrderStatus, { isLoading: isUpdating }] = useUpdateOrderStatusMutation()

  if (!orderId || !Number.isFinite(parsedId) || parsedId <= 0) {
    navigate('/orders/retail', { replace: true })
    return null
  }

  async function handleStatus(nextStatusId: number) {
    setActionError(null)
    setSuccessMessage(null)

    try {
      await updateOrderStatus({ orderId: parsedId, statusId: nextStatusId }).unwrap()
      setSuccessMessage(t('orders.statusUpdateSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('orders.statusUpdateError')))
    }
  }

  async function handleCancel(payload: {
    cancellationReasonId: number
    cancellationNote?: string
  }) {
    setActionError(null)
    setSuccessMessage(null)

    try {
      await updateOrderStatus({
        orderId: parsedId,
        statusId: 6,
        cancellationReasonId: payload.cancellationReasonId,
        cancellationNote: payload.cancellationNote,
      }).unwrap()
      setSuccessMessage(t('orders.statusUpdateSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('orders.statusUpdateError')))
    }
  }

  const isRequestOffer =
    order != null && order.productTypeName.trim().toLowerCase().includes('request')

  return (
    <div className="space-y-6">
      {successMessage ? <div className="admin-alert-success print:hidden">{successMessage}</div> : null}
      {actionError ? <div className="admin-alert-error print:hidden">{actionError}</div> : null}

      {isLoading ? (
        <div className="flex justify-center py-24">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
        </div>
      ) : error || !order ? (
        <div className="admin-card px-6 py-16 text-center">
          <p className="text-sm text-red-600 dark:text-red-400">
            {getRtkErrorMessage(error as never, t('orders.loadError'))}
          </p>
          <Link
            to={backToListPath}
            className="keep-white mt-4 inline-block rounded-xl bg-[#3B7FC7] px-5 py-2.5 text-sm font-semibold text-white"
          >
            {t('orders.backToList')}
          </Link>
        </div>
      ) : isRequestOffer ? (
        <RequestOfferDetailView
          order={order}
          isUpdating={isUpdating}
          onCancelOrder={(payload) => void handleCancel(payload)}
          backToListPath={backToListPath}
        />
      ) : (
        <OffersOrderDetailView
          order={order}
          isUpdating={isUpdating}
          backToListPath={backToListPath}
          listTitleKey={listTitleKey}
          onStatusChange={(nextStatusId) => void handleStatus(nextStatusId)}
          onCancelOrder={(payload) => void handleCancel(payload)}
        />
      )}
    </div>
  )
}
