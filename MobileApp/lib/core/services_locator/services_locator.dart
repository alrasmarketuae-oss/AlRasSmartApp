import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/features/clint/data/datasource/address_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/datasource/cart_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/repository/address_repository.dart';
import 'package:alrasmarket/features/clint/domain/usecases/address_usecases.dart';
import 'package:alrasmarket/features/clint/data/datasource/payment_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/datasource/home_banners_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/datasource/categories_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/datasource/order_remote_data_source.dart';
import 'package:alrasmarket/features/clint/data/repository/cart_repository.dart';
import 'package:alrasmarket/features/clint/data/repository/home_banners_repository.dart';
import 'package:alrasmarket/features/clint/data/repository/categories_repository.dart';
import 'package:alrasmarket/features/clint/data/repository/order_repository.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_cart_repository.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_home_banners_repository.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_categories_repository.dart';
import 'package:alrasmarket/features/clint/domain/repository/base_order_repository.dart';
import 'package:alrasmarket/features/clint/domain/usecases/add_cart_item_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/confirm_cart_order_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/get_cart_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/get_home_banners_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/get_categories_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/order_usecases.dart';
import 'package:alrasmarket/features/clint/domain/usecases/payment_usecases.dart';
import 'package:alrasmarket/features/clint/domain/usecases/reduce_cart_item_quantity_usecase.dart';
import 'package:alrasmarket/features/clint/domain/usecases/remove_cart_item_usecase.dart';
import 'package:alrasmarket/features/clint/presentation/controller/cubit/clint_cubit.dart';
import 'package:alrasmarket/features/company/data/datasource/geo_remote_data_source.dart';
import 'package:alrasmarket/features/company/data/datasource/product_remote_data_source.dart';
import 'package:alrasmarket/features/company/data/repository/geo_repository.dart';
import 'package:alrasmarket/features/company/data/repository/product_repository.dart';
import 'package:alrasmarket/features/company/domain/repository/base_geo_repository.dart';
import 'package:alrasmarket/features/company/domain/repository/base_product_repository.dart';
import 'package:alrasmarket/features/company/domain/usecases/ad_offers_usecases.dart';
import 'package:alrasmarket/features/company/domain/usecases/create_ad_usecases.dart';
import 'package:alrasmarket/features/company/domain/usecases/get_geo_usecases.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/company_cubit.dart';
import 'package:alrasmarket/features/company/presentation/controller/cubit/create_ad_cubit.dart';
import 'package:alrasmarket/features/person/presentation/controller/cubit/person_cubit.dart';
import 'package:alrasmarket/features/shipping_company/data/datasource/shipping_company_remote_data_source.dart';
import 'package:alrasmarket/features/shipping_company/data/repository/shipping_company_repository.dart';
import 'package:alrasmarket/features/shipping_company/presentation/controller/cubit/shipping_company_cubit.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasource/auth_remote_data_source.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/controller/cubit/auth_cubit.dart';
import '../../features/auth/data/repository/auth_repository.dart';
import '../../features/auth/domain/repository/base_auth_repository.dart';
import '../../features/auth/domain/usecases/register_person_usecase.dart';
import '../../features/auth/domain/usecases/register_company_usecase.dart';
import '../../features/auth/domain/usecases/send_email_otp_usecase.dart';
import '../../features/auth/domain/usecases/upload_file_usecase.dart';
import '../../features/auth/domain/usecases/verify_email_otp_usecase.dart';

final sl = GetIt.instance;

