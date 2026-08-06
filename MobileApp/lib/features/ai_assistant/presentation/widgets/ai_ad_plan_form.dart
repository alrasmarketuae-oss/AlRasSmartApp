import 'package:alrasmarket/core/serveses/auth_service.dart';
import 'package:alrasmarket/core/serveses/cached_constants.dart' as cache;
import 'package:flutter/material.dart';

/// Yellow plan-mode palette for AI ad creation chat.
class AiAdPlanColors {
  static const Color bg = Color(0xFFFFF8E7);
  static const Color card = Color(0xFFFFFDF5);
  static const Color border = Color(0xFFF0D48A);
  static const Color accent = Color(0xFFE6A817);
  static const Color accentDark = Color(0xFFB8860B);
  static const Color text = Color(0xFF3F2E0A);
  static const Color muted = Color(0xFF8A7340);
  static const Color fieldBg = Color(0xFFFFFBF0);
  static const Color success = Color(0xFF2F9E44);
}

enum AiAdPlanKind {
  booking,
  request,
  offer,
  retail,
  category,
  shipping,
}

/// Detects ad type from free-text intent when opening plan mode.
AiAdPlanKind? detectAiAdPlanKind(String text) {
  final q = text.toLowerCase();
  if (q.contains('shipping') || q.contains('شحن')) return AiAdPlanKind.shipping;
  if (q.contains('booking') || q.contains('بوكينج') || q.contains('حجز')) {
    return AiAdPlanKind.booking;
  }
  if (q.contains('retail') || q.contains('تجزئة')) return AiAdPlanKind.retail;
  if (q.contains('offer') || q.contains('عرض') || q.contains('عروض')) {
    return AiAdPlanKind.offer;
  }
  if (q.contains('request') || q.contains('طلب')) return AiAdPlanKind.request;
  if (q.contains('category') || q.contains('صنف') || q.contains('فئة')) {
    return AiAdPlanKind.category;
  }
  return null;
}

bool looksLikeAiAdCreationIntent(String text) {
  final q = text.toLowerCase();
  const markers = [
    'اعلان',
    'إعلان',
    'انشر',
    'نشر',
    'add ad',
    'create ad',
    'publish ad',
    'post ad',
    'عاوز اضيف',
    'عاوز أضيف',
    'اضافة اعلان',
    'إضافة إعلان',
    'booking',
    'بوكينج',
  ];
  return markers.any(q.contains);
}

/// Maps account to a locked type for company/shipping/overseas supplier.
AiAdPlanKind? lockedKindForAccount() {
  final auth = AuthService.instance;
  if (cache.isShippingCompanyAccount == true) return AiAdPlanKind.shipping;
  if (auth.isCompanyCustomerAccount) return AiAdPlanKind.request;
  if (auth.isSupplierAccount && !auth.isUaePhoneNumber) {
    return AiAdPlanKind.booking;
  }
  return null;
}

String? planKindLabel(AiAdPlanKind? kind) {
  switch (kind) {
    case AiAdPlanKind.booking:
      return 'Booking';
    case AiAdPlanKind.request:
      return 'Requests';
    case AiAdPlanKind.offer:
      return 'Offers';
    case AiAdPlanKind.retail:
      return 'Retail';
    case AiAdPlanKind.category:
      return 'Categories';
    case AiAdPlanKind.shipping:
      return 'Shipping';
    case null:
      return null;
  }
}

/// Detects FOB/CNF/CIF from user text (Booking incoterm).
String? detectBookingPriceType(String text) {
  final upper = text.toUpperCase();
  if (RegExp(r'\bFOB\b').hasMatch(upper) || text.contains('فوب')) return 'FOB';
  if (RegExp(r'\bCIF\b').hasMatch(upper) || text.contains('سيف')) return 'CIF';
  if (RegExp(r'\bCNF\b').hasMatch(upper) ||
      RegExp(r'\bC\s*&\s*F\b').hasMatch(upper) ||
      text.contains('سي اند اف')) {
    return 'CNF';
  }
  return null;
}

/// Latest booking incoterm mentioned in chat (current message first).
String? resolveBookingPriceTypeFromChat(
  Iterable<String> priorUserMessages,
  String currentMessage,
) {
  final fromCurrent = detectBookingPriceType(currentMessage);
  if (fromCurrent != null) return fromCurrent;
  for (final text in priorUserMessages) {
    final found = detectBookingPriceType(text);
    if (found != null) return found;
  }
  return null;
}

String bookingIncotermPlanHint({
  required String? incoterm,
  required bool isAr,
}) {
  if (incoterm == 'FOB') {
    return isAr
        ? 'نوع السعر FOB: اطلب الدولة المصدرة فقط — لا تطلب بلد الوجهة ولا الموانئ.'
        : 'Price type FOB: ask exporting country only — never destination country or ports.';
  }
  if (incoterm == 'CNF' || incoterm == 'CIF') {
    return isAr
        ? 'نوع السعر $incoterm: يجب جمع الدولة المصدرة + ميناء التحميل + بلد الوجهة + ميناء الوصول (كلها مطلوبة).'
        : 'Price type $incoterm: MUST collect origin country, loading port, destination country, and arrival port.';
  }
  return isAr
      ? 'اسأل عن نوع السعر FOB أو CNF أو CIF أولاً ثم اعرض الحقول حسب النوع.'
      : 'Ask FOB/CNF/CIF first, then list fields matching that price type.';
}

/// True when the assistant reply indicates a generic temporary outage message.
bool looksLikeTemporaryAssistantFailure(String answer) {
  final q = answer.toLowerCase();
  return q.contains('المساعد مش متاح') ||
      q.contains('تعذر الوصول للمساعد') ||
      q.contains('temporarily unavailable') ||
      q.contains('unavailable right now');
}

/// True when the assistant reply indicates the ad was created successfully.
bool looksLikeAdCreateSuccess(String answer) {
  final q = answer.toLowerCase();
  const markers = [
    'تم إنشاء',
    'تم نشر',
    'اتنشر',
    'نُشر',
    'نشرت',
    'إرساله للمراجعة',
    'created successfully',
    'published successfully',
    'ad created',
    'listing created',
    'submitted for review',
    'submitted for admin review',
    'productcode',
    'product code',
    'رمز المنتج',
  ];
  return markers.any(q.contains);
}
