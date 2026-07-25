import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import { useAdminNotificationHub } from '../hooks/useAdminNotificationHub'
import { getAuthToken } from '../lib/authStorage'
import { adminApi, useGetAdminLiveCountsQuery } from '../store/adminApi'
import { liveQueryOptions } from '../store/cachePolicy'
import { useAppDispatch } from '../store/hooks'
import type {
  AdminLiveCounts,
  AdminNavCounts,
  AdminRealtimeAlert,
} from '../types/adminRealtime'
import { useChat } from './ChatProvider'

type AdminNotificationContextValue = {
  navCounts: AdminNavCounts
  totalBadgeCount: number
  subscribeAdminAlert: (handler: (alert: AdminRealtimeAlert) => void) => () => void
}

const AdminNotificationContext = createContext<AdminNotificationContextValue | null>(null)

const emptyCounts: AdminLiveCounts = {
  pendingUsers: 0,
  pendingProfileEdits: 0,
  pendingAds: 0,
  pendingAdEdits: 0,
  pendingOrders: 0,
  pendingRetailOrders: 0,
  pendingBookingOrders: 0,
  pendingOffersOrders: 0,
  pendingCategoriesOrders: 0,
  pendingOffers: 0,
  pendingRequestOfferAds: 0,
  pendingShippingAds: 0,
}

export function AdminNotificationProvider({ children }: { children: ReactNode }) {
  const dispatch = useAppDispatch()
  const { totalUnread } = useChat()
  const isAuthenticated = Boolean(getAuthToken())

  const [liveCounts, setLiveCounts] = useState<AdminLiveCounts>(emptyCounts)
  const alertListenersRef = useRef(new Set<(alert: AdminRealtimeAlert) => void>())

  const { data: fetchedCounts } = useGetAdminLiveCountsQuery(undefined, {
    skip: !isAuthenticated,
    pollingInterval: 60_000,
    ...liveQueryOptions,
  })

  useEffect(() => {
    if (fetchedCounts) {
      setLiveCounts(fetchedCounts)
    }
  }, [fetchedCounts])

  const invalidateLists = useCallback(() => {
    dispatch(
      adminApi.util.invalidateTags([
        { type: 'Dashboard', id: 'LIVE_COUNTS' },
        { type: 'Users', id: 'LIST' },
        { type: 'Products', id: 'LIST' },
        { type: 'Orders', id: 'LIST' },
      ]),
    )
  }, [dispatch])

  useAdminNotificationHub(isAuthenticated, {
    onLiveCountsUpdated: (counts) => {
      setLiveCounts(counts)
      invalidateLists()
    },
    onAdminAlert: (alert) => {
      alertListenersRef.current.forEach((handler) => handler(alert))
      invalidateLists()
    },
  })

  const subscribeAdminAlert = useCallback((handler: (alert: AdminRealtimeAlert) => void) => {
    alertListenersRef.current.add(handler)
    return () => {
      alertListenersRef.current.delete(handler)
    }
  }, [])

  const navCounts = useMemo(
    (): AdminNavCounts => ({
      users: liveCounts.pendingUsers,
      profileEdits: liveCounts.pendingProfileEdits,
      ads: liveCounts.pendingAds,
      adEdits: liveCounts.pendingAdEdits,
      retailOrders: liveCounts.pendingRetailOrders,
      bookingOrders: liveCounts.pendingBookingOrders,
      offersOrders: liveCounts.pendingOffersOrders,
      categoriesOrders: liveCounts.pendingCategoriesOrders,
      // Supplier offers on Request ads + new Request ads (طلب).
      offers: liveCounts.pendingOffers + liveCounts.pendingRequestOfferAds,
      shipping: liveCounts.pendingShippingAds,
      chat: totalUnread,
    }),
    [liveCounts, totalUnread],
  )

  const totalBadgeCount =
    navCounts.users +
    navCounts.profileEdits +
    navCounts.ads +
    navCounts.adEdits +
    navCounts.retailOrders +
    navCounts.bookingOrders +
    navCounts.offersOrders +
    navCounts.categoriesOrders +
    navCounts.offers +
    navCounts.shipping +
    navCounts.chat

  const value = useMemo(
    (): AdminNotificationContextValue => ({
      navCounts,
      totalBadgeCount,
      subscribeAdminAlert,
    }),
    [navCounts, totalBadgeCount, subscribeAdminAlert],
  )

  return (
    <AdminNotificationContext.Provider value={value}>
      {children}
    </AdminNotificationContext.Provider>
  )
}

export function useAdminNotifications() {
  const context = useContext(AdminNotificationContext)
  if (!context) {
    throw new Error('useAdminNotifications must be used within AdminNotificationProvider')
  }
  return context
}
