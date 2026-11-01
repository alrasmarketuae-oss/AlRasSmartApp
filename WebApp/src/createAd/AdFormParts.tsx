import { useQuery } from '@tanstack/react-query'
import { useRef, useState, type ReactNode } from 'react'
import { fetchCountries } from '../auth/geo'
import { useI18n } from '../i18n/I18nProvider'
import type { StringKey } from '../i18n/strings'
import { fetchPorts } from '../orders/ordersApi'
import { UNIT_OPTIONS, unitLabel } from '../products/units'
import { Select, TextArea, TextInput, formatNumberInput } from '../ui/Form'
import { Icon } from '../ui/Icon'
import { Modal } from '../ui/Modal'
import { MAX_VIDEO_MB, MAX_VIDEO_SECONDS, MEDIA_ACCEPT, type useAdMedia } from './useAdMedia'

type IconName = Parameters<typeof Icon>[0]['name']

export const ERROR_BORDER = '!border-[#E11D48] !bg-[#FFF5F7]'

export const priceInput = (value: string) => formatNumberInput(value, 3)
export const intInput = (value: string) => formatNumberInput(value.replace(/\./g, ''), 0)

export function SectionCard({ children, className = '', id }: { children: ReactNode; className?: string; id?: string }) {
  return (
    <section id={id} className={`scroll-mt-24 rounded-[14px] border border-line bg-white p-3.5 shadow-[0_4px_12px_rgba(15,23,42,0.05)] sm:p-5 ${className}`}>
      {children}
    </section>
  )
}

export function SectionTitle({ icon, children, action }: { icon: IconName; children: ReactNode; action?: ReactNode }) {
  return (
    <div className="mb-3 flex items-center gap-2.5">
      <span className="grid size-8 shrink-0 place-items-center rounded-[9px] bg-[#EAF2FB] text-[#3A7DC5]">
        <Icon name={icon} size={16} />
      </span>
      <h2 className="min-w-0 flex-1 text-[14px] font-extrabold text-title">{children}</h2>
      {action}
    </div>
  )
}

export function Label({ text, required, htmlFor, info }: { text: string; required?: boolean; htmlFor?: string; info?: () => void }) {
  return (
    <span className="mb-1.5 flex items-center gap-1 text-[13px] font-bold text-title">
      <label htmlFor={htmlFor}>
        {text}
        {required && <span className="text-[#E11D48]"> *</span>}
      </label>
      {info && (
        <button type="button" onClick={info} className="grid size-5 place-items-center rounded-full text-[#3A7DC5] hover:bg-[#EAF2FB]" aria-label={text}>
          <Icon name="info" size={15} />
        </button>
      )}
    </span>
  )
}

export function FieldError({ message }: { message?: string }) {
  if (!message) return null
  return <p className="mt-1 text-xs font-bold text-[#E11D48]">{message}</p>
}

export function FormField({ id, label, required, error, info, children, className = '' }: { id: string; label: string; required?: boolean; error?: string; info?: () => void; children: ReactNode; className?: string }) {
  return (
    <div id={`f-${id}`} className={`scroll-mt-28 ${className}`}>
      <Label text={label} required={required} htmlFor={id} info={info} />
      {children}
      <FieldError message={error} />
    </div>
  )
}

/** The banner artwork has English copy on its left; only the spices side is shown so the title can be localised. */
export function HeroBanner({ title }: { title?: string }) {
  const { t } = useI18n()
  const [failed, setFailed] = useState(false)
  return (
    <div className="relative flex h-[clamp(96px,17vw,150px)] items-center overflow-hidden rounded-2xl bg-gradient-to-r from-[#1B4FB0] to-[#2A6BD0] shadow-[0_10px_24px_rgba(29,79,168,0.22)] rtl:bg-gradient-to-l">
      {!failed && (
        <img
          src="/assets/images/create_ad_banner.png"
          alt=""
          onError={() => setFailed(true)}
          className="absolute inset-y-0 end-0 h-full w-[60%] object-cover object-right [mask-image:linear-gradient(to_right,transparent,black_30%)] rtl:-scale-x-100"
        />
      )}
      <div className="relative max-w-[52%] px-[5%] text-white">
        <p className="text-[clamp(16px,3.4vw,26px)] font-extrabold leading-tight drop-shadow">{title ?? t('createNewAd')}</p>
        <p className="mt-1 text-[clamp(11px,1.9vw,15px)] font-medium leading-snug text-white/90">{t('createNewAdSubtitle')}</p>
      </div>
    </div>
  )
}

