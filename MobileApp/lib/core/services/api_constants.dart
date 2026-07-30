class ApiConstants {
  /// Always false for store/release APKs — points at production API.
  static bool isLocal = false;
  static String baseUrl = isLocal
      ? 'https://192.168.68.63:7259/api'
      : 'https://api.alrasmarketapp.com/api';

  /// Scheme + host + port from [baseUrl] (use for static files / banner images on same host as API).
  static String get apiOrigin => Uri.parse(baseUrl).origin;

  /// Public media host — custom CDN only (no r2.dev public URL).
  static String mediaBaseUrl = 'https://cdn.alrasmarketapp.com';

  /// Legacy R2 public host — always rewritten to [mediaBaseUrl].
  static const String legacyMediaHost =
      'pub-63bb2df7433f4fd4a71249ac40f944ca.r2.dev';

  /// API host — product-images/videos return 404 here; rewrite those paths to the CDN.
  static const String apiMediaHost = 'api.alrasmarketapp.com';

  /// Full GET URL for home banners. Built from [apiOrigin] so it never hits `/HomeBanners` at domain root
  /// (Dio + paths starting with `/` drop the `/api` segment — see Uri.resolve).
  static String get homeBannersAbsoluteUrl => '$apiOrigin/api/HomeBanners';

  /// Static files (product images, categories, banners, videos) on the CDN.
  static String get baseUrlForImages {
    final media = mediaBaseUrl.trim();
    if (media.isEmpty) return '$apiOrigin/';
    return media.endsWith('/') ? media : '$media/';
  }

  static bool _isMediaObjectPath(String path) {
    final lower = path.toLowerCase();
    return lower.contains('/product-images/') ||
        lower.contains('/product-videos/') ||
        lower.contains('/product-documents/') ||
        lower.contains('/home-banners/') ||
        lower.contains('/images/categories/') ||
        lower.contains('/branding/') ||
        lower.contains('/chat-') ||
        lower.startsWith('product-images/') ||
        lower.startsWith('product-videos/') ||
        lower.startsWith('product-documents/') ||
        lower.startsWith('home-banners/') ||
        lower.startsWith('images/categories/') ||
        lower.startsWith('branding/');
  }

  /// Rewrites legacy r2.dev / API absolute media URLs to the CDN only.
  static String rewriteMediaUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return trimmed;

    final host = uri.host.toLowerCase();
    final media = mediaBaseUrl.trim();
    if (media.isEmpty) return trimmed;

    final mediaHost = Uri.tryParse(media)?.host.toLowerCase() ?? '';
    if (host == mediaHost) return trimmed;

    final shouldRewrite = host == legacyMediaHost ||
        (host == apiMediaHost && _isMediaObjectPath(uri.path));
    if (!shouldRewrite) return trimmed;

    final cdn = Uri.parse(media);
    return uri
        .replace(
          scheme: cdn.scheme,
          host: cdn.host,
          port: cdn.hasPort ? cdn.port : null,
        )
        .toString();
  }

  /// Relative DB path or absolute URL → public CDN media URL.
  static String resolveMediaUrl(String? path) {
    if (path == null) return '';
    final trimmed = path.trim().replaceAll('\\', '/');
    if (trimmed.isEmpty) return '';
    // Handle values accidentally stored as "/https://cdn.../file.jpg"
    final unwrapped = trimmed.replaceFirst(RegExp(r'^/+(https?:/)'), r'$1');
    if (unwrapped.startsWith('http://') || unwrapped.startsWith('https://')) {
      return rewriteMediaUrl(unwrapped);
    }
    final normalized =
        unwrapped.startsWith('/') ? unwrapped.substring(1) : unwrapped;
    return '$baseUrlForImages$normalized';
  }
  static String geoCountriesEndPoint = '/Geo/countries';
  static String geoCitiesByCountryEndPoint = '/Geo/cities';
  static String geoPortsByCountryEndPoint(String countryName) =>
      '/Geo/countries/${Uri.encodeComponent(countryName)}/ports';

  static String addressesEndPoint = '/Addresses';

  static String internationalShippingSearchEndPoint =
      '/InternationalShipping/search';

  static String shippingCompanyDashboardEndPoint = '/ShippingCompany/dashboard';
  static String shippingCompanyPostsEndPoint = '/ShippingCompany/posts';
  static String shippingCompanyPostByIdEndPoint(int postId) =>
      '/ShippingCompany/posts/$postId';

  static String internalDomesticShippingEmiratesEndPoint =
      '/InternalDomesticShipping/emirates';
  static String internalDomesticShippingPriceEndPoint =
      '/InternalDomesticShipping/price';

  // Auth Endpoints
  static String loginEndPoint = '/Auth/login';
  static String clearFcmTokenEndPoint = '/Auth/clear-fcm-token';
  static String deleteAccountEndPoint = '/Auth/delete-account';
  static String registerPersonEndPoint = '/Auth/register-person';
  static String registerCompanyEndPoint = '/Auth/register-company';
  static String registerShippingCompanyEndPoint =
      '/Auth/register-shipping-company';
  static String verifyEmailOtpEndPoint = '/Auth/verify-email-otp';
  static String sendEmailOtpEndPoint = '/Auth/send-email-otp';
  static String forgotPasswordRequestEndPoint = '/Auth/forgot-password/request';
  static String forgotPasswordResetEndPoint = '/Auth/forgot-password/reset';
  static String changePasswordEndPoint = '/Auth/change-password';
  static String accountApprovalStatusEndPoint(String email) =>
      '/Auth/account-approval-status?email=${Uri.encodeComponent(email)}';
  static String uploadCompanyLicenceEndPoint = '/CompanyLicence/upload';
  static String uploadCompanyImagesEndPoint = '/CompanyImages/upload';

  static String userProfileEndPoint = '/users/me';
  static String userProfileImageEndPoint = '/users/me/image';
  static String userPreferredLanguageEndPoint = '/UserPreferences/language';
  static String supplierBalanceEndPoint = '/supplier/balance';
  static String supplierBalanceStatementEndPoint = '/supplier/balance/statement';
  static String supplierBalanceIbansEndPoint = '/supplier/balance/ibans';
  static String supplierBalanceWithdrawalsEndPoint = '/supplier/balance/withdrawals';

  static String categoriesEndPoint = '/Categories';

  static String createProductEndPoint = '/Products';
  static String productsMyListingsEndPoint = '/Products/my-listings';
  static String productsFeaturedEndPoint = '/Products/featured';
  static String productsSearchEndPoint = '/Products/search';
  static String productsSearchNamesEndPoint = '/Products/search-names';
  static String productByCodeEndPoint(String productCode) =>
      '/Products/by-code/${Uri.encodeComponent(productCode)}';
  static String productsDetectByImageEndPoint = '/Products/detect-by-image';
  static String productsByTypeEndPoint(String productTypeName) =>
      '/Products/by-type/${Uri.encodeComponent(productTypeName)}';
  static String productsByCategoryEndPoint(int categoryId) =>
      '/Products/by-category/$categoryId';
  static String productByIdEndPoint(String productId, {bool asRetail = false}) =>
      asRetail ? '/Products/$productId?asRetail=true' : '/Products/$productId';
  static String productListingStatusEndPoint(String productId) =>
      '/Products/$productId/listing-status';
  static String productSoldOutEndPoint(String productId) =>
      '/Products/$productId/sold-out';
  static String productSubmitForReviewEndPoint(String productId) =>
      '/Products/$productId/submit-for-review';
  static String productIncreaseViewEndPoint(String productId) =>
      '/Products/$productId/increase-view';
  static String productImageUploadEndPoint(String productId) =>
      '/ProductAssets/$productId/images/upload';
  static String productImagePresignEndPoint(String productId) =>
      '/ProductAssets/$productId/images/presign';
  static String productImageConfirmEndPoint(String productId) =>
      '/ProductAssets/$productId/images/confirm';
  static String productAssetsConfirmBatchEndPoint(String productId) =>
      '/ProductAssets/$productId/assets/confirm-batch';
  static String productImageDeleteByPathEndPoint(String productId) =>
      '/ProductAssets/$productId/images';
  static String productDocumentUploadEndPoint(String productId) =>
      '/ProductAssets/$productId/documents/upload';
  static String productDocumentPresignEndPoint(String productId) =>
      '/ProductAssets/$productId/documents/presign';
  static String productDocumentConfirmEndPoint(String productId) =>
      '/ProductAssets/$productId/documents/confirm';
  static String productVideoUploadEndPoint(String productId) =>
      '/ProductAssets/$productId/videos/upload';
  static String productVideoPresignEndPoint(String productId) =>
      '/ProductAssets/$productId/videos/presign';
  static String productVideoConfirmEndPoint(String productId) =>
      '/ProductAssets/$productId/videos/confirm';

  static const String productDraftImagePresignEndPoint =
      '/ProductAssets/draft/images/presign';
  static const String productDraftVideoPresignEndPoint =
      '/ProductAssets/draft/videos/presign';
  static const String productDraftDeleteEndPoint = '/ProductAssets/draft';

  static String ordersEndPoint = '/Orders';
  static String myOrdersEndPoint = '/Orders/myOrders';
  static String myOffersEndPoint = '/Orders/myOffers';
  static String getMyOffersOnMyRequestsEndPoint =
      '/Orders/getMyOffersOnMyRequests';
  static String orderByIdEndPoint(int orderId) => '/Orders/$orderId';
  static String orderStatusEndPoint(int orderId) => '/Orders/$orderId/status';
  static String orderReturnEndPoint(int orderId) => '/Orders/$orderId/return';
  static String offerStagingImageUploadEndPoint =
      '/Orders/offer-staging/images/upload';
  static String offerStagingDocumentUploadEndPoint =
      '/Orders/offer-staging/documents/upload';
  static String offerStagingVideoUploadEndPoint =
      '/Orders/offer-staging/videos/upload';

  static String cartMeEndPoint = '/Carts/me';
  static String cartItemsEndPoint = '/Carts/items';
  static String cartItemByIdEndPoint(String cartItemId) =>
      '/Carts/items/$cartItemId';

  static String createStripeCheckoutEndPoint = '/Payments/CreateStripeCheckout';
  static String checkoutStatusEndPoint = '/Payments/CheckoutStatus';

  static String publicCommissionsEndPoint = '/settings/commissions';

  static String notificationsMineEndPoint = '/Notifications/mine';
  static String notificationsUnreadCountEndPoint = '/Notifications/unread-count';
  static String notificationsMarkAllReadEndPoint = '/Notifications/read-all';
  static String notificationMarkReadEndPoint(String id) =>
      '/Notifications/$id/read';

  static String get chatHubUrl => '$apiOrigin/chathub';
  static String get orderHubUrl => '$apiOrigin/orderhub';
  static const String supportAdminUserId =
      'BD469D54-8B82-47F3-A1F0-E1C5D91DDEB0';
  static String chatPresenceEndPoint = '/Chat/presence';
  static String chatMessagesEndPoint = '/Chat/messages';
  static String chatUploadEndPoint = '/Chat/upload';
  static String chatSeenEndPoint = '/Chat/seen';
  static String chatDeliveredEndPoint = '/Chat/delivered';
  static String chatConversationEndPoint = '/Chat/conversation';
  static String chatUnreadCountEndPoint = '/Chat/unread-count';
  static String chatKeysMeEndPoint = '/Chat/keys/me';
  static String chatKeysMePrivateEndPoint = '/Chat/keys/me/private';
  static String chatKeyByUserEndPoint(String userId) => '/Chat/keys/$userId';
  static const String encryptedMessagesInfoUrl =
      'https://www.alrasmarketapp.com/encrypted-messages';
}
