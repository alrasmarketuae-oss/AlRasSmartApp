import type { GeoSearchSelectOption } from '../components/geo/GeoSearchSelect'
import type { GeoCountry, GeoPort } from '../types/geo'

export function buildCountryOptions(
  countries: GeoCountry[],
  locale: 'ar' | 'en',
): GeoSearchSelectOption[] {
  return countries.map((country) => {
    const primary =
      locale === 'ar' && country.countryNameAr?.trim()
        ? country.countryNameAr.trim()
        : country.countryNameEn

    const metaParts = [country.countryNameEn]
    if (country.countryNameAr?.trim() && country.countryNameAr.trim() !== primary) {
      metaParts.push(country.countryNameAr.trim())
    }
    if (country.iso2Code) {
      metaParts.push(country.iso2Code.toUpperCase())
    }

    return {
      value: country.countryNameEn,
      label: primary,
      meta: metaParts.join(' · '),
      searchText: [
        country.countryNameEn,
        country.countryNameAr ?? '',
        country.iso2Code,
        country.id,
      ]
        .join(' ')
        .toLowerCase(),
    }
  })
}

export function buildPortOptions(ports: GeoPort[]): GeoSearchSelectOption[] {
  return ports.map((port) => ({
    value: port.portNameEn,
    label: port.portNameEn,
    meta: port.unLocode?.trim() ? `UN/LOCODE: ${port.unLocode.trim()}` : undefined,
    searchText: [port.portNameEn, port.unLocode ?? '', port.id].join(' ').toLowerCase(),
  }))
}
