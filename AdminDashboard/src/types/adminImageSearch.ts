export type AdminImageSearchStatus = {
  enabled: boolean
  clipConfigured: boolean
  clipReachable: boolean
  clipModel: string | null
  clipVectorDim: number | null
  qdrantReachable: boolean
  qdrantPointsCount: number
  qdrantCollection: string
  vectorSize: number
  totalProductImages: number
  indexedCoveragePercent: number
  autoIndexOnCatalogChanges: boolean
  referenceImageCount: number
}

export type ImageSearchReferenceMatch = {
  referenceImageId: number
  productName: string
  imagePath?: string
  score: number
  isReference?: boolean
}

export type ClipReferenceImageItem = {
  id: number
  productName: string
  productNameAr?: string | null
  productCode?: string | null
  imagePath: string
  createdAtUtc: string
}

export type ClipReferenceImagesPage = {
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  items: ClipReferenceImageItem[]
}

export type ImageSearchTestScore = {
  productId: string
  score: number
}

export type ImageSearchTestProduct = {
  productId?: string
  name?: string
  nameEn?: string
  primaryImagePath?: string
  images?: string[]
  productCode?: string
}

export type ImageSearchTestResult = {
  detectedProductName?: string
  suggestedNames?: string[]
  count?: number
  items?: ImageSearchTestProduct[]
  scores?: ImageSearchTestScore[]
  referenceMatches?: ImageSearchReferenceMatch[]
  referenceCount?: number
  searchMode?: string
}

export function normalizeImageSearchStatus(raw: Record<string, unknown>): AdminImageSearchStatus {
  return {
    enabled: Boolean(raw.enabled ?? raw.Enabled),
    clipConfigured: Boolean(raw.clipConfigured ?? raw.ClipConfigured),
    clipReachable: Boolean(raw.clipReachable ?? raw.ClipReachable),
    clipModel: (raw.clipModel ?? raw.ClipModel ?? null) as string | null,
    clipVectorDim: (raw.clipVectorDim ?? raw.ClipVectorDim ?? null) as number | null,
    qdrantReachable: Boolean(raw.qdrantReachable ?? raw.QdrantReachable),
    qdrantPointsCount: Number(raw.qdrantPointsCount ?? raw.QdrantPointsCount ?? 0),
    qdrantCollection: String(raw.qdrantCollection ?? raw.QdrantCollection ?? ''),
    vectorSize: Number(raw.vectorSize ?? raw.VectorSize ?? 0),
    totalProductImages: Number(raw.totalProductImages ?? raw.TotalProductImages ?? 0),
    indexedCoveragePercent: Number(raw.indexedCoveragePercent ?? raw.IndexedCoveragePercent ?? 0),
    autoIndexOnCatalogChanges: Boolean(
      raw.autoIndexOnCatalogChanges ?? raw.AutoIndexOnCatalogChanges ?? true,
    ),
    referenceImageCount: Number(raw.referenceImageCount ?? raw.ReferenceImageCount ?? 0),
  }
}

export function normalizeClipReferenceImageItem(raw: Record<string, unknown>): ClipReferenceImageItem {
  return {
    id: Number(raw.id ?? raw.Id ?? 0),
    productName: String(raw.productName ?? raw.ProductName ?? ''),
    productNameAr: (raw.productNameAr ?? raw.ProductNameAr ?? null) as string | null,
    productCode: (raw.productCode ?? raw.ProductCode ?? null) as string | null,
    imagePath: String(raw.imagePath ?? raw.ImagePath ?? ''),
    createdAtUtc: String(raw.createdAtUtc ?? raw.CreatedAtUtc ?? ''),
  }
}

export function normalizeClipReferenceImagesPage(raw: Record<string, unknown>): ClipReferenceImagesPage {
  const itemsRaw = (raw.items ?? raw.Items) as unknown[] | undefined
  return {
    page: Number(raw.page ?? raw.Page ?? 1),
    pageSize: Number(raw.pageSize ?? raw.PageSize ?? 20),
    totalCount: Number(raw.totalCount ?? raw.TotalCount ?? 0),
    totalPages: Number(raw.totalPages ?? raw.TotalPages ?? 1),
    items: (itemsRaw ?? []).map((item) =>
      normalizeClipReferenceImageItem(item as Record<string, unknown>),
    ),
  }
}

export function normalizeImageSearchTestResult(raw: Record<string, unknown>): ImageSearchTestResult {
  const itemsRaw = (raw.items ?? raw.Items) as unknown[] | undefined
  const scoresRaw = (raw.scores ?? raw.Scores) as Record<string, unknown>[] | undefined
  const refRaw = (raw.referenceMatches ?? raw.ReferenceMatches) as unknown[] | undefined

  return {
    detectedProductName: String(raw.detectedProductName ?? raw.DetectedProductName ?? ''),
    suggestedNames: ((raw.suggestedNames ?? raw.SuggestedNames) as string[] | undefined) ?? [],
    count: Number(raw.count ?? raw.Count ?? 0),
    referenceCount: Number(raw.referenceCount ?? raw.ReferenceCount ?? 0),
    searchMode: String(raw.searchMode ?? raw.SearchMode ?? ''),
    referenceMatches: (refRaw ?? []).map((item) => {
      const row = item as Record<string, unknown>
      return {
        referenceImageId: Number(row.referenceImageId ?? row.ReferenceImageId ?? 0),
        productName: String(row.productName ?? row.ProductName ?? ''),
        imagePath: String(row.imagePath ?? row.ImagePath ?? ''),
        score: Number(row.score ?? row.Score ?? 0),
        isReference: Boolean(row.isReference ?? row.IsReference ?? true),
      }
    }),
    items: (itemsRaw ?? []).map((item) => {
      const row = item as Record<string, unknown>
      const images = (row.images ?? row.Images) as string[] | undefined
      return {
        productId: String(row.productId ?? row.ProductId ?? ''),
        name: String(row.name ?? row.Name ?? row.nameEn ?? row.NameEn ?? ''),
        nameEn: String(row.nameEn ?? row.NameEn ?? row.name ?? row.Name ?? ''),
        primaryImagePath: (row.primaryImagePath ?? row.PrimaryImagePath ?? images?.[0] ?? null) as
          | string
          | undefined,
        images,
        productCode: String(row.productCode ?? row.ProductCode ?? ''),
      }
    }),
    scores: (scoresRaw ?? []).map((row) => ({
      productId: String(row.productId ?? row.ProductId ?? ''),
      score: Number(row.score ?? row.Score ?? 0),
    })),
  }
}
