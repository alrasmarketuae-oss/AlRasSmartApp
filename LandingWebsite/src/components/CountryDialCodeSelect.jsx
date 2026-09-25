import { useEffect, useMemo, useRef, useState } from 'react'
import {
  COUNTRY_DIAL_CODES,
  findCountryByDialCode,
  searchCountryDialCodes,
} from '../data/countryDialCodes'

export default function CountryDialCodeSelect({
  label,
  value = '+971',
  onChange,
  disabled = false,
}) {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')
  const rootRef = useRef(null)

  const selected =
    findCountryByDialCode(value) ||
    COUNTRY_DIAL_CODES.find((c) => c.isoCode === 'AE') ||
    COUNTRY_DIAL_CODES[0]

  const options = useMemo(() => searchCountryDialCodes(query), [query])

  useEffect(() => {
    function onDocClick(e) {
      if (!rootRef.current?.contains(e.target)) setOpen(false)
    }
    document.addEventListener('mousedown', onDocClick)
    return () => document.removeEventListener('mousedown', onDocClick)
  }, [])

  return (
    <div ref={rootRef} className="relative">
      {label ? (
        <label className="mb-1.5 block text-sm font-semibold text-slate-700">{label}</label>
      ) : null}
      <button
        type="button"
        disabled={disabled}
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center justify-between gap-2 rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-start text-sm font-semibold text-slate-800 transition hover:border-brand-blue disabled:opacity-60"
        dir="ltr"
      >
        <span className="truncate">
          <span className="me-1.5 text-base">{selected?.flag}</span>
          {selected?.dialCode}
        </span>
        <span className="text-slate-400">▾</span>
      </button>

      {open ? (
        <div className="absolute z-40 mt-1 max-h-72 w-[min(100vw-2rem,22rem)] overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xl">
          <div className="border-b border-slate-100 p-2">
            <input
              type="search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search country / code"
              className="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm outline-none focus:border-brand-blue"
              dir="ltr"
              autoFocus
            />
          </div>
          <ul className="max-h-56 overflow-y-auto py-1" role="listbox">
            {options.map((country) => (
              <li key={`${country.isoCode}-${country.dialCode}`}>
                <button
                  type="button"
                  className={`flex w-full items-center gap-2 px-3 py-2 text-start text-sm hover:bg-brand-blue/5 ${
                    country.dialCode === value ? 'bg-brand-blue/10 font-semibold' : ''
                  }`}
                  dir="ltr"
                  onClick={() => {
                    onChange?.(country.dialCode)
                    setOpen(false)
                    setQuery('')
                  }}
                >
                  <span className="text-base">{country.flag}</span>
                  <span className="min-w-0 flex-1 truncate text-slate-800">{country.name}</span>
                  <span className="shrink-0 text-slate-500">{country.dialCode}</span>
                </button>
              </li>
            ))}
            {options.length === 0 ? (
              <li className="px-3 py-4 text-center text-sm text-slate-500">No results</li>
            ) : null}
          </ul>
        </div>
      ) : null}
    </div>
  )
}
