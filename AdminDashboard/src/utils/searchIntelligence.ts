import { POPULAR_SEARCHES, SEARCH_CLUSTERS, type SearchCluster } from '../data/searchKnowledge'
import { normalizeSearchQuery, splitSearchWords } from '../data/searchNormalize'

export type SearchSuggestion = {
  text: string
  textAr: string
  section: string
  route: string
  kind: 'keyword' | 'section' | 'popular'
  score: number
}

function levenshtein(a: string, b: string): number {
  const n = a.length
  const m = b.length
  const d: number[][] = Array.from({ length: n + 1 }, () => Array(m + 1).fill(0))
  for (let i = 0; i <= n; i++) d[i][0] = i
  for (let j = 0; j <= m; j++) d[0][j] = j
  for (let i = 1; i <= n; i++) {
    for (let j = 1; j <= m; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1
      d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
    }
  }
  return d[n][m]
}

function fuzzyMatches(a: string, b: string): boolean {
  if (!a || !b) return false
  if (Math.abs(a.length - b.length) > 2) return false
  const threshold = a.length <= 4 ? 1 : 2
  return levenshtein(a, b) <= threshold
}

function scoreTerm(query: string, term: string): number {
  const q = normalizeSearchQuery(query)
  const t = normalizeSearchQuery(term)
  if (!q || !t) return 0
  if (t === q) return 100
  if (t.startsWith(q)) return 80
  if (q.startsWith(t)) return 70
  if (t.includes(q)) return 55
  if (q.includes(t)) return 45
  return fuzzyMatches(q, t) ? 35 : 0
}

/** Scores a full query against a term — also checks each word separately (Arabic multi-word). */
export function scoreQueryAgainstText(query: string, text: string): number {
  const normalizedQuery = normalizeSearchQuery(query)
  const normalizedText = normalizeSearchQuery(text)
  if (!normalizedQuery || !normalizedText) return 0

  const queryWords = splitSearchWords(normalizedQuery)
  const textWords = splitSearchWords(normalizedText)
  const isMultiWordQuery = queryWords.length >= 2

  let best = scoreTerm(normalizedQuery, normalizedText)
  if (best >= 70) return best

  if (isMultiWordQuery) {
    let matched = 0
    for (const queryWord of queryWords) {
      const wordHit = textWords.some((textWord) => scoreTerm(queryWord, textWord) >= 70)
        || scoreTerm(queryWord, normalizedText) >= 55
      if (wordHit) matched++
    }

    const ratio = matched / queryWords.length
    if (ratio >= 1) best = Math.max(best, queryWords.length >= 3 ? 100 : 95)
    else if (ratio >= 0.75) best = Math.max(best, 88)
    else if (ratio >= 0.5) best = Math.max(best, 72)
    else {
      for (const queryWord of queryWords) {
        best = Math.max(best, Math.min(scoreTerm(queryWord, normalizedText), 55))
        for (const textWord of textWords) {
          best = Math.max(best, Math.min(scoreTerm(queryWord, textWord), 55))
        }
      }
    }
    return best
  }

  for (const queryWord of queryWords) {
    best = Math.max(best, scoreTerm(queryWord, normalizedText))
    for (const textWord of textWords) {
      best = Math.max(best, scoreTerm(queryWord, textWord))
    }
  }

  for (const textWord of textWords) {
    best = Math.max(best, scoreTerm(normalizedQuery, textWord))
  }

  return best
}

function clusterSpecificity(cluster: SearchCluster): number {
  if (cluster.id.startsWith('field-')) return 50
  if (cluster.id.startsWith('settings-')) return 40
  if (cluster.id.startsWith('user-')) return 35
  if (cluster.id.startsWith('ui-labels-')) return 20
  const generic = new Set([
    'ads', 'users', 'orders', 'shipping', 'categories',
    'notifications', 'settings', 'dashboard', 'chat',
  ])
  if (generic.has(cluster.id)) return 0
  return 10
}

export function scoreCluster(query: string, cluster: SearchCluster): number {
  let best = Math.max(
    scoreQueryAgainstText(query, cluster.labelEn),
    scoreQueryAgainstText(query, cluster.labelAr),
  )

  for (const term of cluster.terms) {
    best = Math.max(best, scoreQueryAgainstText(query, term))
  }

  return best
}

export function buildSectionRoute(route: string, query: string): string {
  const trimmed = query.trim()
  if (!trimmed) return route
  const separator = route.includes('?') ? '&' : '?'
  return `${route}${separator}search=${encodeURIComponent(trimmed)}`
}

