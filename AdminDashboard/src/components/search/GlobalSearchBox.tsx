import { useEffect, useMemo, useRef, useState, type FormEvent, type KeyboardEvent } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { useLazyGetGlobalSearchSuggestQuery } from '../../store'
import { getLocalSuggestions, resolvePrimaryRoute, buildSectionRoute, sectionLabelKey } from '../../utils/searchIntelligence'
import { IconSearch } from '../icons'

type GlobalSearchBoxProps = {
  className?: string
  inputClassName?: string
  variant?: 'topbar' | 'inline'
}

export default function GlobalSearchBox({
  className = '',
  inputClassName = '',
  variant: _variant = 'topbar',
}: GlobalSearchBoxProps) {
  const { t, dir, locale } = useAppPreferences()
  const navigate = useNavigate()
  const location = useLocation()
  const [query, setQuery] = useState('')
  const [open, setOpen] = useState(false)
  const [activeIndex, setActiveIndex] = useState(-1)
  const rootRef = useRef<HTMLDivElement>(null)
  const [fetchSuggest, { data: apiSuggest }] = useLazyGetGlobalSearchSuggestQuery()

  useEffect(() => {
    const params = new URLSearchParams(location.search)
    const fromSearchPage = params.get('q') ?? ''
    const fromSection = params.get('search') ?? ''
    if (location.pathname === '/search') {
      setQuery(fromSearchPage)
    } else if (fromSection) {
      setQuery(fromSection)
    } else if (!location.pathname.startsWith('/ads') && !location.pathname.startsWith('/users')) {
      setQuery('')
    }
  }, [location.pathname, location.search])

  useEffect(() => {
    if (!open) return
    const timer = window.setTimeout(() => {
      fetchSuggest({ q: query.trim() || undefined, limit: 8 })
    }, 250)
    return () => window.clearTimeout(timer)
  }, [query, open, fetchSuggest])

  const localSuggestions = useMemo(
    () => getLocalSuggestions(query, 10),
    [query],
  )

  const suggestions = useMemo(() => {
    const trimmedQuery = query.trim()
    const apiItems = (apiSuggest?.items ?? []).map((item) => ({
      text: item.text,
      textAr: item.textAr,
      section: item.section,
      route: item.route.includes('search=') || item.route.includes('q=')
        ? item.route
        : buildSectionRoute(item.route, trimmedQuery || item.text),
      kind: (item.kind === 'section' || item.kind === 'popular' ? item.kind : 'keyword') as 'keyword' | 'section' | 'popular',
      score: 60,
    }))

    const merged = new Map<string, (typeof localSuggestions)[number]>()
    for (const item of [...localSuggestions, ...apiItems]) {
      const key = `${item.section}:${item.text.toLowerCase()}`
      if (!merged.has(key)) merged.set(key, item)
    }
    return [...merged.values()].slice(0, 10)
  }, [localSuggestions, apiSuggest, query])

  useEffect(() => {
    function onDocClick(event: MouseEvent) {
      if (!rootRef.current?.contains(event.target as Node)) {
        setOpen(false)
        setActiveIndex(-1)
      }
    }
    document.addEventListener('mousedown', onDocClick)
    return () => document.removeEventListener('mousedown', onDocClick)
  }, [])

  function goTo(term: string, route?: string) {
    const trimmed = term.trim()
    if (!trimmed) return
    setOpen(false)
    setActiveIndex(-1)
    navigate(route ?? resolvePrimaryRoute(trimmed))
  }

  function handleSubmit(event: FormEvent) {
    event.preventDefault()
    if (activeIndex >= 0 && suggestions[activeIndex]) {
      const item = suggestions[activeIndex]
      goTo(item.text, item.route)
      return
    }
    goTo(query)
  }

  function handleKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (!open && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
      setOpen(true)
      return
    }
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      setActiveIndex((i) => Math.min(i + 1, suggestions.length - 1))
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      setActiveIndex((i) => Math.max(i - 1, 0))
    } else if (event.key === 'Escape') {
      setOpen(false)
      setActiveIndex(-1)
    }
  }

  const showDropdown = open && (query.length > 0 || suggestions.length > 0)

  return (
    <div ref={rootRef} className={`relative ${className}`}>
      <form onSubmit={handleSubmit} className="relative">
        <IconSearch className="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-[#3B7FC7]" />
        <input
          type="search"
          dir={dir}
          value={query}
          onChange={(event) => {
            setQuery(event.target.value)
            setOpen(true)
            setActiveIndex(-1)
          }}
          onFocus={() => setOpen(true)}
          onKeyDown={handleKeyDown}
          placeholder={t('globalSearch.placeholder')}
          className={inputClassName}
          autoComplete="off"
          role="combobox"
          aria-expanded={showDropdown}
          aria-controls="global-search-listbox"
        />
      </form>

      {showDropdown ? (
        <div
          id="global-search-listbox"
          role="listbox"
          className="admin-card absolute z-50 mt-2 max-h-[min(24rem,70vh)] w-full overflow-auto border shadow-xl"
        >
          <p className="admin-text-subtle border-b px-4 py-2 text-xs font-medium">
            {query.trim() ? t('globalSearch.suggestions') : t('globalSearch.quickLinks')}
          </p>
          {suggestions.length === 0 ? (
            <p className="admin-text-subtle px-4 py-3 text-sm">{t('globalSearch.noSuggestions')}</p>
          ) : (
            suggestions.map((item, index) => {
              const label = locale === 'ar' ? item.textAr || item.text : item.text
              return (
                <button
                  key={`${item.section}-${item.text}-${index}`}
                  type="button"
                  role="option"
                  aria-selected={index === activeIndex}
                  className={`flex w-full items-start gap-3 px-4 py-3 text-left transition hover:bg-slate-50 dark:hover:bg-slate-800/80 ${
                    index === activeIndex ? 'bg-slate-50 dark:bg-slate-800/80' : ''
                  }`}
                  onMouseEnter={() => setActiveIndex(index)}
                  onClick={() => goTo(item.text, item.route)}
                >
                  <span className="mt-0.5 text-lg opacity-70">⌕</span>
                  <span className="min-w-0 flex-1">
                    <span className="admin-text block truncate text-sm font-medium">{label}</span>
                    <span className="admin-text-subtle block truncate text-xs">
                      {t(sectionLabelKey(item.section))}
                    </span>
                  </span>
                </button>
              )
            })
          )}
          {query.trim() ? (
            <button
              type="button"
              className="admin-text w-full border-t px-4 py-3 text-left text-sm font-semibold text-[#3B7FC7] hover:bg-slate-50 dark:hover:bg-slate-800/80"
              onClick={() => goTo(query, `/search?q=${encodeURIComponent(query.trim())}`)}
            >
              {t('globalSearch.searchAll').replace('{query}', query.trim())}
            </button>
          ) : null}
        </div>
      ) : null}
    </div>
  )
}
