import { api } from '../lib/api'
import type { RegisterAddress } from './authApi'

export type GeoCountry = { countryId: number; countryNameEn: string; countryNameAr?: string; iso2Code: string }
export type GeoCity = { cityId: string; cityName: string }

type Items<T> = { items?: T[] } | T[]

const itemsOf = <T,>(data: Items<T> | null): T[] => (Array.isArray(data) ? data : (data?.items ?? []))

let countriesCache: Promise<GeoCountry[]> | null = null

export function fetchCountries(): Promise<GeoCountry[]> {
  countriesCache ??= api
    .get<Items<GeoCountry>>('/Geo/countries', { auth: false })
    .then(itemsOf)
    .catch((error) => {
      countriesCache = null
      throw error
    })
  return countriesCache
}

export async function fetchCities(countryId: number): Promise<GeoCity[]> {
  const data = await api.get<Items<GeoCity>>('/Geo/cities', { query: { countryId }, auth: false })
  return itemsOf(data).map((c) => ({ ...c, cityId: String(c.cityId) }))
}

const normalize = (value?: string | null) =>
  (value ?? '')
    .toLowerCase()
    .replace(/^(emirate of|al|el)\s+/g, '')
    .replace(/[^a-z0-9\u0600-\u06ff]+/g, '')

type NominatimAddress = Partial<
  Record<'road' | 'suburb' | 'neighbourhood' | 'quarter' | 'city' | 'town' | 'village' | 'county' | 'state' | 'country' | 'country_code' | 'city_district', string>
>

/** Reverse geocode + country/city matching, mirroring the app's map-only address flow. */
export async function resolveAddress(lat: number, lng: number, contactPerson: string): Promise<{ address: RegisterAddress; summary: string } | null> {
  const url = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=18&addressdetails=1&accept-language=en&lat=${lat}&lon=${lng}`
  const response = await fetch(url, { headers: { Accept: 'application/json' } })
  if (!response.ok) return null
  const place = (await response.json()) as { address?: NominatimAddress }
  const a = place.address ?? {}

  const countries = await fetchCountries()
  const iso = (a.country_code ?? '').toUpperCase()
  const country =
    countries.find((c) => c.iso2Code?.toUpperCase() === iso) ??
    countries.find((c) => normalize(c.countryNameEn) === normalize(a.country))
  if (!country) return null

  const locality = a.city || a.town || a.village || a.county || a.state || ''
  const area = a.suburb || a.neighbourhood || a.quarter || a.city_district || ''
  const street = a.road || ''
  const cityName = locality || area || street
  if (!cityName) return null

  let cityId: string | undefined
  try {
    const cities = await fetchCities(country.countryId)
    const candidates = [a.city, a.town, a.state, a.county].map(normalize).filter(Boolean)
    cityId = cities.find((c) => candidates.includes(normalize(c.cityName)))?.cityId
  } catch {
    // City id is optional; the free-text city name is still sent.
  }

  const addressLine1 =
    [street, area, locality].filter(Boolean).filter((v, i, arr) => arr.indexOf(v) === i).join(', ') ||
    `${lat.toFixed(5)}, ${lng.toFixed(5)}`

  return {
    address: {
      addressTypeId: 1,
      countryId: country.countryId,
      cityId,
      cityName,
      addressLine1,
      area,
      street,
      contactPerson,
      latitude: lat,
      longitude: lng,
    },
    summary: [addressLine1.includes(cityName) ? addressLine1 : `${addressLine1}, ${cityName}`, country.countryNameEn].join(' · '),
  }
}
