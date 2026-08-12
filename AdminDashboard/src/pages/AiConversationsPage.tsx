import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import PageHeader from '../components/layout/PageHeader'
import { IconChat } from '../components/icons'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import {
  useGetAdminAiConversationsQuery,
  useLazyGetAdminAiConversationMessagesQuery,
} from '../store'
import { liveQueryOptions } from '../store/cachePolicy'
import type {
  AiConversationListItem,
  AiConversationMessage,
} from '../types/aiConversation'
import { getRtkErrorMessage } from '../utils/rtkError'

function formatWhen(value: string): string {
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString()
}

export default function AiConversationsPage() {
  const { t } = useAppPreferences()
  const [userFilter, setUserFilter] = useState('')
  const [page, setPage] = useState(1)
  const [selected, setSelected] = useState<AiConversationListItem | null>(null)
  const [messages, setMessages] = useState<AiConversationMessage[]>([])
  const [hasMore, setHasMore] = useState(false)
  const [nextBefore, setNextBefore] = useState<number | null>(null)
  const [isLoadingOlder, setIsLoadingOlder] = useState(false)
  const scrollRef = useRef<HTMLDivElement | null>(null)
  const debouncedUserId = useDebouncedValue(userFilter.trim(), 350)

  const {
    data: listPage,
    isLoading: listLoading,
    error: listError,
  } = useGetAdminAiConversationsQuery(
    {
      userId: debouncedUserId || undefined,
      page,
      pageSize: 20,
    },
    liveQueryOptions,
  )

  const [fetchMessages, { isFetching: messagesLoading, error: messagesError }] =
    useLazyGetAdminAiConversationMessagesQuery()

  const loadInitialMessages = useCallback(
    async (conversation: AiConversationListItem) => {
      const pageResult = await fetchMessages({
        conversationId: conversation.id,
        limit: 50,
      }).unwrap()
      setMessages(pageResult.messages)
      setHasMore(pageResult.hasMore)
      setNextBefore(pageResult.nextBeforeMessageId)
    },
    [fetchMessages],
  )

  useEffect(() => {
    if (!selected) {
      setMessages([])
      setHasMore(false)
      setNextBefore(null)
      return
    }
    void loadInitialMessages(selected).catch(() => undefined)
  }, [selected, loadInitialMessages])

  const handleLoadOlder = useCallback(async () => {
    if (!selected || !hasMore || nextBefore == null || isLoadingOlder) return

    const node = scrollRef.current
    const previousHeight = node?.scrollHeight ?? 0
    setIsLoadingOlder(true)
    try {
      const pageResult = await fetchMessages({
        conversationId: selected.id,
        limit: 50,
        before: nextBefore,
      }).unwrap()
      setMessages((prev) => {
        const known = new Set(prev.map((item) => item.id))
        const prepended = pageResult.messages.filter((item) => !known.has(item.id))
        return [...prepended, ...prev]
      })
      setHasMore(pageResult.hasMore)
      setNextBefore(pageResult.nextBeforeMessageId)
      requestAnimationFrame(() => {
        if (!node) return
        node.scrollTop = node.scrollHeight - previousHeight
      })
    } finally {
      setIsLoadingOlder(false)
    }
  }, [selected, hasMore, nextBefore, isLoadingOlder, fetchMessages])

  useEffect(() => {
    const node = scrollRef.current
    if (!node) return
    function onScroll() {
      if (node && node.scrollTop <= 72) {
        void handleLoadOlder()
      }
    }
    node.addEventListener('scroll', onScroll, { passive: true })
    return () => node.removeEventListener('scroll', onScroll)
  }, [handleLoadOlder, selected?.id])

  const items = listPage?.items ?? []
  const totalPages = listPage?.totalPages ?? 1

  const selectedTitle = useMemo(() => {
    if (!selected) return ''
    return selected.titlePreview?.trim() || t('aiConversations.untitled')
  }, [selected, t])

  return (
    <div className="space-y-5">
      <PageHeader
        eyebrow={t('nav.aiConversations')}
        title={t('aiConversations.title')}
        description={t('aiConversations.subtitle')}
        icon={IconChat}
      />

      <div className="admin-card flex min-h-[70vh] overflow-hidden rounded-2xl shadow-sm">
        <aside className="admin-border flex w-full max-w-md flex-col border-e">
          <div className="admin-border border-b p-4">
            <input
              type="search"
              value={userFilter}
              onChange={(event) => {
                setUserFilter(event.target.value)
                setPage(1)
              }}
              placeholder={t('aiConversations.filterUserId')}
              className="admin-input h-10 w-full px-3 text-sm"
            />
          </div>

          <div className="min-h-0 flex-1 overflow-y-auto">
            {listLoading ? (
              <p className="p-4 text-sm text-slate-500">{t('loading')}</p>
            ) : listError ? (
              <p className="p-4 text-sm text-red-600">
                {getRtkErrorMessage(listError, t('aiConversations.loadError'))}
              </p>
            ) : items.length === 0 ? (
              <p className="p-4 text-sm text-slate-500">{t('noData')}</p>
            ) : (
              items.map((item) => {
                const active = selected?.id === item.id
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setSelected(item)}
                    className={`admin-border flex w-full flex-col gap-1 border-b px-4 py-3 text-start transition ${
                      active ? 'bg-indigo-50 dark:bg-indigo-950/30' : 'hover:bg-slate-50 dark:hover:bg-slate-800/60'
                    }`}
                  >
                    <span className="line-clamp-2 text-sm font-semibold text-slate-900 dark:text-slate-100">
                      {item.titlePreview?.trim() || t('aiConversations.untitled')}
                    </span>
                    <span className="text-xs text-slate-500">
                      {formatWhen(item.lastMessageAtUtc)} · {item.messageCount}{' '}
                      {t('aiConversations.messages')}
                    </span>
                    <span className="truncate text-[11px] text-slate-400">
                      {item.clientSessionId}
                    </span>
                  </button>
                )
              })
            )}
          </div>

          <div className="admin-border flex items-center justify-between border-t px-4 py-3 text-sm">
            <button
              type="button"
              disabled={page <= 1}
              onClick={() => setPage((current) => Math.max(1, current - 1))}
              className="rounded-lg px-3 py-1.5 font-semibold text-indigo-700 disabled:opacity-40"
            >
              {t('previous')}
            </button>
            <span className="text-slate-500">
              {t('pageOf', { page, total: totalPages })}
            </span>
            <button
              type="button"
              disabled={page >= totalPages}
              onClick={() => setPage((current) => current + 1)}
              className="rounded-lg px-3 py-1.5 font-semibold text-indigo-700 disabled:opacity-40"
            >
              {t('next')}
            </button>
          </div>
        </aside>

        <section className="flex min-w-0 flex-1 flex-col bg-slate-50/70 dark:bg-slate-950/20">
          {!selected ? (
            <div className="flex flex-1 items-center justify-center p-8 text-center text-sm text-slate-500">
              {t('aiConversations.selectConversation')}
            </div>
          ) : (
            <>
              <header className="admin-border border-b bg-white px-5 py-4 dark:bg-slate-900">
                <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">
                  {selectedTitle}
                </h2>
                <p className="mt-1 text-xs text-slate-500">
                  {t('aiConversations.sessionId')}: {selected.clientSessionId}
                </p>
              </header>

              <div ref={scrollRef} className="min-h-0 flex-1 space-y-3 overflow-y-auto px-4 py-4">
                {isLoadingOlder ? (
                  <p className="text-center text-xs text-slate-500">{t('chat.loadingOlder')}</p>
                ) : null}
                {!isLoadingOlder && hasMore ? (
                  <p className="text-center text-xs text-slate-400">{t('chat.scrollForOlder')}</p>
                ) : null}
                {messagesLoading && messages.length === 0 ? (
                  <p className="text-center text-sm text-slate-500">{t('loading')}</p>
                ) : messagesError ? (
                  <p className="text-center text-sm text-red-600">
                    {getRtkErrorMessage(messagesError, t('aiConversations.loadMessagesError'))}
                  </p>
                ) : (
                  messages.map((message) => {
                    const isUser = message.role === 'user'
                    return (
                      <div
                        key={message.id}
                        className={`flex ${isUser ? 'justify-end' : 'justify-start'}`}
                      >
                        <div
                          className={`max-w-[85%] rounded-2xl px-4 py-3 text-sm shadow-sm ${
                            isUser
                              ? 'bg-indigo-600 text-white'
                              : 'bg-white text-slate-800 dark:bg-slate-900 dark:text-slate-100'
                          }`}
                        >
                          <p className="mb-1 text-[11px] font-semibold uppercase tracking-wide opacity-70">
                            {isUser ? t('aiConversations.user') : t('aiConversations.assistant')}
                          </p>
                          <p className="whitespace-pre-wrap leading-relaxed">{message.content}</p>
                          <p className="mt-2 text-[11px] opacity-60">
                            {formatWhen(message.createdAtUtc)}
                          </p>
                        </div>
                      </div>
                    )
                  })
                )}
              </div>
            </>
          )}
        </section>
      </div>
    </div>
  )
}
