/// API segment for GET /Products/by-type/{type}
abstract final class ServiceProductType {
  static const requests = 'requests';
  static const booking = 'booking';
  static const offers = 'offers';
  static const retail = 'retail';

  static const all = [requests, booking, offers, retail];
}
