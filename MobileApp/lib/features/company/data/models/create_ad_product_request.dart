import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class CreateAdProductRequest {
  const CreateAdProductRequest({
    this.nameEn,
    this.createdLanguage,
    this.usdPrice,
    this.currency,
    this.quantity,
    this.productTypeName,
    this.unitName,
    this.originCountryName,
    this.destinationCountryName,
    this.loadingPortName,
    this.arrivalPortName,
    this.descriptionEn,
    this.categoryId,
    this.negotiable,
    this.discountPercentage,
    this.discountDays,
    this.supplierNotesEn,
    this.packaging,
    this.packagingDetails,
    this.shippingDuration,
    this.offerDuration,
    this.shippingDescriptionEn,
    this.requestTypeName,
    this.bookingPriceTypeName,
    this.address,
    this.addressId,
    this.productVideoFile,
    this.videoDurationSeconds,
    this.retailPrice,
    this.retailUnitName,
    this.retailQuantity,
    this.enableRetailPricing,
    this.retailPackaging,
    this.retailPackagingDetails,
    this.retailDescriptionEn,
  });

  final String? nameEn;
  /// App UI language when creating the ad (`en` / `ar`).
  final String? createdLanguage;
  final double? usdPrice;
  final String? currency;
  final int? quantity;
  final String? productTypeName;
  final String? unitName;
  final String? originCountryName;
  final String? destinationCountryName;
  final String? loadingPortName;
  final String? arrivalPortName;
  final String? descriptionEn;
  final int? categoryId;
  final bool? negotiable;
  final int? discountPercentage;
  final int? discountDays;
  final String? supplierNotesEn;
  /// Packing type id 1–255.
  final int? packaging;
  final String? packagingDetails;
  final String? shippingDuration;
  final String? offerDuration;
  final String? shippingDescriptionEn;
  final String? requestTypeName;
  final String? bookingPriceTypeName;
  final String? address;
  /// Backend expects AddressId (GUID), not a free-text address label.
  final String? addressId;
  final File? productVideoFile;
  final int? videoDurationSeconds;
  final double? retailPrice;
  final String? retailUnitName;
  final int? retailQuantity;
  final bool? enableRetailPricing;
  final int? retailPackaging;
  final String? retailPackagingDetails;
  final String? retailDescriptionEn;

  Map<String, dynamic> toJson() => {
        'nameEn': nameEn,
        'createdLanguage': createdLanguage,
        'usdPrice': usdPrice,
        'currency': currency,
        'quantity': quantity,
        'productTypeName': productTypeName,
        'unitName': unitName,
        'originCountryName': originCountryName,
        'destinationCountryName': destinationCountryName,
        'loadingPortName': loadingPortName,
        'arrivalPortName': arrivalPortName,
        'descriptionEn': descriptionEn,
        'categoryId': categoryId,
        'negotiable': negotiable,
        'discountPercentage': discountPercentage,
        'discountDays': discountDays,
        'supplierNotesEn': supplierNotesEn,
        'packaging': packaging,
        'packagingDetails': packagingDetails,
        'shippingDuration': shippingDuration,
        'offerDuration': offerDuration,
        'shippingDescriptionEn': shippingDescriptionEn,
        'requestTypeName': requestTypeName,
        'bookingPriceTypeName': bookingPriceTypeName,
        'address': address,
        'addressId': addressId,
        'videoDurationSeconds': videoDurationSeconds,
        'retailPrice': retailPrice,
        'retailUnitName': retailUnitName,
        'retailQuantity': retailQuantity,
        'enableRetailPricing': enableRetailPricing,
        'retailPackaging': retailPackaging,
        'retailPackagingDetails': retailPackagingDetails,
        'retailDescriptionEn': retailDescriptionEn,
      };

  factory CreateAdProductRequest.fromJson(Map<String, dynamic> json) {
    return CreateAdProductRequest(
      nameEn: json['nameEn'] as String?,
      createdLanguage: json['createdLanguage'] as String?,
      usdPrice: (json['usdPrice'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      productTypeName: json['productTypeName'] as String?,
      unitName: json['unitName'] as String?,
      originCountryName: json['originCountryName'] as String?,
      destinationCountryName: json['destinationCountryName'] as String?,
      loadingPortName: json['loadingPortName'] as String?,
      arrivalPortName: json['arrivalPortName'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      negotiable: json['negotiable'] as bool?,
      discountPercentage: (json['discountPercentage'] as num?)?.toInt(),
      discountDays: (json['discountDays'] as num?)?.toInt(),
      supplierNotesEn: json['supplierNotesEn'] as String?,
      packaging: (json['packaging'] as num?)?.toInt(),
      packagingDetails: json['packagingDetails'] as String?,
      shippingDuration: json['shippingDuration'] as String?,
      offerDuration: json['offerDuration'] as String?,
      shippingDescriptionEn: json['shippingDescriptionEn'] as String?,
      requestTypeName: json['requestTypeName'] as String?,
      bookingPriceTypeName: json['bookingPriceTypeName'] as String?,
      address: json['address'] as String?,
      addressId: json['addressId'] as String?,
      videoDurationSeconds: (json['videoDurationSeconds'] as num?)?.toInt(),
      retailPrice: (json['retailPrice'] as num?)?.toDouble(),
      retailUnitName: json['retailUnitName'] as String?,
      retailQuantity: (json['retailQuantity'] as num?)?.toInt(),
      enableRetailPricing: json['enableRetailPricing'] as bool?,
      retailPackaging: (json['retailPackaging'] as num?)?.toInt(),
      retailPackagingDetails: json['retailPackagingDetails'] as String?,
      retailDescriptionEn: json['retailDescriptionEn'] as String?,
    );
  }

  CreateAdProductRequest copyWith({
    String? nameEn,
    String? createdLanguage,
    double? usdPrice,
    String? currency,
    int? quantity,
    String? productTypeName,
    String? unitName,
    String? originCountryName,
    String? destinationCountryName,
    String? loadingPortName,
    String? arrivalPortName,
    String? descriptionEn,
    int? categoryId,
    bool? negotiable,
    int? discountPercentage,
    int? discountDays,
    String? supplierNotesEn,
    int? packaging,
    String? packagingDetails,
    String? shippingDuration,
    String? offerDuration,
    String? shippingDescriptionEn,
    String? requestTypeName,
    String? bookingPriceTypeName,
    String? address,
    String? addressId,
    File? productVideoFile,
    int? videoDurationSeconds,
    double? retailPrice,
    String? retailUnitName,
    int? retailQuantity,
    bool? enableRetailPricing,
    int? retailPackaging,
    String? retailPackagingDetails,
    String? retailDescriptionEn,
    bool clearProductVideoFile = false,
  }) {
    return CreateAdProductRequest(
      nameEn: nameEn ?? this.nameEn,
      createdLanguage: createdLanguage ?? this.createdLanguage,
      usdPrice: usdPrice ?? this.usdPrice,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
      productTypeName: productTypeName ?? this.productTypeName,
      unitName: unitName ?? this.unitName,
      originCountryName: originCountryName ?? this.originCountryName,
      destinationCountryName:
          destinationCountryName ?? this.destinationCountryName,
      loadingPortName: loadingPortName ?? this.loadingPortName,
      arrivalPortName: arrivalPortName ?? this.arrivalPortName,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      categoryId: categoryId ?? this.categoryId,
      negotiable: negotiable ?? this.negotiable,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountDays: discountDays ?? this.discountDays,
      supplierNotesEn: supplierNotesEn ?? this.supplierNotesEn,
      packaging: packaging ?? this.packaging,
      packagingDetails: packagingDetails ?? this.packagingDetails,
      shippingDuration: shippingDuration ?? this.shippingDuration,
      offerDuration: offerDuration ?? this.offerDuration,
      shippingDescriptionEn:
          shippingDescriptionEn ?? this.shippingDescriptionEn,
      requestTypeName: requestTypeName ?? this.requestTypeName,
      bookingPriceTypeName: bookingPriceTypeName ?? this.bookingPriceTypeName,
      address: address ?? this.address,
      addressId: addressId ?? this.addressId,
      productVideoFile: clearProductVideoFile
          ? null
          : (productVideoFile ?? this.productVideoFile),
      videoDurationSeconds: clearProductVideoFile
          ? null
          : (videoDurationSeconds ?? this.videoDurationSeconds),
      retailPrice: retailPrice ?? this.retailPrice,
      retailUnitName: retailUnitName ?? this.retailUnitName,
      retailQuantity: retailQuantity ?? this.retailQuantity,
      enableRetailPricing: enableRetailPricing ?? this.enableRetailPricing,
      retailPackaging: retailPackaging ?? this.retailPackaging,
      retailPackagingDetails:
          retailPackagingDetails ?? this.retailPackagingDetails,
      retailDescriptionEn: retailDescriptionEn ?? this.retailDescriptionEn,
    );
  }

  Future<FormData> toFormData({bool forUpdate = false}) async {
    if (forUpdate) {
      final map = <String, dynamic>{
        'NameEn': nameEn ?? '',
        'USDPrice': usdPrice?.toString() ?? '',
        'Currency': currency ?? '',
        'Quantity': quantity?.toString() ?? '',
        'UnitName': unitName ?? '',
        'Negotiable': (negotiable ?? false).toString(),
        'DescriptionEn': descriptionEn ?? '',
      };

      void putIfPresent(String key, String? value) {
        final trimmed = value?.trim();
        if (trimmed != null && trimmed.isNotEmpty) {
          map[key] = trimmed;
        }
      }

      void putNumberIfPresent(String key, num? value) {
        if (value != null) {
          map[key] = value.toString();
        }
      }

      putNumberIfPresent('DiscountPercentage', discountPercentage);
      putNumberIfPresent('DiscountDays', discountDays);
      putIfPresent('SupplierNotesEn', supplierNotesEn);
      if (packaging != null && packaging! > 0) {
        map['Packaging'] = packaging.toString();
      }
      putIfPresent('PackagingDetails', packagingDetails);
      // Omit empty duration/notes so update does not clear DB / force re-review.
      putIfPresent('ShippingDuration', shippingDuration);
      putIfPresent('OfferDuration', offerDuration);
      putIfPresent('ShippingDescriptionEn', shippingDescriptionEn);
      putIfPresent('RequestTypeName', requestTypeName);
      putIfPresent('BookingPriceTypeName', bookingPriceTypeName);
      putIfPresent('AddressId', addressId);
      putIfPresent('CreatedLanguage', createdLanguage);

      if (productTypeName != null && productTypeName!.trim().isNotEmpty) {
        map['ProductTypeName'] = productTypeName;
      }
      if (categoryId != null) {
        map['CategoryId'] = categoryId.toString();
      }

      // Only send geo when provided (Offers/Retail omit ports entirely).
      if (originCountryName != null && originCountryName!.isNotEmpty) {
        map['OriginCountryName'] = originCountryName;
      }
      if (destinationCountryName != null && destinationCountryName!.isNotEmpty) {
        map['DestinationCountryName'] = destinationCountryName;
      }
      if (loadingPortName != null && loadingPortName!.isNotEmpty) {
        map['LoadingPortName'] = loadingPortName;
      }
      if (arrivalPortName != null && arrivalPortName!.isNotEmpty) {
        map['ArrivalPortName'] = arrivalPortName;
      }

      if (productVideoFile != null) {
        map['ProductVideoFile'] = await MultipartFile.fromFile(
          productVideoFile!.path,
          filename: productVideoFile!.path.split('/').last,
          contentType: _videoContentType(productVideoFile!.path),
        );
        map['VideoDurationSeconds'] =
            (videoDurationSeconds ?? 0).toString();
      }

      _appendRetailPricingFields(map, forUpdate: true);

      return FormData.fromMap(map);
    }

    final map = <String, dynamic>{
      'NameEn': nameEn ?? '',
      'USDPrice': (usdPrice ?? 0).toString(),
      'Currency': currency ?? '',
      'Quantity': (quantity ?? 0).toString(),
      'ProductTypeName': productTypeName ?? '',
      'UnitName': unitName ?? '',
      'Negotiable': (negotiable ?? false).toString(),
    };

    if (createdLanguage != null && createdLanguage!.trim().isNotEmpty) {
      map['CreatedLanguage'] = createdLanguage!.trim().toLowerCase();
    }

    if (originCountryName != null && originCountryName!.isNotEmpty) {
      map['OriginCountryName'] = originCountryName;
    }
    if (destinationCountryName != null && destinationCountryName!.isNotEmpty) {
      map['DestinationCountryName'] = destinationCountryName;
    }
    if (loadingPortName != null && loadingPortName!.isNotEmpty) {
      map['LoadingPortName'] = loadingPortName;
    }
    if (arrivalPortName != null && arrivalPortName!.isNotEmpty) {
      map['ArrivalPortName'] = arrivalPortName;
    }

    if (descriptionEn != null && descriptionEn!.isNotEmpty) {
      map['DescriptionEn'] = descriptionEn;
    }
    if (productTypeName != null && productTypeName!.trim().isNotEmpty) {
      map['ProductTypeName'] = productTypeName;
    }
    if (categoryId != null) {
      map['CategoryId'] = categoryId.toString();
    }
    if (discountPercentage != null) {
      map['DiscountPercentage'] = discountPercentage.toString();
    }
    if (discountDays != null) {
      map['DiscountDays'] = discountDays.toString();
    }
    if (supplierNotesEn != null && supplierNotesEn!.isNotEmpty) {
      map['SupplierNotesEn'] = supplierNotesEn;
    }
    if (packaging != null && packaging! > 0) {
      map['Packaging'] = packaging.toString();
    }
    if (packagingDetails != null && packagingDetails!.isNotEmpty) {
      map['PackagingDetails'] = packagingDetails;
    }
    if (shippingDuration != null && shippingDuration!.isNotEmpty) {
      map['ShippingDuration'] = shippingDuration;
    }
    if (offerDuration != null && offerDuration!.isNotEmpty) {
      map['OfferDuration'] = offerDuration;
    }
    if (shippingDescriptionEn != null && shippingDescriptionEn!.isNotEmpty) {
      map['ShippingDescriptionEn'] = shippingDescriptionEn;
    }
    if (requestTypeName != null && requestTypeName!.isNotEmpty) {
      map['RequestTypeName'] = requestTypeName;
    }
    if (bookingPriceTypeName != null && bookingPriceTypeName!.isNotEmpty) {
      map['BookingPriceTypeName'] = bookingPriceTypeName;
    }
    if (addressId != null && addressId!.isNotEmpty) {
      map['AddressId'] = addressId;
    } else if (address != null && address!.isNotEmpty) {
      // Legacy: only send as AddressId when the value is already a GUID.
      final trimmed = address!.trim();
      final guidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (guidPattern.hasMatch(trimmed)) {
        map['AddressId'] = trimmed;
      }
    }
    if (productVideoFile != null) {
      map['ProductVideoFile'] = await MultipartFile.fromFile(
        productVideoFile!.path,
        filename: productVideoFile!.path.split('/').last,
        contentType: _videoContentType(productVideoFile!.path),
      );
      map['VideoDurationSeconds'] = (videoDurationSeconds ?? 0).toString();
    }

    _appendRetailPricingFields(map, forUpdate: false);

    return FormData.fromMap(map);
  }

  void _appendRetailPricingFields(
    Map<String, dynamic> map, {
    required bool forUpdate,
  }) {
    if (enableRetailPricing == null &&
        retailPrice == null &&
        (retailUnitName == null || retailUnitName!.trim().isEmpty) &&
        retailQuantity == null &&
        retailPackaging == null &&
        (retailDescriptionEn == null || retailDescriptionEn!.trim().isEmpty)) {
      return;
    }

    if (enableRetailPricing != true) {
      if (forUpdate && enableRetailPricing == false) {
        map['EnableRetailPricing'] = 'false';
      }
      // enableRetailPricing == null → omit (leave existing retail channel alone).
      return;
    }

    map['EnableRetailPricing'] = 'true';

    if (retailPrice != null) {
      map['RetailPrice'] = retailPrice.toString();
    }

    if (retailUnitName != null && retailUnitName!.trim().isNotEmpty) {
      map['RetailUnitName'] = retailUnitName;
    }

    if (retailQuantity != null) {
      map['RetailQuantity'] = retailQuantity.toString();
    }

    if (retailPackaging != null && retailPackaging! > 0) {
      map['RetailPackaging'] = retailPackaging.toString();
    }

    if (retailPackagingDetails != null &&
        retailPackagingDetails!.trim().isNotEmpty) {
      map['RetailPackagingDetails'] = retailPackagingDetails;
    }

    if (retailDescriptionEn != null && retailDescriptionEn!.trim().isNotEmpty) {
      map['RetailDescriptionEn'] = retailDescriptionEn;
    }
  }

  static MediaType _videoContentType(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'mov':
        return MediaType('video', 'quicktime');
      case 'webm':
        return MediaType('video', 'webm');
      case 'm4v':
      case 'mp4':
      default:
        return MediaType('video', 'mp4');
    }
  }
}
