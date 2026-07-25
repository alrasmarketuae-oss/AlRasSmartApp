export type GlobalSearchSuggestion = {
  text: string
  textAr: string
  section: string
  route: string
  kind: string
}

export type GlobalSearchHit = {
  id: string
  title: string
  subtitle?: string | null
  route: string
  meta?: string | null
}

export type GlobalSearchSection = {
  section: string
  route: string
  total: number
  items: GlobalSearchHit[]
}

export type GlobalSearchResponse = {
  query: string
  expandedTerms: string[]
  primaryRoute: string
  suggestions: GlobalSearchSuggestion[]
  ads: GlobalSearchSection
  users: GlobalSearchSection
  orders: GlobalSearchSection
  shipping: GlobalSearchSection
  categories: GlobalSearchSection
  sections: GlobalSearchSection
}
