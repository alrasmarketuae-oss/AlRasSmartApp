enum RequestFulfillmentType {
  local('Local'),
  reexport('Reexport');

  const RequestFulfillmentType(this.apiValue);

  final String apiValue;

  static RequestFulfillmentType? fromApiValue(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    // Legacy: booking fulfillment was renamed to Rexport.
    if (normalized == 'booking') {
      return RequestFulfillmentType.reexport;
    }
    for (final type in RequestFulfillmentType.values) {
      if (type.apiValue.toLowerCase() == normalized) return type;
    }
    if (normalized == 'rexport' ||
        normalized == 're-export' ||
        normalized == 're_export' ||
        normalized == 'export' ||
        normalized == 'إعادة تصدير' ||
        normalized == 'اعادة تصدير') {
      return RequestFulfillmentType.reexport;
    }
    if (normalized == 'محلي') {
      return RequestFulfillmentType.local;
    }
    return null;
  }
}
