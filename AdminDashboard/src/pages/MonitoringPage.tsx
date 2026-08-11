import { useMemo, useState } from 'react'
import MonitoringLineChart from '../components/monitoring/MonitoringLineChart'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useGetAdminMonitoringQuery } from '../store'
import { queryViewState } from '../store/queryView'
import type { MonitoringRange } from '../types/adminMonitoring'
import { getRtkErrorMessage } from '../utils/rtkError'

function formatRate(value: number, locale: string): string {
  return value.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US', {
    maximumFractionDigits: 2,
  })
}

function formatLatency(seconds: number, locale: string): string {
  const ms = seconds * 1000
  const number = ms.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US', {
    maximumFractionDigits: ms >= 100 ? 0 : 1,
  })
  return `${number} ms`
}

function formatBytes(bytes: number | null | undefined, locale: string): string {
  if (bytes == null || !Number.isFinite(bytes)) return '—'
  const units = ['B', 'KB', 'MB', 'GB']
  let value = bytes
  let unit = 0
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024
    unit += 1
  }
  const number = value.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US', {
    maximumFractionDigits: value >= 10 ? 1 : 2,
  })
  return `${number} ${units[unit]}`
}

function formatPercent(value: number | null | undefined, locale: string): string {
  if (value == null || !Number.isFinite(value)) return '—'
  return `${value.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US', {
    maximumFractionDigits: 1,
  })}%`
}

function StatusPill({
  label,
  up,
}: {
  label: string
  up: boolean
}) {
  return (
    <span
      className={`inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-xs font-bold ${
        up
          ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300'
          : 'bg-red-50 text-red-700 dark:bg-red-950/40 dark:text-red-300'
      }`}
    >
      <span className={`h-2 w-2 rounded-full ${up ? 'bg-emerald-500' : 'bg-red-500'}`} />
      {label}
    </span>
  )
}

function StatCard({
  title,
  value,
}: {
  title: string
  value: string
}) {
  return (
    <div className="admin-card rounded-2xl border border-slate-100 p-4 shadow-sm dark:border-slate-700">
      <p className="admin-text-muted text-xs font-semibold">{title}</p>
      <p className="admin-text mt-2 text-xl font-extrabold tabular-nums">{value}</p>
    </div>
  )
}