/* ─────────── Media ─────────── */

export function MediaSection({ media, error, id = 'media' }: { media: ReturnType<typeof useAdMedia>; error?: string; id?: string }) {
  const { t } = useI18n()
  const inputRef = useRef<HTMLInputElement>(null)
  const [dragging, setDragging] = useState(false)
  const pick = () => inputRef.current?.click()
  const empty = media.items.length === 0

  const zone = `relative rounded-xl border-[1.6px] border-dashed transition ${
    error ? 'border-[#C62828] bg-[#C62828]/[0.06]' : dragging ? 'border-[#3A7DC5] bg-[#EAF2FB]' : 'border-[#3A7DC5]/45 bg-[#EAF2FB]/40'
  }`

  return (
    <SectionCard id={`f-${id}`}>
      <SectionTitle icon="image">
        {t('productImages')}
        <span className="text-[#E11D48]"> *</span>
      </SectionTitle>
      <div
        className={zone}
        onDragOver={(e) => {
          e.preventDefault()
          setDragging(true)
        }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault()
          setDragging(false)
          void media.add(Array.from(e.dataTransfer.files))
        }}
      >
        {empty ? (
          <button type="button" onClick={pick} className="flex w-full flex-col items-center px-3 py-6">
            <span className={`grid size-11 place-items-center rounded-full bg-white shadow-[0_4px_12px_rgba(15,23,42,0.08)] ${error ? 'text-[#C62828]' : 'text-[#3A7DC5]'}`}>
              <Icon name="upload" size={22} />
            </span>
            <span className="mt-2.5 text-[13px] font-semibold text-title">{t('tapToUploadImageOrVideo')}</span>
            <span className="mt-1 text-[11px] font-medium text-subtitle">{t('mediaFormatsHint', { mb: MAX_VIDEO_MB, sec: MAX_VIDEO_SECONDS })}</span>
            <span className="mt-1 hidden text-[11px] text-subtitle sm:block">{t('dropMediaHere')}</span>
          </button>
        ) : (
          <div className="px-3 py-4">
            <div className="flex flex-wrap gap-2.5">
              {media.items.map((item) => (
                <div key={item.id} className="relative size-[88px] overflow-hidden rounded-xl bg-[#F5F5F5] sm:size-[100px]">
                  {item.kind === 'video' ? (
                    <>
                      <video src={item.previewUrl} muted playsInline preload="metadata" className="size-full object-cover" />
                      <span className="absolute inset-0 grid place-items-center">
                        <span className="grid size-8 place-items-center rounded-full bg-black/50 text-white">
                          <Icon name="play" size={15} fill="currentColor" />
                        </span>
                      </span>
                    </>
                  ) : (
                    <img src={item.previewUrl} alt="" className="size-full object-cover" />
                  )}
                  {item.status === 'uploading' && (
                    <span className="absolute inset-0 grid place-items-center bg-white/60">
                      <span className="size-6 animate-spin rounded-full border-[2.5px] border-[#3A7DC5]/30 border-t-[#3A7DC5]" />
                    </span>
                  )}
                  {item.status === 'error' && (
                    <button type="button" onClick={() => media.retry(item.id)} className="absolute inset-0 flex flex-col items-center justify-center gap-1 bg-[#C62828]/75 text-[11px] font-bold text-white">
                      <Icon name="refresh" size={18} />
                      {t('retryUpload')}
                    </button>
                  )}
                  <button
                    type="button"
                    onClick={() => media.remove(item.id)}
                    className="absolute end-1 top-1 grid size-6 place-items-center rounded-full bg-black/55 text-white hover:bg-black/75"
                    aria-label={t('delete')}
                  >
                    <Icon name="close" size={13} />
                  </button>
                </div>
              ))}
            </div>
            <p className="mt-3 text-center text-[14px] font-semibold text-title">{t('selectedMedia', { count: media.items.length })}</p>
            <button type="button" onClick={pick} className="mx-auto mt-2 flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-[12px] font-semibold text-[#3A7DC5] hover:bg-[#EAF2FB]">
              <Icon name="image" size={17} />
              {t('tapToUploadImageOrVideo')}
            </button>
          </div>
        )}
      </div>
      <input
        ref={inputRef}
        type="file"
        accept={MEDIA_ACCEPT}
        multiple
        hidden
        onChange={(e) => {
          const files = Array.from(e.target.files ?? [])
          e.target.value = ''
          void media.add(files)
        }}
      />
      <FieldError message={error} />
    </SectionCard>
  )
}

