import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import type { FetchBaseQueryError } from '@reduxjs/toolkit/query'
import type { SerializedError } from '@reduxjs/toolkit'
import ChatCompanyReportDialog from '../components/chat/ChatCompanyReportDialog'
import PageHeader from '../components/layout/PageHeader'
import { IconChat } from '../components/icons'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import { resolveProfileAssetUrl, isCompanyMediaPath } from '../lib/assets'
import {
  useGenerateAiConversationReportMutation,
  useGetAdminAiConversationsQuery,
  useLazyGetAdminAiConversationMessagesQuery,
} from '../store'
import { liveQueryOptions } from '../store/cachePolicy'
import type {
  AiConversationListItem,
  AiConversationMessage,
} from '../types/aiConversation'
import type { ChatCompanyReport } from '../types/chatCompanyReport'
import { getRtkErrorMessage } from '../utils/rtkError'
import { formatUtcDateTime } from '../utils/formatTimeAgo'

function formatWhen(value: string): string {
  if (!value) return '—'
  return formatUtcDateTime(value, 'en')
}

function resolveConversationAvatar(item: AiConversationListItem): string | null {
  const profile = item.profileImageUrl?.trim()
  if (profile && !isCompanyMediaPath(profile)) return profile
  return null
}

function resolveCompanyLabel(item: AiConversationListItem): string {
  return item.companyName?.trim() || item.contactFullName?.trim() || item.userId
}

export default function AiConversationsPage() {
  const { t, locale } = useAppPreferences()
  const [userFilter, setUserFilter] = useState('')
  const [page, setPage] = useState(1)
  const [selected, setSelected] = useState<AiConversationListItem | null>(null)
  const [messages, setMessages] = useState<AiConversationMessage[]>([])
  const [hasMore, setHasMore] = useState(false)
  const [nextBefore, setNextBefore] = useState<number | null>(null)
  const [isLoadingOlder, setIsLoadingOlder] = useState(false)
  const [reportOpen, setReportOpen] = useState(false)
  const [reportResult, setReportResult] = useState<ChatCompanyReport | null>(null)
  const [reportError, setReportError] = useState<string | null>(null)
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

  const [generateReport, { isLoading: isGeneratingReport }] =
    useGenerateAiConversationReportMutation()

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

  async function handleGenerateReport() {
    if (!selected) return
    setReportOpen(true)
    setReportError(null)
    setReportResult(null)
    try {
      const result = await generateReport({
        conversationId: selected.id,
        language: locale === 'en' ? 'en' : 'ar',
      }).unwrap()
      setReportResult(result)
    } catch (error: unknown) {
      setReportError(
        getRtkErrorMessage(error as FetchBaseQueryError | SerializedError, t('aiConversations.companyReportError')),
      )
    }
  }

  const items = listPage?.items ?? []
  const totalPages = listPage?.totalPages ?? 1

  const selectedTitle = useMemo(() => {
    if (!selected) return ''
    return selected.titlePreview?.trim() || t('aiConversations.untitled')
  }, [selected, t])

  const selectedCompanyLabel = selected ? resolveCompanyLabel(selected) : ''
  const selectedCompanyImage = selected
    ? resolveProfileAssetUrl(resolveConversationAvatar(selected))
    : null

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
                const companyLabel = resolveCompanyLabel(item)
                const avatarPath = resolveConversationAvatar(item)
                const avatarUrl = avatarPath ? resolveProfileAssetUrl(avatarPath) : null
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setSelected(item)}
                    className={`admin-border flex w-full gap-3 border-b px-4 py-3 text-start transition ${
                      active ? 'bg-indigo-50 dark:bg-indigo-950/30' : 'hover:bg-slate-50 dark:hover:bg-slate-800/60'
                    }`}
                  >
                    {avatarUrl ? (
                      <img
                        src={avatarUrl}
                        alt=""
                        className="h-10 w-10 shrink-0 rounded-full object-cover ring-2 ring-indigo-100 dark:ring-indigo-900"
                      />
                    ) : (
                      <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-indigo-100 text-sm font-bold text-indigo-700 dark:bg-indigo-950 dark:text-indigo-200">
                        {companyLabel.charAt(0).toUpperCase()}
                      </div>
                    )}
                    <div className="min-w-0 flex-1">
                      <span className="block truncate text-sm font-semibold text-slate-900 dark:text-slate-100">
                        {companyLabel}
                      </span>
                      <span className="line-clamp-2 text-xs text-slate-600 dark:text-slate-300">
                        {item.titlePreview?.trim() || t('aiConversations.untitled')}
                      </span>
                      <span className="mt-1 block text-xs text-slate-500">
                        {formatWhen(item.lastMessageAtUtc)} · {item.messageCount}{' '}
                        {t('aiConversations.messages')}
                      </span>
                    </div>
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
                <button
                  type="button"
                  onClick={() => void handleGenerateReport()}
                  disabled={isGeneratingReport}
                  title={t('aiConversations.companyReportHint')}
                  className="flex w-full items-start gap-3 rounded-xl text-start transition hover:bg-slate-50 disabled:opacity-70 dark:hover:bg-slate-800/60"
                >
                  {selectedCompanyImage ? (
                    <img
                      src={selectedCompanyImage}
                      alt=""
                      className="h-12 w-12 shrink-0 rounded-xl object-cover ring-2 ring-indigo-100 dark:ring-indigo-900"
                    />
                  ) : (
                    <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-indigo-100 text-lg font-bold text-indigo-700 dark:bg-indigo-950 dark:text-indigo-200">
                      {selectedCompanyLabel.charAt(0).toUpperCase()}
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <h2 className="truncate text-lg font-bold text-slate-900 dark:text-slate-100">
                        {selectedCompanyLabel}
                      </h2>
                      {isGeneratingReport ? (
                        <span className="text-xs text-indigo-600 dark:text-indigo-300">
                          {t('chat.companyReportGenerating')}
                        </span>
                      ) : null}
                    </div>
                    {selected.contactFullName && selected.companyName ? (
                      <p className="truncate text-sm text-slate-500">{selected.contactFullName}</p>
                    ) : null}
                    <p className="mt-1 line-clamp-2 text-sm text-slate-600 dark:text-slate-300">
                      {selectedTitle}
                    </p>
                    <p className="mt-1 text-xs text-slate-400">
                      {t('aiConversations.sessionId')}: {selected.clientSessionId}
                    </p>
                  </div>
                </button>
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
                          {!isUser && message.listings && message.listings.length > 0 ? (
                            <div className="mt-2 flex flex-wrap gap-1.5">
                              {message.listings.map((listing, index) => (
                                <Link
                                  key={`${listing.productId}-${listing.productCode ?? index}`}
                                  to={`/ads/${listing.productId}`}
                                  className="rounded-full bg-indigo-50 px-2.5 py-1 text-[11px] font-semibold text-indigo-700 hover:bg-indigo-100 dark:bg-indigo-950/40 dark:text-indigo-300"
                                >
                                  {listing.nameAr || listing.nameEn || listing.productCode || listing.productId}
                                </Link>
                              ))}
                            </div>
                          ) : null}
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

      <ChatCompanyReportDialog
        open={reportOpen}
        busy={isGeneratingReport}
        error={reportError}
        report={reportResult}
        onClose={() => {
          if (isGeneratingReport) return
          setReportOpen(false)
        }}
        t={t}
      />
    </div>
  )
}
