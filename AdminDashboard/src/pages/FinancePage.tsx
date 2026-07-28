import { useMemo, useState } from 'react'
import {
  useGetCompanyFinanceProfileQuery,
  useGetCompanyFinanceStatementQuery,
  useGetFinanceWithdrawalsQuery,
  useMarkWithdrawalPaidMutation,
} from '../store'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { getRtkErrorMessage } from '../utils/rtkError'

function formatMoney(value: number, locale: string) {
  return new Intl.NumberFormat(locale === 'ar' ? 'ar-EG' : 'en-US', {
    style: 'currency',
    currency: 'AED',
    maximumFractionDigits: 2,
  }).format(value)
}

function formatUtcLocal(value: string | null, locale: string) {
  if (!value) return '—'
  const normalized = /Z$/i.test(value) ? value : `${value}Z`
  const date = new Date(normalized)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat(locale === 'ar' ? 'ar-EG' : 'en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date)
}

export default function FinancePage() {
  const { locale, dir } = useAppPreferences()
  const [page, setPage] = useState(1)
  const [selectedSupplierId, setSelectedSupplierId] = useState<string>('')
  const [selectedWithdrawalId, setSelectedWithdrawalId] = useState<string>('')
  const isArabic = locale === 'ar'

  const withdrawalsQuery = useMemo(() => ({ page, pageSize: 20 }), [page])
  const { data, error, isLoading, isFetching } = useGetFinanceWithdrawalsQuery(withdrawalsQuery)
  const currentWithdrawal =
    data?.items.find((item) => item.id === selectedWithdrawalId) ?? data?.items[0] ?? null

  const supplierId = selectedSupplierId || currentWithdrawal?.supplierId || ''
  const { data: profile } = useGetCompanyFinanceProfileQuery(supplierId, { skip: !supplierId })
  const { data: statement } = useGetCompanyFinanceStatementQuery(
    { userId: supplierId, page: 1, pageSize: 20 },
    { skip: !supplierId },
  )
  const [markPaid, { isLoading: isMarkingPaid }] = useMarkWithdrawalPaidMutation()
  const [actionMessage, setActionMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  async function handleMarkPaid() {
    if (!currentWithdrawal) return
    const confirmed = window.confirm(
      isArabic ? 'تأكيد تعليم الطلب بأنه تم التحويل؟' : 'Confirm marking this withdrawal as paid?',
    )
    if (!confirmed) return

    setActionMessage(null)
    setActionError(null)
    try {
      const result = await markPaid({
        withdrawalRequestId: currentWithdrawal.id,
        supplierId: currentWithdrawal.supplierId,
      }).unwrap()
      setSelectedSupplierId(currentWithdrawal.supplierId)
      setActionMessage(result.message)
    } catch (err) {
      setActionError(
        getRtkErrorMessage(err as never, isArabic ? 'تعذر تحديث الطلب' : 'Failed to update request'),
      )
    }
  }

  return (
    <div className="space-y-6">
      <header className="space-y-1">
        <h1 className="admin-text text-2xl font-bold">{isArabic ? 'المعاملات المالية' : 'Finance'}</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400">
          {isArabic
            ? 'طلبات السحب، ملف الشركة المالي، وكشف الرصيد.'
            : 'Withdrawal requests, supplier finance profile, and balance statement.'}
        </p>
      </header>

      {actionMessage ? <div className="admin-alert-success">{actionMessage}</div> : null}
      {actionError ? <div className="admin-alert-error">{actionError}</div> : null}

      <div className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
        <section className="admin-card rounded-2xl p-4">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="admin-text text-lg font-semibold">
              {isArabic ? 'طلبات السحب' : 'Withdrawal requests'}
            </h2>
            {isFetching ? <span className="text-xs text-slate-500">{isArabic ? 'تحديث...' : 'Refreshing...'}</span> : null}
          </div>

          {isLoading ? (
            <p className="text-sm text-slate-500">{isArabic ? 'جار التحميل...' : 'Loading...'}</p>
          ) : error ? (
            <p className="text-sm text-red-600">
              {getRtkErrorMessage(error as never, isArabic ? 'تعذر تحميل الطلبات' : 'Failed to load requests')}
            </p>
          ) : (
            <div className="space-y-3">
              {(data?.items ?? []).map((item) => {
                const active = item.id === (selectedWithdrawalId || currentWithdrawal?.id)
                return (
                  <button
                    type="button"
                    key={item.id}
                    onClick={() => {
                      setSelectedWithdrawalId(item.id)
                      setSelectedSupplierId(item.supplierId)
                    }}
                    className={`w-full rounded-2xl border p-4 text-start transition ${
                      active
                        ? 'border-[#3B7FC7] bg-blue-50 dark:bg-blue-950/20'
                        : 'border-slate-200 hover:border-slate-300 dark:border-slate-700'
                    }`}
                  >
                    <div className="flex flex-wrap items-center justify-between gap-3">
                      <div>
                        <div className="font-semibold admin-text">
                          {item.supplierCompanyName || item.supplierName}
                        </div>
                        <div className="text-xs text-slate-500">{item.ibanSnapshot}</div>
                      </div>
                      <div className={`${dir === 'rtl' ? 'text-left' : 'text-right'}`}>
                        <div className="font-semibold text-emerald-700 dark:text-emerald-400">
                          {formatMoney(item.amount, locale)}
                        </div>
                        <div className="text-xs text-slate-500">
                          {isArabic ? item.statusNameAr : item.statusNameEn}
                        </div>
                      </div>
                    </div>
                    <div className="mt-2 text-xs text-slate-500">
                      {formatUtcLocal(item.requestedAtUtc, locale)}
                    </div>
                  </button>
                )
              })}
              {!data?.items.length ? (
                <p className="text-sm text-slate-500">{isArabic ? 'لا توجد طلبات سحب حالياً.' : 'No withdrawal requests yet.'}</p>
              ) : null}
              <div className="flex items-center justify-between pt-2">
                <button
                  type="button"
                  className="rounded-lg border px-3 py-1.5 text-sm disabled:opacity-40"
                  disabled={page <= 1}
                  onClick={() => setPage((value) => Math.max(1, value - 1))}
                >
                  {isArabic ? 'السابق' : 'Previous'}
                </button>
                <span className="text-sm text-slate-500">
                  {page} / {Math.max(1, data?.totalPages ?? 1)}
                </span>
                <button
                  type="button"
                  className="rounded-lg border px-3 py-1.5 text-sm disabled:opacity-40"
                  disabled={page >= Math.max(1, data?.totalPages ?? 1)}
                  onClick={() => setPage((value) => value + 1)}
                >
                  {isArabic ? 'التالي' : 'Next'}
                </button>
              </div>
            </div>
          )}
        </section>

        <section className="space-y-6">
          <div className="admin-card rounded-2xl p-4">
            <h2 className="mb-4 admin-text text-lg font-semibold">{isArabic ? 'بروفايل الشركة' : 'Company profile'}</h2>
            {!profile ? (
              <p className="text-sm text-slate-500">
                {isArabic ? 'اختر طلب سحب لعرض بيانات الشركة.' : 'Select a withdrawal request to view supplier details.'}
              </p>
            ) : (
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  {profile.companyImage || profile.imgPath ? (
                    <img
                      src={profile.companyImage || profile.imgPath || ''}
                      alt={profile.companyName || profile.fullName}
                      className="h-16 w-16 rounded-2xl object-cover"
                    />
                  ) : (
                    <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-slate-100 text-lg font-bold text-slate-500">
                      {(profile.companyName || profile.fullName).slice(0, 1)}
                    </div>
                  )}
                  <div>
                    <div className="admin-text text-lg font-semibold">{profile.companyName || profile.fullName}</div>
                    <div className="text-sm text-slate-500">{profile.email}</div>
                  </div>
                </div>
                <div className="grid gap-3 sm:grid-cols-2">
                  <Info label={isArabic ? 'الرصيد' : 'Balance'} value={formatMoney(profile.balance, locale)} />
                  <Info label={isArabic ? 'عدد الإعلانات' : 'Ads count'} value={String(profile.adsCount)} />
                  <Info label={isArabic ? 'الموبايل' : 'Phone'} value={profile.phoneNumber || '—'} />
                  <Info label={isArabic ? 'الهاتف الأرضي' : 'Landline'} value={profile.landNumber || '—'} />
                </div>
                <div>
                  <div className="mb-2 text-sm font-medium text-slate-500">{isArabic ? 'الحسابات البنكية' : 'IBANs'}</div>
                  <div className="space-y-2">
                    {profile.ibans.map((iban) => (
                      <div key={iban.id} className="rounded-xl border border-slate-200 p-3 text-sm dark:border-slate-700">
                        <div className="font-medium admin-text">{iban.iban}</div>
                        <div className="text-slate-500">
                          {[iban.accountHolderName, iban.bankName].filter(Boolean).join(' • ') || '—'}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
                {currentWithdrawal?.statusId === 1 ? (
                  <button
                    type="button"
                    onClick={handleMarkPaid}
                    disabled={isMarkingPaid}
                    className="rounded-xl bg-emerald-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-60"
                  >
                    {isMarkingPaid
                      ? isArabic ? 'جار التنفيذ...' : 'Processing...'
                      : isArabic ? 'تم إرسال الأموال بنجاح' : 'Mark paid'}
                  </button>
                ) : null}
              </div>
            )}
          </div>

          <div className="admin-card rounded-2xl p-4">
            <h2 className="mb-4 admin-text text-lg font-semibold">{isArabic ? 'كشف الرصيد' : 'Balance statement'}</h2>
            {!statement ? (
              <p className="text-sm text-slate-500">{isArabic ? 'لا يوجد كشف حساب بعد.' : 'No statement selected yet.'}</p>
            ) : (
              <div className="space-y-3">
                {statement.items.map((item) => (
                  <div key={item.id} className="rounded-xl border border-slate-200 p-3 dark:border-slate-700">
                    <div className="flex items-center justify-between gap-3">
                      <div>
                        <div className="font-medium admin-text">
                          {isArabic ? item.reasonAr || item.entryTypeNameAr : item.reasonEn || item.entryTypeNameEn}
                        </div>
                        <div className="text-xs text-slate-500">{formatUtcLocal(item.createdAtUtc, locale)}</div>
                      </div>
                      <div className={`font-semibold ${item.amount >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                        {formatMoney(item.amount, locale)}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </section>
      </div>
    </div>
  )
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl bg-slate-50 p-3 dark:bg-slate-900/40">
      <div className="text-xs text-slate-500">{label}</div>
      <div className="mt-1 font-medium admin-text">{value}</div>
    </div>
  )
}