class ServicesLocator {
  void init() {
    //! Features - Auth

    // Cubit
    sl.registerLazySingleton(
      () => AuthCubit(
        loginUseCase: sl(),
        registerClientUseCase: sl(),
        registerSellerUseCase: sl(),
        verifyEmailOtpUseCase: sl(),
        sendEmailOtpUseCase: sl(),
        uploadCommercialLicenseUseCase: sl(),
        uploadSellerIdentityUseCase: sl(),
        authRepository: sl(),
      ),
    );

    // Use Cases
    sl.registerLazySingleton(() => LoginUseCase(sl()));
    sl.registerLazySingleton(() => RegisterPersonUseCase(sl()));
    sl.registerLazySingleton(() => RegisterCompanyUseCase(sl()));
    sl.registerLazySingleton(() => VerifyEmailOtpUseCase(sl()));
    sl.registerLazySingleton(() => SendEmailOtpUseCase(sl()));
    sl.registerLazySingleton(() => UploadCommercialLicenseUseCase(sl()));
    sl.registerLazySingleton(() => UploadSellerIdentityUseCase(sl()));

    //     // Repository
    sl.registerLazySingleton<BaseAuthRepository>(
      () => AuthRepository(baseAuthRemoteDataSource: sl()),
    );

    // Data Source
    sl.registerLazySingleton<BaseAuthRemoteDataSource>(
      () => AuthRemoteDataSource(),
    );

    //! Features - Clint

    sl.registerLazySingleton<BaseHomeBannersRemoteDataSource>(
      () => HomeBannersRemoteDataSource(),
    );
    sl.registerLazySingleton<BaseHomeBannersRepository>(
      () => HomeBannersRepository(remote: sl()),
    );
    sl.registerLazySingleton(() => GetHomeBannersUseCase(sl()));

    sl.registerLazySingleton<BaseCategoriesRemoteDataSource>(
      () => CategoriesRemoteDataSource(),
    );
    sl.registerLazySingleton<BaseCategoriesRepository>(
      () => CategoriesRepository(remote: sl()),
    );
    sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));

    sl.registerLazySingleton<BaseCartRemoteDataSource>(
      () => CartRemoteDataSource(),
    );
    sl.registerLazySingleton<BaseCartRepository>(
      () => CartRepository(remote: sl()),
    );
    sl.registerLazySingleton(() => GetCartUseCase(sl()));
    sl.registerLazySingleton(() => AddCartItemUseCase(sl()));
    sl.registerLazySingleton(() => RemoveCartItemUseCase(sl()));
    sl.registerLazySingleton(() => ReduceCartItemQuantityUseCase(sl()));
    sl.registerLazySingleton(() => ConfirmCartOrderUseCase(sl()));

    sl.registerLazySingleton<BasePaymentRemoteDataSource>(
      () => PaymentRemoteDataSource(),
    );
    sl.registerLazySingleton(() => CreateStripeCheckoutUseCase(sl()));
    sl.registerLazySingleton(() => GetCheckoutStatusUseCase(sl()));

    sl.registerLazySingleton<BaseOrderRemoteDataSource>(
      () => OrderRemoteDataSource(),
    );
    sl.registerLazySingleton<BaseOrderRepository>(
      () => OrderRepository(remote: sl()),
    );
    sl.registerLazySingleton(() => UploadOrderImageUseCase(sl()));
    sl.registerLazySingleton(() => UploadOrderVideoUseCase(sl()));
    sl.registerLazySingleton(() => UploadOrderDocumentUseCase(sl()));
    sl.registerLazySingleton(() => CreateOrderUseCase(sl()));
    sl.registerLazySingleton(() => GetMyOrdersUseCase(sl()));
    sl.registerLazySingleton(() => GetMyOffersUseCase(sl()));
    sl.registerLazySingleton(() => GetOrderByIdUseCase(sl()));
    sl.registerLazySingleton(() => RequestOrderReturnUseCase(sl()));

    // Cubit
    sl.registerLazySingleton(
      () => ClintCubit(
        getHomeBannersUseCase: sl(),
        getCategoriesUseCase: sl(),
        getCartUseCase: sl(),
        addCartItemUseCase: sl(),
        removeCartItemUseCase: sl(),
        reduceCartItemQuantityUseCase: sl(),
        confirmCartOrderUseCase: sl(),
        createStripeCheckoutUseCase: sl(),
        getCheckoutStatusUseCase: sl(),
        uploadOrderImageUseCase: sl(),
        uploadOrderVideoUseCase: sl(),
        uploadOrderDocumentUseCase: sl(),
        createOrderUseCase: sl(),
        getMyOrdersUseCase: sl(),
        getMyOffersUseCase: sl(),
        getOrderByIdUseCase: sl(),
        updateOrderStatusUseCase: sl(),
        requestOrderReturnUseCase: sl(),
        getGeoPortsByCountryUseCase: sl(),
        getClientAddressesUseCase: sl(),
      ),
    );
    //! Features - Company
    sl.registerLazySingleton(() => GetMyListingsUseCase(sl()));
    sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
    sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
    sl.registerLazySingleton(() => UpdateProductListingStatusUseCase(sl()));
    sl.registerLazySingleton(() => MarkProductSoldOutUseCase(sl()));
    sl.registerLazySingleton(() => GetMyOffersOnMyRequestsUseCase(sl()));
    sl.registerLazySingleton(() => UpdateOrderStatusUseCase(sl()));
    sl.registerLazySingleton(
      () => CompanyCubit(
        getMyListingsUseCase: sl(),
        deleteProductUseCase: sl(),
        updateProductListingStatusUseCase: sl(),
        markProductSoldOutUseCase: sl(),
        getMyOffersOnMyRequestsUseCase: sl(),
        updateOrderStatusUseCase: sl(),
      ),
    );
    sl.registerLazySingleton<BaseGeoRemoteDataSource>(
      () => GeoRemoteDataSource(),
    );
    sl.registerLazySingleton<BaseGeoRepository>(
      () => GeoRepository(remote: sl()),
    );
    sl.registerLazySingleton(() => GetGeoCountriesUseCase(sl()));
    sl.registerLazySingleton(() => GetGeoPortsByCountryUseCase(sl()));
    sl.registerLazySingleton(() => GetGeoCitiesByCountryUseCase(sl()));

    sl.registerLazySingleton<BaseAddressRemoteDataSource>(
      () => AddressRemoteDataSource(),
    );
    sl.registerLazySingleton<BaseAddressRepository>(
      () => AddressRepository(remote: sl()),
    );
    sl.registerLazySingleton(() => GetClientAddressesUseCase(sl()));
    sl.registerLazySingleton(() => CreateClientAddressUseCase(sl()));

    sl.registerLazySingleton<BaseProductRemoteDataSource>(
      () => ProductRemoteDataSource(),
    );
    sl.registerLazySingleton<BaseProductRepository>(
      () => ProductRepository(remote: sl()),
    );
    sl.registerLazySingleton(() => CreateProductUseCase(sl()));
    sl.registerLazySingleton(() => UploadProductImagesUseCase(sl()));
    sl.registerLazySingleton(() => DeleteProductImagesByPathUseCase(sl()));
    sl.registerLazySingleton(() => UploadProductDocumentsUseCase(sl()));
    sl.registerLazySingleton(() => UploadProductVideoUseCase(sl()));
    sl.registerLazySingleton(() => SubmitProductForAdminReviewUseCase(sl()));
    sl.registerFactory(
      () => CreateAdCubit(
        getGeoPortsByCountryUseCase: sl(),
        getCategoriesUseCase: sl(),
        createProductUseCase: sl(),
        updateProductUseCase: sl(),
        uploadProductImagesUseCase: sl(),
        deleteProductImagesByPathUseCase: sl(),
        uploadProductDocumentsUseCase: sl(),
        uploadProductVideoUseCase: sl(),
        submitProductForAdminReviewUseCase: sl(),
      ),
    );
    //! Features - User (Home, Banners, Category, Cart, MyAccount)

    sl.registerLazySingleton(() => PersonCubit(authService: sl()));
    sl.registerLazySingleton<BaseShippingCompanyRemoteDataSource>(
      () => ShippingCompanyRemoteDataSource(),
    );
    sl.registerLazySingleton(
      () => ShippingCompanyRepository(remote: sl()),
    );
    sl.registerLazySingleton(
      () => ShippingCompanyCubit(authService: sl(), repository: sl()),
    );
    sl.registerLazySingleton(() => AuthService.instance);
  }
}
