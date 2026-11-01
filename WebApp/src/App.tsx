import { lazy, Suspense, useEffect, type ReactNode } from 'react'
import { Link, Navigate, Route, Routes, useLocation } from 'react-router-dom'
import { destinationFor, useAuth } from './auth/AuthProvider'
import { Spinner } from './auth/components'
import { useI18n } from './i18n/I18nProvider'
import { MainLayout, PageContainer } from './layout/MainLayout'
import HomePage from './pages/HomePage'
import { CategoriesPage, CategoryProductsPage, ImageSearchPage, SearchPage, ServiceProductsPage } from './pages/ListingPages'

const WelcomePage = lazy(() => import('./pages/WelcomePage'))
const LoginPage = lazy(() => import('./pages/LoginPage'))
const RegisterPage = lazy(() => import('./pages/RegisterPage'))
const RegisterDocumentsPage = lazy(() => import('./pages/RegisterDocumentsPage'))
const OtpPage = lazy(() => import('./pages/OtpPage'))
const UnderReviewPage = lazy(() => import('./pages/UnderReviewPage'))
const ForgotPasswordPage = lazy(() => import('./pages/ForgotPasswordPage'))
const ResetPasswordPage = lazy(() => import('./pages/ResetPasswordPage'))
const ProductPage = lazy(() => import('./pages/ProductPage'))
const ProfilePage = lazy(() => import('./pages/ProfilePage'))
const SavedAdsPage = lazy(() => import('./pages/SavedAdsPage'))
const SupportChatPage = lazy(() => import('./pages/SupportChatPage'))
const AiAssistantHubPage = lazy(() => import('./pages/AiAssistantPages').then((m) => ({ default: m.AiAssistantHubPage })))
const AiChatPage = lazy(() => import('./pages/AiAssistantPages').then((m) => ({ default: m.AiChatPage })))
const PurchaseOrderPage = lazy(() => import('./pages/OrderFlowPages').then((m) => ({ default: m.PurchaseOrderPage })))
const SubmitOfferPage = lazy(() => import('./pages/OrderFlowPages').then((m) => ({ default: m.SubmitOfferPage })))
const OrderSuccessPage = lazy(() => import('./pages/OrderFlowPages').then((m) => ({ default: m.OrderSuccessPage })))
const CartPage = lazy(() => import('./pages/CommercePages').then((m) => ({ default: m.CartPage })))
const OrdersPage = lazy(() => import('./pages/CommercePages').then((m) => ({ default: m.OrdersPage })))
const TrackOrderPage = lazy(() => import('./pages/CommercePages').then((m) => ({ default: m.TrackOrderPage })))
const PaymentSuccessPage = lazy(() => import('./pages/CommercePages').then((m) => ({ default: m.PaymentSuccessPage })))
const PaymentCancelPage = lazy(() => import('./pages/CommercePages').then((m) => ({ default: m.PaymentCancelPage })))
const MyAdsPage = lazy(() => import('./pages/SellerPages').then((m) => ({ default: m.MyAdsPage })))
const AdDetailsPage = lazy(() => import('./pages/SellerPages').then((m) => ({ default: m.AdDetailsPage })))
const ChangePricesPage = lazy(() => import('./pages/SellerPages').then((m) => ({ default: m.ChangePricesPage })))
const NotificationsPage = lazy(() => import('./pages/SellerPages').then((m) => ({ default: m.NotificationsPage })))
const EditProfilePage = lazy(() => import('./pages/ProfileSubPages').then((m) => ({ default: m.EditProfilePage })))
const ChangePasswordPage = lazy(() => import('./pages/ProfileSubPages').then((m) => ({ default: m.ChangePasswordPage })))
const AddressesPage = lazy(() => import('./pages/ProfileSubPages').then((m) => ({ default: m.AddressesPage })))
const FeedbackPage = lazy(() => import('./pages/ProfileSubPages').then((m) => ({ default: m.FeedbackPage })))
const SupportPage = lazy(() => import('./pages/ProfileSubPages').then((m) => ({ default: m.SupportPage })))
const ModelTrainingPage = lazy(() => import('./pages/ProfileSubPages').then((m) => ({ default: m.ModelTrainingPage })))
const CreateAdPage = lazy(() => import('./pages/CreateAdPages').then((m) => ({ default: m.CreateAdPage })))
const CreateOrderPage = lazy(() => import('./pages/CreateAdPages').then((m) => ({ default: m.CreateOrderPage })))
const RequestPublishedPage = lazy(() => import('./pages/CreateAdPages').then((m) => ({ default: m.RequestPublishedPage })))

