export type StatMetric = {
  value: number
  changePercent: number
  sparkline?: number[]
}

export type SalesMetric = {
  value: number
  formatted: string
  changePercent: number
  sparkline?: number[]
}

export type MonthlyProfitPoint = {
  month: string
  monthAr: string
  value: number
}

export type RecentOrder = {
  id: number
  customerName: string
  supplierName: string
  statusId: number
  statusName: string
  statusLabelAr: string
  totalPrice: number
  amountFormatted: string
  createdAt: string
}

export type RecentUser = {
  id: string
  fullName: string
  email: string
  phoneNumber?: string | null
  roleName: string
  roleLabelAr: string
  createdAt: string
  imgPath: string | null
}

export type ActivityItem = {
  type: string
  title: string
  createdAt: string
  timeAgo: string
}

export type DashboardSummary = {
  pendingCompanies: number
  totalProducts: number
  totalOffers: number
  unreadNotifications: number
}

export type DashboardInsights = {
  avgOrderValue: number
  avgOrderValueFormatted: string
  conversionRate: number
  pendingOrders: number
  growthRate: number
}

export type SalesSummary = {
  totalSales: number
  totalSalesFormatted: string
  thisMonth: number
  thisMonthFormatted: string
  growthPercent: number
}

export type DashboardData = {
  stats: {
    totalUsers: StatMetric
    activeSuppliers: StatMetric
    monthlyOrders: StatMetric
    totalSales: SalesMetric
  }
  monthlyProfits: MonthlyProfitPoint[]
  recentOrders: RecentOrder[]
  recentUsers: RecentUser[]
  recentActivity: ActivityItem[]
  summary: DashboardSummary
  insights: DashboardInsights
  salesSummary: SalesSummary
}
