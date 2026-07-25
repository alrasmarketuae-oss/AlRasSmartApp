/// This file contains mapping for all API messages from backend
/// to user-friendly localized messages
class ApiMessagesMapper {
  /// Map of API messages to localization keys
  /// Uses keyword matching - if the message contains the key, it will match
  static final Map<String, String> _messagesMap = {
    // Authentication Messages
    'data loaded successfully': 'apiDataLoadedSuccessfully',
    'Error message from Exception': 'apiGeneralError',
    'lang.users.login': 'apiLoginSuccess',
    'lang.users.Registered': 'apiNeedVerification',
    'lang.users.incorrect': 'apiIncorrectData',
    'lang.users.valid code': 'apiValidCode',
    'invalid code': 'apiInvalidCode',
    'valid code': 'apiValidCode',
    'vaid code': 'apiValidCode',
    'Logged out successfully': 'apiLogoutSuccess',
    'تم تحديث كلمة المرور بنجاح': 'apiPasswordUpdatedSuccess',
    'البريد الإلكتروني غير موجود': 'apiEmailNotFound',
    'رمز التحقق غير صحيح': 'apiInvalidVerificationCode',

    // Real Estates Messages
    'added successfully': 'apiAddedSuccessfully',
    'انتهت صلاحية الباقة أو استهلكت جميع الإعلانات':
        'apiPackageExpiredOrConsumed',
    'send successfully': 'apiSentSuccessfully',
    'delete successfully': 'apiDeletedSuccessfully',
    'Real estate request successfully': 'apiRealEstateRequestSuccess',
    'Real estate successfully': 'apiRealEstateSuccess',
    'updated successfully': 'apiUpdatedSuccessfully',
    'deleted successfully': 'apiDeletedSuccessfully',
    'change successfully': 'apiChangeSuccessfully',

    // Service Messages
    'تم التقيييم بنجاح': 'apiRatingSuccess',

    // Order Messages
    'الإضافة إلى طلبات': 'apiAddedToOrders',
    'تمت الإضافة مسبقًا إلى طلباتك': 'apiAlreadyInOrders',
    'قائمة طلباتك': 'apiYourOrdersList',

    // Package Messages
    'تم الاشتراك في الباقة بنجاح': 'apiPackageSubscriptionSuccess',
    'تم الاشتراك في باقة بالفعل وما زالت سارية':
        'apiAlreadySubscribedToPackage',

    // Notification Messages
    'All notifications marked as read': 'apiAllNotificationsRead',

    // Project Messages
    'data saves sucefully': 'apiDataSavedSuccessfully',

    // General validation messages (common patterns)
    'مطلوب': 'apiFieldRequired',
    'مُستخدمة من قبل': 'apiValueAlreadyUsed',
    'صحيح البُنية': 'apiInvalidFormat',
  };

  /// Get localized message key from API message
  /// Returns the localization key if found, otherwise returns empty string
  static String getLocalizedKey(String apiMessage) {
    // First, try exact match
    if (_messagesMap.containsKey(apiMessage)) {
      return _messagesMap[apiMessage]!;
    }

    // Then, try partial match (if the API message contains any of the keys)
    for (var entry in _messagesMap.entries) {
      if (apiMessage.contains(entry.key)) {
        return entry.value;
      }
    }

    // If no match found, return empty string to indicate using original message
    return '';
  }

  /// Check if message should be translated
  static bool shouldTranslate(String message) {
    return getLocalizedKey(message).isNotEmpty;
  }

  /// Get user-friendly message with fallback to original
  static String getUserFriendlyMessage(
      String apiMessage, String Function(String) translate) {
    final localizedKey = getLocalizedKey(apiMessage);

    if (localizedKey.isNotEmpty) {
      return translate(localizedKey);
    }

    // Return original message if no translation found
    return apiMessage;
  }
}

