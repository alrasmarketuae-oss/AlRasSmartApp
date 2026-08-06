import { whatsappHref } from '../../utils/whatsapp'

type WhatsAppPhoneLinkProps = {
  phone?: string | null
  className?: string
  /** Extra classes when no WhatsApp link is available */
  fallbackClassName?: string
}

/**
 * Blue phone number that opens WhatsApp when a valid number exists.
 */
export default function WhatsAppPhoneLink({
  phone,
  className = '',
  fallbackClassName = '',
}: WhatsAppPhoneLinkProps) {
  const display = phone?.trim() || '—'
  const href = whatsappHref(phone)

  if (!href) {
    return (
      <span className={`font-semibold ${fallbackClassName || className}`} dir="ltr">
        {display}
      </span>
    )
  }

  return (
    <a
      href={href}
      target="_blank"
      rel="noopener noreferrer"
      title="WhatsApp"
      className={`font-semibold text-[#2563eb] underline-offset-2 hover:underline ${className}`}
      dir="ltr"
      onClick={(e) => e.stopPropagation()}
    >
      {display}
    </a>
  )
}
