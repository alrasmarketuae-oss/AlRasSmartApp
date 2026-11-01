import type { InputHTMLAttributes, ReactNode, SelectHTMLAttributes, TextareaHTMLAttributes } from 'react'

const fieldClass =
  'w-full rounded-xl border border-line bg-[#F8FAFC] px-4 text-[15px] text-title outline-none transition placeholder:text-[#9AA7B8] focus:border-brand focus:bg-white disabled:opacity-70'

export function Field({ label, children, hint }: { label: string; children: ReactNode; hint?: string }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[13px] font-bold text-title">{label}</span>
      {children}
      {hint && <span className="mt-1 block text-xs text-subtitle">{hint}</span>}
    </label>
  )
}

export function TextInput({ className = '', ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className={`${fieldClass} h-12 ${className}`} />
}

export function TextArea({ className = '', ...props }: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea rows={4} {...props} className={`${fieldClass} resize-y py-3 leading-relaxed ${className}`} />
}

export function Select({ className = '', children, ...props }: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select {...props} className={`${fieldClass} h-12 appearance-none bg-[length:18px] bg-[position:right_12px_center] bg-no-repeat pe-10 rtl:bg-[position:left_12px_center] ${className}`}
      style={{ backgroundImage: "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%236B7A90' stroke-width='2'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E\")" }}
    >
      {children}
    </select>
  )
}

export function Card({ children, className = '' }: { children: ReactNode; className?: string }) {
  return <div className={`rounded-[14px] border border-line bg-white p-4 shadow-[0_4px_12px_rgba(15,23,42,0.05)] sm:p-5 ${className}`}>{children}</div>
}

/** Normalises typed numbers: digits + one dot, grouped thousands. */
export function formatNumberInput(value: string, decimals = 3) {
  const raw = value.replace(/[^\d.]/g, '')
  const [int, ...dec] = raw.split('.')
  const grouped = int ? Number(int).toLocaleString('en-US') : ''
  return raw.includes('.') ? `${grouped || '0'}.${dec.join('').slice(0, decimals)}` : grouped
}
