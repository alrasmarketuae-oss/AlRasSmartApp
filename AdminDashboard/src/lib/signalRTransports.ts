import * as signalR from '@microsoft/signalr'
import { API_BASE_URL } from '../config/api.js'

export function signalRTransports(): signalR.HttpTransportType {
  const isSharedHosting =
    API_BASE_URL.includes('mtempurl.com')
    || API_BASE_URL.includes('jtempurl.com')
    || API_BASE_URL.includes('ltempurl.com')
    || API_BASE_URL.includes('qtempurl.com')
    || API_BASE_URL.includes('tempurl.host')
    || API_BASE_URL.includes('smarterasp.net')
    || API_BASE_URL.includes('api.alrasmarketapp.com')

  if (isSharedHosting) {
    return (
      signalR.HttpTransportType.LongPolling
      | signalR.HttpTransportType.ServerSentEvents
      | signalR.HttpTransportType.WebSockets
    )
  }

  return (
    signalR.HttpTransportType.WebSockets
    | signalR.HttpTransportType.ServerSentEvents
    | signalR.HttpTransportType.LongPolling
  )
}
