import { createApi } from '@reduxjs/toolkit/query/react'
import { apiUrl } from '../config/api.js'
import { getAuthToken } from '../lib/authStorage'
import type { AdminOrder, AdminOrdersFilters, AdminOrderStats } from '../types/adminOrder'
import type {
  AdminProductLookups,
  AdminProductsFilters,
  AdminProductStats,
  AdminUpdateProductPayload,
} from '../types/adminProduct'
import type { GlobalSearchResponse, GlobalSearchSuggestion } from '../types/globalSearch'
import type { UpdateSystemSettingsPayload } from '../types/adminSettings'
import type {
  InternalDomesticShippingResponse,
  UpdateInternalDomesticShippingPayload,
} from '../types/internalDomesticShipping'
import type {
  AdminNotificationsFilters,
  AdminNotificationsResponse,
  SendAdminNotificationPayload,
} from '../types/adminNotification'
import type { AdminShippingFilters, AdminShippingProvider, AdminShippingProviderDetail } from '../types/adminShipping'
import type { ShippingProviderPayload } from '../types/adminShippingCreate'
import type { Category } from '../types/category'
import type { HomeBanner } from '../types/banner'
import type {
  ChatContact,
  ChatConversationDetails,
  ChatInbox,
  ChatMessage,
  ChatSupportAssignment,
  ChatUnreadSummary,
  ChatUploadResult,
  ChatUploadImagesResult,
  SendChatMessagePayload,
} from '../types/chat'
import { normalizeChatConversationDetails, normalizeChatMessage } from '../types/chat'
import type {
  AdminAuditLogsFilters,
  AdminAuditLogsResponse,
} from '../types/adminAuditLog'
import type {
  AdminMonitoringOverview,
  MonitoringRange,
} from '../types/adminMonitoring'
import type {
  MissedProductSearchesFilters,
  MissedProductSearchesResponse,
} from '../types/missedProductSearch'
import type {
  AdminEmployeeDetail,
  AdminEmployeesResponse,
  AdminPermissionDefinition,
  CreateEmployeePayload,
  UpdateEmployeePayload,
} from '../types/employee'
import {
  normalizeEmployee,
  normalizeEmployeeDetail,
  normalizePermissionDefinition,
} from './employeeNormalizers'
import type { GeoCountry, GeoPortsByCountryResponse } from '../types/geo'
import type { DashboardData } from '../types/dashboard'
import type { AdminLiveCounts } from '../types/adminRealtime'
import { normalizeAdminLiveCounts } from '../types/adminRealtime'
import type { AdminUsersResponse } from '../types/user'
import type { AdminUserDetail } from '../types/adminUserDetail'
import type {
  AdminBalanceStatementResponse,
  AdminCompanyFinanceProfile,
  AdminFinanceWithdrawalsResponse,
} from '../types/adminFinance'
import {
  getOrderStatusLabelAr,
  getOrderStatusLabelEn,
} from '../utils/orderStatusLabel'
import { adminBaseQuery } from './baseQuery'
import {
  normalizeCategoriesResponse,
  normalizeCategory,
  normalizeHomeBanner,
  normalizeHomeBannersResponse,
  normalizeOrdersResponse,
  normalizeOrderStats,
  normalizeOrder,
  normalizeProductsResponse,
  normalizeProductStats,
  normalizeProductDetail,
  normalizeProductLookups,
  normalizeShippingProvider,
  normalizeShippingProviderDetail,
  normalizeShippingProvidersResponse,
  normalizeGeoCountries,
  normalizeGeoPortsByCountry,
  normalizeUsersResponse,
  normalizeUserDetail,
} from './normalizers'
import { normalizeSystemSettings } from './settingsNormalizers'
import {
  BADGE_CACHE_TTL_SECONDS,
  defaultCachePolicy,
  LIVE_CACHE_TTL_SECONDS,
  STATIC_CACHE_TTL_SECONDS,
} from './cachePolicy'

export type FetchUsersParams = {
  page?: number
  pageSize?: number
  roleId?: number
  search?: string
  status?: string
  joinedFrom?: string
  joinedTo?: string
}

