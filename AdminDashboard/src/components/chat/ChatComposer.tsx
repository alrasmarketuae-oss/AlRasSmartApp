import { useEffect, useRef, useState } from 'react'
import { IconDocument, IconImage, IconMapPin, IconMic, IconPlus, IconSend, IconVideo } from '../icons'
import type { VoiceDraft } from './ChatThreadPanel'

type ChatComposerProps = {
  draft: string
  onDraftChange: (value: string) => void
  onSubmit: () => void
  onPickImage: () => void
  onPickVideo: () => void
  onPickDocument: () => void
  onShareLocation: () => void
  recording: boolean
  recordingSeconds: number
  voiceDraft: VoiceDraft | null
  onStartRecording: () => void
  onStopRecording: () => void
  onCancelRecording: () => void
  onSendVoiceDraft: () => void
  replyPreview?: string | null
  onCancelReply?: () => void
  t: (key: string) => string
}

export default function ChatComposer({
  draft,
  onDraftChange,
  onSubmit,
  onPickImage,
  onPickVideo,
  onPickDocument,
  onShareLocation,
  recording,
  recordingSeconds,
  voiceDraft,
  onStartRecording,
  onStopRecording,
  onCancelRecording,
  onSendVoiceDraft,
  replyPreview = null,
  onCancelReply,
  t,
}: ChatComposerProps) {
  const [attachOpen, setAttachOpen] = useState(false)
  const attachRef = useRef<HTMLDivElement>(null)
  const hasText = draft.trim().length > 0

  useEffect(() => {
    if (!attachOpen) return

    function handlePointerDown(event: MouseEvent | TouchEvent) {
      const target = event.target as Node
      if (attachRef.current && !attachRef.current.contains(target)) {
        setAttachOpen(false)
      }
    }

    document.addEventListener('mousedown', handlePointerDown)
    document.addEventListener('touchstart', handlePointerDown)
    return () => {
      document.removeEventListener('mousedown', handlePointerDown)
      document.removeEventListener('touchstart', handlePointerDown)
    }
  }, [attachOpen])

  function handleSubmit(event: React.FormEvent) {
    event.preventDefault()
    if (!hasText) return
    onSubmit()
  }

  function formatRecordingTime(totalSeconds: number) {
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  return (
    <div className="chat-composer shrink-0 border-t border-[#d1d7db] bg-[#f0f2f5] px-2 py-2 dark:border-slate-700 dark:bg-slate-900 sm:px-3">
      {replyPreview ? (
        <div className="mb-2 flex items-center justify-between gap-2 rounded-2xl border-s-4 border-[#3B7FC7] bg-white px-3 py-2 dark:bg-slate-800">
          <div className="min-w-0">
            <p className="text-[11px] font-bold text-[#3B7FC7]">{t('chat.replyTo')}</p>
            <p className="notranslate truncate text-sm text-slate-600 dark:text-slate-300" translate="no">
              {replyPreview}
            </p>
          </div>
          {onCancelReply ? (
            <button
              type="button"
              className="shrink-0 rounded-full px-2 py-1 text-xs font-semibold text-slate-500"
              onClick={onCancelReply}
            >
              {t('chat.cancelReply')}
            </button>
          ) : null}
        </div>
      ) : null}
      {recording ? (
        <div className="mb-2 flex items-center justify-between gap-2 rounded-2xl bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/40 dark:text-red-200">
          <span className="inline-flex items-center gap-2 font-medium">
            <span className="inline-block h-2.5 w-2.5 animate-pulse rounded-full bg-red-500" />
            {t('chat.recordingVoice')} {formatRecordingTime(recordingSeconds)}
          </span>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onCancelRecording}
              className="rounded-full border border-red-300 px-3 py-1 text-xs font-bold text-red-700 dark:border-red-700 dark:text-red-200"
            >
              {t('chat.cancelRecord')}
            </button>
            <button
              type="button"
              onClick={onStopRecording}
              className="rounded-full bg-red-600 px-3 py-1 text-xs font-bold text-white"
            >
              {t('chat.stopRecord')}
            </button>
          </div>
        </div>
      ) : null}

      {voiceDraft ? (
        <div className="mb-2 flex items-center justify-between gap-2 rounded-2xl bg-white px-3 py-2 text-sm shadow-sm dark:bg-slate-800">
          <span className="font-medium text-slate-700 dark:text-slate-200">
            {t('chat.voicePreview')} · {formatRecordingTime(voiceDraft.durationSeconds)}
          </span>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={onCancelRecording}
              className="rounded-full border border-slate-300 px-3 py-1 text-xs font-bold text-slate-600 dark:border-slate-600 dark:text-slate-300"
            >
              {t('chat.cancelRecord')}
            </button>
            <button
              type="button"
              onClick={onSendVoiceDraft}
              className="rounded-full bg-[#3B7FC7] px-3 py-1 text-xs font-bold text-white"
            >
              {t('chat.sendVoice')}
            </button>
          </div>
        </div>
      ) : null}

      <form onSubmit={handleSubmit} className="flex items-end gap-2">
        <div ref={attachRef} className="relative shrink-0">
          <button
            type="button"
            onClick={() => setAttachOpen((open) => !open)}
            className="chat-composer-icon-btn"
            aria-label={t('chat.attach')}
            disabled={recording || Boolean(voiceDraft)}
          >
            <IconPlus className={`h-5 w-5 transition ${attachOpen ? 'rotate-45' : ''}`} />
          </button>

          {attachOpen ? (
            <>
              <div
                className="fixed inset-0 z-40 bg-black/20 lg:hidden"
                onClick={() => setAttachOpen(false)}
                aria-hidden
              />
              <div className="chat-attach-menu absolute bottom-12 start-0 z-50 lg:bottom-11">
                <button
                  type="button"
                  className="chat-attach-item"
                  onClick={() => {
                    setAttachOpen(false)
                    onPickImage()
                  }}
                >
                  <span className="chat-attach-icon chat-attach-icon-image">
                    <IconImage className="h-5 w-5" />
                  </span>
                  <span>{t('chat.attachImage')}</span>
                </button>
                <button
                  type="button"
                  className="chat-attach-item"
                  onClick={() => {
                    setAttachOpen(false)
                    onPickVideo()
                  }}
                >
                  <span className="chat-attach-icon chat-attach-icon-image">
                    <IconVideo className="h-5 w-5" />
                  </span>
                  <span>{t('chat.attachVideo')}</span>
                </button>
                <button
                  type="button"
                  className="chat-attach-item"
                  onClick={() => {
                    setAttachOpen(false)
                    onPickDocument()
                  }}
                >
                  <span className="chat-attach-icon chat-attach-icon-document">
                    <IconDocument className="h-5 w-5" />
                  </span>
                  <span>{t('chat.attachDocument')}</span>
                </button>
                <button
                  type="button"
                  className="chat-attach-item"
                  onClick={() => {
                    setAttachOpen(false)
                    onShareLocation()
                  }}
                >
                  <span className="chat-attach-icon chat-attach-icon-location">
                    <IconMapPin className="h-5 w-5" />
                  </span>
                  <span>{t('chat.shareLocation')}</span>
                </button>
              </div>
            </>
          ) : null}
        </div>

        <textarea
          value={draft}
          onChange={(event) => onDraftChange(event.target.value)}
          rows={1}
          placeholder={t('chat.messagePlaceholder')}
          disabled={recording || Boolean(voiceDraft)}
          className="chat-compose-input max-h-28 min-h-[42px] flex-1 resize-none rounded-3xl border-0 bg-white px-4 py-2.5 text-[15px] shadow-sm outline-none focus:ring-2 focus:ring-[#3B7FC7]/20 disabled:opacity-60 dark:bg-slate-800"
          onKeyDown={(event) => {
            if (event.key === 'Enter' && !event.shiftKey) {
              event.preventDefault()
              if (hasText) onSubmit()
            }
          }}
        />

        {hasText ? (
          <button type="submit" className="chat-composer-send-btn" aria-label={t('chat.send')}>
            <IconSend className="h-5 w-5" />
          </button>
        ) : (
          <button
            type="button"
            onClick={recording ? onStopRecording : onStartRecording}
            disabled={Boolean(voiceDraft)}
            className={`chat-composer-icon-btn ${recording ? 'bg-red-100 text-red-600 dark:bg-red-950/50' : ''}`}
            aria-label={recording ? t('chat.stopRecord') : t('chat.recordVoice')}
          >
            <IconMic className="h-5 w-5" />
          </button>
        )}
      </form>
    </div>
  )
}
