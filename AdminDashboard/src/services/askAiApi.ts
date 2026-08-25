import { apiRequest } from '../lib/http'

export type AskAiHistoryMessage = {
  role: 'user' | 'assistant'
  content: string
}

export type AskAiAnswer = {
  answer: string
  language?: string
  usedKnowledge?: boolean
  sources?: string[]
  offerSupportCallback?: boolean
}

export async function askAdminAi(input: {
  message: string
  language: string
  history: AskAiHistoryMessage[]
  pagePath: string
  pageContext: string
  signal?: AbortSignal
}): Promise<AskAiAnswer> {
  const history = input.history
    .filter((m) => m.content.trim().length > 0)
    .slice(-8)
    .map((m) => ({
      role: m.role,
      content: m.content.trim().slice(0, 1200),
    }))

  return apiRequest<AskAiAnswer>('/api/AiAssistant/ask', {
    method: 'POST',
    auth: true,
    signal: input.signal,
    body: {
      message: input.message.trim(),
      language: input.language === 'ar' ? 'ar' : 'auto',
      history,
      pagePath: input.pagePath,
      pageContext: input.pageContext,
      clientSource: 'admin_dashboard',
    },
  })
}
