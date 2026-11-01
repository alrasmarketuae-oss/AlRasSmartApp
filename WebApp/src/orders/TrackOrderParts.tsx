import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useI18n } from '../i18n/I18nProvider'
import { parseUtc } from '../products/productRules'
import { TextArea } from '../ui/Form'
import { Icon } from '../ui/Icon'
import { Modal } from '../ui/Modal'
import { useToast } from '../ui/Toast'
import { MediaThumb, quantityText } from './OrderParts'
import { localize, orderImage, orderVideo, RETURN_MEDIA_ACCEPT, RETURN_MEDIA_MAX_BYTES, type MyOrder } from './ordersApi'
import type { TimelineStep } from './orderStatus'

const SUPPORT_PHONE = '+97142285598'
const cardClass = 'rounded-xl border border-[#EAECF0] bg-white'

export function TrackSummaryCard({ order }: { order: MyOrder }) {
  const { t, isAr } = useI18n()
  const destination = order.portName || localize(order.categoryName, isAr) || '—'
  return (
    <div className={`p-3.5 ${cardClass}`}>
      <div className="flex gap-3">
        <MediaThumb image={orderImage(order)} video={orderVideo(order)} size={72} radius={8} />
        <div className="min-w-0 flex-1 text-[#333]">
          <p className="line-clamp-2 text-[15px] font-bold">{localize(order.productName, isAr) || '—'}</p>
          <p className="mt-1 text-[13px] text-[#333]/65">{`${t('quantity')}: ${quantityText(order.quantity, localize(order.unitName, isAr), t)}`}</p>
          <p className="mt-0.5 text-[13px] text-[#333]/65">{`${t('destination')}: ${destination}`}</p>
        </div>
      </div>
      <p className="mt-3 rounded-lg bg-[#F2F4F7] px-3 py-2 text-[13px] font-semibold text-[#333]">{`${t('orderNumber')}: #${order.id}`}</p>
    </div>
  )
}

export function TimelineCard({ steps }: { steps: TimelineStep[] }) {
  return (
    <div className={`px-4 py-[18px] ${cardClass}`}>
      {steps.map((step, i) => {
        const last = i === steps.length - 1
        return (
          <div key={i} className="flex gap-3">
            <div className={`min-w-0 flex-1 ${last ? '' : 'pb-5'}`}>
              <p className="text-[15px] font-bold text-[#333]">{step.title}</p>
              <p className="mt-1 min-h-4 text-[13px] text-[#333]/55">{step.date ?? ''}</p>
              {step.subtitle && <p className="mt-0.5 text-[13px] font-semibold text-brand">{step.subtitle}</p>}
            </div>
            <div className="flex flex-col items-center">
              <span className="grid size-10 shrink-0 place-items-center rounded-[10px] bg-[#E0F1FF] text-brand">
                <Icon name={step.done ? 'check' : 'clock'} size={22} strokeWidth={step.done ? 2.6 : 1.9} />
              </span>
              {!last && <span className="my-1.5 w-0.5 flex-1 bg-brand" />}
            </div>
          </div>
        )
      })}
    </div>
  )
}

function formatRefundDate(raw: string, isAr: boolean) {
  const date = parseUtc(raw)
  if (!date) return raw || null
  return new Intl.DateTimeFormat(isAr ? 'ar' : 'en', { day: 'numeric', month: isAr ? 'long' : 'short', year: 'numeric', hour: 'numeric', minute: '2-digit' }).format(date)
}

export function RefundIdCard({ order }: { order: MyOrder }) {
  const { t, isAr } = useI18n()
  const toast = useToast()
  const navigate = useNavigate()
  const refundId = order.stripeRefundId
  const refundedOn = order.refundedAtUtc ? formatRefundDate(order.refundedAtUtc, isAr) : null
  const openAi = () => refundId && navigate('/ai-assistant/chat', { state: { initialMessage: t('orderRefundAiPrompt', { id: refundId }) } })
  return (
    <div
      role={refundId ? 'button' : undefined}
      tabIndex={refundId ? 0 : undefined}
      onClick={openAi}
      onKeyDown={(e) => e.key === 'Enter' && openAi()}
      className={`rounded-[14px] border border-[#A7F3D0] bg-[#ECFDF5] p-4 ${refundId ? 'cursor-pointer hover:brightness-[0.98]' : ''}`}
    >
      <p className="flex items-center gap-2 text-[15px] font-bold text-[#065F46]">
        <Icon name="shield" size={22} className="text-[#059669]" />
        {t('orderRefundCompleted')}
      </p>
      <p className="mt-2.5 text-[13px] leading-relaxed text-[#047857]">{t('orderRefundProcessedFromOurSide')}</p>
      {refundedOn && <p className="mt-2 text-xs font-semibold text-[#065F46]">{`${t('orderRefundProcessedOnLabel')}: ${refundedOn}`}</p>}
      {refundId && (
        <>
          <div className="mt-3 flex items-center gap-2 rounded-[10px] border border-[#D1FAE5] bg-white px-3 py-2.5">
            <div className="min-w-0 flex-1">
              <p className="text-[11px] font-semibold text-[#6B7280]">{t('orderRefundIdLabel')}</p>
              <p dir="ltr" className="mt-1 break-all text-start font-[Inter] text-[13px] font-bold tracking-[0.2px] text-[#111827]">
                {refundId}
              </p>
            </div>
            <button
              type="button"
              aria-label={t('orderRefundIdLabel')}
              onClick={(e) => {
                e.stopPropagation()
                void navigator.clipboard?.writeText(refundId)
                toast.success(t('orderRefundIdCopied'))
              }}
              className="rounded-full p-2 text-[#059669] hover:bg-[#ECFDF5]"
            >
              <Icon name="copy" size={18} />
            </button>
          </div>
          <p className="mt-3 flex items-center gap-2 text-xs font-semibold leading-snug text-[#1D4ED8]">
            <Icon name="robot" size={18} className="shrink-0 text-[#2563EB]" />
            <span className="flex-1">{t('orderRefundAskAiHint')}</span>
            <Icon name="chevronRight" size={22} className="shrink-0 text-[#2563EB] rtl:rotate-180" />
          </p>
        </>
      )}
      <p className="mt-2 text-xs leading-relaxed text-[#047857]">{t('orderRefundBankDelayHint')}</p>
    </div>
  )
}

