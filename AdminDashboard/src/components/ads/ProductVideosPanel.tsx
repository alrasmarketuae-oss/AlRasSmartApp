import { resolveAssetUrl } from '../../lib/assets'

type ProductVideosPanelProps = {
  videos: { path: string; isMuted?: boolean }[]
  selectedIndex: number
  onSelectedIndexChange: (index: number) => void
  onMuteChange: (path: string, muted: boolean) => void
  muteLabel: string
  muteHint?: string
  emptyLabel: string
  isBusy?: boolean
  className?: string
  videoClassName?: string
  onDeleteVideo?: (path: string) => void
  deleteLabel?: string
  deletingPath?: string | null
  onTrimVideo?: (path: string) => void
  trimLabel?: string
  trimmingPath?: string | null
}

/** Single video player with prev/next — avoids stacking one &lt;video&gt; per path. */
export default function ProductVideosPanel({
  videos,
  selectedIndex,
  onSelectedIndexChange,
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
  onTrimVideo,
  trimLabel = 'Trim video',
  trimmingPath = null,
}: ProductVideosPanelProps) {
  if (videos.length === 0) {
    return (
      <div className={className}>
        <p className="py-4 text-center text-[10px] text-slate-400">{emptyLabel}</p>
      </div>
    )
  }

  const safeIndex =
    selectedIndex >= 0 && selectedIndex < videos.length ? selectedIndex : 0
  const activeVideo = videos[safeIndex]
  const activePath = activeVideo.path
  const activeUrl = resolveAssetUrl(activePath)
  const count = videos.length
  const isDeleting = Boolean(deletingPath && deletingPath === activePath)
  const isTrimming = Boolean(trimmingPath && trimmingPath === activePath)
  const actionBusy = isBusy || isDeleting || isTrimming

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
          muted={activeVideo.isMuted ?? true}
          preload="metadata"
          className={videoClassName}
          src={activeUrl}
        />
      ) : null}

      {count > 1 ? (
        <div className="flex items-center justify-between gap-2">
          <button
            type="button"
            disabled={actionBusy}
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
            disabled={actionBusy}
            onClick={() => go(1)}
            className="rounded border border-slate-200 px-2 py-1 text-[11px] font-bold text-slate-700 disabled:opacity-50"
            aria-label="Next video"
          >
            ›
          </button>
        </div>
      ) : null}

      <div className="flex flex-wrap gap-2">
        {onTrimVideo ? (
          <button
            type="button"
            disabled={actionBusy}
            onClick={() => onTrimVideo(activePath)}
            className="rounded border border-slate-200 bg-white px-2.5 py-1.5 text-[11px] font-bold text-slate-700 disabled:opacity-50"
          >
            {isTrimming ? '…' : trimLabel}
          </button>
        ) : null}
        {onDeleteVideo ? (
          <button
            type="button"
            disabled={actionBusy}
            onClick={() => {
              if (!window.confirm(deleteLabel + '?')) return
              onDeleteVideo(activePath)
            }}
            className="rounded border border-red-200 bg-red-50 px-2.5 py-1.5 text-[11px] font-bold text-red-700 disabled:opacity-50"
          >
            {isDeleting ? '…' : deleteLabel}
          </button>
        ) : null}
      </div>

      <label className="flex items-start gap-2 text-start">
        <input
          type="checkbox"
          checked={activeVideo.isMuted ?? true}
          disabled={actionBusy}
          onChange={(e) => onMuteChange(activePath, e.target.checked)}
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
  videos?: { path: string }[] | null
  videoPaths?: string[] | null
  videoPath?: string | null
}): string[] {
  const fromVideos = (product.videos ?? [])
    .map((video) => video.path?.trim())
    .filter((path): path is string => Boolean(path))
  if (fromVideos.length > 0) return fromVideos
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
