import { useState } from 'react'
import { useAuth } from '../auth/AuthProvider'
import AddressPickerModal, { type ResolvedAddress } from '../auth/AddressPickerModal'
import type { RegisterAddress } from '../auth/authApi'
import { useI18n } from '../i18n/I18nProvider'
import { ApiError } from '../lib/api'
import { Field, TextInput } from '../ui/Form'
import { useToast } from '../ui/Toast'
import { createAddress, parseAddress, updateAddress, type SavedAddress } from './addressApi'

function initialFrom(existing: SavedAddress): ResolvedAddress | null {
  if (existing.latitude === null || existing.longitude === null || !existing.countryId) return null
  return {
    address: {
      addressTypeId: existing.addressTypeId,
      countryId: existing.countryId,
      cityId: existing.cityId || undefined,
      cityName: existing.cityName,
      addressLine1: existing.addressLine1,
      area: existing.area,
      street: existing.street,
      contactPerson: existing.contactPerson,
      latitude: existing.latitude,
      longitude: existing.longitude,
    },
    summary: [existing.addressLine1, existing.cityName, existing.countryNameEn].filter(Boolean).join(' · '),
  }
}

type Props = { open: boolean; onClose: () => void; existing?: SavedAddress | null; onSaved: (address: SavedAddress | null) => void }

/** Map-only add/edit address with phone, like the app's AddAddressDialog (mapOnly + askPhone). */
export function AddressDialog({ open, onClose, existing = null, onSaved }: Props) {
  if (!open) return null
  return <AddressDialogBody key={existing?.addressId ?? 'new'} onClose={onClose} existing={existing} onSaved={onSaved} />
}

function AddressDialogBody({ onClose, existing, onSaved }: Omit<Props, 'open'>) {
  const { t } = useI18n()
  const toast = useToast()
  const { session, displayName } = useAuth()
  const [phone, setPhone] = useState(existing?.mobileNumber || session?.phone || '')
  const [phoneError, setPhoneError] = useState('')
  const contactPerson = existing?.contactPerson || session?.name || displayName

  const save = async (address: RegisterAddress) => {
    if (phone.replace(/\D/g, '').length < 7) {
      setPhoneError(t('invalidPhoneNumber'))
      return false
    }
    const body = {
      countryId: address.countryId,
      cityId: address.cityId,
      cityName: address.cityName,
      addressLine1: address.addressLine1 || `${address.latitude.toFixed(5)}, ${address.longitude.toFixed(5)}`,
      addressTypeId: existing?.addressTypeId ?? 4,
      area: address.area,
      street: address.street,
      contactPerson: address.contactPerson || contactPerson,
      mobileNumber: phone.trim(),
      latitude: address.latitude,
      longitude: address.longitude,
    }
    try {
      const saved = existing ? await updateAddress(existing.addressId, body) : await createAddress(body)
      onSaved(saved && typeof saved === 'object' ? parseAddress(saved) : null)
      return true
    } catch (error) {
      toast.error(error instanceof ApiError ? error.message : t('unexpectedError'))
      return false
    }
  }

  return (
    <AddressPickerModal
      open
      onClose={onClose}
      contactPerson={contactPerson}
      onSaved={save}
      initial={existing ? initialFrom(existing) : null}
      title={existing ? t('editAddress') : t('addNewAddress')}
      hint={t('addressDialogHint')}
      confirmLabel={t('confirmLocation')}
    >
      <Field label={t('mobileNumber')}>
        <TextInput
          dir="ltr"
          type="tel"
          inputMode="tel"
          value={phone}
          placeholder="05xxxxxxxx"
          onChange={(event) => {
            setPhone(event.target.value)
            setPhoneError('')
          }}
        />
      </Field>
      {phoneError && <p className="mt-1 text-xs text-[#d92d20]">{phoneError}</p>}
    </AddressPickerModal>
  )
}
