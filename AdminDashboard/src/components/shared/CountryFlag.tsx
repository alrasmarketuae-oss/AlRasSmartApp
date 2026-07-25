import { flagCdnUrl, resolveCountryIso } from '../../utils/countryFlags'

type CountryFlagProps = {
  countryName?: string | null
  city?: string | null
  phone?: string | null
  iso2?: string | null
  size?: 20 | 40 | 80
  className?: string
  title?: string
}

export default function CountryFlag({
  countryName,
  city,
  phone,
  iso2,
  size = 20,
  className = '',
  title,
}: CountryFlagProps) {
  const code = iso2?.trim() || resolveCountryIso({ countryName, city, phone })
  if (!code) return null

  const px = size === 80 ? 28 : size === 40 ? 20 : 16

  return (
    <img
      src={flagCdnUrl(code, size)}
      alt={title || code.toUpperCase()}
      title={title || code.toUpperCase()}
      width={px}
      height={Math.round(px * 0.75)}
      className={`inline-block shrink-0 rounded-[2px] object-cover shadow-sm ring-1 ring-black/10 ${className}`}
      loading="lazy"
      referrerPolicy="no-referrer"
    />
  )
}
