export type HomeBanner = {
  id: number
  imagePath: string
  linkUrl: string
  displayOrder: number
}

export type HomeBannersResponse = {
  count: number
  items: HomeBanner[]
}
