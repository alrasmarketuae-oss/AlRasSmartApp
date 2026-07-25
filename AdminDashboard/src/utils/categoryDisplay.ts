import type { Category } from '../types/category'

export function categoryDisplayName(
  category: Pick<Category, 'nameEn'> & { nameAr?: string },
  locale: 'ar' | 'en',
): string {
  const nameAr = category.nameAr?.trim() ?? ''
  const nameEn = category.nameEn?.trim() ?? ''
  if (locale === 'ar' && nameAr.length > 0) {
    return nameAr
  }
  return nameEn
}

export function categoryDisplaySubtitle(
  category: Pick<Category, 'nameEn'> & { nameAr?: string },
  locale: 'ar' | 'en',
): string {
  const primary = categoryDisplayName(category, locale)
  const secondary = locale === 'ar' ? category.nameEn.trim() : (category.nameAr?.trim() ?? '')
  if (!secondary || secondary === primary) {
    return ''
  }
  return secondary
}
