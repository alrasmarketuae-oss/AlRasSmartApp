import { useEffect, useState } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import {
  DEFAULT_ORDER_PRINT_OPTIONS,
  ORDER_PRINT_SECTION_KEYS,
  type OrderPrintOptions,
  orderPrintSectionHintKey,
  orderPrintSectionLabelKey,
} from '../../utils/orderPrintOptions'

type OrderPrintOptionsDialogProps = {
  open: boolean
  initialOptions?: OrderPrintOptions
  onClose: () => void
  onConfirm: (options: OrderPrintOptions) => void
}

export default function OrderPrintOptionsDialog({
  open,
  initialOptions = DEFAULT_ORDER_PRINT_OPTIONS,
  onClose,
  onConfirm,
}: OrderPrintOptionsDialogProps) {
  const { t } = useAppPreferences()
  const [draft, setDraft] = useState<OrderPrintOptions>(initialOptions)

  useEffect(() => {
    if (open) setDraft(initialOptions)
  }, [open, initialOptions])

  if (!open) return null

  const setAll = (value: boolean) => {
    setDraft(
      ORDER_PRINT_SECTION_KEYS.reduce(
        (acc, key) => {
          acc[key] = value
          return acc
        },
        { ...draft },
      ),
    )
  }

  const toggle = (key: keyof OrderPrintOptions) => {
    setDraft((prev) => ({ ...prev, [key]: !prev[key] }))
  }

  const hasSelection = ORDER_PRINT_SECTION_KEYS.some((key) => draft[key])

  return (
    <div
      className="fixed inset-0 z-[120] flex items-center justify-center bg-black/45 p-4 print:hidden"
      role="dialog"
      aria-modal="true"
      aria-labelledby="order-print-options-title"
    >
      <div className="admin-card w-full max-w-lg rounded-2xl p-5 shadow-xl">
        <h2 id="order-print-options-title" className="admin-text text-base font-bold">
          {t('orders.printOptionsTitle')}
        </h2>
        <p className="admin-text-muted mt-1 text-sm">{t('orders.printOptionsHint')}</p>

        <div className="mt-4 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => setAll(true)}
            className="rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
          >
            {t('orders.printSelectAll')}
          </button>
          <button
            type="button"
            onClick={() => setAll(false)}
            className="rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
          >
            {t('orders.printClearAll')}
          </button>
        </div>

        <ul className="mt-4 space-y-2">
          {ORDER_PRINT_SECTION_KEYS.map((key) => (
            <li key={key}>
              <label className="flex cursor-pointer items-start gap-3 rounded-xl border border-slate-200/80 px-3 py-2.5 hover:bg-slate-50/80">
                <input
                  type="checkbox"
                  checked={draft[key]}
                  onChange={() => toggle(key)}
                  className="mt-0.5 h-4 w-4 rounded border-slate-300 text-[#2563eb]"
                />
                <span className="min-w-0 text-start">
                  <span className="admin-text block text-sm font-semibold">
                    {t(orderPrintSectionLabelKey(key))}
                  </span>
                  <span className="admin-text-muted block text-xs leading-snug">
                    {t(orderPrintSectionHintKey(key))}
                  </span>
                </span>
              </label>
            </li>
          ))}
        </ul>

        {!hasSelection ? (
          <p className="admin-alert-error mt-3 text-xs">{t('orders.printNothingSelected')}</p>
        ) : null}

        <div className="mt-5 flex flex-wrap justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded-xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700"
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            disabled={!hasSelection}
            onClick={() => onConfirm(draft)}
            className="keep-white rounded-xl bg-[#2563eb] px-4 py-2 text-sm font-bold text-white disabled:opacity-50"
          >
            {t('orders.printConfirm')}
          </button>
        </div>
      </div>
    </div>
  )
}
