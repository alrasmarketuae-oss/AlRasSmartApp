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

export function revokeMessagePreview(message: ChatMessage): void {
  if (message.localPreviewUrl?.startsWith('blob:')) {
    URL.revokeObjectURL(message.localPreviewUrl)
  }
}
