import { formatUtcDate } from './formatTimeAgo'

export function getTypeBadgeClass(typeLabel: string): string {
  switch (typeLabel) {
    case 'مورد':
      return 'bg-blue-50 text-blue-600'
    case 'عميل':
      return 'bg-emerald-50 text-emerald-600'
    case 'مدير':
      return 'bg-violet-50 text-violet-600'
    case 'شركة شحن':
      return 'bg-cyan-50 text-cyan-700'
    default:
      return 'bg-slate-100 text-slate-600'
  }
}

export function getStatusBadgeClass(statusLabel: string): string {
  switch (statusLabel) {
    case 'مكتمل':
      return 'bg-emerald-50 text-emerald-600'
    case 'غير مكتمل':
      return 'bg-orange-50 text-orange-600'
    case 'موقوف':
      return 'bg-red-50 text-red-600'
    case 'بانتظار الموافقة':
      return 'bg-amber-50 text-amber-700'
    case 'مرفوض':
      return 'bg-red-50 text-red-700'
    default:
      return 'bg-slate-100 text-slate-600'
  }
}

export function formatJoinDate(value: string): string {
  return formatUtcDate(value)
}