export function RefundNoticeCard() {
  const { t } = useI18n()
  return (
    <div className="flex items-start gap-2.5 rounded-xl border border-[#BFDBFE] bg-[#EFF6FF] p-3.5 text-[13px] font-medium leading-relaxed text-[#1D4ED8]">
      <Icon name="info" size={18} className="mt-0.5 shrink-0" />
      <p>{t('orderRefundNotice')}</p>
    </div>
  )
}

export function CustomerServiceCard() {
  const { t } = useI18n()
  const action = 'grid size-10 place-items-center rounded-[10px] bg-[#E0F1FF] text-brand hover:brightness-95'
  return (
    <div className={`flex items-center gap-3 px-4 py-3.5 ${cardClass}`}>
      <p className="flex-1 text-[15px] font-bold text-[#333]">{t('customerService')}</p>
      <Link to="/support" className={action} aria-label={t('customerService')}>
        <Icon name="chat" size={20} />
      </Link>
      <a href={`tel:${SUPPORT_PHONE}`} className={action} aria-label={SUPPORT_PHONE}>
        <Icon name="phone" size={20} />
      </a>
    </div>
  )
}

export function ConfirmDialog(props: { open: boolean; title: string; message: string; confirmLabel: string; busy: boolean; onClose: () => void; onConfirm: () => void }) {
  const { t } = useI18n()
  return (
    <Modal open={props.open} onClose={props.onClose} title={props.title}>
      <p className="text-sm leading-relaxed text-auth-body">{props.message}</p>
      <div className="mt-5 flex justify-end gap-2">
        <button type="button" onClick={props.onClose} className="rounded-xl px-4 py-2.5 text-sm font-bold text-brand hover:bg-brand/5">
          {t('cancel')}
        </button>
        <button
          type="button"
          disabled={props.busy}
          onClick={props.onConfirm}
          className="inline-flex items-center gap-2 rounded-xl bg-[#DC2626] px-4 py-2.5 text-sm font-bold text-white hover:brightness-110 disabled:opacity-60"
        >
          {props.busy && <span className="size-4 animate-spin rounded-full border-2 border-white/40 border-t-white" />}
          {props.confirmLabel}
        </button>
      </div>
    </Modal>
  )
}

export function ReturnDialog({ open, busy, onClose, onSubmit }: { open: boolean; busy: boolean; onClose: () => void; onSubmit: (reason: string, files: File[]) => void }) {
  const { t } = useI18n()
  const toast = useToast()
  const [reason, setReason] = useState('')
  const [files, setFiles] = useState<File[]>([])
  const submit = () => {
    if (reason.trim().length < 3) return toast.error(t('returnReasonTooShort'))
    if (files.reduce((sum, f) => sum + f.size, 0) > RETURN_MEDIA_MAX_BYTES) return toast.error(t('returnMediaTooLarge'))
    onSubmit(reason.trim(), files)
  }
  return (
    <Modal open={open} onClose={onClose} title={t('returnOrderConfirmTitle')}>
      <p className="text-sm leading-relaxed text-auth-body">{t('returnOrderConfirmMessage')}</p>
      <TextArea className="mt-3" rows={3} value={reason} placeholder={t('returnOrderConfirmMessage')} onChange={(e) => setReason(e.target.value)} />
      <label className="mt-3 flex cursor-pointer items-center justify-center gap-2 rounded-xl border border-line px-4 py-3 text-sm font-semibold text-brand hover:bg-brand/5">
        <Icon name="paperclip" size={18} />
        {files.length ? files.length : t('returnOrder')}
        <input
          type="file"
          multiple
          accept={RETURN_MEDIA_ACCEPT}
          className="hidden"
          onChange={(e) => {
            const picked = Array.from(e.target.files ?? [])
            setFiles((prev) => [...prev, ...picked.filter((f) => !prev.some((p) => p.name === f.name && p.size === f.size))])
            e.target.value = ''
          }}
        />
      </label>
      <p className="mt-1.5 text-xs text-subtitle">{t('returnMediaHint')}</p>
      <div className="mt-5 flex justify-end gap-2">
        <button type="button" onClick={onClose} className="rounded-xl px-4 py-2.5 text-sm font-bold text-brand hover:bg-brand/5">
          {t('cancel')}
        </button>
        <button
          type="button"
          disabled={busy}
          onClick={submit}
          className="inline-flex items-center gap-2 rounded-xl bg-[#DC2626] px-4 py-2.5 text-sm font-bold text-white hover:brightness-110 disabled:opacity-60"
        >
          {busy && <span className="size-4 animate-spin rounded-full border-2 border-white/40 border-t-white" />}
          {t('returnOrder')}
        </button>
      </div>
    </Modal>
  )
}