/* ─────────── Pricing widgets ─────────── */

export function UnitSelect({ id, value, onChange, disabled }: { id?: string; value: string; onChange: (value: string) => void; disabled?: boolean }) {
  const { t } = useI18n()
  const options = value && !(UNIT_OPTIONS as readonly string[]).includes(value) ? [value, ...UNIT_OPTIONS] : [...UNIT_OPTIONS]
  return (
    <Select id={id} value={value} disabled={disabled} onChange={(e) => onChange(e.target.value)}>
      {options.map((u) => (
        <option key={u} value={u}>
          {unitLabel(u, t)}
        </option>
      ))}
    </Select>
  )
}

export function CurrencySelect({ id, value, onChange, locked }: { id?: string; value: 'AED' | 'USD'; onChange: (value: 'AED' | 'USD') => void; locked?: boolean }) {
  if (locked)
    return (
      <span id={id} className="flex h-12 items-center rounded-xl border border-line bg-[#EEF4FB] px-4 text-[15px] font-bold text-[#3A7DC5]" dir="ltr">
        {value}
      </span>
    )
  return (
    <Select id={id} value={value} onChange={(e) => onChange(e.target.value as 'AED' | 'USD')}>
      <option value="AED">AED</option>
      <option value="USD">USD</option>
    </Select>
  )
}

export function Switch({ checked, onChange, label }: { checked: boolean; onChange: (value: boolean) => void; label: string }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={() => onChange(!checked)}
      className={`relative h-[26px] w-[46px] shrink-0 rounded-full transition ${checked ? 'bg-[#3A7DC5]' : 'bg-[#CBD5E1]'}`}
    >
      <span className={`absolute top-[3px] size-5 rounded-full bg-white shadow transition-all ${checked ? 'start-[23px]' : 'start-[3px]'}`} />
    </button>
  )
}

export function InfoDialog({ open, onClose, title, body }: { open: boolean; onClose: () => void; title: string; body: string }) {
  const { t } = useI18n()
  return (
    <Modal open={open} onClose={onClose} title={title}>
      <p className="whitespace-pre-line text-sm leading-relaxed text-subtitle">{body}</p>
      <button type="button" onClick={onClose} className="mt-5 h-11 w-full rounded-xl bg-brand text-sm font-bold text-white hover:brightness-110">
        {t('gotIt')}
      </button>
    </Modal>
  )
}

export function ShowPriceToggle({ value, onChange }: { value: boolean; onChange: (value: boolean) => void }) {
  const { t } = useI18n()
  const [info, setInfo] = useState(false)
  return (
    <div>
      <div className="flex items-center justify-between gap-3 rounded-xl border border-line bg-[#F8FAFC] px-3.5 py-2.5">
        <span className="flex items-center gap-1.5 text-[13px] font-bold text-title">
          {t('showPrice')}
          <button type="button" onClick={() => setInfo(true)} className="grid size-5 place-items-center rounded-full text-[#3A7DC5] hover:bg-[#EAF2FB]" aria-label={t('showPrice')}>
            <Icon name="info" size={15} />
          </button>
        </span>
        <Switch checked={value} onChange={onChange} label={t('showPrice')} />
      </div>
      {!value && <p className="mt-2 rounded-lg bg-[#FFF7E6] px-3 py-2 text-[12px] font-semibold text-[#B45309]">{t('createAdPriceHiddenNotice')}</p>}
      <InfoDialog open={info} onClose={() => setInfo(false)} title={t('showPrice')} body={t('showPriceHint')} />
    </div>
  )
}

