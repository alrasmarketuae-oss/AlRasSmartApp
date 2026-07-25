export type GeoCountry = {
  id: number
  countryNameEn: string
  countryNameAr?: string | null
  iso2Code: string
}

export type GeoPort = {
  id: number
  portNameEn: string
  unLocode?: string | null
}

export type GeoPortsByCountryResponse = {
  country: string
  ports: GeoPort[]
}
