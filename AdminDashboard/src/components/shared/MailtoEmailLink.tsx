type MailtoEmailLinkProps = {
  email?: string | null
  className?: string
  /** Extra classes when no valid email is available */
  fallbackClassName?: string
}

/**
 * Blue email address that opens the default mail client when a valid address exists.
 */
export default function MailtoEmailLink({
  email,
  className = '',
  fallbackClassName = '',
}: MailtoEmailLinkProps) {
  const clean = email?.trim() ?? ''
  const display = clean || '—'
  const isValid = clean.includes('@') && !clean.includes(' ')

  if (!isValid) {
    return (
      <span className={`font-semibold break-all ${fallbackClassName || className}`} dir="ltr">
        {display}
      </span>
    )
  }

  return (
    <a
      href={`mailto:${clean}`}
      title="Email"
      className={`font-semibold text-[#2563eb] break-all underline-offset-2 hover:underline ${className}`}
      dir="ltr"
      onClick={(e) => e.stopPropagation()}
    >
      {display}
    </a>
  )
}
