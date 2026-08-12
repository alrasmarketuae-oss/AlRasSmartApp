import type { ChatMessage } from '../types/chat'

export function createOptimisticMessageId(): string {
  return `temp-${crypto.randomUUID()}`
}

export function mergeThreadWithPending(
  serverMessages: ChatMessage[],
  localMessages: ChatMessage[],
  otherUserId: string | null,
  myUserId: string | null,
): ChatMessage[] {
  if (!otherUserId || !myUserId) {
    return serverMessages
  }

  const pending = localMessages.filter(
    (message) =>
      (message.deliveryStatus === 'sending' || message.deliveryStatus === 'failed') &&
      message.fromUserId === myUserId &&
      message.toUserId === otherUserId,
  )

  if (pending.length === 0) {
    return serverMessages
  }

  const merged = [...serverMessages]
  const knownIds = new Set(serverMessages.map((message) => message.messageId))

  for (const message of pending) {
    if (!knownIds.has(message.messageId)) {
      merged.push(message)
    }
  }

  return merged.sort((a, b) => a.sentAtUtc.localeCompare(b.sentAtUtc))
}

export function mergeOlderMessages(
  olderMessages: ChatMessage[],
  currentMessages: ChatMessage[],
): ChatMessage[] {
  const knownIds = new Set(currentMessages.map((message) => message.messageId))
  const prepended = olderMessages.filter((message) => !knownIds.has(message.messageId))
  if (prepended.length === 0) {
    return currentMessages
  }
  return [...prepended, ...currentMessages].sort((a, b) =>
    a.sentAtUtc.localeCompare(b.sentAtUtc),
  )
}

export function mergeThreadTail(
  serverLatestPage: ChatMessage[],
  localMessages: ChatMessage[],
  otherUserId: string | null,
  myUserId: string | null,
): ChatMessage[] {
  if (localMessages.length <= serverLatestPage.length) {
    return mergeThreadWithPending(serverLatestPage, localMessages, otherUserId, myUserId)
  }

  const serverIds = new Set(serverLatestPage.map((message) => message.messageId))
  const oldestServerTime = serverLatestPage[0]?.sentAtUtc ?? ''
  const prepended = localMessages.filter(
    (message) =>
      !serverIds.has(message.messageId) &&
      message.sentAtUtc.localeCompare(oldestServerTime) < 0,
  )
  const merged = [...prepended, ...serverLatestPage]
  return mergeThreadWithPending(merged, localMessages, otherUserId, myUserId)
}

export function revokeMessagePreview(message: ChatMessage): void {
  if (message.localPreviewUrl?.startsWith('blob:')) {
    URL.revokeObjectURL(message.localPreviewUrl)
  }
}
