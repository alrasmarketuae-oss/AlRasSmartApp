import 'package:alrasmarket/features/clint/data/models/my_order_model.dart';
import 'package:alrasmarket/features/clint/data/models/international_shipping_post_model.dart';
import 'package:alrasmarket/features/clint/domain/entities/banner_adds.dart';
import 'package:alrasmarket/features/clint/data/models/category_model.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_entity.dart';
import 'package:alrasmarket/features/clint/domain/entities/cart_payment_method.dart';
import 'package:alrasmarket/features/company/data/models/my_listing_product_model.dart';
import 'package:equatable/equatable.dart';

abstract class ClintStates extends Equatable {
  const ClintStates();

  @override
  List<Object?> get props => [];
}

class ClintInitialState extends ClintStates {}

class ClintTabState extends ClintStates {
  final int index;

  const ClintTabState(this.index);

  @override
  List<Object?> get props => [index];
}

class ClintErrorState extends ClintStates {
  final String message;

  const ClintErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Home banners ---

class FetchBannersLoadingState extends ClintStates {}

class FetchBannersSuccessState extends ClintStates {
  final List<BannerAdds> banners;

  const FetchBannersSuccessState(this.banners);

  @override
  List<Object?> get props => [banners];
}

class FetchBannersErrorState extends ClintStates {
  final String message;

  const FetchBannersErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Categories ---

class FetchCategoriesLoadingState extends ClintStates {}

class FetchCategoriesSuccessState extends ClintStates {
  final List<CategoryModel> categories;

  const FetchCategoriesSuccessState(this.categories);

  @override
  List<Object?> get props => [categories];
}

class FetchCategoriesErrorState extends ClintStates {
  final String message;

  const FetchCategoriesErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Home / catalog products ---

class FetchHomeProductsLoadingState extends ClintStates {}

class FetchHomeProductsLoadingMoreState extends ClintStates {}

class FetchHomeProductsSuccessState extends ClintStates {
  final List<MyListingProductModel> products;

  const FetchHomeProductsSuccessState(this.products);

  @override
  List<Object?> get props => [products];
}

class FetchHomeProductsErrorState extends ClintStates {
  final String message;

  const FetchHomeProductsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class FetchFeaturedProductsLoadingState extends ClintStates {}

class FetchFeaturedProductsSuccessState extends ClintStates {
  final List<MyListingProductModel> products;

  const FetchFeaturedProductsSuccessState(this.products);

  @override
  List<Object?> get props => [products];
}

class FetchFeaturedProductsErrorState extends ClintStates {
  final String message;

  const FetchFeaturedProductsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Products by type (requests, booking, offers, retail) ---

class FetchProductsByTypeLoadingState extends ClintStates {
  const FetchProductsByTypeLoadingState(this.productType);

  final String productType;

  @override
  List<Object?> get props => [productType];
}

class FetchProductsByTypeLoadingMoreState extends ClintStates {
  const FetchProductsByTypeLoadingMoreState(this.productType);

  final String productType;

  @override
  List<Object?> get props => [productType];
}

class FetchProductsByTypeSuccessState extends ClintStates {
  const FetchProductsByTypeSuccessState({
    required this.productType,
    required this.products,
  });

  final String productType;
  final List<MyListingProductModel> products;

  @override
  List<Object?> get props => [productType, products];
}

class FetchProductsByTypeErrorState extends ClintStates {
  const FetchProductsByTypeErrorState({
    required this.productType,
    required this.message,
  });

  final String productType;
  final String message;

  @override
  List<Object?> get props => [productType, message];
}

// --- My orders ---

class FetchMyOrdersLoadingState extends ClintStates {}

class FetchMyOrdersSuccessState extends ClintStates {
  const FetchMyOrdersSuccessState(this.orders);

  final List<MyOrderModel> orders;

  @override
  List<Object?> get props => [orders];
}

class FetchMyOrdersErrorState extends ClintStates {
  const FetchMyOrdersErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class FetchMyOffersLoadingState extends ClintStates {}

class FetchMyOffersSuccessState extends ClintStates {
  const FetchMyOffersSuccessState(this.offers);