export function NegotiationCards({ value, onChange, simple }: { value: boolean; onChange: (value: boolean) => void; simple?: boolean }) {
  const { t } = useI18n()
  const options: { value: boolean; label: StringKey; sub: StringKey; icon: IconName }[] = [
    { value: true, label: 'negotiable', sub: 'negotiableSubtitle', icon: 'chat' },
    { value: false, label: 'nonNegotiable', sub: 'nonNegotiableSubtitle', icon: 'lock' },
  ]
  if (simple)
    return (
      <div className="flex flex-wrap gap-4">
        {options.map((o) => (
          <label key={o.label} className="flex cursor-pointer items-center gap-2 text-[13px] font-semibold text-title">
            <input type="radio" checked={value === o.value} onChange={() => onChange(o.value)} className="size-4 accent-[#3A7DC5]" />
            {t(o.label)}
          </label>
        ))}
      </div>
    )
  return (
    <div className="grid grid-cols-2 gap-2.5">
      {options.map((o) => {
        const selected = value === o.value
        return (
          <button
            key={o.label}
            type="button"
            onClick={() => onChange(o.value)}
            aria-pressed={selected}
            className={`flex items-center gap-2.5 rounded-xl border-[1.5px] px-3 py-2.5 text-start transition ${selected ? 'border-[#3A7DC5] bg-[#EAF2FB]' : 'border-line bg-white hover:border-[#3A7DC5]/50'}`}
          >
            <span className={`grid size-8 shrink-0 place-items-center rounded-full ${selected ? 'bg-[#3A7DC5] text-white' : 'bg-[#F1F5F9] text-subtitle'}`}>
              <Icon name={o.icon} size={15} />
            </span>
            <span className="min-w-0">
              <span className={`block text-[13px] font-bold ${selected ? 'text-[#3A7DC5]' : 'text-title'}`}>{t(o.label)}</span>
              <span className="block text-[11px] text-subtitle">{t(o.sub)}</span>
            </span>
          </button>
        )
      })}
    </div>
  )
}

export function FulfillmentRadio({ value, onChange, error }: { value: string; onChange: (value: 'Local' | 'Reexport') => void; error?: string }) {
  const { t } = useI18n()
  const options: { value: 'Local' | 'Reexport'; label: StringKey }[] = [
    { value: 'Local', label: 'requestFulfillmentLocal' },
    { value: 'Reexport', label: 'requestFulfillmentReexport' },
  ]
  return (
    <FormField id="fulfillment" label={t('requestFulfillment')} required error={error}>
      <div className="flex flex-wrap items-center gap-2">
        {options.map((o) => {
          const selected = value === o.value
          return (
            <button
              key={o.value}
              type="button"
              onClick={() => onChange(o.value)}
              aria-pressed={selected}
              className={`flex h-10 items-center gap-2 rounded-full border-[1.5px] px-4 text-[13px] font-bold transition ${selected ? 'border-[#3A7DC5] bg-[#EAF2FB] text-[#3A7DC5]' : 'border-line bg-white text-title hover:border-[#3A7DC5]/50'}`}
            >
              <span className={`grid size-4 place-items-center rounded-full border-2 ${selected ? 'border-[#3A7DC5]' : 'border-[#94A3B8]'}`}>
                {selected && <span className="size-2 rounded-full bg-[#3A7DC5]" />}
              </span>
              {t(o.label)}
            </button>
          )
        })}
        <span className="text-[11px] text-subtitle">{t('requestFulfillmentNote')}</span>
      </div>
    </FormField>
  )
}

/* ─────────── Packing & specs ─────────── */

type PackingProps = {
  id: string
  label: string
  kg: string
  other: string
  isOther: boolean
  error?: string
  onChange: (changes: { kg?: string; other?: string; isOther?: boolean }) => void
}

export function PackingSection({ id, label, kg, other, isOther, error, onChange }: PackingProps) {
  const { t } = useI18n()
  return (
    <div id={`f-${id}`} className="scroll-mt-28">
      <div className="mb-1.5 flex items-center justify-between gap-2">
        <Label text={label} htmlFor={id} />
        <span className="flex items-center gap-2 text-[12px] font-semibold text-subtitle">
          {t('otherPacking')}
          <Switch checked={isOther} onChange={(value) => onChange({ isOther: value })} label={t('otherPacking')} />
        </span>
      </div>
      {isOther ? (
        <TextInput id={id} value={other} maxLength={60} placeholder={t('packingOtherHint')} onChange={(e) => onChange({ other: e.target.value })} />
      ) : (
        <div className="relative">
          <TextInput
            id={id}
            inputMode="numeric"
            dir="ltr"
            value={kg}
            placeholder={t('packingKgHint')}
            onChange={(e) => onChange({ kg: e.target.value.replace(/\D/g, '').slice(0, 3) })}
            className={`pe-14 ${error ? ERROR_BORDER : ''}`}
          />
          <span className="pointer-events-none absolute inset-y-0 end-4 flex items-center text-sm font-bold text-subtitle">{t('packingKgSuffix')}</span>
        </div>
      )}
      <FieldError message={error} />
    </div>
  )
}

