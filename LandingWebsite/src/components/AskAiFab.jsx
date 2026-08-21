import { aiAgentContent } from '../data/aiAgent'

export default function AskAiFab({ lang, onClick }) {
  const t = aiAgentContent[lang] ?? aiAgentContent.en
  const isAr = lang === 'ar'

  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={t.fabAria}
      className={`ask-ai-fab fixed bottom-[max(1.25rem,env(safe-area-inset-bottom))] z-[70] flex items-center gap-2 rounded-full border border-white/70 bg-white/95 px-2.5 py-2 shadow-[0_12px_40px_rgba(22,58,107,0.28)] backdrop-blur sm:gap-3 sm:px-3 ${
        isAr ? 'left-4 sm:left-5' : 'right-4 sm:right-5'
      }`}
    >
      <span className="ask-ai-fab__pulse" aria-hidden />
      <span className="ask-ai-fab__ring" aria-hidden />
      <img
        src="/seo/alras-agent-robot.png"
        alt=""
        className="ask-ai-fab__logo relative z-10 h-11 w-11 rounded-full object-cover ring-2 ring-[#7B61FF]/30 sm:h-12 sm:w-12"
      />
      <span className="relative z-10 pr-1.5 text-xs font-extrabold text-[#163A6B] sm:pr-2 sm:text-sm">
        {t.fabLabel}
      </span>
    </button>
  )
}
