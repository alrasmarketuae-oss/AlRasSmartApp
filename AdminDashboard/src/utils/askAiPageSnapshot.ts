const MAX_VISIBLE_CHARS = 14_000
const MAX_REGISTERED_CHARS = 16_000

function truncate(value: string, max: number): string {
  const trimmed = value.trim()
  if (trimmed.length <= max) return trimmed
  return `${trimmed.slice(0, max)}\n…[truncated]`
}

function safeJson(value: unknown, max: number): string | null {
  if (value == null) return null
  try {
    return truncate(JSON.stringify(value, null, 0), max)
  } catch {
    return null
  }
}

/** Collect visible text from the main admin content pane. */
function collectVisibleMainText(): string {
  const main = document.querySelector('main')
  if (!main) return ''

  const clone = main.cloneNode(true) as HTMLElement
  clone
    .querySelectorAll('script, style, noscript, svg, [aria-hidden="true"]')
    .forEach((el) => el.remove())

  const text = (clone.innerText || clone.textContent || '')
    .replace(/\u00a0/g, ' ')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim()

  return truncate(text, MAX_VISIBLE_CHARS)
}

export type AskAiPageSnapshot = {
  path: string
  title: string
  registeredData: unknown
  visibleText: string
}

export function buildAskAiPageSnapshot(input: {
  path: string
  registeredData?: unknown
}): AskAiPageSnapshot {
  return {
    path: input.path,
    title: document.title || '',
    registeredData: input.registeredData ?? null,
    visibleText: collectVisibleMainText(),
  }
}

/** Serialize snapshot for the API `pageContext` field. */
export function serializeAskAiPageContext(snapshot: AskAiPageSnapshot): string {
  const registered = safeJson(snapshot.registeredData, MAX_REGISTERED_CHARS)
  const parts = [
    `title: ${snapshot.title || '(none)'}`,
    `path: ${snapshot.path}`,
  ]
  if (registered && registered !== 'null') {
    parts.push(`registeredPageData: ${registered}`)
  }
  if (snapshot.visibleText) {
    parts.push(`visiblePageText:\n${snapshot.visibleText}`)
  }
  return parts.join('\n\n')
}
