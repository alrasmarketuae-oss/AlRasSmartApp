import { resolveAssetUrl } from '../../lib/assets'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { HomeBanner } from '../../types/banner'

type BannerCardProps = {
  banner: HomeBanner
  isDeleting?: boolean
  onEdit: (banner: HomeBanner) => void
  onDelete: (banner: HomeBanner) => void
}

export default function BannerCard({
  banner,
  isDeleting = false,
  onEdit,
  onDelete,
}: BannerCardProps) {
  const { t } = useAppPreferences()

  return (
    <article className="admin-card overflow-hidden rounded-xl border shadow-sm">
      <div className="admin-surface-muted relative flex h-36 items-center justify-center sm:h-40">
        {banner.imagePath ? (
          <img
            src={resolveAssetUrl(banner.imagePath)}
            alt={t('banners.bannerAlt')}
            className="h-full w-full object-cover"
          />
        ) : (
          <div className="admin-text-subtle px-2 text-center text-xs">{t('banners.noImage')}</div>
        )}
        <span className="absolute start-2 top-2 rounded-full bg-black/55 px-2 py-0.5 text-[10px] font-semibold text-white">
          #{banner.displayOrder}
        </span>
      </div>

      <div className="space-y-2 p-3">
        <p className="admin-text-muted truncate text-xs" title={banner.linkUrl}>
          {banner.linkUrl || '—'}
        </p>
        <div className="flex flex-wrap items-center gap-3">
          <button
            type="button"
            onClick={() => onEdit(banner)}
            className="text-xs font-semibold text-[#3B7FC7] hover:underline"
          >
            {t('banners.edit')}
          </button>
          <button
            type="button"
            onClick={() => onDelete(banner)}
            disabled={isDeleting}
            className="text-xs font-semibold text-red-600 hover:underline disabled:opacity-60"
          >
            {isDeleting ? t('banners.deleting') : t('banners.delete')}
          </button>
        </div>
      </div>
    </article>
  )
}
