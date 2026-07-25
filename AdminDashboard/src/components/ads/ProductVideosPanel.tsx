import { resolveAssetUrl } from '../../lib/assets'

type ProductVideosPanelProps = {
  videoPaths: string[]
  selectedIndex: number
  onSelectedIndexChange: (index: number) => void
  isVideoMuted: boolean
  onMuteChange: (muted: boolean) => void
  muteLabel: string
  muteHint?: string
  emptyLabel: string
  isBusy?: boolean
  className?: string
  videoClassName?: string
  onDeleteVideo?: (path: string) => void
  deleteLabel?: string
  deletingPath?: string | null
}

/** Single video player with prev/next — avoids stacking one &lt;video&gt; per path. */
export default function ProductVideosPanel({
  videoPaths,
  selectedIndex,
  onSelectedIndexChange,
  isVideoMuted,
  onMuteChange,
  muteLabel,
  muteHint,
  emptyLabel,
  isBusy = false,
  className = 'space-y-2 px-2.5 py-2',
  videoClassName = 'max-h-40 w-full rounded-lg bg-black',
  onDeleteVideo,
  deleteLabel = 'Delete video',
  deletingPath = null,
}: ProductVideosPanelProps) {
  if (videoPaths.length === 0) {
    return (
      <div className={className}>
        <p className="py-4 text-center text-[10px] text-slate-400">{emptyLabel}</p>
      </div>
    )
  }

  const safeIndex =
    selectedIndex >= 0 && selectedIndex < videoPaths.length ? selectedIndex : 0
  const activePath = videoPaths[safeIndex]
  const activeUrl = resolveAssetUrl(activePath)
  const count = videoPaths.length
  const isDeleting = Boolean(deletingPath && deletingPath === activePath)

  function go(delta: number) {
    if (count <= 1) return
    onSelectedIndexChange((safeIndex + delta + count) % count)
  }

  return (
    <div className={className}>
      {activeUrl ? (
        <video
          key={activePath}
          controls
          muted={isVideoMuted}
          preload="metadata"
          className={videoClassName}
          src={activeUrl}
        />
      ) : null}

      {count > 1 ? (
        <div className="flex items-center justify-between gap-2">
          <button
            type="button"
            disabled={isBusy || isDeleting}
            onClick={() => go(-1)}
            className="rounded border border-slate-200 px-2 py-1 text-[11px] font-bold text-slate-700 disabled:opacity-50"
            aria-label="Previous video"
          >
            ‹
          </button>
          <span className="text-[11px] font-semibold text-slate-600">
            {safeIndex + 1} / {count}
          </span>
          <button
            type="button"
            disabled={isBusy || isDeleting}
            onClick={() => go(1)}
            className="rounded border border-slate-200 px-2 py-1 text-[11px] font-bold text-slate-700 disabled:opacity-50"
            aria-label="Next video"
          >
            ›
          </button>
        </div>
      ) : null}

      {onDeleteVideo ? (
        <button
          type="button"
          disabled={isBusy || isDeleting}
          onClick={() => {
            if (!window.confirm(deleteLabel + '?')) return
            onDeleteVideo(activePath)
          }}
          className="rounded border border-red-200 bg-red-50 px-2.5 py-1.5 text-[11px] font-bold text-red-700 disabled:opacity-50"
        >
          {isDeleting ? '…' : deleteLabel}
        </button>
      ) : null}

      <label className="flex items-start gap-2 text-start">
        <input
          type="checkbox"
          checked={isVideoMuted}
          disabled={isBusy || isDeleting}
          onChange={(e) => onMuteChange(e.target.checked)}
          className="mt-0.5"
        />
        <span>
          <span className="block text-[11px] font-bold text-slate-900">{muteLabel}</span>
          {muteHint ? (
            <span className="text-[10px] font-normal text-slate-500">{muteHint}</span>
          ) : null}
        </span>
      </label>
    </div>
  )
}

export function resolveProductVideoPaths(product: {
  videoPaths?: string[] | null
  videoPath?: string | null
}): string[] {
  const fromList = (product.videoPaths ?? [])
    .map((p) => p?.trim())
    .filter((p): p is string => Boolean(p))
  if (fromList.length > 0) {
    const seen = new Set<string>()
    const unique: string[] = []
    for (const path of fromList) {
      const key = path.toLowerCase()
      if (seen.has(key)) continue
      seen.add(key)
      unique.push(path)
    }
    return unique
  }
  const primary = product.videoPath?.trim()
  return primary ? [primary] : []
}