  final List<MyOrderModel> offers;

  @override
  List<Object?> get props => [offers];
}

class FetchMyOffersErrorState extends ClintStates {
  const FetchMyOffersErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class CancelOrderLoadingState extends ClintStates {
  const CancelOrderLoadingState(this.orderId);

  final int orderId;

  @override
  List<Object?> get props => [orderId];
}

class CancelOrderSuccessState extends ClintStates {
  const CancelOrderSuccessState({
    required this.orderId,
    this.refundMessage,
  });

  final int orderId;
  final String? refundMessage;

  @override
  List<Object?> get props => [orderId, refundMessage];
}

class CancelOrderErrorState extends ClintStates {
  const CancelOrderErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// --- Category products ---

class FetchCategoryProductsLoadingState extends ClintStates {
  const FetchCategoryProductsLoadingState(this.categoryId);

  final int categoryId;

  @override
  List<Object?> get props => [categoryId];
}

class FetchCategoryProductsSuccessState extends ClintStates {
  const FetchCategoryProductsSuccessState({
    required this.categoryId,
    required this.products,
  });

  final int categoryId;
  final List<MyListingProductModel> products;

  @override
  List<Object?> get props => [categoryId, products];
}

class FetchCategoryProductsErrorState extends ClintStates {
  const FetchCategoryProductsErrorState({
    required this.categoryId,
    required this.message,
  });

  final int categoryId;
  final String message;

  @override
  List<Object?> get props => [categoryId, message];
}

// --- International shipping posts ---

class FetchShippingPostsLoadingState extends ClintStates {}

class FetchShippingPostsSuccessState extends ClintStates {
  const FetchShippingPostsSuccessState(this.posts);

  final List<InternationalShippingPostModel> posts;

  @override
  List<Object?> get props => [posts];
}

class FetchShippingPostsErrorState extends ClintStates {
  const FetchShippingPostsErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// --- Submit offer form ---

class SubmitOfferFormState extends ClintStates {
  const SubmitOfferFormState({
    required this.product,
    this.selectedUnit = 'Kg',
    this.selectedCurrency = 'AED',
    this.productImages = const [],
    this.isSubmitting = false,
  });

  final MyListingProductModel product;
  final String selectedUnit;
  final String selectedCurrency;
  final List<String> productImages;
  final bool isSubmitting;

  SubmitOfferFormState copyWith({
    MyListingProductModel? product,
    String? selectedUnit,
    String? selectedCurrency,
    List<String>? productImages,
    bool? isSubmitting,
  }) {
    return SubmitOfferFormState(
      product: product ?? this.product,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      productImages: productImages ?? this.productImages,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        product,
        selectedUnit,
        selectedCurrency,
        productImages,
        isSubmitting,
      ];
}

class SubmitOfferLoadingState extends ClintStates {}

class SubmitOfferSuccessState extends ClintStates {
  final String message;

  const SubmitOfferSuccessState(this.message);

  @override
  List<Object?> get props => [message];
}

class SubmitOfferErrorState extends ClintStates {
  final String error;

  const SubmitOfferErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

// --- Booking purchase order ---

class BookingOrderFormState extends ClintStates {
  const BookingOrderFormState({
    required this.product,
    required this.selectedUnit,
    this.selectedCountry,
    this.selectedPort,
    this.ports = const [],
    this.isPortsLoading = false,
    this.isSubmitting = false,
    this.quantityRevision = 0,
  });

  final MyListingProductModel product;
  final String selectedUnit;
  final String? selectedCountry;
  final String? selectedPort;
  final List<String> ports;
  final bool isPortsLoading;
  final bool isSubmitting;
  /// Bumps when the quantity field changes so Equatable/Bloc rebuild the total.
  final int quantityRevision;

