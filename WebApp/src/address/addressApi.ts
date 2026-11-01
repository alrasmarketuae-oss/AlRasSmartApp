import { api } from '../lib/api'

export type SavedAddress = {
  addressId: string
  label: string
  cityId: string
  cityName: string
  countryId: number
  countryNameEn: string
  countryNameAr?: string | null
  addressLine1: string
  addressLine2?: string | null
  addressTypeId: number
  addressTypeNameEn: string
  addressTypeNameAr: string
  area: string
  street: string
  contactPerson: string
  mobileNumber: string
  latitude: number | null
  longitude: number | null
  formattedAddress: string
}

export type AddressBody = {
  cityId?: string
  countryId?: number
  cityName?: string
  addressLine1: string
  addressLine2?: string
  addressTypeId?: number
  area?: string
  street?: string
  contactPerson?: string
  mobileNumber?: string
  latitude?: number
  longitude?: number
}

type Raw = Record<string, unknown>
const text = (raw: Raw, key: string) => String(raw[key] ?? raw[key.charAt(0).toUpperCase() + key.slice(1)] ?? '').trim()
const coord = (value: unknown) => {
  const parsed = value === null || value === undefined || value === '' ? NaN : Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

export function parseAddress(raw: Raw): SavedAddress {
  const country = text(raw, 'countryNameEn')
  const city = text(raw, 'cityName')
  const line1 = text(raw, 'addressLine1')
  const line2 = text(raw, 'addressLine2')
  const formatted = text(raw, 'formattedAddress')
  return {
    addressId: text(raw, 'addressId') || text(raw, 'id'),
    label: formatted || [country, city, line1, line2].filter(Boolean).join(' - '),
    cityId: text(raw, 'cityId'),
    cityName: city,
    countryId: Number(raw.countryId ?? raw.CountryId ?? 0) || 0,
    countryNameEn: country,
    countryNameAr: text(raw, 'countryNameAr') || null,
    addressLine1: line1,
    addressLine2: line2 || null,
    addressTypeId: Number(raw.addressTypeId ?? raw.AddressTypeId ?? 4) || 4,
    addressTypeNameEn: text(raw, 'addressTypeNameEn'),
    addressTypeNameAr: text(raw, 'addressTypeNameAr'),
    area: text(raw, 'area'),
    street: text(raw, 'street'),
    contactPerson: text(raw, 'contactPerson'),
    mobileNumber: text(raw, 'mobileNumber'),
    latitude: coord(raw.latitude ?? raw.Latitude),
    longitude: coord(raw.longitude ?? raw.Longitude),
    formattedAddress: formatted,
  }
}

export const addressLine = (a: SavedAddress) => a.formattedAddress || [a.addressLine1, a.addressLine2].filter(Boolean).join(', ')

export const addressCountry = (a: SavedAddress, isAr: boolean) => (isAr && a.countryNameAr ? a.countryNameAr : a.countryNameEn)

export async function fetchAddresses(): Promise<SavedAddress[]> {
  const data = await api.get<{ items?: Raw[]; Items?: Raw[] } | Raw[]>('/Addresses')
  const items = Array.isArray(data) ? data : (data?.items ?? data?.Items ?? [])
  return items.map(parseAddress)
}

const clean = (body: AddressBody) => Object.fromEntries(Object.entries(body).filter(([, v]) => v !== undefined && v !== null && v !== ''))

export const createAddress = (body: AddressBody) => api.post<Raw>('/Addresses', clean(body))

export const updateAddress = (addressId: string, body: AddressBody) => api.put<Raw>(`/Addresses/${encodeURIComponent(addressId)}`, clean(body))

export const deleteAddress = (addressId: string) => api.delete(`/Addresses/${encodeURIComponent(addressId)}`)
