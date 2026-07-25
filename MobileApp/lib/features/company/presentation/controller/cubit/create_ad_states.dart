import 'package:equatable/equatable.dart';

import '../../models/booking_price_type.dart';
import '../../models/create_ad_currency.dart';
import '../../models/create_ad_publish_step.dart';
import '../../models/negotiation_type.dart';
import '../../models/request_fulfillment_type.dart';

class CreateAdFormState extends Equatable {
  const CreateAdFormState({
    this.selectedType,
    this.selectedCategory,
    this.selectedCategoryId,
    this.selectedUnit = 'Ton',
    this.selectedRetailUnit = 'Kg',
    this.enableRetailPricing = false,
    this.selectedCurrency = CreateAdCurrency.aed,
    this.negotiationType = NegotiationType.negotiable,
    this.requestFulfillmentType,
    this.bookingPriceType,
    this.productImages = const [],
    this.productDocuments = const [],
    this.countries = const [],
    this.isCountriesLoading = false,
    this.originCountry,
    this.originPort,
    this.originPorts = const [],
    this.isOriginPortsLoading = false,
    this.destinationCountry,
    this.destinationPort,
    this.destinationPorts = const [],
    this.isDestinationPortsLoading = false,
    this.isSubmitting = false,
    this.submitErrorMessage,
    this.submitSuccessMessage,
    this.submitNavigateProductId,
    this.requiredDeliveryDate,
    this.address,
    this.addressId,
    this.editingProductId,
    this.formRevision = 0,
    this.isCompressingMedia = false,
    this.mediaCompressionProgress = 0,
    this.mediaCompressionLabel,
    this.publishStep = CreateAdPublishStep.idle,
    this.publishVideoPercent = 0,
    this.publishHasImages = false,
    this.publishHasVideo = false,
    this.publishHasDocuments = false,
  });

  final String? selectedType;
  final String? selectedCategory;
  final int? selectedCategoryId;
  final String selectedUnit;
  final String selectedRetailUnit;
  final bool enableRetailPricing;
  final String selectedCurrency;
  final NegotiationType negotiationType;
  final RequestFulfillmentType? requestFulfillmentType;
  final BookingPriceType? bookingPriceType;
  final List<String> productImages;
  final List<String> productDocuments;
  final List<String> countries;
  final bool isCountriesLoading;
  final String? originCountry;
  final String? originPort;
  final List<String> originPorts;
  final bool isOriginPortsLoading;
  final String? destinationCountry;
  final String? destinationPort;
  final List<String> destinationPorts;
  final bool isDestinationPortsLoading;
  final bool isSubmitting;
  final String? submitErrorMessage;
  final String? submitSuccessMessage;
  final String? submitNavigateProductId;
  final DateTime? requiredDeliveryDate;
  final String? address;
  final String? addressId;
  final String? editingProductId;
  final int formRevision;
  final bool isCompressingMedia;
  final double mediaCompressionProgress;
  final String? mediaCompressionLabel;
  final CreateAdPublishStep publishStep;
  final int publishVideoPercent;
  final bool publishHasImages;
  final bool publishHasVideo;
  final bool publishHasDocuments;

  bool get isEditMode =>
      editingProductId != null && editingProductId!.isNotEmpty;

