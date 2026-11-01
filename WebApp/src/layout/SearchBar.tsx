import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useI18n } from '../i18n/I18nProvider'
import { fetchSearchSuggestions } from '../products/productsApi'
import { Icon } from '../ui/Icon'

export function SearchBar({ compact = false }: { compact?: boolean }) {
  const { t } = useI18n()
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const [value, setValue] = useState(params.get('q') ?? '')
  const [suggestions, setSuggestions] = useState<string[]>([])
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(-1)
  const wrapperRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const fileRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    setValue(params.get('q') ?? '')
  }, [params])

  useEffect(() => {
    const q = value.trim()
    if (q.length < 2) {
      setSuggestions([])
      return
    }
    const controller = new AbortController()
    const id = window.setTimeout(() => {
      fetchSearchSuggestions(q, controller.signal)
        .then((data) => {
          setSuggestions((data?.suggestions ?? []).filter(Boolean).slice(0, 8))
          setActive(-1)
        })
        .catch(() => undefined)
    }, 220)
    return () => {
      window.clearTimeout(id)
      controller.abort()
    }
  }, [value])

  useEffect(() => {
    const onDown = (event: MouseEvent) => {
      if (!wrapperRef.current?.contains(event.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onDown)
    return () => document.removeEventListener('mousedown', onDown)
  }, [])

  const go = (query: string) => {
    const q = query.trim()
    if (!q) return
    setValue(q)
    setOpen(false)
    inputRef.current?.blur()
    navigate(`/search?q=${encodeURIComponent(q)}`)
  }

  const submit = (event: FormEvent) => {
    event.preventDefault()
    go(active >= 0 ? suggestions[active] : value)
  }

  const showList = open && suggestions.length > 0

  return (
    <div ref={wrapperRef} className="relative w-full">
      <form onSubmit={submit} role="search">
        <div
          className={`flex items-center rounded-full border border-input-line bg-white transition focus-within:border-brand focus-within:shadow-[0_0_0_3px_rgba(58,125,197,0.15)] ${compact ? 'h-10' : 'h-11'}`}
        >
          <button type="submit" className="grid h-full w-11 shrink-0 place-items-center text-subtitle" aria-label={t('searchForProducts')}>
            <img src="/assets/home/search.svg" alt="" className="size-[18px]" />
          </button>
          <input
            ref={inputRef}
            type="search"
            enterKeyHint="search"
            value={value}
            onChange={(e) => {
              setValue(e.target.value)
              setOpen(true)
            }}
            onFocus={() => setOpen(true)}
            onKeyDown={(e) => {
              if (!showList) return
              if (e.key === 'ArrowDown') {
                e.preventDefault()
                setActive((i) => (i + 1) % suggestions.length)
              } else if (e.key === 'ArrowUp') {
                e.preventDefault()
                setActive((i) => (i <= 0 ? suggestions.length - 1 : i - 1))
              } else if (e.key === 'Escape') {
                setOpen(false)
              }
            }}
            placeholder={t('searchHint')}
            aria-label={t('searchForProducts')}
            className="min-w-0 flex-1 bg-transparent text-sm font-medium text-title outline-none placeholder:font-normal placeholder:text-subtitle [&::-webkit-search-cancel-button]:hidden"
          />
          {value && (
            <button
              type="button"
              onClick={() => {
                setValue('')
                setSuggestions([])
                inputRef.current?.focus()
              }}
              className="grid h-full w-9 shrink-0 place-items-center text-subtitle hover:text-title"
              aria-label="Clear"
            >
              <Icon name="close" size={18} />
            </button>
          )}
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="me-1 grid size-9 shrink-0 place-items-center rounded-full text-brand hover:bg-brand/10"
            aria-label={t('searchByImage')}
            title={t('searchByImage')}
          >
            <Icon name="camera" size={20} />
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0]
              e.target.value = ''
              if (!file) return
              setOpen(false)
              navigate('/search/image', { state: { file, at: Date.now() } })
            }}
          />
        </div>
      </form>
      {showList && (
        <ul className="absolute inset-x-0 top-full z-40 mt-1.5 overflow-hidden rounded-xl border border-input-line bg-white py-1 shadow-[0_10px_30px_rgba(0,0,0,0.12)]" role="listbox">
          {suggestions.map((s, i) => (
            <li key={`${s}-${i}`} role="option" aria-selected={i === active}>
              <button
                type="button"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => go(s)}
                className={`flex w-full items-center gap-2.5 px-4 py-2.5 text-start text-sm text-title ${i === active ? 'bg-page' : 'hover:bg-page'}`}
              >
                <Icon name="search" size={16} className="shrink-0 text-subtitle" />
                <span className="truncate">{s}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