export function expandQuery(query: string): string[] {
  const normalized = normalizeSearchQuery(query)
  if (!normalized) return []

  const terms = new Set<string>([normalized])
  splitSearchWords(normalized).forEach((word) => terms.add(word))

  for (const cluster of SEARCH_CLUSTERS) {
    if (scoreCluster(normalized, cluster) > 0) {
      cluster.terms.forEach((term) => {
        const t = normalizeSearchQuery(term)
        if (t.length >= 2) terms.add(t)
      })
      splitSearchWords(cluster.labelEn).forEach((word) => terms.add(word))
      splitSearchWords(cluster.labelAr).forEach((word) => terms.add(word))
    }
  }

  for (const cluster of SEARCH_CLUSTERS) {
    for (const term of cluster.terms) {
      const t = normalizeSearchQuery(term)
      if (t.length < 3) continue
      if (fuzzyMatches(normalized, t)) {
        terms.add(t)
        cluster.terms.slice(0, 12).forEach((related) => {
          const r = normalizeSearchQuery(related)
          if (r.length >= 3) terms.add(r)
        })
      }
    }
  }

  return [...terms].filter((t) => t.length >= 2).slice(0, 32)
}

export function getLocalSuggestions(query: string, limit = 10): SearchSuggestion[] {
  const normalized = normalizeSearchQuery(query)

  if (!normalized) {
    return [
      ...POPULAR_SEARCHES.slice(0, 4).map((text) => ({
        text,
        textAr: text,
        section: 'popular',
        route: `/search?q=${encodeURIComponent(text)}`,
        kind: 'popular' as const,
        score: 50,
      })),
      ...SEARCH_CLUSTERS.slice(0, 8).map((cluster) => ({
        text: cluster.labelEn,
        textAr: cluster.labelAr,
        section: cluster.section,
        route: cluster.route,
        kind: 'section' as const,
        score: 40,
      })),
    ].slice(0, limit)
  }

  const scored: SearchSuggestion[] = []

  for (const cluster of SEARCH_CLUSTERS) {
    const clusterScore = scoreCluster(normalized, cluster)
    if (clusterScore > 0) {
      scored.push({
        text: cluster.labelEn,
        textAr: cluster.labelAr,
        section: cluster.section,
        route: buildSectionRoute(cluster.route, query.trim()),
        kind: 'section',
        score: clusterScore + 15,
      })
    }

    for (const term of cluster.terms) {
      const termScore = scoreQueryAgainstText(normalized, term)
      if (termScore > 0) {
        scored.push({
          text: term,
          textAr: cluster.labelAr,
          section: cluster.section,
          route: buildSectionRoute(cluster.route, query.trim()),
          kind: 'keyword',
          score: termScore,
        })
      }
    }
  }

  for (const popular of POPULAR_SEARCHES) {
    const score = scoreQueryAgainstText(normalized, popular)
    if (score > 0) {
      scored.push({
        text: popular,
        textAr: popular,
        section: 'popular',
        route: `/search?q=${encodeURIComponent(popular)}`,
        kind: 'popular',
        score: score + 5,
      })
    }
  }

  const deduped = new Map<string, SearchSuggestion>()
  for (const item of scored.sort((a, b) => b.score - a.score)) {
    const key = `${item.section}:${item.route}:${normalizeSearchQuery(item.text)}`
    if (!deduped.has(key)) deduped.set(key, item)
  }

  return [...deduped.values()].slice(0, limit)
}

export function resolvePrimaryRoute(query: string): string {
  const trimmed = query.trim()
  if (!trimmed) return '/search'
  if (trimmed.includes('@')) return buildSectionRoute('/users', trimmed)

  const normalized = normalizeSearchQuery(trimmed)
  let best: { cluster: SearchCluster; score: number; specificity: number } | null = null
  for (const cluster of SEARCH_CLUSTERS) {
    const score = scoreCluster(normalized, cluster)
    const specificity = clusterSpecificity(cluster)
    if (
      !best
      || score > best.score
      || (score === best.score && specificity > best.specificity)
    ) {
      best = { cluster, score, specificity }
    }
  }

  if (best && best.score >= 35) {
    return buildSectionRoute(best.cluster.route, trimmed)
  }

  return `/search?q=${encodeURIComponent(trimmed)}`
}

export function sectionLabelKey(section: string): string {
  const map: Record<string, string> = {
    ads: 'nav.ads',
    users: 'nav.users',
    orders: 'nav.orders',
    shipping: 'nav.shipping',
    categories: 'nav.categories',
    notifications: 'nav.notifications',
    settings: 'nav.settings',
    dashboard: 'nav.dashboard',
    chat: 'nav.chat',
    sections: 'globalSearch.sections',
    popular: 'globalSearch.popular',
  }
  return map[section] ?? 'globalSearch.result'
}
