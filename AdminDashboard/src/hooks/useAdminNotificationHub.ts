import { useEffect, useRef } from 'react'
import * as signalR from '@microsoft/signalr'
import { API_BASE_URL } from '../config/api.js'
import { getAuthToken } from '../lib/authStorage'
import { attachSignalRHealthCheck } from '../lib/signalRHealth'
import { signalRTransports } from '../lib/signalRTransports'
import {
  normalizeAdminLiveCounts,
  normalizeAdminRealtimeAlert,
  type AdminLiveCounts,
  type AdminRealtimeAlert,
} from '../types/adminRealtime'

type AdminNotificationHubHandlers = {
  onLiveCountsUpdated?: (counts: AdminLiveCounts) => void
  onAdminAlert?: (alert: AdminRealtimeAlert) => void
}

export function useAdminNotificationHub(enabled: boolean, handlers: AdminNotificationHubHandlers) {
  const handlersRef = useRef(handlers)
  handlersRef.current = handlers

  useEffect(() => {
    if (!enabled) return

    const token = getAuthToken()
    if (!token) return

    const hubBase = `${API_BASE_URL.replace(/\/$/, '')}/adminhub`
    const connection = new signalR.HubConnectionBuilder()
      .withUrl(hubBase, {
        accessTokenFactory: () => getAuthToken() ?? '',
        transport: signalRTransports(),
        withCredentials: true,
      })
      .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
      .configureLogging(signalR.LogLevel.Warning)
      .build()

    connection.on('liveCountsUpdated', (payload: Record<string, unknown>) => {
      handlersRef.current.onLiveCountsUpdated?.(normalizeAdminLiveCounts(payload))
    })

    connection.on('adminAlert', (payload: Record<string, unknown>) => {
      handlersRef.current.onAdminAlert?.(normalizeAdminRealtimeAlert(payload))
    })

    let cancelled = false

    const rejoin = async () => {
      if (cancelled || !getAuthToken()) return
      await connection.invoke('JoinAdminNotifications')
    }

    const clearHealthCheck = attachSignalRHealthCheck(connection, rejoin)

    async function start() {
      try {
        await connection.start()
        if (!cancelled) {
          await rejoin()
        }
      } catch (error) {
        if (import.meta.env.DEV) {
          console.warn('[AdminNotificationHub] connection failed', error)
        }
      }
    }

    void start()

    return () => {
      cancelled = true
      clearHealthCheck()
      void connection.invoke('LeaveAdminNotifications').catch(() => undefined)
      void connection.stop()
    }
  }, [enabled])
}
