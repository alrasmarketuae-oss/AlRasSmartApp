class UpdateProductPriceRequest {
  const UpdateProductPriceRequest({
    this.usdPrice,
    this.retailPrice,
  });

  final double? usdPrice;
  final double? retailPrice;

  Map<String, dynamic> toJson() => {
        if (usdPrice != null) 'usdPrice': usdPrice,
        if (retailPrice != null) 'retailPrice': retailPrice,
      };
}
