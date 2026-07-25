export type Category = {
  categoryId: number
  nameEn: string
  nameAr: string
  imgPath: string
  commissionPercent: number
  /** When true, category is hidden from the mobile app. */
  isHide: boolean
}

export type CategoriesResponse = {
  count: number
  items: Category[]
}
