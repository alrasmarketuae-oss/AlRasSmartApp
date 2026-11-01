import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { useEffect, useState, type ReactNode } from 'react'
import { MapContainer, Marker, TileLayer, useMap, useMapEvents } from 'react-leaflet'
import { useI18n } from '../i18n/I18nProvider'
import { Icon } from '../ui/Icon'
import { Modal } from '../ui/Modal'
import { useToast } from '../ui/Toast'
import type { RegisterAddress } from './authApi'
import { Spinner } from './components'
import { resolveAddress } from './geo'

const DUBAI: [number, number] = [25.2048, 55.2708]

const PIN = L.divIcon({
  className: '',
  iconSize: [34, 44],
  iconAnchor: [17, 42],
  html: `<svg width="34" height="44" viewBox="0 0 34 44" xmlns="http://www.w3.org/2000/svg"><path d="M17 43s15-14.3 15-26A15 15 0 0 0 2 17c0 11.7 15 26 15 26z" fill="#E31E24" stroke="#fff" stroke-width="2"/><circle cx="17" cy="17" r="6" fill="#fff"/></svg>`,
})

function ClickToPin({ onPick }: { onPick: (lat: number, lng: number) => void }) {
  useMapEvents({ click: (event) => onPick(event.latlng.lat, event.latlng.lng) })
  return null
}

function FlyTo({ position }: { position: [number, number] | null }) {
  const map = useMap()
  useEffect(() => {
    if (position) map.flyTo(position, Math.max(map.getZoom(), 15), { duration: 0.6 })
  }, [map, position])
  return null
}

export type ResolvedAddress = { address: RegisterAddress; summary: string }

type Props = {
  open: boolean
  onClose: () => void
  contactPerson: string
  /** Return `false` to keep the dialog open (e.g. when saving failed). */
  onSaved: (address: RegisterAddress, summary: string) => void | boolean | Promise<void | boolean>
  title?: string
  hint?: string
  confirmLabel?: string
  initial?: ResolvedAddress | null
  children?: ReactNode
}

export default function AddressPickerModal({ open, onClose, contactPerson, onSaved, title, hint, confirmLabel, initial = null, children }: Props) {
  const { t } = useI18n()
  const toast = useToast()
  const initialPosition: [number, number] | null = initial ? [initial.address.latitude, initial.address.longitude] : null
  const [position, setPosition] = useState<[number, number] | null>(initialPosition)
  const [resolved, setResolved] = useState<ResolvedAddress | null>(initial)
  const [busy, setBusy] = useState(false)
  const [saving, setSaving] = useState(false)

  const apply = async (lat: number, lng: number) => {
    setPosition([lat, lng])
    setResolved(null)
    setBusy(true)
    try {
      const result = await resolveAddress(lat, lng, contactPerson)
      if (!result) toast.error(t('couldNotReadLocation'))
      setResolved(result)
    } catch {
      toast.error(t('couldNotReadLocation'))
    } finally {
      setBusy(false)
    }
  }

  const useCurrent = () => {
    if (!navigator.geolocation) {
      toast.error(t('locationDenied'))
      return
    }
    setBusy(true)
    navigator.geolocation.getCurrentPosition(
      (pos) => void apply(pos.coords.latitude, pos.coords.longitude),
      () => {
        setBusy(false)
        toast.error(t('locationDenied'))
      },
      { enableHighAccuracy: true, timeout: 15000 },
    )
  }

  const confirm = async () => {
    if (!resolved) {
      toast.error(t('addressPickFirst'))
      return
    }
    setSaving(true)
    try {
      if ((await onSaved(resolved.address, resolved.summary)) !== false) onClose()
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal open={open} onClose={onClose} title={title ?? t('setLocation')} wide>
      {hint && <p className="mb-3 text-[13px] leading-relaxed text-subtitle">{hint}</p>}
      <button
        type="button"
        onClick={useCurrent}
        disabled={busy}
        className="mb-3 flex w-full items-center justify-center gap-2 rounded-xl border border-brand/30 bg-brand/8 py-3 text-sm font-bold text-brand hover:bg-brand/12 disabled:opacity-60"
      >
        <Icon name="myLocation" size={20} />
        {busy && !position ? t('locating') : t('useCurrentLocation')}
      </button>
      <p className="mb-2 text-xs text-auth-body">{t('pickOnMap')}</p>
      <div className="relative h-[46vh] min-h-[260px] overflow-hidden rounded-2xl border border-auth-border sm:h-[360px]">
        <MapContainer center={position ?? DUBAI} zoom={position ? 15 : 11} className="size-full" scrollWheelZoom>
          <TileLayer attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>' url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
          <ClickToPin onPick={(lat, lng) => void apply(lat, lng)} />
          <FlyTo position={position} />
          {position && <Marker position={position} icon={PIN} />}
        </MapContainer>
        {busy && (
          <div className="absolute inset-0 z-[500] grid place-items-center bg-white/40">
            <Spinner className="size-8 border-[3px] border-brand/25 border-t-brand" />
          </div>
        )}
      </div>
      <div className="mt-3 flex min-h-12 items-start gap-2 rounded-xl bg-[#F4F7FB] px-3 py-2.5 text-[13px] text-auth-label">
        <Icon name="location" size={18} className="mt-0.5 shrink-0 text-brand" />
        <span>{resolved?.summary ?? t('locationHint')}</span>
      </div>
      {children && <div className="mt-4">{children}</div>}
      <button
        type="button"
        disabled={!resolved || busy || saving}
        onClick={confirm}
        className="mt-4 flex h-12 w-full items-center justify-center gap-2 rounded-xl bg-brand text-[15px] font-bold text-white hover:brightness-110 disabled:opacity-50"
      >
        {saving && <Spinner className="size-4 border-2 border-white/40 border-t-white" />}
        {confirmLabel ?? t('saveLocation')}
      </button>
    </Modal>
  )
}
