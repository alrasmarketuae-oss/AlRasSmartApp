import { splitPhoneNumbers, whatsappHref } from '../../utils/whatsapp'

type WhatsAppPhoneLinkProps = {
  phone?: string | null
  className?: string
  /** Extra classes when no WhatsApp link is available */
  fallbackClassName?: string
}

/**
 * Blue phone number(s) that open WhatsApp.
 * If the field contains several numbers (comma/semicolon separated),
 * each number is its own clickable WhatsApp link.
 */
export default function WhatsAppPhoneLink({
  phone,
  className = '',
  fallbackClassName = '',
}: WhatsAppPhoneLinkProps) {
  const numbers = splitPhoneNumbers(phone)
  if (numbers.length === 0) {
    const display = phone?.trim() || '—'
    return (
      <span className={`font-semibold ${fallbackClassName || className}`} dir="ltr">
        {display}
      </span>
    )
  }

  if (numbers.length === 1) {
    return (
      <SingleWhatsAppLink
        phone={numbers[0]}
        className={className}
        fallbackClassName={fallbackClassName}
      />
    )
  }

  return (
    <span className={`inline-flex flex-wrap items-center gap-x-1 gap-y-0.5 ${className}`} dir="ltr">
      {numbers.map((num, index) => (
        <span key={`${num}-${index}`} className="inline-flex items-center gap-x-1">
          {index > 0 ? (
            <span className="admin-text-muted font-normal" aria-hidden>
              ,
            </span>
          ) : null}
          <SingleWhatsAppLink phone={num} className={className} fallbackClassName={fallbackClassName} />
        </span>
      ))}
    </span>
  )
}

function SingleWhatsAppLink({
  phone,
  className,
  fallbackClassName,
}: {
  phone: string
  className: string
  fallbackClassName: string
}) {
  const href = whatsappHref(phone)
  if (!href) {
    return (
      <span className={`font-semibold ${fallbackClassName || className}`} dir="ltr">
        {phone}
      </span>
    )
  }

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      title={`WhatsApp ${phone}`}
      className={`font-semibold text-[#2563eb] underline-offset-2 hover:underline ${className}`}
      dir="ltr"
      onClick={(e) => e.stopPropagation()}
    >
      {phone}
    </a>
  )
}
