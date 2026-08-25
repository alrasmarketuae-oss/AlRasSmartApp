type AskAiFabProps = {
  label: string
  ariaLabel: string
  onClick: () => void
  isRtl: boolean
}

export default function AskAiFab({
  label,
  ariaLabel,
  onClick,
  isRtl,
}: AskAiFabProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={ariaLabel}
      className={`ask-ai-fab print:hidden fixed bottom-[max(1.25rem,env(safe-area-inset-bottom))] z-[90] flex items-center gap-2 rounded-full border border-[#3B7FC7]/25 bg-white/95 px-2.5 py-2 shadow-[0_12px_40px_rgba(59,127,199,0.28)] backdrop-blur transition hover:shadow-[0_14px_44px_rgba(59,127,199,0.36)] dark:border-slate-600 dark:bg-slate-900/95 sm:gap-3 sm:px-3 ${
        isRtl ? 'left-4 sm:left-5' : 'right-4 sm:right-5'
      }`}
    >
      <span className="ask-ai-fab__pulse" aria-hidden />
      <span className="ask-ai-fab__ring" aria-hidden />
      <img
        src="/seo/alras-agent-robot.png"
        alt=""
        className="ask-ai-fab__logo relative z-10 h-11 w-11 rounded-full object-cover ring-2 ring-[#3B7FC7]/35 sm:h-12 sm:w-12"
      />
      <span className="relative z-10 pe-1.5 text-xs font-extrabold text-[#0b1f3a] dark:text-slate-100 sm:pe-2 sm:text-sm">
        {label}
      </span>
    </button>
  )
}
