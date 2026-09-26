type CreateCompanyAdChooserProps = {
  open: boolean
  companyName: string
  onClose: () => void
  onManual: () => void
  onAi: () => void
  labels: {
    title: string
    subtitle: string
    manual: string
    manualHint: string
    ai: string
    aiHint: string
    cancel: string
  }
}

export default function CreateCompanyAdChooser({
  open,
  companyName,
  onClose,
  onManual,
  onAi,
  labels,
}: CreateCompanyAdChooserProps) {
  if (!open) return null

  return (
    <div className="fixed inset-0 z-[90] flex items-center justify-center p-4" role="dialog" aria-modal="true">
      <button
        type="button"
        className="absolute inset-0 bg-slate-900/40"
        aria-label={labels.cancel}
        onClick={onClose}
      />
      <div className="relative z-10 w-full max-w-md rounded-2xl bg-white p-5 shadow-2xl dark:bg-slate-900">
        <h2 className="admin-text text-lg font-extrabold">{labels.title}</h2>
        <p className="admin-text-muted mt-1 text-sm">
          {labels.subtitle.replace('{name}', companyName)}
        </p>

        <div className="mt-5 grid gap-3">
          <button
            type="button"
            onClick={onManual}
            className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-start transition hover:border-[#3B7FC7]/50 hover:bg-[#eff6ff] dark:border-slate-700 dark:bg-slate-800 dark:hover:bg-slate-800/80"
          >
            <span className="admin-text block text-sm font-extrabold">{labels.manual}</span>
            <span className="admin-text-muted mt-0.5 block text-xs">{labels.manualHint}</span>
          </button>
          <button
            type="button"
            onClick={onAi}
            className="rounded-xl border border-[#3B7FC7]/35 bg-[#3B7FC7]/10 px-4 py-3 text-start transition hover:bg-[#3B7FC7]/18"
          >
            <span className="block text-sm font-extrabold text-[#3B7FC7]">{labels.ai}</span>
            <span className="admin-text-muted mt-0.5 block text-xs">{labels.aiHint}</span>
          </button>
        </div>

        <button
          type="button"
          onClick={onClose}
          className="admin-btn-ghost mt-4 w-full text-sm font-semibold"
        >
          {labels.cancel}
        </button>
      </div>
    </div>
  )
}
