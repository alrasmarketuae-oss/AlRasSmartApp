import { Navigate, Route, Routes } from 'react-router-dom'
import AdminLayout from '../layouts/AdminLayout'
import CategoriesPage from '../pages/CategoriesPage'
import BannersPage from '../pages/BannersPage'
import ChatPage from '../pages/ChatPage'
import AiConversationsPage from '../pages/AiConversationsPage'
import ShippingPage from '../pages/ShippingPage'
import ShippingDetailPage from '../pages/ShippingDetailPage'
import DashboardPage from '../pages/DashboardPage'
import UsersPage from '../pages/UsersPage'
import UserDetailPage from '../pages/UserDetailPage'
import UserAdsPage from '../pages/UserAdsPage'
import AdsPage from '../pages/AdsPage'
import AdDetailPage from '../pages/AdDetailPage'
import OrderDetailPage from '../pages/OrderDetailPage'
import OrdersPage from '../pages/OrdersPage'
import ReqsOffersPage from '../pages/ReqsOffersPage'
import LoginPage from '../pages/LoginPage'
import PaymentCancelPage from '../pages/PaymentCancelPage'
import PaymentSuccessPage from '../pages/PaymentSuccessPage'
import SettingsPage from '../pages/SettingsPage'
import NotificationsPage from '../pages/NotificationsPage'
import GlobalSearchPage from '../pages/GlobalSearchPage'
import AuditLogsPage from '../pages/AuditLogsPage'
import MonitoringPage from '../pages/MonitoringPage'
import MissedProductSearchesPage from '../pages/MissedProductSearchesPage'
import TechSupportCallbacksPage from '../pages/TechSupportCallbacksPage'
import EmployeesPage from '../pages/EmployeesPage'
import PermissionRoute from './PermissionRoute'
import { getAuthToken, getAuthUser } from '../lib/authStorage'
import { getDefaultRoute, isSuperAdmin, PERMISSIONS } from '../lib/permissions'

function LoginRoute() {
  if (getAuthToken()) {
    return <Navigate to={getDefaultRoute()} replace />
  }
  return <LoginPage />
}

function ProtectedLayout() {
  if (!getAuthToken()) {
    return <Navigate to="/login" replace />
  }
  return <AdminLayout />
}

function SuperAdminRoute({ children }: { children: React.ReactNode }) {
  if (!isSuperAdmin(getAuthUser()?.roleName)) {
    return <Navigate to={getDefaultRoute()} replace />
  }
  return <>{children}</>
}

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<LoginRoute />} />
      <Route path="/payment-success" element={<PaymentSuccessPage />} />
      <Route path="/payment-cancel" element={<PaymentCancelPage />} />
      <Route element={<ProtectedLayout />}>
        <Route
          path="/"
          element={
            <PermissionRoute permission={PERMISSIONS.dashboardView}>
              <DashboardPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/users"
          element={
            <PermissionRoute
              anyOf={[PERMISSIONS.usersView, PERMISSIONS.usersProfileEdits]}
            >
              <UsersPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/users/:userId"
          element={
            <PermissionRoute
              anyOf={[PERMISSIONS.usersView, PERMISSIONS.usersProfileEdits]}
            >
              <UserDetailPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/users/:userId/ads"
          element={
            <PermissionRoute
              anyOf={[
                PERMISSIONS.usersView,
                PERMISSIONS.usersProfileEdits,
                PERMISSIONS.productsView,
                PERMISSIONS.productsAdEdits,
              ]}
            >
              <UserAdsPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/ads"
          element={
            <PermissionRoute
              anyOf={[PERMISSIONS.productsView, PERMISSIONS.productsAdEdits]}
            >
              <AdsPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/ads/:productId"
          element={
            <PermissionRoute
              anyOf={[PERMISSIONS.productsView, PERMISSIONS.productsAdEdits]}
            >
              <AdDetailPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/orders"
          element={<Navigate to="/orders/all" replace />}
        />
        <Route
          path="/orders/all"
          element={
            <PermissionRoute permission={PERMISSIONS.ordersView}>
              <OrdersPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/orders/retail"
          element={
            <PermissionRoute permission={PERMISSIONS.ordersView}>
              <OrdersPage channel="retail" />
            </PermissionRoute>
          }
        />
        <Route
          path="/orders/booking"
          element={
            <PermissionRoute permission={PERMISSIONS.ordersView}>
              <OrdersPage channel="booking" />
            </PermissionRoute>
          }
        />
        <Route
          path="/orders/offers"
          element={
            <PermissionRoute permission={PERMISSIONS.ordersView}>
              <OrdersPage channel="offers" />
            </PermissionRoute>
          }
        />
        <Route
          path="/orders/categories"
          element={
            <PermissionRoute permission={PERMISSIONS.ordersView}>
              <OrdersPage channel="categories" />
            </PermissionRoute>
          }
        />
        <Route
          path="/reqs-offers"
          element={
            <PermissionRoute
              anyOf={[PERMISSIONS.ordersView, PERMISSIONS.ordersReqsOffers]}
            >
              <ReqsOffersPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/orders/:orderId"
          element={
            <PermissionRoute
              anyOf={[PERMISSIONS.ordersView, PERMISSIONS.ordersReqsOffers]}
            >
              <OrderDetailPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/categories"
          element={
            <PermissionRoute permission={PERMISSIONS.categoriesManage}>
              <CategoriesPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/banners"
          element={
            <PermissionRoute permission={PERMISSIONS.bannersManage}>
              <BannersPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/shipping"
          element={
            <PermissionRoute permission={PERMISSIONS.shippingView}>
              <ShippingPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/shipping/:providerId"
          element={
            <PermissionRoute permission={PERMISSIONS.shippingView}>
              <ShippingDetailPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/chat"
          element={
            <PermissionRoute permission={PERMISSIONS.chatAccess}>
              <ChatPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/ai-conversations"
          element={
            <PermissionRoute permission={PERMISSIONS.chatAccess}>
              <AiConversationsPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/search"
          element={
            <PermissionRoute permission={PERMISSIONS.searchAccess}>
              <GlobalSearchPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/notifications"
          element={
            <PermissionRoute permission={PERMISSIONS.notificationsView}>
              <NotificationsPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/tech-support"
          element={
            <PermissionRoute permission={PERMISSIONS.chatAccess}>
              <TechSupportCallbacksPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/missed-searches"
          element={
            <PermissionRoute permission={PERMISSIONS.searchAccess}>
              <MissedProductSearchesPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/audit-logs"
          element={
            <PermissionRoute permission={PERMISSIONS.auditView}>
              <AuditLogsPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/monitoring"
          element={
            <PermissionRoute permission={PERMISSIONS.monitoringView}>
              <MonitoringPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/settings"
          element={
            <PermissionRoute permission={PERMISSIONS.settingsView}>
              <SettingsPage />
            </PermissionRoute>
          }
        />
        <Route
          path="/employees"
          element={
            <SuperAdminRoute>
              <EmployeesPage />
            </SuperAdminRoute>
          }
        />
      </Route>
      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  )
}