  BookingOrderFormState copyWith({
    MyListingProductModel? product,
    String? selectedUnit,
    String? selectedCountry,
    String? selectedPort,
    List<String>? ports,
    bool? isPortsLoading,
    bool? isSubmitting,
    int? quantityRevision,
    bool clearSelectedPort = false,
    bool clearPorts = false,
  }) {
    return BookingOrderFormState(
      product: product ?? this.product,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedPort: clearSelectedPort ? null : selectedPort ?? this.selectedPort,
      ports: clearPorts ? const [] : ports ?? this.ports,
      isPortsLoading: isPortsLoading ?? this.isPortsLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      quantityRevision: quantityRevision ?? this.quantityRevision,
    );
  }

  @override
  List<Object?> get props => [
        product,
        selectedUnit,
        selectedCountry,
        selectedPort,
        ports,
        isPortsLoading,
        isSubmitting,
        quantityRevision,
      ];
}

class BookingOrderSuccessState extends ClintStates {
  const BookingOrderSuccessState(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class BookingOrderErrorState extends ClintStates {
  const BookingOrderErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// --- Offer purchase order (retail product details) ---

class OfferOrderFormState extends ClintStates {
  const OfferOrderFormState({
    required this.product,
    required this.selectedUnit,
    this.isSubmitting = false,
  });

  final MyListingProductModel product;
  final String selectedUnit;
  final bool isSubmitting;

  OfferOrderFormState copyWith({
    MyListingProductModel? product,
    String? selectedUnit,
    bool? isSubmitting,
  }) {
    return OfferOrderFormState(
      product: product ?? this.product,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [product, selectedUnit, isSubmitting];
}

class OfferOrderSuccessState extends ClintStates {
  const OfferOrderSuccessState(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class OfferOrderErrorState extends ClintStates {
  const OfferOrderErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// --- Cart ---

class CartInitialState extends ClintStates {
  const CartInitialState();
}

class CartLoadedState extends ClintStates {
  const CartLoadedState({
    required this.cart,
    this.selectedPaymentMethod = CartPaymentMethod.online,
    this.selectedAddressId,
    this.selectedEmirateName,
    this.deliveryAddressLine,
    this.isSelfPickup = false,
    this.isLoading = false,
    this.isLoadingShipping = false,
    this.isConfirming = false,
    this.isUpdatingItem = false,
    this.updatingCartItemId,
    this.errorMessage,
    this.successMessage,
    this.infoMessage,
    this.paymentSessionId,
    this.paymentCheckoutUrl,
    this.isCheckingPayment = false,
  });

  final CartEntity cart;
  final CartPaymentMethod selectedPaymentMethod;
  final String? selectedAddressId;
  final String? selectedEmirateName;
  final String? deliveryAddressLine;
  final bool isSelfPickup;
  final bool isLoading;
  final bool isLoadingShipping;
  final bool isConfirming;
  final bool isUpdatingItem;
  final int? updatingCartItemId;
  final String? errorMessage;
  final String? successMessage;
  final String? infoMessage;
  final String? paymentSessionId;
  final String? paymentCheckoutUrl;
  final bool isCheckingPayment;

  bool get isAwaitingOnlinePayment =>
      paymentSessionId != null && paymentCheckoutUrl != null;

  bool get isOnlinePaymentFlow =>
      selectedPaymentMethod == CartPaymentMethod.online ||
      isAwaitingOnlinePayment;

  CartLoadedState copyWith({
    CartEntity? cart,
    CartPaymentMethod? selectedPaymentMethod,
    String? selectedAddressId,
    String? selectedEmirateName,
    String? deliveryAddressLine,
    bool? isSelfPickup,
    bool? isLoading,
    bool? isLoadingShipping,
    bool? isConfirming,
    bool? isUpdatingItem,
    int? updatingCartItemId,
    String? errorMessage,
    String? successMessage,
    String? infoMessage,
    String? paymentSessionId,
    String? paymentCheckoutUrl,
    bool? isCheckingPayment,
    bool clearErrorMessage = false,
    bool clearSuccessMessage = false,
    bool clearInfoMessage = false,
    bool clearUpdatingCartItemId = false,
    bool clearPaymentInfo = false,
    bool clearSelectedAddressId = false,
    bool clearSelectedEmirateName = false,
    bool clearDeliveryAddressLine = false,
  }) {
    return CartLoadedState(
      cart: cart ?? this.cart,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      selectedAddressId: clearSelectedAddressId
          ? null
          : selectedAddressId ?? this.selectedAddressId,
      selectedEmirateName: clearSelectedEmirateName
          ? null
          : selectedEmirateName ?? this.selectedEmirateName,
      deliveryAddressLine: clearDeliveryAddressLine
          ? null
          : deliveryAddressLine ?? this.deliveryAddressLine,
      isSelfPickup: isSelfPickup ?? this.isSelfPickup,
      isLoading: isLoading ?? this.isLoading,
      isLoadingShipping: isLoadingShipping ?? this.isLoadingShipping,
      isConfirming: isConfirming ?? this.isConfirming,
      isUpdatingItem: isUpdatingItem ?? this.isUpdatingItem,
      updatingCartItemId: clearUpdatingCartItemId
          ? null
          : updatingCartItemId ?? this.updatingCartItemId,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccessMessage ? null : successMessage ?? this.successMessage,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
      paymentSessionId:
          clearPaymentInfo ? null : paymentSessionId ?? this.paymentSessionId,
      paymentCheckoutUrl: clearPaymentInfo
          ? null
          : paymentCheckoutUrl ?? this.paymentCheckoutUrl,
      isCheckingPayment: isCheckingPayment ?? this.isCheckingPayment,
    );
  }

  @override
  List<Object?> get props => [
        cart,
        selectedPaymentMethod,
        selectedAddressId,
        selectedEmirateName,
        deliveryAddressLine,
        isSelfPickup,
        isLoading,
        isLoadingShipping,
        isConfirming,
        isUpdatingItem,
        updatingCartItemId,
        errorMessage,
        successMessage,
        infoMessage,
        paymentSessionId,
        paymentCheckoutUrl,
        isCheckingPayment,
      ];
}

class CartErrorState extends ClintStates {
  const CartErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// --- Order file upload ---

class UploadOrderFileLoadingState extends ClintStates {
  const UploadOrderFileLoadingState(this.uploadType);

  final String uploadType;

  @override
  List<Object?> get props => [uploadType];
}

class UploadOrderFileSuccessState extends ClintStates {
  const UploadOrderFileSuccessState(this.filePath, this.uploadType);

  final String filePath;
  final String uploadType;

  @override
  List<Object?> get props => [filePath, uploadType];
}

class UploadOrderFileErrorState extends ClintStates {
  const UploadOrderFileErrorState(this.message, this.uploadType);

  final String message;
  final String uploadType;

  @override
  List<Object?> get props => [message, uploadType];
}

// --- Create order ---

class CreateOrderLoadingState extends ClintStates {}

class CreateOrderSuccessState extends ClintStates {
  const CreateOrderSuccessState(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class CreateOrderErrorState extends ClintStates {
  const CreateOrderErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

// --- Product search ---

class ProductSearchLoadingState extends ClintStates {
  const ProductSearchLoadingState({this.query, this.fromImage = false});

  final String? query;
  final bool fromImage;

  @override
  List<Object?> get props => [query, fromImage];
}

class ProductSearchSuccessState extends ClintStates {
  const ProductSearchSuccessState({
    required this.products,
    this.query,
    this.suggestedNames = const [],
    this.fromImage = false,
    this.aiAssist,
  });

  final List<MyListingProductModel> products;
  final String? query;
  final List<String> suggestedNames;
  final bool fromImage;
  final Map<String, dynamic>? aiAssist;

  @override
  List<Object?> get props => [products, query, suggestedNames, fromImage, aiAssist];
}

class ProductSearchErrorState extends ClintStates {
  const ProductSearchErrorState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NavigateToTrackOrderState extends ClintStates {
  const NavigateToTrackOrderState({required this.order});

  final MyOrderModel order;

  @override
  List<Object?> get props => [order.id, order.statusId];
}

class RefreshOrderSuccessState extends ClintStates {
  const RefreshOrderSuccessState(this.order);

  final MyOrderModel order;

  @override
  List<Object?> get props => [order.id, order.statusId, order.isRefunded];
}
