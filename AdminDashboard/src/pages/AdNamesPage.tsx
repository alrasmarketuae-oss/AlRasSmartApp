import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useListPageParam } from '../hooks/useListPageParam'
import { resolveAssetUrl } from '../lib/assets'
import {
  useGetAdminProductNamesQuery,
  useUpdateAdminProductNamesMutation,
} from '../store'
import { getRtkErrorMessage } from '../utils/rtkError'

type NameDraft = { nameEn: string; nameAr: string }

type NameRow = {
  productId: string
  productCode: string
  nameEn: string
  nameAr: string
  productTypeName: string
  ownerCompanyName: string
  primaryImagePath: string | null
}

const pageSize = 20

export default function AdNamesPage() {
  const { t } = useAppPreferences()
  const { page, setPage } = useListPageParam()
  const [search, setSearch] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const skipPageReset = useRef(true)
  const { data, isLoading, isFetching, error } = useGetAdminProductNamesQuery({
    page,
    pageSize,
    search: appliedSearch || undefined,
  })
  const rows = data?.items ?? []
  const totalPages = data?.totalPages ?? 1
  const [updateNames] = useUpdateAdminProductNamesMutation()
  const [drafts, setDrafts] = useState<Record<string, NameDraft>>({})
  const [savingAll, setSavingAll] = useState(false)
  const [savingId, setSavingId] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  function current(row: NameRow): NameDraft {
    return drafts[row.productId] ?? { nameEn: row.nameEn, nameAr: row.nameAr }
  }

  function isDirty(row: NameRow) {
    const draft = current(row)
    return draft.nameEn.trim() !== row.nameEn.trim() || draft.nameAr.trim() !== row.nameAr.trim()
  }

  const dirtyRows = rows.filter(isDirty)

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setAppliedSearch(search.trim())
      if (skipPageReset.current) {
        skipPageReset.current = false
        return
      }
      setPage(1)
    }, 300)
    return () => window.clearTimeout(timer)
  }, [search, setPage])

  function setField(productId: string, row: NameRow, field: keyof NameDraft, value: string) {
    setDrafts((prev) => {
      const base = prev[productId] ?? { nameEn: row.nameEn, nameAr: row.nameAr }
      return { ...prev, [productId]: { ...base, [field]: value } }
    })
  }

  async function saveRow(row: NameRow) {
    const draft = current(row)
    const nameEn = draft.nameEn.trim()
    const nameAr = draft.nameAr.trim()
    if (!nameEn || !nameAr) {
      setActionError(t('ads.nameRequired'))
      setSuccessMessage(null)
      return false
    }

    setSavingId(row.productId)
    setActionError(null)
    try {
      await updateNames({ productId: row.productId, nameEn, nameAr }).unwrap()
      setDrafts((prev) => {
        const next = { ...prev }
        delete next[row.productId]
        return next
      })
      return true
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.namesSaveError')))
      setSuccessMessage(null)
      return false
    } finally {
      setSavingId(null)
    }
  }

  async function saveAll() {
    if (dirtyRows.length === 0 || savingAll) return
    setSavingAll(true)
    setActionError(null)
    setSuccessMessage(null)
    let saved = 0
    for (const row of dirtyRows) {
      const ok = await saveRow(row)
      if (ok) saved += 1
      else break
    }
    setSavingAll(false)
    if (saved > 0) setSuccessMessage(t('ads.namesSaved'))
  }

  const busy = savingAll || savingId != null

  return (
    <div className="space-y-4">
      <div className="admin-card px-5 py-5 sm:px-6">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div className="min-w-0 text-start">
            <Link to="/ads" className="text-xs font-semibold text-[#3B7FC7] hover:underline">
              ← {t('ads.backToAds')}
            </Link>
            <h1 className="admin-text mt-1 text-2xl font-extrabold">{t('ads.changeNames')}</h1>
            <p className="admin-text-muted mt-1 max-w-2xl text-sm">{t('ads.changeNamesHint')}</p>
          </div>
          <button
            type="button"
            disabled={busy || dirtyRows.length === 0}
            onClick={() => void saveAll()}
            className="keep-white rounded-xl bg-[#3B7FC7] px-5 py-2.5 text-sm font-bold text-white disabled:opacity-50"
          >
            {savingAll
              ? t('ads.savingNames')
              : dirtyRows.length > 0
                ? `${t('ads.saveNames')} (${dirtyRows.length})`
                : t('ads.saveNames')}
          </button>
        </div>
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder={t('ads.changeNamesSearch')}
          className="admin-input mt-4 w-full px-3 py-2.5 text-sm"
        />
      </div>

      {successMessage ? <div className="admin-alert-success">{successMessage}</div> : null}
      {actionError ? <div className="admin-alert-error">{actionError}</div> : null}

      {isLoading ? (
        <p className="admin-text-subtle py-16 text-center">{t('loading')}</p>
      ) : error ? (
        <div className="admin-card px-6 py-16 text-center text-sm text-red-600">
          {getRtkErrorMessage(error as never, t('ads.namesSaveError'))}
        </div>
      ) : rows.length === 0 ? (
        <p className="admin-text-subtle py-16 text-center">
          {appliedSearch ? t('ads.noNamesMatch') : t('ads.noNames')}
        </p>
      ) : (
        <ul className="space-y-3">
          {isFetching ? (
            <li className="admin-text-subtle text-center text-sm">{t('updating')}</li>
          ) : null}
          {rows.map((row) => {
            const draft = current(row)
            const dirty = isDirty(row)
            const image = resolveAssetUrl(row.primaryImagePath)
            return (
              <li
                key={row.productId}
                className={`admin-card grid gap-3 p-3 sm:grid-cols-[72px_minmax(0,1fr)] sm:p-4 ${
                  dirty ? 'ring-2 ring-amber-300' : ''
                }`}
              >
                <Link to={`/ads/${row.productId}`} className="block">
                  {image ? (
                    <img
                      src={image}
                      alt=""
                      className="h-16 w-16 rounded-xl object-cover sm:h-[72px] sm:w-[72px]"
                    />
                  ) : (
                    <span className="admin-border flex h-16 w-16 items-center justify-center rounded-xl border text-[10px] text-slate-400 sm:h-[72px] sm:w-[72px]">
                      —
                    </span>
                  )}
                </Link>
                <div className="min-w-0">
                  <div className="mb-2 flex flex-wrap items-center gap-x-2 gap-y-1 text-xs">
                    <span className="admin-text font-bold">{row.ownerCompanyName || '—'}</span>
                    {row.productCode ? (
                      <span className="admin-text-muted">{row.productCode}</span>
                    ) : null}
                    {row.productTypeName ? (
                      <span className="rounded-full bg-[#eff6ff] px-2 py-0.5 font-semibold text-[#3B7FC7]">
                        {row.productTypeName}
                      </span>
                    ) : null}
                  </div>
                  <div className="grid gap-2 sm:grid-cols-2">
                    <label className="block text-start">
                      <span className="admin-text-muted mb-1 block text-[10px] font-semibold">
                        {t('ads.productNameEn')}
                      </span>
                      <input
                        dir="ltr"
                        value={draft.nameEn}
                        onChange={(e) => setField(row.productId, row, 'nameEn', e.target.value)}
                        className="admin-input w-full px-3 py-2 text-sm"
                      />
                    </label>
                    <label className="block text-start">
                      <span className="admin-text-muted mb-1 block text-[10px] font-semibold">
                        {t('ads.productNameAr')}
                      </span>
                      <input
                        dir="rtl"
                        value={draft.nameAr}
                        onChange={(e) => setField(row.productId, row, 'nameAr', e.target.value)}
                        className="admin-input w-full px-3 py-2 text-sm"
                      />
                    </label>
                  </div>
                </div>
              </li>
            )
          })}
        </ul>
      )}

      {totalPages > 1 ? (
        <div
          dir="ltr"
          className="admin-card flex flex-wrap items-center justify-between gap-3 px-4 py-4"
        >
          <button
            type="button"
            disabled={page <= 1}
            onClick={() => setPage((p) => p - 1)}
            className="admin-btn-ghost"
          >
            {t('previous')}
          </button>
          <span className="admin-text-muted text-sm">
            {t('pageOf', { page, total: totalPages })}
          </span>
          <button
            type="button"
            disabled={page >= totalPages}
            onClick={() => setPage((p) => p + 1)}
            className="admin-btn-ghost"
          >
            {t('next')}
          </button>
        </div>
      ) : null}

      {dirtyRows.length > 0 ? (
        <div className="sticky bottom-3 flex justify-end">
          <button
            type="button"
            disabled={busy}
            onClick={() => void saveAll()}
            className="keep-white rounded-xl bg-[#3B7FC7] px-5 py-3 text-sm font-bold text-white shadow-lg disabled:opacity-50"
          >
            {savingAll
              ? t('ads.savingNames')
              : `${t('ads.saveNames')} (${dirtyRows.length})`}
          </button>
        </div>
      ) : null}
    </div>
  )
}
