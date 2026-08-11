export type MonitoringRange = '1h' | '6h' | '24h'

export type AdminMonitoringPoint = {
  t: string
  v: number
}

export type AdminMonitoringTarget = {
  job: string
  instance: string
  health: string
}

export type AdminMonitoringSnapshot = {
  httpRequestsPerSec: number
  http5xxPerSec: number
  httpP95Seconds: number
  httpP50Seconds: number
  redisUp: boolean
  redisMemoryBytes: number | null
  apiWorkingSetBytes: number | null
  apiCpuPercent: number | null
}

export type AdminMonitoringSeries = {
  httpRequestsPerSec: AdminMonitoringPoint[]
  http5xxPerSec: AdminMonitoringPoint[]
  httpP95Seconds: AdminMonitoringPoint[]
  httpP50Seconds: AdminMonitoringPoint[]
}

export type AdminMonitoringOverview = {
  serverUtcNow: string
  prometheusReachable: boolean
  range: MonitoringRange
  snapshot: AdminMonitoringSnapshot
  series: AdminMonitoringSeries
  targets: AdminMonitoringTarget[]
}
