import type { ChatContact, ChatMessage } from '../types/chat'
import type { ChatCompanyReportMessage } from '../types/chatCompanyReport'
import { messageTypeLabel } from '../types/chat'

export type ChatCompanyDisplay = {
  title: string
  subtitle: string | null
  imageUrl: string | null
  isCompany: boolean
}

/** Company logo lives under company-images; profile photo under images/profiles. */
export function resolveContactAvatarUrl(contact: {
  isCompanyAccount?: boolean
  companyName?: string | null
  companyImageUrl?: string | null
  avatarUrl?: string | null
}): string | null {
  const isCompany = contact.isCompanyAccount || Boolean(contact.companyName?.trim())
  const companyImage = contact.companyImageUrl?.trim()
  const profileImage = contact.avatarUrl?.trim()
  if (isCompany && companyImage) return companyImage
  return profileImage || companyImage || null
}

export function resolveChatCompanyDisplay(contact: ChatContact): ChatCompanyDisplay {
  const companyName = contact.companyName?.trim() || null
  const isCompany = contact.isCompanyAccount || Boolean(companyName)
  const title = companyName || contact.displayName
  const subtitle =
    companyName && contact.contactFullName?.trim() && contact.contactFullName !== companyName
      ? contact.contactFullName.trim()
      : null
  const imageUrl = resolveContactAvatarUrl(contact)

  return { title, subtitle, imageUrl, isCompany }
}

function describeMessageContent(
  message: ChatMessage,
  t: (key: string) => string,
): string {
  switch (message.messageType) {
    case 2:
      return t('chat.reportVoice')
    case 3:
      return t('chat.reportImage')
    case 4:
      return t('chat.reportLocation')
    case 5:
      return t('chat.reportVideo')
    case 6:
      return t('chat.reportFile')
    default:
      return message.content.trim() || t('chat.reportEmpty')
  }
}

export function buildReportMessages(
  messages: ChatMessage[],
  participantUserId: string,
  t: (key: string) => string,
): ChatCompanyReportMessage[] {
  const sorted = [...messages].sort((a, b) => a.sentAtUtc.localeCompare(b.sentAtUtc))
  return sorted.slice(-10).map((message) => ({
    sender: message.fromUserId === participantUserId ? 'customer' : 'support',
    content: describeMessageContent(message, t),
    messageType: messageTypeLabel(message.messageType),
    sentAtUtc: message.sentAtUtc,
  }))
}
