import * as signalR from '@microsoft/signalr'
import { getAuthToken } from './authStorage'

const HEALTH_CHECK_MS = 10_000

export function attachSignalRHealthCheck(
  connection: signalR.HubConnection,
  rejoin: () => Promise<void>,
): () => void {
  const ensureConnected = async () => {
    if (!getAuthToken()) return
    if (connection.state === signalR.HubConnectionState.Connected) return
    if (connection.state === signalR.HubConnectionState.Connecting) return
    if (connection.state === signalR.HubConnectionState.Reconnecting) return

    try {
      await connection.start()
      await rejoin()
    } catch {
      // retry on next interval
    }
  }

  connection.onreconnected(() => {
    void rejoin().catch(() => undefined)
  })

  const timer = window.setInterval(() => {
    void ensureConnected()
  }, HEALTH_CHECK_MS)

  return () => {
    window.clearInterval(timer)
  }
}
