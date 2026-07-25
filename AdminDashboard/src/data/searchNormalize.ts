/** Normalize user query for matching — strips punctuation, parentheses, extra spaces. */
export function normalizeSearchQuery(query: string): string {
  return query
    .trim()
    .toLowerCase()
    .replace(/[()[\]{}«»"'""''،,:;!?./\\|@#%&*+=<>~`]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

export function splitSearchWords(text: string): string[] {
  const normalized = normalizeSearchQuery(text)
  if (!normalized) return []

  return normalized
    .split(/\s+/)
    .filter((word) => word.length >= 2)
}
