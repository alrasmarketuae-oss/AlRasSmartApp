enum CartPaymentMethod {
  cash('CashOnDelivery'),
  online('Online');

  const CartPaymentMethod(this.apiValue);

  final String apiValue;
}
