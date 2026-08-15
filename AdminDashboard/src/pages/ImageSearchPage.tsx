import { useEffect, useMemo, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../lib/assets'
import { hasPermission, PERMISSIONS } from '../lib/permissions'
import {
  useDeleteClipReferenceImageMutation,
  useGetAdminImageSearchStatusQuery,
  useGetClipReferenceImagesQuery,
  useReindexClipReferenceImagesMutation,
  useReindexImageVectorsMutation,
  useUploadClipReferenceImagesMutation,
} from '../store'
import { queryViewState } from '../store/queryView'
import type {
  ImageSearchReferenceMatch,
  ImageSearchTestProduct,
  ImageSearchTestResult,
} from '../types/adminImageSearch'
import { getRtkErrorMessage } from '../utils/rtkError'
import { runImageSearchTest } from '../utils/imageSearchTest'

type TestRun = {
  id: string
  fileName: string
  previewUrl: string
  status: 'pending' | 'loading' | 'done' | 'error'
  result?: ImageSearchTestResult
  error?: string
}

type StagedTrainingImage = {
  id: string
  file: File
  previewUrl: string
}

function StatusPill({ label, up }: { label: string; up: boolean }) {
  return (
    <span
      className={`inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-xs font-bold ${
        up
          ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300'
          : 'bg-red-50 text-red-700 dark:bg-red-950/40 dark:text-red-300'
      }`}
    >
      <span className={`h-2 w-2 rounded-full ${up ? 'bg-emerald-500' : 'bg-red-500'}`} />
      {label}
    </span>
  )
}

function StatCard({ title, value }: { title: string; value: string }) {
  return (
    <div className="admin-card rounded-2xl border border-slate-100 p-4 shadow-sm dark:border-slate-700">
      <p className="admin-text-muted text-xs font-semibold">{title}</p>
      <p className="admin-text mt-2 text-xl font-extrabold tabular-nums">{value}</p>
    </div>
  )
}

function scoreForProduct(
  productId: string,
  scores: { productId: string; score: number }[],
): number | null {
  const hit = scores.find((s) => s.productId.toLowerCase() === productId.toLowerCase())
  return hit?.score ?? null
}

function sortedItemsForResult(result: ImageSearchTestResult): ImageSearchTestProduct[] {
  const items = result.items ?? []
  const scores = result.scores ?? []
  if (scores.length === 0) return items
  return [...items].sort((a, b) => {
    const sa = scoreForProduct(a.productId ?? '', scores) ?? 0
    const sb = scoreForProduct(b.productId ?? '', scores) ?? 0
    return sb - sa
  })
}

function ResultCard({
  item,
  score,
  locale,
  scoreLabel,
}: {
  item: ImageSearchTestProduct
  score: number | null
  locale: string
  scoreLabel: string
}) {
  const imageUrl = resolveAssetUrl(item.primaryImagePath ?? item.images?.[0])
  const productId = item.productId ?? ''

  return (
    <Link
      to={productId ? `/ads/${productId}` : '/ads'}
      className="admin-card block overflow-hidden rounded-2xl border border-slate-100 transition hover:border-indigo-200 dark:border-slate-700 dark:hover:border-indigo-800"
    >
      <div className="aspect-square bg-slate-50 dark:bg-slate-900">
        {imageUrl ? (
          <img src={imageUrl} alt={item.name ?? ''} className="h-full w-full object-cover" />
        ) : (
          <div className="flex h-full items-center justify-center text-xs text-slate-400">—</div>
        )}
      </div>
      <div className="space-y-1 p-3">
        <p className="admin-text line-clamp-2 text-sm font-semibold">{item.name || item.nameEn || '—'}</p>
        {item.productCode ? (
          <p className="text-xs text-slate-500">{item.productCode}</p>
        ) : null}
        {score != null ? (
          <p className="text-xs font-bold text-indigo-600 dark:text-indigo-400">
            {scoreLabel}:{' '}
            {score.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US', {
              maximumFractionDigits: 3,
            })}
          </p>
        ) : null}
      </div>
    </Link>
  )
}