  CreateAdFormState copyWith({
    String? selectedType,
    String? selectedCategory,
    int? selectedCategoryId,
    String? selectedUnit,
    String? selectedRetailUnit,
    bool? enableRetailPricing,
    String? selectedCurrency,
    NegotiationType? negotiationType,
    RequestFulfillmentType? requestFulfillmentType,
    bool clearRequestFulfillmentType = false,
    BookingPriceType? bookingPriceType,
    bool clearBookingPriceType = false,
    List<String>? productImages,
    List<String>? productDocuments,
    List<String>? countries,
    bool? isCountriesLoading,
    String? originCountry,
    String? originPort,
    List<String>? originPorts,
    bool? isOriginPortsLoading,
    String? destinationCountry,
    String? destinationPort,
    List<String>? destinationPorts,
    bool? isDestinationPortsLoading,
    bool? isSubmitting,
    String? submitErrorMessage,
    String? submitSuccessMessage,
    String? submitNavigateProductId,
    DateTime? requiredDeliveryDate,
    String? address,
    String? addressId,
    String? editingProductId,
    int? formRevision,
    bool? isCompressingMedia,
    double? mediaCompressionProgress,
    String? mediaCompressionLabel,
    CreateAdPublishStep? publishStep,
    int? publishVideoPercent,
    bool? publishHasImages,
    bool? publishHasVideo,
    bool? publishHasDocuments,
    bool clearMediaCompressionLabel = false,
    bool clearRequiredDeliveryDate = false,
    bool clearAddress = false,
    bool clearAddressId = false,
    bool clearEditingProductId = false,
    bool clearSubmitErrorMessage = false,
    bool clearSubmitSuccessMessage = false,
    bool clearSubmitNavigateProductId = false,
    bool clearOriginPort = false,
    bool clearOriginPorts = false,
    bool clearDestinationPort = false,
    bool clearDestinationPorts = false,
    bool clearSelectedCategory = false,
    bool clearSelectedCategoryId = false,
  }) {
    return CreateAdFormState(
      selectedType: selectedType ?? this.selectedType,
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      selectedCategoryId: clearSelectedCategoryId
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedUnit: selectedUnit ?? this.selectedUnit,
      selectedRetailUnit: selectedRetailUnit ?? this.selectedRetailUnit,
      enableRetailPricing: enableRetailPricing ?? this.enableRetailPricing,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      negotiationType: negotiationType ?? this.negotiationType,
      requestFulfillmentType: clearRequestFulfillmentType
          ? null
          : (requestFulfillmentType ?? this.requestFulfillmentType),
      bookingPriceType: clearBookingPriceType
          ? null
          : (bookingPriceType ?? this.bookingPriceType),
      productImages: productImages ?? this.productImages,
      productDocuments: productDocuments ?? this.productDocuments,
      countries: countries ?? this.countries,
      isCountriesLoading: isCountriesLoading ?? this.isCountriesLoading,
      originCountry: originCountry ?? this.originCountry,
      originPort: clearOriginPort ? null : (originPort ?? this.originPort),
      originPorts: clearOriginPorts ? const [] : (originPorts ?? this.originPorts),
      isOriginPortsLoading: isOriginPortsLoading ?? this.isOriginPortsLoading,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      destinationPort:
          clearDestinationPort ? null : (destinationPort ?? this.destinationPort),
      destinationPorts: clearDestinationPorts
          ? const []
          : (destinationPorts ?? this.destinationPorts),
      isDestinationPortsLoading:
          isDestinationPortsLoading ?? this.isDestinationPortsLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitErrorMessage: clearSubmitErrorMessage
          ? null
          : (submitErrorMessage ?? this.submitErrorMessage),
      submitSuccessMessage: clearSubmitSuccessMessage
          ? null
          : (submitSuccessMessage ?? this.submitSuccessMessage),
      submitNavigateProductId: clearSubmitNavigateProductId
          ? null
          : (submitNavigateProductId ?? this.submitNavigateProductId),
      requiredDeliveryDate: clearRequiredDeliveryDate
          ? null
          : (requiredDeliveryDate ?? this.requiredDeliveryDate),
      address: clearAddress ? null : (address ?? this.address),
      addressId: clearAddressId ? null : (addressId ?? this.addressId),
      editingProductId: clearEditingProductId
          ? null
          : (editingProductId ?? this.editingProductId),
      formRevision: formRevision ?? this.formRevision,
      isCompressingMedia: isCompressingMedia ?? this.isCompressingMedia,
      mediaCompressionProgress:
          mediaCompressionProgress ?? this.mediaCompressionProgress,
      mediaCompressionLabel: clearMediaCompressionLabel
          ? null
          : (mediaCompressionLabel ?? this.mediaCompressionLabel),
      publishStep: publishStep ?? this.publishStep,
      publishVideoPercent: publishVideoPercent ?? this.publishVideoPercent,
      publishHasImages: publishHasImages ?? this.publishHasImages,
      publishHasVideo: publishHasVideo ?? this.publishHasVideo,
      publishHasDocuments: publishHasDocuments ?? this.publishHasDocuments,
    );
  }

  @override
  List<Object?> get props => [
        selectedType,
        selectedCategory,
        selectedCategoryId,
        selectedUnit,
        selectedRetailUnit,
        enableRetailPricing,
        selectedCurrency,
        negotiationType,
        requestFulfillmentType,
        bookingPriceType,
        productImages,
        productDocuments,
        countries,
        isCountriesLoading,
        originCountry,
        originPort,
        originPorts,
        isOriginPortsLoading,
        destinationCountry,
        destinationPort,
        destinationPorts,
        isDestinationPortsLoading,
        isSubmitting,
        submitErrorMessage,
        submitSuccessMessage,
        submitNavigateProductId,
        requiredDeliveryDate,
        address,
        addressId,
        editingProductId,
        formRevision,
        isCompressingMedia,
        mediaCompressionProgress,
        mediaCompressionLabel,
        publishStep,
        publishVideoPercent,
        publishHasImages,
        publishHasVideo,
        publishHasDocuments,
      ];
}
