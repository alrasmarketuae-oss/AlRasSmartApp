import { resolveAssetUrl } from '../../lib/assets'
import type { AdminPendingProductEdit } from '../../types/adminProduct'
import { useAppPreferences } from '../../context/AppPreferencesProvider'

function displayOrDash(value: string | number | null | undefined): string {
  if (value == null) return '—'
  const text = String(value).trim()
  return text ? text : '—'
}

function FieldDiffRow({
  label,
  previous,
  proposed,
  previousLabel,
  proposedLabel,
  alwaysShow = false,
}: {
  label: string
  previous: string | number | null | undefined
  proposed: string | number | null | undefined
  previousLabel: string
  proposedLabel: string
  alwaysShow?: boolean
}) {
  const prev = displayOrDash(previous)
  const next = displayOrDash(proposed)
  if (!alwaysShow && prev === next) return null
  return (
    <div className="rounded-xl border border-amber-200 bg-amber-50/60 p-3 dark:border-amber-800/50 dark:bg-amber-950/20">
      <p className="admin-text mb-2 text-sm font-semibold">{label}</p>
      <div className="grid gap-2 sm:grid-cols-2">
        <div>
          <p className="admin-text-subtle text-xs">{previousLabel}</p>
          <p className="admin-text mt-1 text-sm">{prev}</p>
        </div>
        <div>
          <p className="admin-text-subtle text-xs">{proposedLabel}</p>
          <p className="admin-text mt-1 text-sm font-semibold text-[#B54708]">{next}</p>
        </div>
      </div>
    </div>
  )
}

function ImageCompareStrip({
  title,
  paths,
}: {
  title: string
  paths: string[]
}) {
  if (paths.length === 0) {
    return (
      <div>
        <p className="admin-text-subtle mb-2 text-xs font-semibold uppercase tracking-wide">{title}</p>
        <p className="admin-text-muted text-sm">—</p>
      </div>
    )
  }

  return (
    <div>
      <p className="admin-text-subtle mb-2 text-xs font-semibold uppercase tracking-wide">{title}</p>
      <div className="flex flex-wrap gap-2">
        {paths.map((path) => {
          const url = resolveAssetUrl(path)
          return (
            <a
              key={path}
              href={url || undefined}
              target="_blank"
              rel="noreferrer"
              className="block h-20 w-20 overflow-hidden rounded-xl bg-slate-100 ring-1 ring-slate-200"
            >
              {url ? (
                <img src={url} alt="" className="h-full w-full object-cover" />
              ) : (
                <span className="block h-full w-full bg-slate-200" />
              )}
            </a>
          )
        })}
      </div>
    </div>
  )
}

export default function PendingProductEditPanel({
  pendingEdit,
}: {
  pendingEdit: AdminPendingProductEdit
}) {
  const { t, locale } = useAppPreferences()
  const previousLabel = t('ads.previousValue')
  const proposedLabel = t('ads.proposedValue')

  const pricePrev = `${pendingEdit.previousPrice} ${pendingEdit.previousCurrency ?? ''}`.trim()
  const priceNext = `${pendingEdit.proposedPrice} ${pendingEdit.proposedCurrency ?? ''}`.trim()

  return (
    <section className="rounded-2xl border border-amber-200 bg-amber-50/40 p-4 sm:p-5 dark:border-amber-800/50 dark:bg-amber-950/30">
      <h2 className="text-sm font-bold text-amber-900 dark:text-amber-200">
        {t('ads.editAdRequest')}
      </h2>
      <p className="mt-1 text-xs leading-relaxed text-amber-800 dark:text-amber-300/90">
        {t('ads.editAdCompareHint')}
      </p>

      <div className="mt-4 grid gap-4 lg:grid-cols-2">
        <ImageCompareStrip title={previousLabel} paths={pendingEdit.previousImagePaths} />
        <ImageCompareStrip title={proposedLabel} paths={pendingEdit.proposedImagePaths} />
      </div>

      {(pendingEdit.previousVideoPath || pendingEdit.proposedVideoPath) &&
      (pendingEdit.previousVideoPath ?? '') !== (pendingEdit.proposedVideoPath ?? '') ? (
        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          <div>
            <p className="admin-text-subtle mb-2 text-xs font-semibold uppercase tracking-wide">
              {locale === 'ar' ? 'فيديو سابق' : 'Previous video'}
            </p>
            {pendingEdit.previousVideoPath ? (
              <video
                controls
                className="aspect-video w-full rounded-xl bg-black object-contain"
                src={resolveAssetUrl(pendingEdit.previousVideoPath) ?? undefined}
              />
            ) : (
              <p className="admin-text-muted text-sm">—</p>
            )}
          </div>
          <div>
            <p className="admin-text-subtle mb-2 text-xs font-semibold uppercase tracking-wide">
              {locale === 'ar' ? 'فيديو مقترح' : 'Proposed video'}
            </p>
            {pendingEdit.proposedVideoPath ? (
              <video
                controls
                className="aspect-video w-full rounded-xl bg-black object-contain"
                src={resolveAssetUrl(pendingEdit.proposedVideoPath) ?? undefined}
              />
            ) : (
              <p className="admin-text-muted text-sm">—</p>
            )}
          </div>
        </div>
      ) : null}

      <div className="mt-4 space-y-3">
        <FieldDiffRow
          label={t('ads.productName')}
          previous={pendingEdit.previousName}
          proposed={pendingEdit.proposedName}
          previousLabel={previousLabel}
          proposedLabel={proposedLabel}
        />
        <FieldDiffRow
          label={t('ads.productDescription')}
          previous={pendingEdit.previousDescription}
          proposed={pendingEdit.proposedDescription}
          previousLabel={previousLabel}
          proposedLabel={proposedLabel}
        />
        <FieldDiffRow
          label={t('ads.price')}
          previous={pricePrev}
          proposed={priceNext}
          previousLabel={previousLabel}
          proposedLabel={proposedLabel}
        />
        <FieldDiffRow
          label={t('ads.quantity')}
          previous={pendingEdit.previousQuantity}
          proposed={pendingEdit.proposedQuantity}
          previousLabel={previousLabel}
          proposedLabel={proposedLabel}
        />
      </div>
    </section>
  )
}
