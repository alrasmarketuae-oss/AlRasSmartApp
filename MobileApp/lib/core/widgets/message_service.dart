import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/widgets/api_messages_mapper.dart';

import '../../generated/l10n.dart';
import '../theme/colors.dart';

class MessageService implements IMessageService {
  /// Translate API message to user-friendly localized message
  /// Takes the message from API and returns a localized version if available
  String _translateApiMessage(String? message, BuildContext? context) {
    if (message == null || message.isEmpty) {
      return '';
    }

    // If context is not available, return original message
    if (context == null) {
      return message;
    }

    // Try to get user-friendly message using the mapper
    final translatedMessage = ApiMessagesMapper.getUserFriendlyMessage(
      message,
      (key) => _getLocalizedString(key, context),
    );

    return translatedMessage;
  }

  /// Helper method to get localized string using S class
  String _getLocalizedString(String key, BuildContext context) {
    try {
      final s = S.of(context);
      // Use reflection or a switch case to get the value
      // Since Dart doesn't support direct string-to-property reflection easily,
      // we'll use a map-based approach
      return _getTranslationByKey(key, context);
    } catch (e) {
      return key;
    }
  }

  /// Get translation by key from S class
  String _getTranslationByKey(String key, BuildContext context) {
    switch (key) {
      case 'apiDataLoadedSuccessfully':
        return "S.of(context).apiDataLoadedSuccessfully";
      case 'apiGeneralError':
        return "S.of(context).apiGeneralError";
      case 'apiLoginSuccess':
        return "S.of(context).apiLoginSuccess";
      case 'apiNeedVerification':
        return "S.of(context).apiNeedVerification";
      case 'apiIncorrectData':
        return "S.of(context).apiIncorrectData";
      case 'apiValidCode':
        return "S.of(context).apiValidCode";
      case 'apiInvalidCode':
        return "S.of(context).apiInvalidCode";
      case 'apiLogoutSuccess':
        return "S.of(context).apiLogoutSuccess";
      case 'apiPasswordUpdatedSuccess':
        return "S.of(context).apiPasswordUpdatedSuccess";
      case 'apiEmailNotFound':
        return "S.of(context).apiEmailNotFound";
      case 'apiInvalidVerificationCode':
        return "S.of(context).apiInvalidVerificationCode";
      case 'apiAddedSuccessfully':
        return "S.of(context).apiAddedSuccessfully";
      case 'apiPackageExpiredOrConsumed':
        return "S.of(context).apiPackageExpiredOrConsumed";
      case 'apiSentSuccessfully':
        return "S.of(context).apiSentSuccessfully";
      case 'apiDeletedSuccessfully':
        return "S.of(context).apiDeletedSuccessfully";
      case 'apiRealEstateRequestSuccess':
        return "S.of(context).apiRealEstateRequestSuccess";
      case 'apiRealEstateSuccess':
        return "S.of(context).apiRealEstateSuccess";
      case 'apiUpdatedSuccessfully':
        return "S.of(context).apiUpdatedSuccessfully";
      case 'apiChangeSuccessfully':
        return "S.of(context).apiChangeSuccessfully";
      case 'apiRatingSuccess':
        return "S.of(context).apiRatingSuccess";
      case 'apiAddedToOrders':
        return "S.of(context).apiAddedToOrders";
      case 'apiAlreadyInOrders':
        return "S.of(context).apiAlreadyInOrders";
      case 'apiYourOrdersList':
        return "S.of(context).apiYourOrdersList";
      case 'apiPackageSubscriptionSuccess':
        return "S.of(context).apiPackageSubscriptionSuccess";
      case 'apiAlreadySubscribedToPackage':
        return "S.of(context).apiAlreadySubscribedToPackage";
      case 'apiAllNotificationsRead':
        return "S.of(context).apiAllNotificationsRead";
      case 'apiDataSavedSuccessfully':
        return "S.of(context).apiDataSavedSuccessfully";
      case 'apiFieldRequired':
        return "S.of(context).apiFieldRequired";
      case 'apiValueAlreadyUsed':
        return "S.of(context).apiValueAlreadyUsed";
      case 'apiInvalidFormat':
        return "S.of(context).apiInvalidFormat";
      default:
        return "S.of(context).$key";
    }
  }

  @override
  void noInternetConnectionAlert({BuildContext? context}) {
    final message = context != null
        ? _translateApiMessage(
            'no internet \n please check your internet',
            context,
          )
        : 'no internet \n please check your internet';

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void showSuccessSnackBarAlert<T>({
    required String? message,
    Color color = LightColor.defaultColor,
    BuildContext? context,
  }) {
    final translatedMessage = _translateApiMessage(message, context);

    Fluttertoast.showToast(
      msg: translatedMessage.isEmpty
          ? (message ?? "")
          : translatedMessage.length > 50
          ? "${translatedMessage.substring(0, 50)}..."
          : translatedMessage,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,

      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void snackBarActionAlert<T>({
    required String? message,
    required Function() onButtonPressed,
    BuildContext? context,
  }) {
    final translatedMessage = _translateApiMessage(message, context);

    Fluttertoast.showToast(
      msg: translatedMessage.isEmpty
          ? (message ?? "")
          : translatedMessage.length > 50
          ? "${translatedMessage.substring(0, 50)}..."
          : translatedMessage,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: LightColor.defaultColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void snackBarAlert<T>({
    required String? message,
    Color color = Colors.red,
    BuildContext? context,
  }) {
    final translatedMessage = _translateApiMessage(message, context);

    Fluttertoast.showToast(
      msg: translatedMessage.isEmpty
          ? (message ?? "")
          : translatedMessage.length > 50
          ? "${translatedMessage.substring(0, 50)}..."
          : translatedMessage,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

abstract class IMessageService {
  void snackBarAlert<T>({
    required String? message,
    Color color = Colors.red,
    BuildContext? context,
  });

  void showSuccessSnackBarAlert<T>({
    required String? message,
    BuildContext? context,
  });

  void noInternetConnectionAlert({BuildContext? context});

  void snackBarActionAlert<T>({
    required String? message,
    required Function() onButtonPressed,
    BuildContext? context,
  });
}
