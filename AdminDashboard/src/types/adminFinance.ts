export type AdminFinanceWithdrawal = {
  id: string
  amount: number
  statusId: number
  statusNameEn: string
  statusNameAr: string
  supplierId: string
  supplierName: string
  supplierCompanyName: string | null
  supplierEmail: string | null
  supplierPhone: string | null
  ibanSnapshot: string
  accountHolderNameSnapshot: string | null
  bankNameSnapshot: string | null
  notes: string | null
  requestedAtUtc: string
  completedAtUtc: string | null
}

export type AdminFinanceWithdrawalsResponse = {
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  items: AdminFinanceWithdrawal[]
}

export type AdminCompanyFinanceProfile = {
  userId: string
  fullName: string
  companyName: string | null
  email: string
  phoneNumber: string | null
  landNumber: string | null
  balance: number
  adsCount: number
  imgPath: string | null
  companyImage: string | null
  ibans: Array<{
    id: string
    iban: string
    accountHolderName: string | null
    bankName: string | null
    isDefault: boolean
  }>
}

export type AdminBalanceStatementItem = {
  id: string
  orderId: number | null
  amount: number
  entryType: number
  entryTypeNameEn: string
  entryTypeNameAr: string
  reasonEn: string | null
  reasonAr: string | null
  createdAtUtc: string
  source: string
}

export type AdminBalanceStatementResponse = {
  balance: number
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  items: AdminBalanceStatementItem[]
}