export const adminApi = createApi({
  reducerPath: 'adminApi',
  baseQuery: adminBaseQuery,
  tagTypes: [
    'Dashboard',
    'Users',
    'Products',
    'Categories',
    'Banners',
    'Orders',
    'Shipping',
    'Settings',
    'Notifications',
    'GlobalSearch',
    'Geo',
    'Chat',
    'Employees',
    'AuditLogs',
    'Monitoring',
    'MissedProductSearches',
    'Finance',
  ],
  ...defaultCachePolicy,
  endpoints: (builder) => ({
    getDashboard: builder.query<
      DashboardData,
      { createdFrom?: string; createdTo?: string } | void
    >({
      query: (params) => ({
        url: '/api/admin/dashboard',
        params: {
          createdFrom: params?.createdFrom,
          createdTo: params?.createdTo,
        },
      }),
      providesTags: ['Dashboard'],
    }),

    getAdminLiveCounts: builder.query<AdminLiveCounts, void>({
      query: () => '/api/admin/notifications/live-counts',
      transformResponse: (response: Record<string, unknown>) =>
        normalizeAdminLiveCounts(response),
      providesTags: [{ type: 'Dashboard', id: 'LIVE_COUNTS' }],
      keepUnusedDataFor: BADGE_CACHE_TTL_SECONDS,
    }),

    getUsers: builder.query<AdminUsersResponse, FetchUsersParams>({
      query: (params) => ({
        url: '/api/admin/users',
        params: {
          page: params.page,
          pageSize: params.pageSize,
          roleId: params.roleId,
          search: params.search,
          status: params.status,
          joinedFrom: params.joinedFrom,
          joinedTo: params.joinedTo,
        },
      }),
      transformResponse: (response: AdminUsersResponse) =>
        normalizeUsersResponse(response),
      providesTags: (result) =>
        result
          ? [
              { type: 'Users', id: 'LIST' },
              ...result.items.map((user) => ({
                type: 'Users' as const,
                id: user.id,
              })),
            ]
          : [{ type: 'Users', id: 'LIST' }],
    }),

    getAdminUserDetail: builder.query<AdminUserDetail, string>({
      query: (userId) => `/api/admin/users/${userId}`,
      transformResponse: (response: AdminUserDetail) => normalizeUserDetail(response),
      providesTags: (_result, _error, userId) => [{ type: 'Users', id: userId }],
    }),

    getAdminProductStats: builder.query<AdminProductStats, void>({
      query: () => '/api/admin/products/stats',
      transformResponse: normalizeProductStats,
      providesTags: [{ type: 'Products', id: 'STATS' }],
    }),

    getAdminProducts: builder.query<
      ReturnType<typeof normalizeProductsResponse>,
      AdminProductsFilters
    >({
      query: (params) => ({
        url: '/api/admin/products',
        params: {
          page: params.page,
          pageSize: params.pageSize,
          search: params.search,
          approval: params.approval,
          categoryId: params.categoryId,
          productTypeId: params.productTypeId,
          excludeProductTypeId: params.excludeProductTypeId,
          hasCategory: params.hasCategory === true ? true : undefined,
          status: params.status,
          createdFrom: params.createdFrom,
          createdTo: params.createdTo,
          hasPendingOffers: params.hasPendingOffers === true ? true : undefined,
          editResubmitOnly: params.editResubmitOnly === true ? true : undefined,
          ownerId: params.ownerId || undefined,
          lang: params.lang,
        },
      }),
      transformResponse: normalizeProductsResponse,
      providesTags: (result) =>
        result
          ? [
              { type: 'Products', id: 'LIST' },
              ...result.items.map((product) => ({
                type: 'Products' as const,
                id: product.productId,
              })),
            ]
          : [{ type: 'Products', id: 'LIST' }],
    }),

    approveProduct: builder.mutation<
      { message: string },
      { productId: string; supplierNotesEn?: string | null }
    >({
      query: ({ productId, supplierNotesEn }) => ({
        url: `/api/admin/products/${productId}/approve`,
        method: 'POST',
        body: { supplierNotesEn: supplierNotesEn ?? null },
      }),
      invalidatesTags: (_r, _e, { productId }) => [
        { type: 'Products', id: 'LIST' },
        { type: 'Products', id: 'STATS' },
        { type: 'Products', id: productId },
        'Dashboard',
        { type: 'AuditLogs', id: 'LIST' },
      ],
    }),

    rejectProduct: builder.mutation<
      { message: string },
      {
        productId: string
        supplierNotesEn?: string | null
        supplierNotesAr?: string | null
      }
    >({
      query: ({ productId, supplierNotesEn, supplierNotesAr }) => ({
        url: `/api/admin/products/${productId}/reject`,
        method: 'POST',
        body: {
          supplierNotesEn: supplierNotesEn ?? null,
          supplierNotesAr: supplierNotesAr ?? null,
        },
      }),
      invalidatesTags: (_r, _e, { productId }) => [
        { type: 'Products', id: 'LIST' },
        { type: 'Products', id: 'STATS' },
        { type: 'Products', id: productId },
        'Dashboard',
        { type: 'AuditLogs', id: 'LIST' },
      ],
    }),

    getAdminProductDetail: builder.query<
      ReturnType<typeof normalizeProductDetail>,
      { productId: string; lang?: 'ar' | 'en' }
    >({
      query: ({ productId, lang }) => ({
        url: `/api/admin/products/${productId}`,
        params: lang ? { lang } : undefined,
      }),
      transformResponse: normalizeProductDetail,
      providesTags: (_r, _e, { productId }) => [{ type: 'Products', id: productId }],
    }),

    getAdminProductLookups: builder.query<AdminProductLookups, void>({
      query: () => '/api/admin/products/lookups',
      transformResponse: normalizeProductLookups,
    }),

    updateAdminProduct: builder.mutation<
      unknown,
      { productId: string; body: AdminUpdateProductPayload }
    >({
      query: ({ productId, body }) => ({
        url: `/api/admin/products/${productId}`,
        method: 'PUT',
        // Undefined keys are dropped during JSON serialization, so the optional
        // full-edit fields are only sent when the edit dialog provides them.
        body: {
          nameEn: body.nameEn,
          usdPrice: body.usdPrice,
          currency: body.currency,
          quantity: body.quantity,
          descriptionEn: body.descriptionEn,
          categoryId: body.categoryId,
          productTypeName: body.productTypeName,
          unitName: body.unitName,
          supplierNotesEn: body.supplierNotesEn,
          negotiable: body.negotiable,
          packaging: body.packaging,
          packagingDetails: body.packagingDetails,
          shippingDuration: body.shippingDuration,
          offerDuration: body.offerDuration,
          discountPercentage: body.discountPercentage,
          discountDays: body.discountDays,
          requestTypeName: body.requestTypeName,
          bookingPriceTypeName: body.bookingPriceTypeName,
          originCountryName: body.originCountryName,
          destinationCountryName: body.destinationCountryName,
          loadingPortName: body.loadingPortName,
          arrivalPortName: body.arrivalPortName,
          enableRetailPricing: body.enableRetailPricing,
          retailPrice: body.retailPrice,
          retailUnitName: body.retailUnitName,
          retailQuantity: body.retailQuantity,
          retailPackaging: body.retailPackaging,
          retailPackagingDetails: body.retailPackagingDetails,
          retailDescriptionEn: body.retailDescriptionEn,
        },
      }),
      invalidatesTags: (_r, _e, { productId }) => [
        { type: 'Products', id: 'LIST' },
        { type: 'Products', id: productId },
      ],
    }),

    uploadAdminProductImage: builder.mutation<
      { id: number; path: string },
      { productId: string; file: File }
    >({
      queryFn: async ({ productId, file }) => {
        const token = getAuthToken()
        const form = new FormData()
        form.append('File', file)

        try {
          const response = await fetch(
            apiUrl(`/api/admin/products/${productId}/images/upload`),
            {
              method: 'POST',
              headers: token ? { Authorization: `Bearer ${token}` } : {},
              body: form,
            },
          )

          const data: unknown = await response.json().catch(() => ({}))

          if (!response.ok) {
            const error = data as { message?: string }
            return {
              error: {
                status: response.status,
                data: { message: error.message ?? 'تعذر رفع الصورة.' },
              },
            }
          }

          const raw = data as { id?: number; Id?: number; path?: string; Path?: string }
          return {
            data: {
              id: raw.id ?? raw.Id ?? 0,
              path: raw.path ?? raw.Path ?? '',
            },
          }
        } catch {
          return {
            error: {
              status: 'FETCH_ERROR',
              error: 'تعذر رفع الصورة.',
            },
          }
        }
      },
      invalidatesTags: (_r, _e, { productId }) => [
        { type: 'Products', id: productId },
        { type: 'Products', id: 'LIST' },
      ],
    }),

    deleteAdminProductImage: builder.mutation<
      { message: string },
      { productId: string; imageId: number }
    >({
      query: ({ productId, imageId }) => ({
        url: `/api/admin/products/${productId}/images/${imageId}`,
        method: 'DELETE',
      }),
      invalidatesTags: (_r, _e, { productId }) => [
        { type: 'Products', id: productId },
        { type: 'Products', id: 'LIST' },
      ],
    }),

    deleteAdminProductVideo: builder.mutation<
      { message: string },
      { productId: string; path: string }
    >({
      query: ({ productId, path }) => ({
        url: `/api/admin/products/${productId}/videos`,
        method: 'DELETE',
        params: { path },
      }),
      invalidatesTags: (_r, _e, { productId }) => [
        { type: 'Products', id: productId },
        { type: 'Products', id: 'LIST' },
      ],
    }),

    setAdminProductVideoMute: builder.mutation<
      { id: number; path: string; isMuted: boolean },
      { productId: string; path: string; isMuted: boolean }
    >({
      query: ({ productId, path, isMuted }) => ({
        url: `/api/admin/products/${productId}/videos/mute`,
        method: 'PUT',
        body: { path, isMuted },
      }),
      // Flip the mute flag in the cache immediately, then let the (slow) backend
      // request run in the background. Roll back only if it fails.
      async onQueryStarted(
        { productId, path, isMuted },
        { dispatch, queryFulfilled, getState },
      ) {
        const cachedArgs = adminApi.util.selectCachedArgsForQuery(
          getState(),
          'getAdminProductDetail',
        )

        const patchResults = cachedArgs
          .filter((args) => args.productId === productId)
          .map((args) =>
            dispatch(
              adminApi.util.updateQueryData(
                'getAdminProductDetail',
                args,
                (draft) => {
                  const video = draft.videos?.find((item) => item.path === path)
                  if (video) video.isMuted = isMuted
                },
              ),
            ),
          )

        try {
          await queryFulfilled
        } catch {
          patchResults.forEach((patch) => patch.undo())
        }
      },
    }),

    approveCompany: builder.mutation<{ message: string }, string>({
      query: (companyUserId) => ({
        url: `/api/admin/companies/${companyUserId}/approve`,
        method: 'POST',
      }),
      invalidatesTags: (_r, _e, companyUserId) => [
        { type: 'Users', id: 'LIST' },
        { type: 'Users', id: companyUserId },
        'Dashboard',
        { type: 'AuditLogs', id: 'LIST' },
      ],
    }),

    rejectCompany: builder.mutation<
      { message: string },
      { companyUserId: string; reason: string }
    >({
      query: ({ companyUserId, reason }) => ({
        url: `/api/admin/companies/${companyUserId}/reject`,
        method: 'POST',
        body: { reason },
      }),
      invalidatesTags: (_r, _e, { companyUserId }) => [
        { type: 'Users', id: 'LIST' },
        { type: 'Users', id: companyUserId },
        'Dashboard',
        { type: 'AuditLogs', id: 'LIST' },
      ],
    }),

    setUserActive: builder.mutation<
      { message: string; userId: string; isActive: boolean },
      { userId: string; isActive: boolean }
    >({
      query: ({ userId, isActive }) => ({
        url: `/api/admin/users/${userId}/active`,
        method: 'PATCH',
        body: { isActive },
      }),
      invalidatesTags: (_r, _e, { userId }) => [
        { type: 'Users', id: 'LIST' },
        { type: 'Users', id: userId },
        'Dashboard',
      ],
    }),

    deleteAdminUser: builder.mutation<{ message: string; userId: string }, string>({
      query: (userId) => ({
        url: `/api/admin/users/${userId}`,
        method: 'DELETE',
      }),
      invalidatesTags: (_r, _e, userId) => [
        { type: 'Users', id: 'LIST' },
        { type: 'Users', id: userId },
        'Dashboard',
        { type: 'AuditLogs', id: 'LIST' },
      ],
    }),

    deleteProduct: builder.mutation<{ message: string }, string>({
      query: (productId) => ({
        url: `/api/admin/products/${productId}`,
        method: 'DELETE',
      }),
      invalidatesTags: (_result, _error, productId) => [
        { type: 'Products', id: 'LIST' },
        { type: 'Products', id: 'STATS' },
        { type: 'Products', id: productId },
        'Dashboard',
      ],
    }),

    getAdminOrderStats: builder.query<AdminOrderStats, void>({
      query: () => '/api/admin/orders/stats',
      transformResponse: normalizeOrderStats,
      providesTags: [{ type: 'Orders', id: 'STATS' }],
    }),

    getAdminOrderDetail: builder.query<AdminOrder, number>({
      query: (orderId) => `/api/admin/orders/${orderId}`,
      transformResponse: (response: AdminOrder) => normalizeOrder(response),
      providesTags: (_result, _error, orderId) => [{ type: 'Orders', id: String(orderId) }],
    }),

    getAdminOrders: builder.query<
      ReturnType<typeof normalizeOrdersResponse>,
      AdminOrdersFilters
    >({
      query: (params) => ({
        url: '/api/admin/orders',
        params: {
          page: params.page,
          pageSize: params.pageSize,
          statusId: params.statusId,
          productTypeId: params.productTypeId,
          excludeProductTypeId: params.excludeProductTypeId,
          productId: params.productId,
          search: params.search,
          createdFrom: params.createdFrom,
          createdTo: params.createdTo,
          offerReview:
            params.offerReview && params.offerReview !== 'all'
              ? params.offerReview
              : undefined,
          orderChannel: params.orderChannel,
        },
      }),
      transformResponse: normalizeOrdersResponse,
      providesTags: (result) =>
        result
          ? [
              { type: 'Orders', id: 'LIST' },
              ...result.items.map((order) => ({
                type: 'Orders' as const,
                id: String(order.id),
              })),
            ]
          : [{ type: 'Orders', id: 'LIST' }],
    }),

    respondToOrderReturn: builder.mutation<
      AdminOrder | { order: AdminOrder; refundMessage?: string },
      { orderId: number; response: string; approved?: boolean }
    >({
      query: ({ orderId, response, approved = true }) => ({
        url: `/api/admin/orders/${orderId}/return/respond`,
        method: 'POST',
        body: { response, approved },
      }),
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: String(orderId) },
      ],
    }),

    manualRefundOrder: builder.mutation<
      {
        message: string
        orderGroupId?: string
        refundId?: string
        refundedAtUtc?: string
      },
      { orderId: number }
    >({
      query: ({ orderId }) => ({
        url: `/api/Payments/ManualRefund/${orderId}`,
        method: 'POST',
      }),
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: String(orderId) },
      ],
    }),

    approveRequestOffer: builder.mutation<
      AdminOrder,
      { orderId: number; adminUnitPrice?: number; adminTotalPrice?: number }
    >({
      query: ({ orderId, adminUnitPrice, adminTotalPrice }) => ({
        url: `/api/admin/orders/${orderId}/request-offer/approve`,
        method: 'POST',
        body: { adminUnitPrice, adminTotalPrice },
      }),
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: 'STATS' },
        { type: 'Orders', id: String(orderId) },
        'Dashboard',
      ],
    }),

    setRequestOfferAdvertiserPrice: builder.mutation<
      AdminOrder,
      { orderId: number; adminUnitPrice: number; adminTotalPrice?: number }
    >({
      query: ({ orderId, adminUnitPrice, adminTotalPrice }) => ({
        url: `/api/admin/orders/${orderId}/request-offer/advertiser-price`,
        method: 'PATCH',
        body: { adminUnitPrice, adminTotalPrice },
      }),
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: String(orderId) },
      ],
    }),

    rejectRequestOffer: builder.mutation<AdminOrder, { orderId: number }>({
      query: ({ orderId }) => ({
        url: `/api/admin/orders/${orderId}/request-offer/reject`,
        method: 'POST',
      }),
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: 'STATS' },
        { type: 'Orders', id: String(orderId) },
        'Dashboard',
      ],
    }),

    updateOrderStatus: builder.mutation<
      { orderId: number; statusId: number; status: string; statusAr: string; isApproved: boolean },
      { orderId: number; statusId: number }
    >({
      query: ({ orderId, statusId }) => ({
        url: `/api/admin/orders/${orderId}/status`,
        method: 'PATCH',
        body: { statusId },
      }),
      async onQueryStarted({ orderId, statusId }, { dispatch, queryFulfilled, getState }) {
        const cachedArgs = adminApi.util.selectCachedArgsForQuery(
          getState(),
          'getAdminOrders',
        )

        const patchResults = cachedArgs.map((args) =>
          dispatch(
            adminApi.util.updateQueryData('getAdminOrders', args, (draft) => {
              const item = draft.items.find((order) => order.id === orderId)
              if (!item) return
              item.statusId = statusId
              item.statusName = getOrderStatusLabelEn(statusId)
              item.statusLabelAr = getOrderStatusLabelAr(statusId)
              if (statusId === 2) {
                item.isApproved = true
              }
            }),
          ),
        )

        try {
          await queryFulfilled
        } catch {
          patchResults.forEach((patch) => patch.undo())
        }
      },
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: 'STATS' },
        { type: 'Orders', id: String(orderId) },
        'Dashboard',
      ],
    }),

    setCustomOrderStatus: builder.mutation<
      AdminOrder,
      { orderId: number; statusNameEn: string; statusNameAr: string }
    >({
      query: ({ orderId, statusNameEn, statusNameAr }) => ({
        url: `/api/admin/orders/${orderId}/custom-status`,
        method: 'PATCH',
        body: { statusNameEn, statusNameAr },
      }),
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: 'STATS' },
        { type: 'Orders', id: String(orderId) },
        'Dashboard',
      ],
    }),

    markOrderReceived: builder.mutation<AdminOrder, { orderId: number }>({
      query: ({ orderId }) => ({
        url: `/api/admin/orders/${orderId}/mark-received`,
        method: 'POST',
      }),
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: 'STATS' },
        { type: 'Orders', id: String(orderId) },
        'Dashboard',
      ],
    }),

    uploadOrderImage: builder.mutation<
      { id: number; path: string },
      { orderId: number; file: File }
    >({
      queryFn: async ({ orderId, file }) => {
        const token = getAuthToken()
        const form = new FormData()
        form.append('File', file)

        try {
          const response = await fetch(
            apiUrl(`/api/admin/orders/${orderId}/images/upload`),
            {
              method: 'POST',
              headers: token ? { Authorization: `Bearer ${token}` } : {},
              body: form,
            },
          )

          const data: unknown = await response.json().catch(() => ({}))

          if (!response.ok) {
            const error = data as { message?: string }
            return {
              error: {
                status: response.status,
                data: { message: error.message ?? 'تعذر رفع الصورة.' },
              },
            }
          }

          const raw = data as { id?: number; Id?: number; path?: string; Path?: string }
          return {
            data: {
              id: raw.id ?? raw.Id ?? 0,
              path: raw.path ?? raw.Path ?? '',
            },
          }
        } catch {
          return {
            error: {
              status: 'FETCH_ERROR',
              error: 'تعذر رفع الصورة.',
            },
          }
        }
      },
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: String(orderId) },
      ],
    }),

    deleteOrderImage: builder.mutation<void, { orderId: number; imageId: number }>({
      query: ({ orderId, imageId }) => ({
        url: `/api/admin/orders/${orderId}/images/${imageId}`,
        method: 'DELETE',
      }),
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: String(orderId) },
      ],
    }),

    uploadOrderVideo: builder.mutation<
      { id: number; path: string },
      { orderId: number; file: File }
    >({
      queryFn: async ({ orderId, file }) => {
        const token = getAuthToken()
        const form = new FormData()
        form.append('File', file)

        try {
          const response = await fetch(
            apiUrl(`/api/admin/orders/${orderId}/videos/upload`),
            {
              method: 'POST',
              headers: token ? { Authorization: `Bearer ${token}` } : {},
              body: form,
            },
          )

          const data: unknown = await response.json().catch(() => ({}))

          if (!response.ok) {
            const error = data as { message?: string }
            return {
              error: {
                status: response.status,
                data: { message: error.message ?? 'تعذر رفع الفيديو.' },
              },
            }
          }

          const raw = data as { id?: number; Id?: number; path?: string; Path?: string }
          return {
            data: {
              id: raw.id ?? raw.Id ?? 0,
              path: raw.path ?? raw.Path ?? '',
            },
          }
        } catch {
          return {
            error: {
              status: 'FETCH_ERROR',
              error: 'تعذر رفع الفيديو.',
            },
          }
        }
      },
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: String(orderId) },
      ],
    }),

    deleteOrderVideo: builder.mutation<void, { orderId: number; videoId: number }>({
      query: ({ orderId, videoId }) => ({
        url: `/api/admin/orders/${orderId}/videos/${videoId}`,
        method: 'DELETE',
      }),
      invalidatesTags: (_result, _error, { orderId }) => [
        { type: 'Orders', id: 'LIST' },
        { type: 'Orders', id: String(orderId) },
      ],
    }),

    uploadAdminProductVideo: builder.mutation<
      { path: string },
      {
        productId: string
        file: File
        videoDurationSeconds: number
        replaceVideoPath?: string
      }
    >({
      queryFn: async ({ productId, file, videoDurationSeconds, replaceVideoPath }) => {
        const token = getAuthToken()
        const form = new FormData()
        form.append('File', file)
        form.append('VideoDurationSeconds', String(videoDurationSeconds))
        if (replaceVideoPath?.trim()) {
          form.append('ReplaceVideoPath', replaceVideoPath.trim())
        }

        try {
          const response = await fetch(
            apiUrl(`/api/admin/products/${productId}/videos/upload`),
            {
              method: 'POST',
              headers: token ? { Authorization: `Bearer ${token}` } : {},
              body: form,
            },
          )

          const data: unknown = await response.json().catch(() => ({}))

          if (!response.ok) {
            const error = data as { message?: string }
            return {
              error: {
                status: response.status,
                data: { message: error.message ?? 'تعذر رفع الفيديو.' },
              },
            }
          }

          const raw = data as { path?: string; Path?: string }
          return { data: { path: raw.path ?? raw.Path ?? '' } }
        } catch {
          return {
            error: {
              status: 'FETCH_ERROR',
              error: 'تعذر رفع الفيديو.',
            },
          }
        }
      },
      invalidatesTags: (_result, _error, { productId }) => [
        { type: 'Products', id: productId },
        { type: 'Products', id: 'LIST' },
      ],
    }),

    getShippingProviders: builder.query<
      ReturnType<typeof normalizeShippingProvidersResponse>,
      AdminShippingFilters
    >({
      query: (params) => ({
        url: '/api/admin/shipping/providers',
        params: {
          page: params.page,
          pageSize: params.pageSize,
          search: params.search,
        },
      }),
      transformResponse: normalizeShippingProvidersResponse,
      providesTags: [{ type: 'Shipping', id: 'LIST' }],
    }),

    getShippingProviderDetail: builder.query<AdminShippingProviderDetail, string>({
      query: (providerId) => `/api/admin/shipping/providers/${providerId}`,
      transformResponse: (raw: AdminShippingProviderDetail) =>
        normalizeShippingProviderDetail(raw),
      providesTags: (_result, _error, providerId) => [
        { type: 'Shipping', id: providerId },
        { type: 'Shipping', id: 'LIST' },
      ],
    }),

    setShippingProviderActive: builder.mutation<
      { message: string; isActive: boolean },
      { providerId: string; isActive: boolean }
    >({
      query: ({ providerId, isActive }) => ({
        url: `/api/admin/shipping/providers/${providerId}/active`,
        method: 'PATCH',
        body: { isActive },
      }),
      invalidatesTags: (_result, _error, { providerId }) => [
        { type: 'Shipping', id: providerId },
        { type: 'Shipping', id: 'LIST' },
      ],
    }),

    createShippingProvider: builder.mutation<
      AdminShippingProvider,
      ShippingProviderPayload
    >({
      query: (body) => ({
        url: '/api/admin/shipping/providers',
        method: 'POST',
        body: {
          companyName: body.companyName,
          fullName: body.fullName,
          email: body.email,
          phoneNumber: body.phoneNumber,
          fromCountryName: body.fromCountryName,
          fromPortName: body.fromPortName,
          toCountryName: body.toCountryName,
          toPortName: body.toPortName,
          container20ftPriceUsd: body.container20ftPriceUsd,
          container40ftPriceUsd: body.container40ftPriceUsd,
        },
      }),
      transformResponse: (raw: AdminShippingProvider) => normalizeShippingProvider(raw),
      invalidatesTags: [{ type: 'Shipping', id: 'LIST' }],
    }),

    updateShippingProvider: builder.mutation<
      AdminShippingProviderDetail,
      { providerId: string } & ShippingProviderPayload
    >({
      query: ({ providerId, ...body }) => ({
        url: `/api/admin/shipping/providers/${providerId}`,
        method: 'PUT',
        body: {
          companyName: body.companyName,
          fullName: body.fullName,
          email: body.email,
          phoneNumber: body.phoneNumber,
          fromCountryName: body.fromCountryName,
          fromPortName: body.fromPortName,
          toCountryName: body.toCountryName,
          toPortName: body.toPortName,
          container20ftPriceUsd: body.container20ftPriceUsd,
          container40ftPriceUsd: body.container40ftPriceUsd,
        },
      }),
      transformResponse: (raw: AdminShippingProviderDetail) =>
        normalizeShippingProviderDetail(raw),
      invalidatesTags: (_result, _error, { providerId }) => [
        { type: 'Shipping', id: providerId },
        { type: 'Shipping', id: 'LIST' },
      ],
    }),

    deleteShippingProvider: builder.mutation<{ message: string }, string>({
      query: (providerId) => ({
        url: `/api/admin/shipping/providers/${providerId}`,
        method: 'DELETE',
      }),
      invalidatesTags: (_result, _error, providerId) => [
        { type: 'Shipping', id: providerId },
        { type: 'Shipping', id: 'LIST' },
        { type: 'Dashboard', id: 'LIVE_COUNTS' },
      ],
    }),

    approveShippingPost: builder.mutation<{ message: string }, number>({
      query: (postId) => ({
        url: `/api/admin/shipping/posts/${postId}/approve`,
        method: 'POST',
      }),
      invalidatesTags: () => [
        { type: 'Shipping' },
        { type: 'Dashboard', id: 'LIVE_COUNTS' },
      ],
    }),

    rejectShippingPost: builder.mutation<
      { message: string },
      { postId: number; reason?: string }
    >({
      query: ({ postId, reason }) => ({
        url: `/api/admin/shipping/posts/${postId}/reject`,
        method: 'POST',
        body: { reason: reason ?? '' },
      }),
      invalidatesTags: () => [
        { type: 'Shipping' },
        { type: 'Dashboard', id: 'LIVE_COUNTS' },
      ],
    }),

    uploadShippingProviderImage: builder.mutation<
      { id: string; imgPath: string },
      { providerId: string; file: File }
    >({
      queryFn: async ({ providerId, file }) => {
        const token = getAuthToken()
        const form = new FormData()
        form.append('File', file)

        try {
          const response = await fetch(apiUrl(`/api/admin/shipping/providers/${providerId}/image`), {
            method: 'POST',
            headers: token ? { Authorization: `Bearer ${token}` } : {},
            body: form,
          })

          const data: unknown = await response.json().catch(() => ({}))

          if (!response.ok) {
            const error = data as { message?: string }
            return {
              error: {
                status: response.status,
                data: { message: error.message ?? 'Could not upload image.' },
              },
            }
          }

          const payload = data as { id?: string; imgPath?: string; ImgPath?: string }
          return {
            data: {
              id: String(payload.id ?? providerId),
              imgPath: payload.imgPath ?? payload.ImgPath ?? '',
            },
          }
        } catch (error) {
          return {
            error: {
              status: 'FETCH_ERROR',
              error: error instanceof Error ? error.message : 'Could not upload image.',
            },
          }
        }
      },
      invalidatesTags: (_result, _error, { providerId }) => [
        { type: 'Shipping', id: providerId },
        { type: 'Shipping', id: 'LIST' },
      ],
    }),

    getCategories: builder.query<
      ReturnType<typeof normalizeCategoriesResponse>,
      void
    >({
      query: () => '/api/Categories/manage',
      transformResponse: normalizeCategoriesResponse,
      providesTags: (result) =>
        result
          ? [
              { type: 'Categories', id: 'LIST' },
              ...result.items.map((category) => ({
                type: 'Categories' as const,
                id: String(category.categoryId),
              })),
            ]
          : [{ type: 'Categories', id: 'LIST' }],
    }),

    setCategoryVisibility: builder.mutation<
      Category,
      { categoryId: number; isHide: boolean }
    >({
      query: ({ categoryId, isHide }) => ({
        url: `/api/Categories/${categoryId}/visibility`,
        method: 'PATCH',
        body: { isHide },
      }),
      transformResponse: (raw: Category) => normalizeCategory(raw),
      invalidatesTags: (_result, _error, { categoryId }) => [
        { type: 'Categories', id: 'LIST' },
        { type: 'Categories', id: String(categoryId) },
        { type: 'Settings', id: 'CURRENT' },
      ],
    }),

    createCategory: builder.mutation<
      Category,
      { nameEn: string; nameAr: string; imgPath?: string }
    >({
      query: (body) => ({
        url: '/api/Categories',
        method: 'POST',
        body: {
          nameEn: body.nameEn,
          nameAr: body.nameAr,
          imgPath: body.imgPath ?? '',
        },
      }),
      transformResponse: (raw: Category) => normalizeCategory(raw),
      invalidatesTags: [
        { type: 'Categories', id: 'LIST' },
        { type: 'Settings', id: 'CURRENT' },
      ],
    }),

    updateCategory: builder.mutation<
      Category,
      { categoryId: number; nameEn: string; nameAr: string; imgPath?: string }
    >({
      query: ({ categoryId, nameEn, nameAr, imgPath }) => ({
        url: `/api/Categories/${categoryId}`,
        method: 'PUT',
        body: { nameEn, nameAr, imgPath: imgPath ?? null },
      }),
      transformResponse: (raw: Category) => normalizeCategory(raw),
      invalidatesTags: (_result, _error, { categoryId }) => [
        { type: 'Categories', id: 'LIST' },
        { type: 'Categories', id: String(categoryId) },
      ],
    }),

    uploadCategoryImage: builder.mutation<Category, { categoryId: number; file: File }>({
      queryFn: async ({ categoryId, file }) => {
        const token = getAuthToken()
        const form = new FormData()
        form.append('File', file)

        try {
          const response = await fetch(
            apiUrl(`/api/Categories/${categoryId}/image/upload`),
            {
              method: 'POST',
              headers: token ? { Authorization: `Bearer ${token}` } : {},
              body: form,
            },
          )

          const data: unknown = await response.json().catch(() => ({}))

          if (!response.ok) {
            const error = data as { message?: string }
            return {
              error: {
                status: response.status,
                data: { message: error.message ?? 'تعذر رفع الصورة.' },
              },
            }
          }

          return { data: normalizeCategory(data as Category) }
        } catch {
          return {
            error: {
              status: 'FETCH_ERROR',
              error: 'تعذر رفع الصورة.',
            },
          }
        }
      },
      async onQueryStarted({ categoryId }, { dispatch, queryFulfilled }) {
        try {
          const { data } = await queryFulfilled
          dispatch(
            adminApi.util.updateQueryData('getCategories', undefined, (draft) => {
              const item = draft.items.find((c) => c.categoryId === categoryId)
              if (item) {
                item.imgPath = data.imgPath
                item.nameEn = data.nameEn || item.nameEn
                item.nameAr = data.nameAr || item.nameAr
              }
            }),
          )
        } catch {
          // invalidatesTags will refetch on failure paths that still succeed partially
        }
      },
      invalidatesTags: (_result, _error, { categoryId }) => [
        { type: 'Categories', id: 'LIST' },
        { type: 'Categories', id: String(categoryId) },
      ],
    }),

    deleteCategory: builder.mutation<{ message: string; categoryId: number }, number>({
      query: (categoryId) => ({
        url: `/api/Categories/${categoryId}`,
        method: 'DELETE',
      }),
      async onQueryStarted(categoryId, { dispatch, queryFulfilled }) {
        const patch = dispatch(
          adminApi.util.updateQueryData('getCategories', undefined, (draft) => {
            draft.items = draft.items.filter((c) => c.categoryId !== categoryId)
            draft.count = draft.items.length
          }),
        )
        try {
          await queryFulfilled
        } catch {
          patch.undo()
        }
      },
      invalidatesTags: (_result, _error, categoryId) => [
        { type: 'Categories', id: 'LIST' },
        { type: 'Categories', id: String(categoryId) },
        { type: 'Settings', id: 'CURRENT' },
      ],
    }),

    getHomeBanners: builder.query<
      ReturnType<typeof normalizeHomeBannersResponse>,
      void
    >({
      query: () => '/api/HomeBanners',
      transformResponse: normalizeHomeBannersResponse,
      providesTags: (result) =>
        result
          ? [
              { type: 'Banners', id: 'LIST' },
              ...result.items.map((banner) => ({
                type: 'Banners' as const,
                id: String(banner.id),
              })),
            ]
          : [{ type: 'Banners', id: 'LIST' }],
    }),

    createHomeBanner: builder.mutation<
      HomeBanner,
      { file: File; linkUrl?: string | null; displayOrder: number }
    >({
      queryFn: async ({ file, linkUrl, displayOrder }) => {
        const token = getAuthToken()
        const form = new FormData()
        form.append('File', file)
        form.append('LinkUrl', linkUrl?.trim() ?? '')
        form.append('DisplayOrder', String(displayOrder))

        try {
          const response = await fetch(apiUrl('/api/HomeBanners'), {
            method: 'POST',
            headers: token ? { Authorization: `Bearer ${token}` } : {},
            body: form,
          })

          const data: unknown = await response.json().catch(() => ({}))

          if (!response.ok) {
            const error = data as { message?: string }
            return {
              error: {
                status: response.status,
                data: { message: error.message ?? 'Could not create banner.' },
              },
            }
          }

          return { data: normalizeHomeBanner(data as HomeBanner) }
        } catch {
          return {
            error: {
              status: 'FETCH_ERROR',
              error: 'Could not create banner.',
            },
          }
        }
      },
      invalidatesTags: [{ type: 'Banners', id: 'LIST' }],
    }),

    updateHomeBanner: builder.mutation<
      HomeBanner,
      { bannerId: number; linkUrl?: string | null; displayOrder?: number; file?: File | null }
    >({
      queryFn: async ({ bannerId, linkUrl, displayOrder, file }) => {
        const token = getAuthToken()
        const form = new FormData()
        if (linkUrl !== undefined) form.append('LinkUrl', linkUrl?.trim() ?? '')
        if (displayOrder !== undefined) form.append('DisplayOrder', String(displayOrder))
        if (file) form.append('File', file)

        try {
          const response = await fetch(apiUrl(`/api/HomeBanners/${bannerId}`), {
            method: 'PUT',
            headers: token ? { Authorization: `Bearer ${token}` } : {},
            body: form,
          })

          const data: unknown = await response.json().catch(() => ({}))

          if (!response.ok) {
            const error = data as { message?: string }
            return {
              error: {
                status: response.status,
                data: { message: error.message ?? 'Could not update banner.' },
              },
            }
          }

          return { data: normalizeHomeBanner(data as HomeBanner) }
        } catch {
          return {
            error: {
              status: 'FETCH_ERROR',
              error: 'Could not update banner.',
            },
          }
        }
      },
      invalidatesTags: (_result, _error, { bannerId }) => [
        { type: 'Banners', id: 'LIST' },
        { type: 'Banners', id: String(bannerId) },
      ],
    }),

    deleteHomeBanner: builder.mutation<{ message: string }, number>({
      query: (bannerId) => ({
        url: `/api/HomeBanners/${bannerId}`,
        method: 'DELETE',
      }),
      invalidatesTags: (_result, _error, bannerId) => [
        { type: 'Banners', id: 'LIST' },
        { type: 'Banners', id: String(bannerId) },
      ],
    }),

    getSystemSettings: builder.query<
      ReturnType<typeof normalizeSystemSettings>,
      void
    >({
      query: () => '/api/admin/settings',
      transformResponse: normalizeSystemSettings,
      providesTags: [{ type: 'Settings', id: 'CURRENT' }],
    }),

    updateSystemSettings: builder.mutation<
      ReturnType<typeof normalizeSystemSettings>,
      UpdateSystemSettingsPayload
    >({
      query: (body) => ({
        url: '/api/admin/settings',
        method: 'PUT',
        body,
      }),
      transformResponse: normalizeSystemSettings,
      invalidatesTags: [{ type: 'Settings', id: 'CURRENT' }],
    }),

    getInternalDomesticShipping: builder.query<
      InternalDomesticShippingResponse,
      void
    >({
      query: () => '/api/admin/internal-shipping',
      transformResponse: (response: {
        items?: Array<{
          id?: number
          Id?: number
          emirateNameEn?: string
          EmirateNameEn?: string
          emirateNameAr?: string
          EmirateNameAr?: string
          priceAed?: number
          PriceAed?: number
        }>
        excessKgRateAed?: number
        ExcessKgRateAed?: number
        freeWeightKg?: number
        FreeWeightKg?: number
      }) => ({
        items: (response.items ?? []).map((item) => ({
          id: item.id ?? item.Id ?? 0,
          emirateNameEn: item.emirateNameEn ?? item.EmirateNameEn ?? '',
          emirateNameAr: item.emirateNameAr ?? item.EmirateNameAr ?? '',
          priceAed: item.priceAed ?? item.PriceAed ?? 0,
        })),
        excessKgRateAed: response.excessKgRateAed ?? response.ExcessKgRateAed ?? 0,
        freeWeightKg: response.freeWeightKg ?? response.FreeWeightKg ?? 10,
      }),
      providesTags: [{ type: 'Settings', id: 'INTERNAL_SHIPPING' }],
    }),

    updateInternalDomesticShipping: builder.mutation<
      InternalDomesticShippingResponse,
      UpdateInternalDomesticShippingPayload
    >({
      query: (body) => ({
        url: '/api/admin/internal-shipping',
        method: 'PUT',
        body: {
          rates: body.rates.map((rate) => ({
            id: rate.id,
            priceAed: rate.priceAed,
          })),
          excessKgRateAed: body.excessKgRateAed,
        },
      }),
      transformResponse: (response: {
        items?: Array<{
          id?: number
          Id?: number
          emirateNameEn?: string
          EmirateNameEn?: string
          emirateNameAr?: string
          EmirateNameAr?: string
          priceAed?: number
          PriceAed?: number
        }>
        excessKgRateAed?: number
        ExcessKgRateAed?: number
        freeWeightKg?: number
        FreeWeightKg?: number
      }) => ({
        items: (response.items ?? []).map((item) => ({
          id: item.id ?? item.Id ?? 0,
          emirateNameEn: item.emirateNameEn ?? item.EmirateNameEn ?? '',
          emirateNameAr: item.emirateNameAr ?? item.EmirateNameAr ?? '',
          priceAed: item.priceAed ?? item.PriceAed ?? 0,
        })),
        excessKgRateAed: response.excessKgRateAed ?? response.ExcessKgRateAed ?? 0,
        freeWeightKg: response.freeWeightKg ?? response.FreeWeightKg ?? 10,
      }),
      invalidatesTags: [{ type: 'Settings', id: 'INTERNAL_SHIPPING' }],
    }),

    getAdminNotifications: builder.query<AdminNotificationsResponse, AdminNotificationsFilters>({
      query: (params) => ({
        url: '/api/admin/notifications',
        params: {
          page: params.page,
          pageSize: params.pageSize,
          audience: params.audience || undefined,
        },
      }),
      providesTags: [{ type: 'Notifications', id: 'LIST' }],
    }),

    sendAdminNotification: builder.mutation<
      { message: string; notificationId: string; audience: string },
      SendAdminNotificationPayload
    >({
      query: (body) => ({
        url: '/api/admin/notifications/send',
        method: 'POST',
        body,
      }),
      invalidatesTags: [{ type: 'Notifications', id: 'LIST' }],
    }),

    getGlobalSearch: builder.query<GlobalSearchResponse, string>({
      query: (q) => ({
        url: '/api/admin/search',
        params: { q },
      }),
      providesTags: (_result, _error, q) => [{ type: 'GlobalSearch', id: q || 'empty' }],
    }),

    getGlobalSearchSuggest: builder.query<
      { items: GlobalSearchSuggestion[] },
      { q?: string; limit?: number }
    >({
      query: ({ q, limit }) => ({
        url: '/api/admin/search/suggest',
        params: { q, limit },
      }),
    }),

    getGeoCountries: builder.query<GeoCountry[], void>({
      query: () => '/api/Geo/countries',
      transformResponse: (raw: Parameters<typeof normalizeGeoCountries>[0]) =>
        normalizeGeoCountries(raw),
      providesTags: [{ type: 'Geo', id: 'COUNTRIES' }],
      keepUnusedDataFor: STATIC_CACHE_TTL_SECONDS,
    }),

    getGeoPortsByCountry: builder.query<GeoPortsByCountryResponse, string>({
      query: (countryName) =>
        `/api/Geo/countries/${encodeURIComponent(countryName)}/ports`,
      transformResponse: (raw: Parameters<typeof normalizeGeoPortsByCountry>[0]) =>
        normalizeGeoPortsByCountry(raw),
      providesTags: (_result, _error, countryName) => [
        { type: 'Geo', id: `PORTS:${countryName}` },
      ],
      keepUnusedDataFor: STATIC_CACHE_TTL_SECONDS,
    }),

    getChatInbox: builder.query<ChatInbox, void>({
      query: () => '/api/Chat/my',
      providesTags: [{ type: 'Chat', id: 'INBOX' }],
      keepUnusedDataFor: LIVE_CACHE_TTL_SECONDS,
    }),

    getChatUnreadCount: builder.query<ChatUnreadSummary, void>({
      query: () => '/api/Chat/unread-count',
      providesTags: [{ type: 'Chat', id: 'UNREAD' }],
      keepUnusedDataFor: BADGE_CACHE_TTL_SECONDS,
    }),

    searchChatConversations: builder.query<ChatContact[], string>({
      query: (q) => ({
        url: '/api/Chat/search',
        params: { q },
      }),
      keepUnusedDataFor: LIVE_CACHE_TTL_SECONDS,
    }),

    getChatMessages: builder.query<ChatMessage[], string>({
      query: (otherUserId) => ({
        url: '/api/Chat/messages',
        params: { otherUserId },
      }),
      transformResponse: (response: ChatMessage[]) =>
        response.map((message) => normalizeChatMessage(message)),
      providesTags: (_result, _error, otherUserId) => [
        { type: 'Chat', id: `THREAD:${otherUserId}` },
      ],
      keepUnusedDataFor: LIVE_CACHE_TTL_SECONDS,
    }),

    getChatConversationDetails: builder.query<ChatConversationDetails, string>({
      query: (otherUserId) => ({
        url: '/api/Chat/conversation',
        params: { otherUserId },
      }),
      transformResponse: (response: Record<string, unknown>) =>
        normalizeChatConversationDetails(response),
      providesTags: (_result, _error, otherUserId) => [
        { type: 'Chat', id: `THREAD:${otherUserId}` },
      ],
      keepUnusedDataFor: LIVE_CACHE_TTL_SECONDS,
    }),

    sendChatMessage: builder.mutation<ChatMessage, SendChatMessagePayload>({
      query: (body) => ({
        url: '/api/Chat/messages',
        method: 'POST',
        body,
      }),
      transformResponse: (response: ChatMessage) => normalizeChatMessage(response),
      invalidatesTags: [{ type: 'Chat', id: 'INBOX' }, { type: 'Chat', id: 'UNREAD' }],
    }),

    getChatPublicKey: builder.query<
      { userId: string; publicKeySpkiBase64: string },
      string
    >({
      query: (targetUserId) => `/api/Chat/keys/${targetUserId}`,
      keepUnusedDataFor: 300,
    }),

    upsertMyChatPublicKey: builder.mutation<
      { userId: string; publicKeySpkiBase64: string },
      { publicKeySpkiBase64: string }
    >({
      query: (body) => ({
        url: '/api/Chat/keys/me',
        method: 'PUT',
        body,
      }),
    }),

    upsertSupportChatKeys: builder.mutation<
      { userId: string; publicKeySpkiBase64: string },
      { publicKeySpkiBase64: string; privateKeyPkcs8Base64: string }
    >({
      query: (body) => ({
        url: '/api/Chat/keys/support',
        method: 'PUT',
        body,
      }),
    }),

    getSupportChatPrivateKey: builder.query<
      { userId: string; privateKeyPkcs8Base64: string },
      void
    >({
      query: () => '/api/Chat/keys/support/private',
    }),

    markChatSeen: builder.mutation<
      { viewerUserId: string; otherUserId: string; seenAtUtc: string; markedCount: number },
      { otherUserId: string }
    >({
      query: (body) => ({
        url: '/api/Chat/seen',
        method: 'POST',
        body,
      }),
      invalidatesTags: (_result, _error, arg) => [
        { type: 'Chat', id: 'INBOX' },
        { type: 'Chat', id: 'UNREAD' },
        { type: 'Chat', id: `THREAD:${arg.otherUserId}` },
      ],
    }),

    markChatDelivered: builder.mutation<
      {
        fromUserId: string
        toUserId: string
        messageIds: string[]
        deliveredAtUtc: string
        markedCount: number
      },
      { otherUserId: string }
    >({
      query: (body) => ({
        url: '/api/Chat/delivered',
        method: 'POST',
        body,
      }),
    }),

    uploadChatMedia: builder.mutation<
      ChatUploadResult,
      { file: File; messageType: 2 | 3 | 5 | 6 }
    >({
      queryFn: async ({ file, messageType }) => {
        try {
          const { uploadChatMediaDirect } = await import('../utils/chatDirectUpload')
          const data = await uploadChatMediaDirect(file, messageType)
          return { data }
        } catch (error) {
          return {
            error: {
              status: 'FETCH_ERROR',
              error: error instanceof Error ? error.message : 'تعذر رفع الملف.',
            },
          }
        }
      },
    }),

    uploadChatImages: builder.mutation<ChatUploadImagesResult, { files: File[] }>({
      queryFn: async ({ files }) => {
        try {
          const { uploadChatImagesDirect } = await import('../utils/chatDirectUpload')
          const data = await uploadChatImagesDirect(files)
          return { data }
        } catch (error) {
          return {
            error: {
              status: 'FETCH_ERROR',
              error: error instanceof Error ? error.message : 'تعذر رفع الصور.',
            },
          }
        }
      },
    }),

    getPermissionDefinitions: builder.query<AdminPermissionDefinition[], void>({
      query: () => '/api/admin/employees/permissions',
      transformResponse: (response: AdminPermissionDefinition[]) =>
        response.map((item) => normalizePermissionDefinition(item as unknown as Record<string, unknown>)),
      keepUnusedDataFor: 60,
    }),

    getAdminMonitoring: builder.query<AdminMonitoringOverview, MonitoringRange | void>({
      query: (range) => ({
        url: '/api/admin/monitoring',
        params: { range: range || '1h' },
      }),
      providesTags: [{ type: 'Monitoring', id: 'OVERVIEW' }],
      keepUnusedDataFor: 20,
    }),

    getAdminAuditLogs: builder.query<AdminAuditLogsResponse, AdminAuditLogsFilters | void>({
      query: (params) => ({
        url: '/api/admin/audit-logs',
        params: {
          page: params?.page ?? 1,
          pageSize: params?.pageSize ?? 20,
          search: params?.search || undefined,
          action: params?.action || undefined,
          entityType: params?.entityType || undefined,
          fromUtc: params?.fromUtc || undefined,
          toUtc: params?.toUtc || undefined,
        },
      }),
      providesTags: [{ type: 'AuditLogs', id: 'LIST' }],
      keepUnusedDataFor: 45,
    }),

    getMissedProductSearches: builder.query<
      MissedProductSearchesResponse,
      MissedProductSearchesFilters | void
    >({
      query: (params) => ({
        url: '/api/admin/missed-product-searches',
        params: {
          page: params?.page ?? 1,
          pageSize: params?.pageSize ?? 20,
          search: params?.search || undefined,
          fromUtc: params?.fromUtc || undefined,
          toUtc: params?.toUtc || undefined,
        },
      }),
      providesTags: [{ type: 'MissedProductSearches', id: 'LIST' }],
      keepUnusedDataFor: 45,
    }),

    getEmployees: builder.query<
      AdminEmployeesResponse,
      { page?: number; pageSize?: number; search?: string }
    >({
      query: ({ page = 1, pageSize = 20, search }) => ({
        url: '/api/admin/employees',
        params: { page, pageSize, search: search || undefined },
      }),
      transformResponse: (response: AdminEmployeesResponse) => ({
        ...response,
        items: (response.items ?? []).map((item) =>
          normalizeEmployee(item as unknown as Record<string, unknown>),
        ),
      }),
      providesTags: [{ type: 'Employees', id: 'LIST' }],
    }),

    getEmployeeDetail: builder.query<AdminEmployeeDetail, string>({
      query: (employeeId) => `/api/admin/employees/${employeeId}`,
      transformResponse: (response: AdminEmployeeDetail) =>
        normalizeEmployeeDetail(response as unknown as Record<string, unknown>),
      providesTags: (_result, _error, employeeId) => [{ type: 'Employees', id: employeeId }],
    }),

    createEmployee: builder.mutation<AdminEmployeeDetail, CreateEmployeePayload>({
      query: (body) => ({
        url: '/api/admin/employees',
        method: 'POST',
        body,
      }),
      transformResponse: (response: AdminEmployeeDetail) =>
        normalizeEmployeeDetail(response as unknown as Record<string, unknown>),
      invalidatesTags: [{ type: 'Employees', id: 'LIST' }],
    }),

    updateEmployee: builder.mutation<
      AdminEmployeeDetail,
      { employeeId: string; body: UpdateEmployeePayload }
    >({
      query: ({ employeeId, body }) => ({
        url: `/api/admin/employees/${employeeId}`,
        method: 'PUT',
        body,
      }),
      transformResponse: (response: AdminEmployeeDetail) =>
        normalizeEmployeeDetail(response as unknown as Record<string, unknown>),
      invalidatesTags: (_result, _error, arg) => [
        { type: 'Employees', id: 'LIST' },
        { type: 'Employees', id: arg.employeeId },
      ],
    }),

    deleteEmployee: builder.mutation<{ message: string }, string>({
      query: (employeeId) => ({
        url: `/api/admin/employees/${employeeId}`,
        method: 'DELETE',
      }),
      invalidatesTags: [{ type: 'Employees', id: 'LIST' }],
    }),

    getFinanceWithdrawals: builder.query<
      AdminFinanceWithdrawalsResponse,
      { page?: number; pageSize?: number; statusId?: number; search?: string }
    >({
      query: (params) => ({
        url: '/api/admin/finance/withdrawals',
        params,
      }),
      providesTags: [{ type: 'Finance', id: 'WITHDRAWALS' }],
    }),

    getCompanyFinanceProfile: builder.query<AdminCompanyFinanceProfile, string>({
      query: (userId) => `/api/admin/finance/companies/${userId}`,
      providesTags: (_result, _error, userId) => [{ type: 'Finance', id: `PROFILE-${userId}` }],
    }),

    getCompanyFinanceStatement: builder.query<
      AdminBalanceStatementResponse,
      { userId: string; page?: number; pageSize?: number }
    >({
      query: ({ userId, page, pageSize }) => ({
        url: `/api/admin/finance/companies/${userId}/statement`,
        params: { page, pageSize },
      }),
      providesTags: (_result, _error, { userId }) => [{ type: 'Finance', id: `STATEMENT-${userId}` }],
    }),

    markWithdrawalPaid: builder.mutation<
      { message: string; id: string; completedAtUtc: string },
      { withdrawalRequestId: string; notes?: string | null; supplierId: string }
    >({
      query: ({ withdrawalRequestId, notes }) => ({
        url: `/api/admin/finance/withdrawals/${withdrawalRequestId}/mark-paid`,
        method: 'POST',
        body: { notes: notes ?? null },
      }),
      invalidatesTags: (_result, _error, { supplierId }) => [
        { type: 'Finance', id: 'WITHDRAWALS' },
        { type: 'Finance', id: `PROFILE-${supplierId}` },
        { type: 'Finance', id: `STATEMENT-${supplierId}` },
        { type: 'AuditLogs', id: 'LIST' },
      ],
    }),

    claimSupportConversation: builder.mutation<ChatSupportAssignment, { otherUserId: string }>({
      query: (body) => ({
        url: '/api/Chat/support/claim',
        method: 'POST',
        body,
      }),
      invalidatesTags: [{ type: 'Chat', id: 'INBOX' }],
    }),

    releaseSupportConversation: builder.mutation<{ message: string }, { otherUserId: string }>({
      query: (body) => ({
        url: '/api/Chat/support/release',
        method: 'POST',
        body,
      }),
      invalidatesTags: [{ type: 'Chat', id: 'INBOX' }],
    }),
  }),
})