function TestRunSection({
  run,
  locale,
  t,
}: {
  run: TestRun
  locale: string
  t: (key: string, params?: Record<string, string | number>) => string
}) {
  const scores = run.result?.scores ?? []
  const sortedItems = run.result ? sortedItemsForResult(run.result) : []

  return (
    <article className="rounded-2xl border border-slate-100 p-4 dark:border-slate-700">
      <div className="flex flex-wrap items-start gap-3">
        <img src={run.previewUrl} alt="" className="h-20 w-20 shrink-0 rounded-xl border object-cover" />
        <div className="min-w-0 flex-1">
          <p className="admin-text truncate text-sm font-bold">{run.fileName}</p>
          {run.status === 'loading' ? (
            <p className="mt-1 text-xs text-slate-500">{t('imageSearch.testing')}</p>
          ) : null}
          {run.status === 'error' ? (
            <p className="mt-1 text-xs text-red-600 dark:text-red-400">{run.error}</p>
          ) : null}
          {run.status === 'done' && run.result?.detectedProductName ? (
            <p className="mt-1 text-xs text-slate-600 dark:text-slate-300">
              <span className="font-semibold">{t('imageSearch.detected')}:</span>{' '}
              {run.result.detectedProductName}
            </p>
          ) : null}
        </div>
      </div>

      {run.status === 'done' ? (
        <>
          {(run.result?.referenceMatches?.length ?? 0) > 0 ? (
            <div className="mt-4 space-y-3">
              <p className="text-sm font-semibold text-amber-800 dark:text-amber-200">
                {t('imageSearch.referenceMatchesCount', {
                  count: run.result?.referenceMatches?.length ?? 0,
                })}
              </p>
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                {(run.result?.referenceMatches ?? []).map((ref) => (
                  <ReferenceMatchCard
                    key={`${run.id}-ref-${ref.referenceImageId}`}
                    item={ref}
                    locale={locale}
                    scoreLabel={t('imageSearch.similarity')}
                    noAdLabel={t('imageSearch.noAdYet')}
                  />
                ))}
              </div>
            </div>
          ) : null}
          {sortedItems.length > 0 ? (
            <div className="mt-4 space-y-3">
              <p className="text-sm font-semibold">
                {t('imageSearch.catalogResultsCount', { count: run.result?.count ?? sortedItems.length })}
              </p>
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                {sortedItems.map((item) => (
                  <ResultCard
                    key={`${run.id}-${item.productId}-${item.name}`}
                    item={item}
                    score={scoreForProduct(item.productId ?? '', scores)}
                    locale={locale}
                    scoreLabel={t('imageSearch.similarity')}
                  />
                ))}
              </div>
            </div>
          ) : (run.result?.referenceMatches?.length ?? 0) === 0 ? (
            <p className="mt-3 text-sm text-slate-500">{t('imageSearch.noResults')}</p>
          ) : null}
        </>
      ) : null}
    </article>
  )
}

function ReferenceMatchCard({
  item,
  locale,
  scoreLabel,
  noAdLabel,
}: {
  item: ImageSearchReferenceMatch
  locale: string
  scoreLabel: string
  noAdLabel: string
}) {
  const imageUrl = resolveAssetUrl(item.imagePath)
  return (
    <div className="admin-card overflow-hidden rounded-2xl border border-amber-200 dark:border-amber-900/50">
      <div className="aspect-square bg-slate-50 dark:bg-slate-900">
        {imageUrl ? (
          <img src={imageUrl} alt={item.productName} className="h-full w-full object-cover" />
        ) : (
          <div className="flex h-full items-center justify-center text-xs text-slate-400">—</div>
        )}
      </div>
      <div className="space-y-1 p-3">
        <p className="admin-text line-clamp-2 text-sm font-semibold">{item.productName}</p>
        <p className="text-xs font-medium text-amber-700 dark:text-amber-300">{noAdLabel}</p>
        <p className="text-xs font-bold text-indigo-600 dark:text-indigo-400">
          {scoreLabel}:{' '}
          {item.score.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US', {
            maximumFractionDigits: 3,
          })}
        </p>
      </div>
    </div>
  )
}