export function SpecsField({ id, label, hint, value, onChange, required, error }: { id: string; label: string; hint: string; value: string; onChange: (value: string) => void; required?: boolean; error?: string }) {
  return (
    <FormField id={id} label={label} required={required} error={error}>
      <TextArea id={id} rows={4} maxLength={500} value={value} placeholder={hint} onChange={(e) => onChange(e.target.value)} className={error ? ERROR_BORDER : ''} />
      <span className="mt-1 block text-end text-[11px] text-subtitle" dir="ltr">
        {value.length}/500
      </span>
    </FormField>
  )
}

/* ─────────── Geo ─────────── */

export function CountryField({ id, label, value, onChange, required, error }: { id: string; label: string; value: string; onChange: (value: string) => void; required?: boolean; error?: string }) {
  const { t, isAr } = useI18n()
  const countries = useQuery({ queryKey: ['geo-countries'], queryFn: fetchCountries, staleTime: Infinity })
  return (
    <FormField id={id} label={label} required={required} error={error}>
      <TextInput id={id} list={`${id}-list`} value={value} autoComplete="off" placeholder={t('enterCountry')} onChange={(e) => onChange(e.target.value)} className={error ? ERROR_BORDER : ''} />
      <datalist id={`${id}-list`}>
        {(countries.data ?? []).map((c) => (
          <option key={c.countryId} value={c.countryNameEn}>
            {isAr ? c.countryNameAr : ''}
          </option>
        ))}
      </datalist>
    </FormField>
  )
}

export function PortField({ id, label, country, value, onChange }: { id: string; label: string; country: string; value: string; onChange: (value: string) => void }) {
  const { t, isAr } = useI18n()
  const name = country.trim()
  const ports = useQuery({ queryKey: ['geo-ports', name], queryFn: () => fetchPorts(name), enabled: name.length > 1, staleTime: 3_600_000, retry: false })
  const options = ports.data ?? []
  return (
    <FormField id={id} label={label}>
      {options.length ? (
        <Select id={id} value={value} onChange={(e) => onChange(e.target.value)}>
          <option value="">{t('selectPort')}</option>
          {value && !options.some((p) => p.portNameEn === value) && <option value={value}>{value}</option>}
          {options.map((p) => (
            <option key={p.id} value={p.portNameEn || p.portNameAr || ''}>
              {(isAr && p.portNameAr) || p.portNameEn}
              {p.unLocode ? ` (${p.unLocode})` : ''}
            </option>
          ))}
        </Select>
      ) : (
        <TextInput id={id} value={value} disabled={!name} placeholder={ports.isFetching ? t('loadingEllipsis') : t('selectPort')} onChange={(e) => onChange(e.target.value)} />
      )}
    </FormField>
  )
}

/* ─────────── Publish ─────────── */

export function PublishButton({ busy, label, subtitle, progress, onClick, disabled }: { busy: boolean; label: string; subtitle?: string; progress?: string; onClick: () => void; disabled?: boolean }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={busy || disabled}
      className="flex min-h-[58px] w-full items-center justify-center gap-3 rounded-2xl bg-gradient-to-r from-[#2F6AAD] to-[#4A90E2] px-5 py-2.5 text-white shadow-[0_10px_22px_rgba(47,106,173,0.3)] transition hover:brightness-110 disabled:opacity-70"
    >
      {busy ? <span className="size-5 animate-spin rounded-full border-2 border-white/40 border-t-white" /> : <Icon name="send" size={20} />}
      <span className="flex flex-col items-start leading-tight">
        <span className="text-[16px] font-extrabold">{progress || label}</span>
        {subtitle && !busy && <span className="text-[11px] font-medium text-white/85">{subtitle}</span>}
      </span>
    </button>
  )
}
