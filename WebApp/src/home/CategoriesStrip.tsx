import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useI18n } from '../i18n/I18nProvider'
import { resolveMediaUrl } from '../lib/media'
import { fetchCategories } from '../products/productsApi'
import type { Category } from '../products/types'
import { Icon } from '../ui/Icon'

/** Home strip order (API `nameEn` values), same as the app. */
const HOME_CATEGORY_NAMES = ['Nuts', 'Pulses', 'Herbs', 'Spices', 'Canned', 'Rice', 'Milk', 'Coffee']

export function useCategories() {
  return useQuery({
    queryKey: ['categories'],
    queryFn: fetchCategories,
    staleTime: 10 * 60_000,
    select: (data) => (data?.items ?? []).filter((c) => !c.isHide),
  })
}

export const categoryName = (c: Category, isAr: boolean) => (isAr ? c.nameAr || c.nameEn : c.nameEn || c.nameAr) || ''

export function CategoryTile({ category, label }: { category?: Category; label: string }) {
  const [failed, setFailed] = useState(false)
  const src = resolveMediaUrl(category?.imgPath)
  const body = (
    <>
      <div className="aspect-square overflow-hidden bg-[#EEF3FA]">
        {src && !failed ? (
          <img src={src} alt={label} loading="lazy" onError={() => setFailed(true)} className="size-full object-cover transition duration-300 group-hover:scale-105" />
        ) : (
          <div className="grid size-full place-items-center">
            <img src="/assets/logo/brand_mark.png" alt="" className="h-1/3 w-auto opacity-30" />
          </div>
        )}
      </div>
      <p className="truncate px-1 pb-2.5 pt-2 text-center text-xs font-semibold text-title sm:text-sm">{label}</p>
    </>
  )
  const cls = 'group block overflow-hidden rounded-xl border border-line bg-white shadow-[0_2px_8px_rgba(0,0,0,0.07)] transition hover:-translate-y-0.5 hover:border-brand/40'
  if (!category) return <div className={cls}>{body}</div>
  return (
    <Link to={`/category/${category.categoryId}`} className={cls}>
      {body}
    </Link>
  )
}

export function SectionHeader({ title, viewAllTo }: { title: string; viewAllTo?: string }) {
  const { t, isAr } = useI18n()
  return (
    <div className="flex items-center">
      <h2 className="flex-1 text-base font-bold text-title sm:text-lg lg:text-xl">{title}</h2>
      {viewAllTo && (
        <Link to={viewAllTo} className="flex items-center gap-0.5 rounded-lg px-1 py-1 text-[13px] font-medium text-brand hover:underline sm:text-sm">
          {t('viewAll')}
          <Icon name={isAr ? 'chevronLeft' : 'chevronRight'} size={18} />
        </Link>
      )}
    </div>
  )
}

export function CategoriesStrip() {
  const { t, isAr } = useI18n()
  const { data, isPending, isError, refetch } = useCategories()

  if (isPending) {
    return (
      <div className="grid grid-cols-4 gap-2 sm:gap-3 md:grid-cols-8">
        {HOME_CATEGORY_NAMES.map((name) => (
          <div key={name} className="overflow-hidden rounded-xl bg-[#E5E7EB]">
            <div className="shimmer aspect-square" />
            <div className="h-9" />
          </div>
        ))}
      </div>
    )
  }

  if (isError) {
    return (
      <div className="py-3 text-center">
        <button type="button" onClick={() => void refetch()} className="text-sm font-semibold text-brand">
          {t('retry')}
        </button>
      </div>
    )
  }

  const byName = new Map((data ?? []).map((c) => [c.nameEn?.trim().toLowerCase(), c]))

  return (
    <div className="grid grid-cols-4 gap-2 gap-y-2.5 sm:gap-3 md:grid-cols-8">
      {HOME_CATEGORY_NAMES.map((name) => {
        const category = byName.get(name.toLowerCase())
        return <CategoryTile key={name} category={category} label={category ? categoryName(category, isAr) : name} />
      })}
    </div>
  )
}