export const {
  useGetDashboardQuery,
  useGetAdminLiveCountsQuery,
  useGetUsersQuery,
  useGetAdminUserDetailQuery,
  useGetAdminProductStatsQuery,
  useGetAdminProductsQuery,
  useApproveProductMutation,
  useRejectProductMutation,
  useGetAdminProductDetailQuery,
  useGetAdminProductLookupsQuery,
  useUpdateAdminProductMutation,
  useUploadAdminProductImageMutation,
  useDeleteAdminProductImageMutation,
  useDeleteAdminProductVideoMutation,
  useSetAdminProductVideoMuteMutation,
  useApproveCompanyMutation,
  useRejectCompanyMutation,
  useSetUserActiveMutation,
  useDeleteAdminUserMutation,
  useDeleteProductMutation,
  useGetAdminOrderStatsQuery,
  useGetAdminOrderDetailQuery,
  useGetAdminOrdersQuery,
  useLazyGetAdminOrdersQuery,
  useRespondToOrderReturnMutation,
  useManualRefundOrderMutation,
  useApproveRequestOfferMutation,
  useSetRequestOfferAdvertiserPriceMutation,
  useRejectRequestOfferMutation,
  useUpdateOrderStatusMutation,
  useSetCustomOrderStatusMutation,
  useMarkOrderReceivedMutation,
  useUploadOrderImageMutation,
  useDeleteOrderImageMutation,
  useUploadOrderVideoMutation,
  useDeleteOrderVideoMutation,
  useUploadAdminProductVideoMutation,
  useGetShippingProvidersQuery,
  useGetShippingProviderDetailQuery,
  useSetShippingProviderActiveMutation,
  useCreateShippingProviderMutation,
  useUpdateShippingProviderMutation,
  useDeleteShippingProviderMutation,
  useApproveShippingPostMutation,
  useRejectShippingPostMutation,
  useUploadShippingProviderImageMutation,
  useGetCategoriesQuery,
  useCreateCategoryMutation,
  useUpdateCategoryMutation,
  useSetCategoryVisibilityMutation,
  useUploadCategoryImageMutation,
  useDeleteCategoryMutation,
  useGetHomeBannersQuery,
  useCreateHomeBannerMutation,
  useUpdateHomeBannerMutation,
  useDeleteHomeBannerMutation,
  useGetSystemSettingsQuery,
  useUpdateSystemSettingsMutation,
  useGetInternalDomesticShippingQuery,
  useUpdateInternalDomesticShippingMutation,
  useGetAdminNotificationsQuery,
  useSendAdminNotificationMutation,
  useGetGlobalSearchQuery,
  useLazyGetGlobalSearchSuggestQuery,
  useGetGeoCountriesQuery,
  useGetGeoPortsByCountryQuery,
  useGetChatInboxQuery,
  useGetChatUnreadCountQuery,
  useSearchChatConversationsQuery,
  useGetChatMessagesQuery,
  useGetChatConversationDetailsQuery,
  useSendChatMessageMutation,
  useGetChatPublicKeyQuery,
  useLazyGetChatPublicKeyQuery,
  useUpsertMyChatPublicKeyMutation,
  useUpsertSupportChatKeysMutation,
  useLazyGetSupportChatPrivateKeyQuery,
  useMarkChatSeenMutation,
  useMarkChatDeliveredMutation,
  useUploadChatMediaMutation,
  useUploadChatImagesMutation,
  useGetPermissionDefinitionsQuery,
  useGetAdminMonitoringQuery,
  useGetAdminAuditLogsQuery,
  useGetMissedProductSearchesQuery,
  useGetEmployeesQuery,
  useGetEmployeeDetailQuery,
  useCreateEmployeeMutation,
  useUpdateEmployeeMutation,
  useDeleteEmployeeMutation,
  useGetFinanceWithdrawalsQuery,
  useGetCompanyFinanceProfileQuery,
  useGetCompanyFinanceStatementQuery,
  useMarkWithdrawalPaidMutation,
  useClaimSupportConversationMutation,
  useReleaseSupportConversationMutation,
} = adminApi
