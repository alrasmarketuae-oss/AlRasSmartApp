import type { CSSProperties } from 'react'
import { resolveAssetUrl } from '../../lib/assets'

type CompanyAvatarProps = {
  path?: string | null
  name: string
  className?: string
  roundedClassName?: string
  fallbackClassName?: string
  fallbackStyle?: CSSProperties
}

/** Company/supplier logo; falls back to name initials when no image. */
export default function CompanyAvatar({
  path,
  name,
  className = 'h-8 w-8',
  roundedClassName = 'rounded-full',
  fallbackClassName = 'bg-slate-100 text-[10px] font-bold text-slate-600',
  fallbackStyle,
}: CompanyAvatarProps) {
  const url = resolveAssetUrl(path)
  const initials = (name || '—').slice(0, 2).toUpperCase()

  if (url) {
    return (
      <img
        src={url}
        alt=""
        className={`${className} ${roundedClassName} shrink-0 object-cover ring-1 ring-slate-200`}
      />
    )
  }

  return (
    <span
      className={`flex ${className} shrink-0 items-center justify-center ${roundedClassName} ${fallbackClassName}`}
      style={fallbackStyle}
    >
      {initials}
    </span>
  )
}