function ScrollToTop() {
  const { pathname, search } = useLocation()
  useEffect(() => {
    window.scrollTo({ top: 0 })
  }, [pathname, search])
  return null
}

/** Signed-in users skip the entry screens, like the app's redirect on launch. */
function GuestOnly({ children }: { children: ReactNode }) {
  const { isAuthenticated, session } = useAuth()
  return isAuthenticated ? <Navigate to={destinationFor(session)} replace /> : <>{children}</>
}

function PageFallback() {
  return (
    <div className="grid min-h-[60vh] place-items-center">
      <Spinner className="size-9 border-[3px] border-brand/25 border-t-brand" />
    </div>
  )
}

function NotFound() {
  const { t } = useI18n()
  return (
    <PageContainer className="flex flex-col items-center gap-4 py-24 text-center">
      <p className="text-5xl font-extrabold text-brand">404</p>
      <p className="text-auth-body">{t('pageNotFound')}</p>
      <Link to="/" className="rounded-xl bg-brand px-5 py-2.5 text-sm font-bold text-white">
        {t('goHome')}
      </Link>
    </PageContainer>
  )
}

export default function App() {
  return (
    <>
      <ScrollToTop />
      <Suspense fallback={<PageFallback />}>
        <Routes>
          <Route path="/welcome" element={<GuestOnly><WelcomePage /></GuestOnly>} />
          <Route path="/login" element={<GuestOnly><LoginPage /></GuestOnly>} />
          <Route path="/register" element={<GuestOnly><RegisterPage /></GuestOnly>} />
          <Route path="/register/documents" element={<GuestOnly><RegisterDocumentsPage /></GuestOnly>} />
          <Route path="/forgot-password" element={<ForgotPasswordPage />} />
          <Route path="/reset-password" element={<ResetPasswordPage />} />
          <Route path="/verify-otp" element={<OtpPage />} />
          <Route path="/under-review" element={<UnderReviewPage />} />

          <Route path="/product/:id/order" element={<PurchaseOrderPage />} />
          <Route path="/product/:id/offer" element={<SubmitOfferPage />} />
          <Route path="/product/:id/:slug?" element={<ProductPage />} />
          <Route path="/order-success" element={<OrderSuccessPage />} />
          <Route path="/saved-ads" element={<SavedAdsPage />} />
          <Route path="/chat" element={<SupportChatPage />} />
          <Route path="/chat/support" element={<SupportChatPage />} />
          <Route path="/ai-assistant" element={<AiAssistantHubPage />} />
          <Route path="/ai-assistant/chat" element={<AiChatPage />} />
          <Route path="/orders/:orderId" element={<TrackOrderPage />} />
          <Route path="/payment-success" element={<PaymentSuccessPage />} />
          <Route path="/payment-cancel" element={<PaymentCancelPage />} />
          <Route path="/my-ads/:productId" element={<AdDetailsPage />} />
          <Route path="/change-prices" element={<ChangePricesPage />} />
          <Route path="/notifications" element={<NotificationsPage />} />
          <Route path="/profile/edit" element={<EditProfilePage />} />
          <Route path="/profile/change-password" element={<ChangePasswordPage />} />
          <Route path="/profile/addresses" element={<AddressesPage />} />
          <Route path="/profile/feedback" element={<FeedbackPage />} />
          <Route path="/support" element={<SupportPage />} />
          <Route path="/model-training" element={<ModelTrainingPage />} />
          <Route path="/request-published" element={<RequestPublishedPage />} />

          <Route element={<MainLayout />}>
            <Route index element={<HomePage />} />
            <Route path="/categories" element={<CategoriesPage />} />
            <Route path="/category/:id" element={<CategoryProductsPage />} />
            <Route path="/services/:type" element={<ServiceProductsPage />} />
            <Route path="/search" element={<SearchPage />} />
            <Route path="/search/image" element={<ImageSearchPage />} />
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/cart" element={<CartPage />} />
            <Route path="/orders" element={<OrdersPage />} />
            <Route path="/my-ads" element={<MyAdsPage />} />
            <Route path="/create-ad" element={<CreateAdPage />} />
            <Route path="/create-order" element={<CreateOrderPage />} />
            <Route path="*" element={<NotFound />} />
          </Route>
        </Routes>
      </Suspense>
    </>
  )
}
