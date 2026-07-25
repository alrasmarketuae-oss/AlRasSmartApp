import { useState } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import {
  getOrderStatusActions,
  type OrderStatusAction,
} from '../../utils/orderWorkflow'
import { getOrderStatusLabel } from '../../utils/orderStatus'
import ConfirmDialog from '../ui/ConfirmDialog'

type OrderStatusActionButtonsProps = {
  statusId: number
  isUpdating: boolean
  onStatusChange: (statusId: number) => void
  compact?: boolean
  paymentMethodName?: string
  productTypeName?: string
}

function actionClassName(action: OrderStatusAction, compact: boolean): string {
  const base = compact
    ? 'inline-flex h-9 min-w-[5.5rem] items-center justify-center rounded-lg px-3 text-xs font-bold transition disabled:opacity-60'
    : 'inline-flex h-10 min-w-[7rem] items-center justify-center gap-2 rounded-xl px-4 text-sm font-bold transition disabled:opacity-60'

  if (action.tone === 'danger') {
    return compact
      ? `${base} bg-[#ef4444] text-white hover:bg-[#dc2626]`
      : `${base} border-2 border-red-200 bg-white text-red-600 hover:bg-red-50`
  }

  if (action.tone === 'primary') {
    return compact
      ? `${base} bg-[#619D51] text-white hover:bg-[#528a45]`
      : `${base} keep-white bg-[#619D51] text-white hover:bg-[#528a45]`
  }

  return `${base} admin-border border bg-white text-slate-700 hover:bg-slate-50`
}

export default function OrderStatusActionButtons({
  statusId,
  isUpdating,
  onStatusChange,
  compact = false,
  paymentMethodName,
  productTypeName,
}: OrderStatusActionButtonsProps) {
  const { t, locale } = useAppPreferences()
  const actions = getOrderStatusActions(statusId, {
    paymentMethodName,
    productTypeName,
  })
  const [pendingAction, setPendingAction] = useState<OrderStatusAction | null>(null)

  if (actions.length === 0) {
    return null
  }

  const pendingLabel = pendingAction ? t(pendingAction.labelKey) : ''
  const pendingStatusName = pendingAction
    ? getOrderStatusLabel(pendingAction.statusId, locale)
    : ''

  return (
    <>
      <div className="flex flex-wrap gap-2">
        {actions.map((action) => (
          <button
            key={action.statusId}
            type="button"
            disabled={isUpdating}
            onClick={() => setPendingAction(action)}
            className={actionClassName(action, compact)}
            title={t(action.labelKey)}
          >
            {isUpdating ? (
              <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" />
            ) : (
              t(action.labelKey)
            )}
          </button>
        ))}
      </div>

      <ConfirmDialog
        open={pendingAction != null}
        title={t('orders.statusChangeConfirmTitle')}
        message={t('orders.statusChangeConfirmMessage', {
          action: pendingLabel,
          status: pendingStatusName,
        })}
        confirmLabel={t('orders.statusChangeConfirmAction')}
        cancelLabel={t('cancel')}
        danger={pendingAction?.tone === 'danger'}
        busy={isUpdating}
        onCancel={() => {
          if (!isUpdating) setPendingAction(null)
        }}
        onConfirm={() => {
          if (!pendingAction) return
          const next = pendingAction.statusId
          setPendingAction(null)
          onStatusChange(next)
        }}
      />
    </>
  )
}
