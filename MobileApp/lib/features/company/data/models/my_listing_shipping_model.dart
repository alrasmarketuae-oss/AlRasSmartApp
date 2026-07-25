import 'package:alrasmarket/core/utils/localized_product_text.dart';

class MyListingShippingModel {
  const MyListingShippingModel({
    this.routeFromCountry = '',
    this.routeFromPort = '',
    this.routeToCountry = '',
    this.routeToPort = '',
    this.routeFromCountryEn = '',
    this.routeFromPortEn = '',
    this.routeToCountryEn = '',
    this.routeToPortEn = '',
    this.routeSummary = '',
    this.additionalShippingNotes = '',
    this.shippingDuration = '',
    this.hasRouteInformation = false,
  });

  final String routeFromCountry;
  final String routeFromPort;
  final String routeToCountry;
  final String routeToPort;
  /// Canonical English names for edit-submit / geo dropdown matching.
  final String routeFromCountryEn;
  final String routeFromPortEn;
  final String routeToCountryEn;
  final String routeToPortEn;
  final String routeSummary;
  final String additionalShippingNotes;
  /// Days (booking/retail) or required receipt date `yyyy-MM-dd` (requests).
  final String shippingDuration;
  final bool hasRouteInformation;

  factory MyListingShippingModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MyListingShippingModel();

    final hasRoute = json['hasRouteInformation']?.toString().toLowerCase();
    final fromCountry = json['routeFromCountry']?.toString() ??
        json['originCountryName']?.toString() ??
        '';
    final fromPort = json['routeFromPort']?.toString() ??
        json['loadingPortName']?.toString() ??
        '';
    final toCountry = json['routeToCountry']?.toString() ??
        json['destinationCountryName']?.toString() ??
        '';
    final toPort = json['routeToPort']?.toString() ??
        json['arrivalPortName']?.toString() ??
        '';
    final fromCountryEn = json['routeFromCountryEn']?.toString() ??
        json['originCountryNameEn']?.toString() ??
        json['OriginCountryNameEn']?.toString() ??
        json['originCountryName']?.toString() ??
        '';
    // API stores English in routeFromPort / LoadingPortName; Arabic in *Ar.
    final fromPortEn = json['routeFromPortEn']?.toString() ??
        json['loadingPortNameEn']?.toString() ??
        json['LoadingPortNameEn']?.toString() ??
        json['routeFromPort']?.toString() ??
        json['loadingPortName']?.toString() ??
        '';
    final toCountryEn = json['routeToCountryEn']?.toString() ??
        json['destinationCountryNameEn']?.toString() ??
        json['DestinationCountryNameEn']?.toString() ??
        json['destinationCountryName']?.toString() ??
        '';
    final toPortEn = json['routeToPortEn']?.toString() ??
        json['arrivalPortNameEn']?.toString() ??
        json['ArrivalPortNameEn']?.toString() ??
        json['routeToPort']?.toString() ??
        json['arrivalPortName']?.toString() ??
        '';
    // Prefer English port names everywhere until Arabic catalog is complete.
    final resolvedFromPort =
        fromPortEn.isNotEmpty ? fromPortEn : fromPort;
    final resolvedToPort = toPortEn.isNotEmpty ? toPortEn : toPort;
    return MyListingShippingModel(
      routeFromCountry: fromCountry,
      routeFromPort: resolvedFromPort,
      routeToCountry: toCountry,
      routeToPort: resolvedToPort,
      routeFromCountryEn: fromCountryEn.isNotEmpty ? fromCountryEn : fromCountry,
      routeFromPortEn: resolvedFromPort,
      routeToCountryEn: toCountryEn.isNotEmpty ? toCountryEn : toCountry,
      routeToPortEn: resolvedToPort,
      routeSummary: json['routeSummary']?.toString() ?? '',
      additionalShippingNotes:
          json['additionalShippingNotes']?.toString() ??
          json['shippingDescriptionEn']?.toString() ??
          json['ShippingDescriptionEn']?.toString() ??
          '',
      shippingDuration: json['shippingDuration']?.toString() ??
          json['ShippingDuration']?.toString() ??
          '',
      hasRouteInformation: hasRoute == 'yes' ||
          hasRoute == 'true' ||
          fromCountry.isNotEmpty ||
          toCountry.isNotEmpty ||
          fromPort.isNotEmpty ||
          toPort.isNotEmpty,
    );
  }

  String get displayRoute {
    if (routeSummary.trim().isNotEmpty) return routeSummary.trim();
    if (!hasRouteInformation) return '';
    if (routeFromCountry.isEmpty && routeToCountry.isEmpty) return '';
    final from = routeFromPort.isEmpty
        ? routeFromCountry
        : '$routeFromCountry ($routeFromPort)';
    final to = routeToPort.isEmpty
        ? routeToCountry
        : '$routeToCountry ($routeToPort)';
    if (from.isEmpty) return to;
    if (to.isEmpty) return from;
    return LocalizedProductText.isArabic
        ? 'من $from → إلى $to'
        : 'From $from → to $to';
  }
}
