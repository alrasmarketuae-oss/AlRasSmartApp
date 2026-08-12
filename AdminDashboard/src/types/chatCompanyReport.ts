export type ChatCompanyReportMessage = {
  sender: 'customer' | 'support'
  content: string
  messageType: string
  sentAtUtc: string
}

export type ChatCompanyReport = {
  companyName: string
  contactFullName: string | null
  companyImageUrl: string | null
  adsCount: number
  report: string
  language: string
}

export type ChatCompanyReportRequest = {
  participantUserId: string
  language: string
  messages: ChatCompanyReportMessage[]
}

function readString(raw: unknown, fallback = ''): string {
  return raw == null ? fallback : String(raw)
}

export function normalizeChatCompanyReport(raw: Record<string, unknown>): ChatCompanyReport {
  return {
    companyName: readString(raw.companyName ?? raw.CompanyName),
    contactFullName: (raw.contactFullName ?? raw.ContactFullName ?? null) as string | null,
    companyImageUrl: (raw.companyImageUrl ?? raw.CompanyImageUrl ?? null) as string | null,
    adsCount: Number(raw.adsCount ?? raw.AdsCount ?? 0),
    report: readString(raw.report ?? raw.Report),
    language: readString(raw.language ?? raw.Language, 'ar'),
  }
}
