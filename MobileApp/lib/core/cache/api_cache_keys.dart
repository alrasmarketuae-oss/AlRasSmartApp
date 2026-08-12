/// Cache key prefixes and TTL values for API responses.
class ApiCacheKeys {
  ApiCacheKeys._();

  static const categories = 'catalog.categories.v2';
  static const homeBanners = 'catalog.home_banners';
  static const geoCountries = 'geo.countries.v2';
  static const domesticEmirates = 'geo.domestic_emirates';

  static String geoPorts(String countryName) =>
      'geo.ports.v2.${countryName.trim().toLowerCase()}';

  static String geoCities(String countryName) =>
      'geo.cities.${countryName.trim().toLowerCase()}';

  static String homeProducts(int page, int pageSize) =>
      'products.home.catalog.v8.p$page.s$pageSize';

  static String featuredProducts(int page, int pageSize) =>
      'products.featured.catalog.v3.p$page.s$pageSize';

  static String productsByType(String type, int page, int pageSize) =>
      'products.type.v2.${type.toLowerCase()}.p$page.s$pageSize';

  static String productsByCategory(int categoryId, int page, int pageSize) =>
      'products.category.v5.$categoryId.p$page.s$pageSize';

  static String userProfile(String userId) => 'user.profile.$userId';

  static String userOrders(String userId, int page, int pageSize) =>
      'user.orders.$userId.p$page.s$pageSize';

  static const userOrdersPrefix = 'user.orders.';

  static String userAddresses(String userId) => 'user.addresses.$userId';

  static const productSearchNames = 'catalog.product_search_names';

  static const homePrefix = 'products.';
  static const userPrefix = 'user.';
}

/// Time-to-live per resource type.
class ApiCacheTtl {
  ApiCacheTtl._();

  static const catalog = Duration(hours: 6);
  static const geo = Duration(days: 7);
  /// Short TTL so commission / price markup changes from admin appear quickly.
  static const products = Duration(minutes: 1);
  static const profile = Duration(minutes: 30);
  static const orders = Duration(minutes: 2);
  static const addresses = Duration(minutes: 5);

  /// Stale entries may still be shown offline for up to this age.
  static const maxStale = Duration(days: 7);
}