export default function MonitoringPage() {
  const { t, locale } = useAppPreferences()
  const [range, setRange] = useState<MonitoringRange>('1h')
  const { data, error, isLoading, isFetching } = useGetAdminMonitoringQuery(range, {
    pollingInterval: 15_000,
    refetchOnFocus: true,
    refetchOnReconnect: true,
  })
  const { showInitialLoader } = queryViewState({ isLoading, isFetching })

  const snapshot = data?.snapshot
  const series = data?.series
  const apiUp = Boolean(data)
  const redisUp = Boolean(snapshot?.redisUp)
  const prometheusUp = Boolean(data?.prometheusReachable)

  const rangeOptions = useMemo(
    () =>
      [
        { id: '1h' as const, label: t('monitoring.range1h') },
        { id: '6h' as const, label: t('monitoring.range6h') },
        { id: '24h' as const, label: t('monitoring.range24h') },
      ],
    [t],
  )

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="admin-text text-2xl font-bold">{t('monitoring.title')}</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {t('monitoring.subtitle')}
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          {data?.serverUtcNow ? (
            <p className="text-xs text-slate-500">
              {t('monitoring.serverUtc')}: {data.serverUtcNow.replace('T', ' ').slice(0, 19)} UTC
            </p>
          ) : null}
          <p className="text-xs text-slate-400">{t('monitoring.autoRefresh')}</p>
        </div>
      </header>

      <div className="flex flex-wrap items-center gap-2">
        {rangeOptions.map((option) => (
          <button
            key={option.id}
            type="button"
            onClick={() => setRange(option.id)}
            className={`rounded-xl px-3 py-1.5 text-sm font-semibold transition ${
              range === option.id
                ? 'bg-[#3B7FC7] text-white'
                : 'admin-input'
            }`}
          >
            {option.label}
          </button>
        ))}
      </div>

      {showInitialLoader ? (
        <p className="text-sm text-slate-500">{t('loading')}</p>
      ) : error ? (
        <p className="text-sm text-red-600">
          {getRtkErrorMessage(error, t('monitoring.loadError'))}
        </p>
      ) : (
        <>
          <div className="flex flex-wrap items-center gap-2">
            <StatusPill
              label={`${t('monitoring.api')}: ${apiUp ? t('monitoring.up') : t('monitoring.down')}`}
              up={apiUp}
            />
            <StatusPill
              label={`${t('monitoring.redis')}: ${redisUp ? t('monitoring.up') : t('monitoring.down')}`}
              up={redisUp}
            />
            <StatusPill
              label={`${t('monitoring.prometheus')}: ${prometheusUp ? t('monitoring.up') : t('monitoring.down')}`}
              up={prometheusUp}
            />
          </div>

          <p
            className={`text-sm ${
              prometheusUp ? 'text-emerald-700 dark:text-emerald-300' : 'text-amber-700 dark:text-amber-300'
            }`}
          >
            {prometheusUp ? t('monitoring.prometheusUp') : t('monitoring.prometheusDown')}
          </p>

          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
            <StatCard
              title={t('monitoring.httpRate')}
              value={formatRate(snapshot?.httpRequestsPerSec ?? 0, locale)}
            />
            <StatCard
              title={t('monitoring.http5xx')}
              value={formatRate(snapshot?.http5xxPerSec ?? 0, locale)}
            />
            <StatCard
              title={t('monitoring.httpP95')}
              value={formatLatency(snapshot?.httpP95Seconds ?? 0, locale)}
            />
            <StatCard
              title={t('monitoring.httpP50')}
              value={formatLatency(snapshot?.httpP50Seconds ?? 0, locale)}
            />
            <StatCard
              title={t('monitoring.apiMemory')}
              value={formatBytes(snapshot?.apiWorkingSetBytes, locale)}
            />
            <StatCard
              title={t('monitoring.redisMemory')}
              value={formatBytes(snapshot?.redisMemoryBytes, locale)}
            />
            <StatCard
              title={t('monitoring.cpu')}
              value={formatPercent(snapshot?.apiCpuPercent, locale)}
            />
          </div>

          <div className="grid gap-4 xl:grid-cols-2">
            <MonitoringLineChart
              title={t('monitoring.httpRate')}
              points={series?.httpRequestsPerSec ?? []}
              color="#3B7FC7"
              formatValue={(v) => formatRate(v, locale)}
              emptyLabel={t('monitoring.noData')}
            />
            <MonitoringLineChart
              title={t('monitoring.http5xx')}
              points={series?.http5xxPerSec ?? []}
              color="#ef4444"
              formatValue={(v) => formatRate(v, locale)}
              emptyLabel={t('monitoring.noData')}
            />
            <MonitoringLineChart
              title={t('monitoring.httpP95')}
              points={series?.httpP95Seconds ?? []}
              color="#8B5CF6"
              formatValue={(v) => formatLatency(v, locale)}
              emptyLabel={t('monitoring.noData')}
            />
            <MonitoringLineChart
              title={t('monitoring.httpP50')}
              points={series?.httpP50Seconds ?? []}
              color="#22C55E"
              formatValue={(v) => formatLatency(v, locale)}
              emptyLabel={t('monitoring.noData')}
            />
          </div>

          <div className="admin-card overflow-hidden rounded-2xl border border-slate-100 dark:border-slate-700">
            <div className="border-b border-slate-100 px-4 py-3 dark:border-slate-700">
              <h2 className="admin-text text-sm font-bold">{t('monitoring.targets')}</h2>
            </div>
            {(data?.targets.length ?? 0) === 0 ? (
              <p className="admin-text-muted px-4 py-6 text-sm">{t('monitoring.noData')}</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full text-sm">
                  <thead className="admin-text-muted bg-slate-50 text-xs uppercase dark:bg-slate-900/40">
                    <tr>
                      <th className="px-4 py-2 text-start">{t('monitoring.job')}</th>
                      <th className="px-4 py-2 text-start">{t('monitoring.instance')}</th>
                      <th className="px-4 py-2 text-start">{t('monitoring.health')}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data?.targets.map((target) => {
                      const up = target.health.toLowerCase() === 'up'
                      return (
                        <tr
                          key={`${target.job}-${target.instance}`}
                          className="border-t border-slate-100 dark:border-slate-800"
                        >
                          <td className="admin-text px-4 py-2.5 font-medium">{target.job || '—'}</td>
                          <td className="admin-text-muted px-4 py-2.5">{target.instance || '—'}</td>
                          <td className="px-4 py-2.5">
                            <StatusPill
                              label={up ? t('monitoring.up') : t('monitoring.down')}
                              up={up}
                            />
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  )
}
