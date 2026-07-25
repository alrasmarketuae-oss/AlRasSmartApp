/** Parse free-text product description into specification lines (same data as description). */
export function parseProductSpecificationItems(
  description: string | null | undefined,
): Array<{ label: string; value: string } | string> {
  const lines = (description ?? '')
    .split(/[\n\r]+/)
    .map((line) => line.trim())
    .filter(Boolean)

  if (lines.length === 0) return []

  return lines.map((line) => {
    const match = line.match(/^([^:：]+)[:：]\s*(.+)$/)
    if (match) {
      return { label: match[1].trim(), value: match[2].trim() }
    }
    return line
  })
}
