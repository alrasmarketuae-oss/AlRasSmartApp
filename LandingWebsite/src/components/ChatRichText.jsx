/**
 * Renders assistant text with clickable Markdown links and bare URLs/emails.
 */
export default function ChatRichText({ text, className = '' }) {
  const nodes = parseRichText(String(text ?? ''))

  return (
    <div className={`whitespace-pre-wrap break-words ${className}`}>
      {nodes.map((node, i) => {
        if (node.type === 'text') {
          return <span key={i}>{node.value}</span>
        }
        if (node.type === 'br') {
          return <br key={i} />
        }
        return (
          <a
            key={i}
            href={node.href}
            target={node.href.startsWith('mailto:') ? undefined : '_blank'}
            rel="noopener noreferrer"
            className="font-bold text-[#3A6AA5] underline underline-offset-2 hover:text-[#7B61FF]"
            onClick={(e) => e.stopPropagation()}
          >
            {node.label}
          </a>
        )
      })}
    </div>
  )
}

function parseRichText(raw) {
  if (!raw) return [{ type: 'text', value: '' }]

  const nodes = []
  // [label](url) then bare https?:// then emails
  const re =
    /\[([^\]]+)\]\((https?:\/\/[^)\s]+|mailto:[^)\s]+)\)|(https?:\/\/[^\s<]+)|(mailto:[^\s<]+)|([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})/gi

  let last = 0
  let match
  while ((match = re.exec(raw)) !== null) {
    if (match.index > last) {
      pushTextWithBreaks(nodes, raw.slice(last, match.index))
    }

    if (match[1] && match[2]) {
      nodes.push({ type: 'link', label: match[1], href: match[2] })
    } else if (match[3]) {
      const href = match[3].replace(/[),.;]+$/, '')
      nodes.push({ type: 'link', label: href, href })
    } else if (match[4]) {
      nodes.push({ type: 'link', label: match[4].replace(/^mailto:/i, ''), href: match[4] })
    } else if (match[5]) {
      nodes.push({ type: 'link', label: match[5], href: `mailto:${match[5]}` })
    }

    last = match.index + match[0].length
  }

  if (last < raw.length) {
    pushTextWithBreaks(nodes, raw.slice(last))
  }

  return nodes.length ? nodes : [{ type: 'text', value: raw }]
}

function pushTextWithBreaks(nodes, text) {
  const parts = text.split('\n')
  parts.forEach((part, i) => {
    if (part) nodes.push({ type: 'text', value: part })
    if (i < parts.length - 1) nodes.push({ type: 'br' })
  })
}
