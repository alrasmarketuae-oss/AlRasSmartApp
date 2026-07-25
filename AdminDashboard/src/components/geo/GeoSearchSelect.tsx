import { useEffect, useMemo, useRef, useState } from 'react'

export type GeoSearchSelectOption = {
  value: string
  label: string
  meta?: string
  searchText: string
}

type GeoSearchSelectProps = {
  label: string
  value: string
  onChange: (value: string) => void
  options: GeoSearchSelectOption[]
  placeholder: string
  searchPlaceholder: string
  emptyText: string
  loading?: boolean
  disabled?: boolean
  required?: boolean
  resultsHint?: string
}

export default function GeoSearchSelect({
  label,
  value,
  onChange,
  options,
  placeholder,
  searchPlaceholder,
  emptyText,
  loading = false,
  disabled = false,
  required = false,
  resultsHint,
}: GeoSearchSelectProps) {
  const rootRef = useRef<HTMLDivElement>(null)
  const searchRef = useRef<HTMLInputElement>(null)
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')

  const selected = useMemo(
    () => options.find((option) => option.value === value) ?? null,
    [options, value],
  )

  const filtered = useMemo(() => {
    const normalized = query.trim().toLowerCase()
    if (!normalized) return options
    return options.filter((option) => option.searchText.includes(normalized))
  }, [options, query])

  useEffect(() => {
    if (!open) return

    const timer = window.setTimeout(() => searchRef.current?.focus(), 0)

    function onDocClick(event: MouseEvent) {
      if (!rootRef.current?.contains(event.target as Node)) {
        setOpen(false)
        setQuery('')
      }
    }

    document.addEventListener('mousedown', onDocClick)
    return () => {
      window.clearTimeout(timer)
      document.removeEventListener('mousedown', onDocClick)
    }
  }, [open])

  function pick(option: GeoSearchSelectOption) {
    onChange(option.value)
    setOpen(false)
    setQuery('')
  }

  const isDisabled = disabled || loading

  return (
    <div ref={rootRef} className="relative block text-right">
      <span className="admin-text-subtle mb-1 block text-xs font-medium">{label}</span>

      <button
        type="button"
        disabled={isDisabled}
        onClick={() => {
          if (isDisabled) return
          setOpen((prev) => !prev)
        }}
        className="admin-input flex w-full items-center justify-between gap-2 text-right disabled:cursor-not-allowed disabled:opacity-60"
      >
        <span className="min-w-0 flex-1 truncate">
          {loading ? (
            <span className="admin-text-subtle">{placeholder}</span>
          ) : selected ? (
            <>
              <span className="admin-text block truncate font-medium">{selected.label}</span>
              {selected.meta ? (
                <span className="admin-text-muted block truncate text-xs">{selected.meta}</span>
              ) : null}
            </>
          ) : (
            <span className="admin-text-subtle">{placeholder}</span>
          )}
        </span>
        <span className="admin-text-muted shrink-0 text-xs" aria-hidden>
          ▾
        </span>
      </button>

      {required ? (
        <input
          tabIndex={-1}
          aria-hidden
          value={value}
          onChange={() => undefined}
          required
          className="pointer-events-none absolute h-0 w-0 opacity-0"
        />
      ) : null}

      {open && !isDisabled ? (
        <div className="admin-card absolute z-30 mt-1 w-full overflow-hidden shadow-lg">
          <div className="admin-border border-b p-2">
            <input
              ref={searchRef}
              type="search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={searchPlaceholder}
              className="admin-input w-full"
            />
          </div>

          {resultsHint ? (
            <p className="admin-text-muted border-b px-3 py-2 text-xs">{resultsHint}</p>
          ) : null}

          <ul className="max-h-56 overflow-y-auto py-1" role="listbox">
            {filtered.length === 0 ? (
              <li className="admin-text-subtle px-3 py-3 text-center text-sm">{emptyText}</li>
            ) : (
              filtered.map((option) => {
                const active = option.value === value
                return (
                  <li key={option.value}>
                    <button
                      type="button"
                      role="option"
                      aria-selected={active}
                      onClick={() => pick(option)}
                      className={`flex w-full flex-col gap-0.5 px-3 py-2.5 text-right transition ${
                        active ? 'bg-[#3B7FC7]/10' : 'hover:bg-black/5 dark:hover:bg-white/5'
                      }`}
                    >
                      <span className="admin-text text-sm font-medium">{option.label}</span>
                      {option.meta ? (
                        <span className="admin-text-muted text-xs">{option.meta}</span>
                      ) : null}
                    </button>
                  </li>
                )
              })
            )}
          </ul>

          <div className="admin-border admin-text-muted border-t px-3 py-2 text-xs">
            {filtered.length} / {options.length}
          </div>
        </div>
      ) : null}
    </div>
  )
}
