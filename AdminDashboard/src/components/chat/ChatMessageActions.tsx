import { useRef, useState, type PointerEvent, type ReactNode } from 'react'
import { IconForward, IconReply, IconTrash } from '../icons'

type ChatMessageActionsProps = {
  isMine: boolean
  disabled?: boolean
  canDeleteEveryone?: boolean
  onReply: () => void
  onForward: () => void
  onDeleteForMe: () => void
  onDeleteForEveryone?: () => void
  t: (key: string) => string
  children: ReactNode
}

export default function ChatMessageActions({
  isMine,
  disabled = false,
  canDeleteEveryone = false,
  onReply,
  onForward,
  onDeleteForMe,
  onDeleteForEveryone,
  t,
  children,
}: ChatMessageActionsProps) {
  const startXRef = useRef(0)
  const trackingRef = useRef(false)
  const [offset, setOffset] = useState(0)
  const [menuOpen, setMenuOpen] = useState(false)
  const longPressTimer = useRef<number | null>(null)

  function clearLongPress() {
    if (longPressTimer.current) {
      window.clearTimeout(longPressTimer.current)
      longPressTimer.current = null
    }
  }

  function onPointerDown(event: PointerEvent<HTMLDivElement>) {
    if (disabled) return
    trackingRef.current = true
    startXRef.current = event.clientX
    setMenuOpen(false)
    longPressTimer.current = window.setTimeout(() => {
      trackingRef.current = false
      setOffset(0)
      setMenuOpen(true)
    }, 420)
  }

  function onPointerMove(event: PointerEvent<HTMLDivElement>) {
    if (!trackingRef.current || disabled) return
    const delta = event.clientX - startXRef.current
    if (Math.abs(delta) > 8) clearLongPress()
    const directed = isMine ? -delta : delta
    setOffset(Math.max(0, Math.min(72, directed)))
  }

  function onPointerUp() {
    if (!trackingRef.current) {
      clearLongPress()
      setOffset(0)
      return
    }
    trackingRef.current = false
    clearLongPress()
    if (offset >= 48) {
      onReply()
    }
    setOffset(0)
  }

  return (
    <div className="relative">
      <div
        className="select-none touch-pan-y"
        style={{
          transform: `translateX(${isMine ? -offset : offset}px)`,
          transition: trackingRef.current ? 'none' : 'transform 160ms ease',
        }}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
        onContextMenu={(event) => {
          if (disabled) return
          event.preventDefault()
          setMenuOpen(true)
        }}
      >
        {children}
      </div>

      {menuOpen ? (
        <>
          <button
            type="button"
            className="fixed inset-0 z-30 cursor-default bg-black/10"
            aria-label={t('chat.back')}
            onClick={() => setMenuOpen(false)}
          />
          <div
            className={`absolute z-40 mt-1 w-48 overflow-hidden rounded-xl border border-slate-200 bg-white py-1 text-sm shadow-xl dark:border-slate-700 dark:bg-slate-900 ${
              isMine ? 'end-0' : 'start-0'
            }`}
          >
            <button
              type="button"
              className="flex w-full items-center gap-2 px-3 py-2 text-start hover:bg-slate-50 dark:hover:bg-slate-800"
              onClick={() => {
                setMenuOpen(false)
                onReply()
              }}
            >
              <IconReply className="h-4 w-4" />
              {t('chat.reply')}
            </button>
            <button
              type="button"
              className="flex w-full items-center gap-2 px-3 py-2 text-start hover:bg-slate-50 dark:hover:bg-slate-800"
              onClick={() => {
                setMenuOpen(false)
                onForward()
              }}
            >
              <IconForward className="h-4 w-4" />
              {t('chat.forward')}
            </button>
            <button
              type="button"
              className="flex w-full items-center gap-2 px-3 py-2 text-start text-red-600 hover:bg-red-50 dark:hover:bg-red-950/40"
              onClick={() => {
                setMenuOpen(false)
                onDeleteForMe()
              }}
            >
              <IconTrash className="h-4 w-4" />
              {t('chat.deleteForMe')}
            </button>
            {canDeleteEveryone && onDeleteForEveryone ? (
              <button
                type="button"
                className="flex w-full items-center gap-2 px-3 py-2 text-start text-red-700 hover:bg-red-50 dark:hover:bg-red-950/40"
                onClick={() => {
                  setMenuOpen(false)
                  onDeleteForEveryone()
                }}
              >
                <IconTrash className="h-4 w-4" />
                {t('chat.deleteForEveryone')}
              </button>
            ) : null}
          </div>
        </>
      ) : null}

      {offset > 8 ? (
        <div
          className={`pointer-events-none absolute top-1/2 -translate-y-1/2 text-[#3B7FC7] ${
            isMine ? 'end-full me-2' : 'start-full ms-2'
          }`}
        >
          <IconReply className="h-5 w-5" />
        </div>
      ) : null}
    </div>
  )
}