export default function ImageSearchPage() {
  const { t, locale } = useAppPreferences()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const referenceInputRef = useRef<HTMLInputElement>(null)
  const [testRuns, setTestRuns] = useState<TestRun[]>([])
  const [isTesting, setIsTesting] = useState(false)
  const [productName, setProductName] = useState('')
  const [productNameAr, setProductNameAr] = useState('')
  const [productCode, setProductCode] = useState('')
  const [refSearch, setRefSearch] = useState('')
  const [appliedRefSearch, setAppliedRefSearch] = useState('')
  const [refPage, setRefPage] = useState(1)
  const [stagedTrainingImages, setStagedTrainingImages] = useState<StagedTrainingImage[]>([])
  const [showTrainedLibrary, setShowTrainedLibrary] = useState(false)
  const canManage = hasPermission(PERMISSIONS.productsManage)

  const { data, error, isLoading, isFetching, refetch } = useGetAdminImageSearchStatusQuery(undefined, {
    pollingInterval: 30_000,
    refetchOnFocus: true,
  })
  const [reindex, reindexState] = useReindexImageVectorsMutation()
  const [uploadReferences, uploadReferencesState] = useUploadClipReferenceImagesMutation()
  const [deleteReference] = useDeleteClipReferenceImageMutation()
  const [reindexReferences, reindexReferencesState] = useReindexClipReferenceImagesMutation()
  const { data: referencePage, refetch: refetchReferences } = useGetClipReferenceImagesQuery(
    {
      page: refPage,
      pageSize: 12,
      search: appliedRefSearch || undefined,
    },
    { skip: !showTrainedLibrary },
  )
  const { showInitialLoader } = queryViewState({ isLoading, isFetching })

  const completedCount = useMemo(
    () => testRuns.filter((run) => run.status === 'done').length,
    [testRuns],
  )

  async function handleReindex() {
    if (!canManage) return
    try {
      await reindex().unwrap()
      refetch()
    } catch {
      // RTK handles error state
    }
  }

  async function handleFilesSelected(files: FileList | null) {
    if (!files?.length) return

    const selected = Array.from(files).filter((file) => file.type.startsWith('image/'))
    if (selected.length === 0) return

    const initialRuns: TestRun[] = selected.map((file) => ({
      id: `${file.name}-${file.lastModified}-${crypto.randomUUID()}`,
      fileName: file.name,
      previewUrl: URL.createObjectURL(file),
      status: 'pending',
    }))

    setTestRuns((prev) => [...initialRuns, ...prev])
    setIsTesting(true)

    for (let i = 0; i < selected.length; i += 1) {
      const file = selected[i]
      const runId = initialRuns[i].id

      setTestRuns((prev) =>
        prev.map((run) => (run.id === runId ? { ...run, status: 'loading' } : run)),
      )

      try {
        const result = await runImageSearchTest(file)
        setTestRuns((prev) =>
          prev.map((run) =>
            run.id === runId ? { ...run, status: 'done', result } : run,
          ),
        )
      } catch (err) {
        setTestRuns((prev) =>
          prev.map((run) =>
            run.id === runId
              ? {
                  ...run,
                  status: 'error',
                  error: err instanceof Error ? err.message : t('imageSearch.testError'),
                }
              : run,
          ),
        )
      }
    }

    setIsTesting(false)
  }

  function clearTestRuns() {
    testRuns.forEach((run) => URL.revokeObjectURL(run.previewUrl))
    setTestRuns([])
  }

  const stagedTrainingRef = useRef(stagedTrainingImages)
  stagedTrainingRef.current = stagedTrainingImages

  useEffect(() => {
    return () => {
      stagedTrainingRef.current.forEach((item) => URL.revokeObjectURL(item.previewUrl))
    }
  }, [])

  function clearStagedTrainingImages() {
    stagedTrainingImages.forEach((item) => URL.revokeObjectURL(item.previewUrl))
    setStagedTrainingImages([])
  }

  function stageReferenceFiles(files: FileList | null) {
    if (!canManage || !files?.length) return
    const selected = Array.from(files).filter((file) => file.type.startsWith('image/'))
    if (selected.length === 0) return

    setStagedTrainingImages((prev) => [
      ...prev,
      ...selected.map((file) => ({
        id: `${file.name}-${file.lastModified}-${crypto.randomUUID()}`,
        file,
        previewUrl: URL.createObjectURL(file),
      })),
    ])
  }

  function removeStagedTrainingImage(id: string) {
    setStagedTrainingImages((prev) => {
      const item = prev.find((row) => row.id === id)
      if (item) URL.revokeObjectURL(item.previewUrl)
      return prev.filter((row) => row.id !== id)
    })
  }

  async function handleReferenceUpload() {
    if (!canManage || stagedTrainingImages.length === 0 || !productName.trim()) return

    try {
      await uploadReferences({
        productName: productName.trim(),
        productNameAr: productNameAr.trim() || undefined,
        productCode: productCode.trim() || undefined,
        files: stagedTrainingImages.map((item) => item.file),
      }).unwrap()
      clearStagedTrainingImages()
      setShowTrainedLibrary(false)
      refetch()
    } catch {
      // RTK error state — keep staged images so the admin can retry
    }
  }

  async function handleDeleteReference(id: number) {
    if (!canManage) return
    try {
      await deleteReference(id).unwrap()
      refetch()
      refetchReferences()
    } catch {
      // RTK error state
    }
  }

  const clipUp = Boolean(data?.clipReachable)
  const qdrantUp = Boolean(data?.qdrantReachable)
  const systemUp = Boolean(data?.enabled) && clipUp && qdrantUp
  const autoIndexOff = data ? !data.autoIndexOnCatalogChanges : false

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="admin-text text-2xl font-bold">{t('imageSearch.title')}</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{t('imageSearch.subtitle')}</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            className="rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
            onClick={() => refetch()}
          >
            {t('imageSearch.refresh')}
          </button>
          {canManage ? (
            <button
              type="button"
              className="rounded-xl bg-indigo-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
              disabled={reindexState.isLoading}
              onClick={() => void handleReindex()}
            >
              {reindexState.isLoading ? t('imageSearch.reindexing') : t('imageSearch.reindexAll')}
            </button>
          ) : null}
        </div>
      </header>

      <div className="admin-card rounded-2xl border border-indigo-100 bg-indigo-50/60 p-4 text-sm leading-relaxed text-indigo-950 dark:border-indigo-900/50 dark:bg-indigo-950/20 dark:text-indigo-100">
        {t('imageSearch.howItWorks')}
      </div>

      {autoIndexOff ? (
        <div className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900 dark:border-amber-900/50 dark:bg-amber-950/30 dark:text-amber-100">
          {t('imageSearch.autoIndexPaused')}
        </div>
      ) : null}

      {showInitialLoader ? (
        <p className="text-sm text-slate-500">{t('imageSearch.loading')}</p>
      ) : error ? (
        <p className="rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700 dark:bg-red-950/30 dark:text-red-300">
          {getRtkErrorMessage(error, t('imageSearch.loadError'))}
        </p>
      ) : data ? (
        <>
          <div className="flex flex-wrap gap-2">
            <StatusPill
              label={`${t('imageSearch.clipService')}: ${clipUp ? t('imageSearch.up') : t('imageSearch.down')}`}
              up={clipUp}
            />
            <StatusPill
              label={`${t('imageSearch.qdrant')}: ${qdrantUp ? t('imageSearch.up') : t('imageSearch.down')}`}
              up={qdrantUp}
            />
            <StatusPill
              label={`${t('imageSearch.pipeline')}: ${systemUp ? t('imageSearch.ready') : t('imageSearch.notReady')}`}
              up={systemUp}
            />
            <StatusPill
              label={`${t('imageSearch.autoIndex')}: ${data.autoIndexOnCatalogChanges ? t('imageSearch.on') : t('imageSearch.off')}`}
              up={data.autoIndexOnCatalogChanges}
            />
          </div>

          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            <StatCard
              title={t('imageSearch.totalImages')}
              value={data.totalProductImages.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US')}
            />
            <StatCard
              title={t('imageSearch.referenceImages')}
              value={data.referenceImageCount.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US')}
            />
            <StatCard
              title={t('imageSearch.indexedVectors')}
              value={data.qdrantPointsCount.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US')}
            />
            <StatCard
              title={t('imageSearch.coverage')}
              value={`${data.indexedCoveragePercent}%`}
            />
            <StatCard title={t('imageSearch.vectorDim')} value={String(data.vectorSize || data.clipVectorDim || '—')} />
          </div>

          <div className="admin-card rounded-2xl p-4 text-sm text-slate-600 dark:text-slate-300">
            <p>
              <span className="font-semibold">{t('imageSearch.collection')}:</span> {data.qdrantCollection || '—'}
            </p>
            {data.clipModel ? (
              <p className="mt-1">
                <span className="font-semibold">{t('imageSearch.model')}:</span> {data.clipModel}
              </p>
            ) : null}
            {reindexState.data?.enqueued != null ? (
              <p className="mt-2 font-semibold text-emerald-700 dark:text-emerald-300">
                {t('imageSearch.reindexQueued', { count: reindexState.data.enqueued })}
              </p>
            ) : null}
          </div>
        </>
      ) : null}

      {canManage ? (
        <section className="admin-card space-y-4 rounded-2xl p-5">
          <div>
            <h2 className="admin-text text-lg font-bold">{t('imageSearch.referenceTitle')}</h2>
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
              {t('imageSearch.referenceSubtitle')}
            </p>
          </div>

          <div className="grid gap-3 md:grid-cols-3">
            <input
              className="admin-input rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
              placeholder={t('imageSearch.productNameEn')}
              value={productName}
              onChange={(e) => setProductName(e.target.value)}
            />
            <input
              className="admin-input rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
              placeholder={t('imageSearch.productNameAr')}
              value={productNameAr}
              onChange={(e) => setProductNameAr(e.target.value)}
            />
            <input
              className="admin-input rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
              placeholder={t('imageSearch.productCodeOptional')}
              value={productCode}
              onChange={(e) => setProductCode(e.target.value)}
            />
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <input
              ref={referenceInputRef}
              type="file"
              multiple
              accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp"
              className="hidden"
              onChange={(e) => {
                stageReferenceFiles(e.target.files)
                e.target.value = ''
              }}
            />
            <button
              type="button"
              className="rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
              disabled={uploadReferencesState.isLoading}
              onClick={() => referenceInputRef.current?.click()}
            >
              {t('imageSearch.selectTrainingImages')}
            </button>
            <button
              type="button"
              className="rounded-xl bg-indigo-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
              disabled={
                uploadReferencesState.isLoading ||
                !productName.trim() ||
                stagedTrainingImages.length === 0
              }
              onClick={() => void handleReferenceUpload()}
            >
              {uploadReferencesState.isLoading
                ? t('imageSearch.uploadingReferences')
                : t('imageSearch.trainNow')}
            </button>
            {stagedTrainingImages.length > 0 ? (
              <button
                type="button"
                className="rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
                disabled={uploadReferencesState.isLoading}
                onClick={clearStagedTrainingImages}
              >
                {t('imageSearch.clearStaged')}
              </button>
            ) : null}
            <button
              type="button"
              className="rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
              disabled={reindexReferencesState.isLoading}
              onClick={() => void reindexReferences()}
            >
              {reindexReferencesState.isLoading
                ? t('imageSearch.reindexing')
                : t('imageSearch.reindexReferences')}
            </button>
          </div>

          {stagedTrainingImages.length > 0 ? (
            <div className="space-y-2">
              <p className="text-xs text-slate-500 dark:text-slate-400">
                {t('imageSearch.stagedImagesHint', { count: stagedTrainingImages.length })}
              </p>
              <div className="grid grid-cols-3 gap-3 sm:grid-cols-4 md:grid-cols-6 xl:grid-cols-8">
                {stagedTrainingImages.map((item) => (
                  <div key={item.id} className="relative overflow-hidden rounded-xl border border-slate-200 dark:border-slate-700">
                    <img
                      src={item.previewUrl}
                      alt={item.file.name}
                      className="aspect-square w-full object-cover"
                    />
                    <button
                      type="button"
                      className="absolute end-1 top-1 rounded-full bg-black/70 px-2 py-0.5 text-[11px] font-semibold text-white"
                      disabled={uploadReferencesState.isLoading}
                      onClick={() => removeStagedTrainingImage(item.id)}
                    >
                      {t('imageSearch.removeStaged')}
                    </button>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <p className="text-xs text-slate-500 dark:text-slate-400">{t('imageSearch.noStagedImages')}</p>
          )}

          {uploadReferencesState.error ? (
            <p className="text-sm text-red-600">
              {getRtkErrorMessage(uploadReferencesState.error, t('imageSearch.uploadReferencesError'))}
            </p>
          ) : null}
          {uploadReferencesState.data ? (
            <p className="text-sm font-semibold text-emerald-700 dark:text-emerald-300">
              {t('imageSearch.uploadReferencesSuccess', {
                count: uploadReferencesState.data.uploaded,
                name: uploadReferencesState.data.productName,
              })}
            </p>
          ) : null}

          <button
            type="button"
            className="rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
            onClick={() => setShowTrainedLibrary((open) => !open)}
          >
            {showTrainedLibrary
              ? t('imageSearch.hideTrainedLibrary')
              : t('imageSearch.showTrainedLibrary', {
                  count: referencePage?.totalCount ?? data?.referenceImageCount ?? 0,
                })}
          </button>

          {showTrainedLibrary ? (
            <>
              <div className="flex flex-wrap gap-2">
                <input
                  className="admin-input min-w-[200px] flex-1 rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
                  placeholder={t('imageSearch.searchReferences')}
                  value={refSearch}
                  onChange={(e) => setRefSearch(e.target.value)}
                />
                <button
                  type="button"
                  className="rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
                  onClick={() => {
                    setAppliedRefSearch(refSearch.trim())
                    setRefPage(1)
                  }}
                >
                  {t('imageSearch.search')}
                </button>
              </div>

              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                {(referencePage?.items ?? []).map((item) => (
                  <div
                    key={item.id}
                    className="admin-card overflow-hidden rounded-2xl border border-slate-100 dark:border-slate-700"
                  >
                    <div className="aspect-square bg-slate-50 dark:bg-slate-900">
                      <img
                        src={resolveAssetUrl(item.imagePath)}
                        alt={item.productName}
                        className="h-full w-full object-cover"
                      />
                    </div>
                    <div className="space-y-1 p-3">
                      <p className="admin-text line-clamp-2 text-sm font-semibold">{item.productName}</p>
                      {item.productNameAr ? (
                        <p className="text-xs text-slate-500">{item.productNameAr}</p>
                      ) : null}
                      <button
                        type="button"
                        className="text-xs font-semibold text-red-600 dark:text-red-400"
                        onClick={() => void handleDeleteReference(item.id)}
                      >
                        {t('imageSearch.deleteReference')}
                      </button>
                    </div>
                  </div>
                ))}
              </div>

              {(referencePage?.totalPages ?? 1) > 1 ? (
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    className="rounded-lg border px-3 py-1 text-sm disabled:opacity-50"
                    disabled={refPage <= 1}
                    onClick={() => setRefPage((p) => Math.max(1, p - 1))}
                  >
                    {t('imageSearch.prev')}
                  </button>
                  <span className="text-sm text-slate-500">
                    {refPage} / {referencePage?.totalPages ?? 1}
                  </span>
                  <button
                    type="button"
                    className="rounded-lg border px-3 py-1 text-sm disabled:opacity-50"
                    disabled={refPage >= (referencePage?.totalPages ?? 1)}
                    onClick={() => setRefPage((p) => p + 1)}
                  >
                    {t('imageSearch.next')}
                  </button>
                </div>
              ) : null}
            </>
          ) : null}
        </section>
      ) : null}

      <section className="admin-card space-y-4 rounded-2xl p-5">
        <div>
          <h2 className="admin-text text-lg font-bold">{t('imageSearch.testTitle')}</h2>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{t('imageSearch.testSubtitleMulti')}</p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <input
            ref={fileInputRef}
            type="file"
            multiple
            accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp"
            className="hidden"
            onChange={(e) => {
              void handleFilesSelected(e.target.files)
              e.target.value = ''
            }}
          />
          <button
            type="button"
            className="rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white dark:bg-slate-100 dark:text-slate-900"
            disabled={isTesting}
            onClick={() => fileInputRef.current?.click()}
          >
            {isTesting ? t('imageSearch.testing') : t('imageSearch.uploadTestMulti')}
          </button>
          {testRuns.length > 0 ? (
            <button
              type="button"
              className="rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
              onClick={clearTestRuns}
            >
              {t('imageSearch.clearTests')}
            </button>
          ) : null}
          {testRuns.length > 0 ? (
            <span className="text-xs text-slate-500">
              {t('imageSearch.testProgress', {
                done: completedCount,
                total: testRuns.length,
              })}
            </span>
          ) : null}
        </div>

        {testRuns.length > 0 ? (
          <div className="space-y-4">
            {testRuns.map((run) => (
              <TestRunSection key={run.id} run={run} locale={locale} t={t} />
            ))}
          </div>
        ) : null}
      </section>

      <section className="admin-card rounded-2xl p-5 text-sm text-slate-600 dark:text-slate-300">
        <h2 className="admin-text mb-2 text-lg font-bold">{t('imageSearch.addImagesTitle')}</h2>
        <p className="leading-relaxed">{t('imageSearch.addImagesBodyReference')}</p>
        <Link to="/ads" className="mt-3 inline-block font-semibold text-indigo-600 dark:text-indigo-400">
          {t('imageSearch.goToAds')} →
        </Link>
      </section>
    </div>
  )
}
