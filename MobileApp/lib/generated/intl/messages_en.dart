// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(name) =>
      "Failed to upload ad \"${name}\". Please try again.";

  static String m1(percent) => "Compressing video… ${percent}%";

  static String m2(count) => "${count} views";

  static String m3(name) =>
      "Did you mean \"${name}\"? Showing results for the corrected name.";

  static String m4(name) =>
      "Our AI recognition system identified your product as ${name}.";

  static String m5(orderId) => "Order #${orderId}";

  static String m6(count) => "${count} Items";

  static String m7(quantity) =>
      "Only ${quantity} available for this product. Please review your cart.";

  static String m8(name) => "You are chatting with ${name}";

  static String m9(name) => "Chat closed by ${name}";

  static String m10(name) => "Conversation started with ${name}";

  static String m11(percent) => "${percent}%";

  static String m12(days) => "${days} days ago";

  static String m13(name) =>
      "Are you sure you want to delete \"${name}\"? This action cannot be undone.";

  static String m14(unit) => "Enter price per ${unit}";

  static String m15(maxSize) => "jpg, png, mp4 (max ${maxSize} MB for video)";

  static String m16(maxCount) => "You can upload at most ${maxCount} videos.";

  static String m17(quantity) => "Maximum order quantity is ${quantity}.";

  static String m18(quantity) => "Minimum order quantity is ${quantity}.";

  static String m19(unit) => "Offer price per ${unit}";

  static String m20(count) => "${count} offers available";

  static String m21(count) => "${count} orders available";

  static String m22(unit) => "Price per ${unit}";

  static String m23(percent) => "Preparing video… ${percent}%";

  static String m24(required) =>
      "Quantity cannot exceed the required quantity (${required}).";

  static String m25(requested, available) =>
      "Requested quantity (${requested}) exceeds available quantity (${available}).";

  static String m26(count) => "Selected Documents (${count})";

  static String m27(count) => "Selected Media (${count})";

  static String m28(from, to) => "Shipping time: ${from}-${to} days";

  static String m29(hours) => "${hours} hours ago";

  static String m30(minutes) => "${minutes} min ago";

  static String m31(unit) => "Target price per ${unit}";

  static String m32(maxMb) =>
      "Could not compress video below ${maxMb} MB. Try a shorter video.";

  static String m33(sizeMb) => "Video compressed to ${sizeMb} MB.";

  static String m34(sizeMb, maxMb) =>
      "Video size is ${sizeMb} MB. Maximum allowed size is ${maxMb} MB.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "PolicyandPrivacy": MessageLookupByLibrary.simpleMessage(
      "Policy and Privacy",
    ),
    "acceptOffer": MessageLookupByLibrary.simpleMessage("Accept"),
    "acceptOfferAction": MessageLookupByLibrary.simpleMessage("Accept Offer"),
    "acceptOrderAction": MessageLookupByLibrary.simpleMessage("Accept order"),
    "acceptanceText": MessageLookupByLibrary.simpleMessage(
      "By using the app, the user (supplier or client) fully agrees to all the above terms and conditions.",
    ),
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "accountCreatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Account created successfully",
    ),
    "accountCreationFailed": MessageLookupByLibrary.simpleMessage(
      "Account creation failed",
    ),
    "accountStatement": MessageLookupByLibrary.simpleMessage(
      "Account statement",
    ),
    "acids": MessageLookupByLibrary.simpleMessage("Acids"),
    "activeShippingOffers": MessageLookupByLibrary.simpleMessage(
      "Active Shipping Offers",
    ),
    "adBackgroundUploadFailed": m0,
    "adBackgroundUploadFailedGeneric": MessageLookupByLibrary.simpleMessage(
      "Failed to upload your ad. Please try again.",
    ),
    "adDeletedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Ad deleted successfully.",
    ),
    "adDetails": MessageLookupByLibrary.simpleMessage("Ad details"),
    "adPublishedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Ad published successfully.",
    ),
    "adReceivedUploadingMedia": MessageLookupByLibrary.simpleMessage(
      "Your ad was received. Video and photos are uploading now.",
    ),
    "adSubmittedForReview": MessageLookupByLibrary.simpleMessage(
      "Your ad was submitted for review successfully.",
    ),
    "adUpdatedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Ad updated successfully.",
    ),
    "adUploadNotificationText": MessageLookupByLibrary.simpleMessage(
      "Compressing and uploading in the background",
    ),
    "adUploadNotificationTitle": MessageLookupByLibrary.simpleMessage(
      "Uploading ad media",
    ),
    "adUploadProgressAttachingMedia": MessageLookupByLibrary.simpleMessage(
      "Attaching media to your ad…",
    ),
    "adUploadProgressCompressingImages": MessageLookupByLibrary.simpleMessage(
      "Compressing photos…",
    ),
    "adUploadProgressCompressingVideo": m1,
    "adUploadProgressDone": MessageLookupByLibrary.simpleMessage(
      "Media upload complete",
    ),
    "adUploadProgressUploadingImages": MessageLookupByLibrary.simpleMessage(
      "Uploading photos…",
    ),
    "adUploadProgressUploadingVideo": MessageLookupByLibrary.simpleMessage(
      "Uploading video…",
    ),
    "adViewsCount": m2,
    "addAnyNotesOrSpecialRequirementsOptional":
        MessageLookupByLibrary.simpleMessage(
          "Add any notes or special requirements... (Optional)",
        ),
    "addAnySpecialInstructionsHere": MessageLookupByLibrary.simpleMessage(
      "Add any special instructions here...",
    ),
    "addNewAddress": MessageLookupByLibrary.simpleMessage("Add New Address"),
    "addRetailPriceQuestion": MessageLookupByLibrary.simpleMessage(
      "Do you want to add a retail price?",
    ),
    "addShippingAd": MessageLookupByLibrary.simpleMessage("Add Shipping Ad"),
    "addShippingOffer": MessageLookupByLibrary.simpleMessage(
      "Add Shipping Offer",
    ),
    "addShippingOfferHint": MessageLookupByLibrary.simpleMessage(
      "Create a new shipping offer for clients",
    ),
    "addToCart": MessageLookupByLibrary.simpleMessage("Add to Cart"),
    "additionalNotes": MessageLookupByLibrary.simpleMessage("Additional Notes"),
    "address": MessageLookupByLibrary.simpleMessage("Address"),
    "addressIsRequired": MessageLookupByLibrary.simpleMessage(
      "Address is required",
    ),
    "addressLine1": MessageLookupByLibrary.simpleMessage("Address Line 1"),
    "addressLine2Optional": MessageLookupByLibrary.simpleMessage(
      "Address Line 2 (Optional)",
    ),
    "afterDiscount": MessageLookupByLibrary.simpleMessage("After Discount"),
    "agreeToTermsPrefix": MessageLookupByLibrary.simpleMessage(
      "I agree to the ",
    ),
    "aiAssistantBalanceHint": MessageLookupByLibrary.simpleMessage(
      "Supplier balance increases immediately on Retail card payments. Cash-on-delivery credits after collection/receipt. Withdrawals via IBAN are processed within 7 business days after support approval.",
    ),
    "aiAssistantCardSubtitle": MessageLookupByLibrary.simpleMessage(
      "Smart help at your fingertips",
    ),
    "aiAssistantFabLabel": MessageLookupByLibrary.simpleMessage("AI"),
    "aiAssistantHint": MessageLookupByLibrary.simpleMessage(
      "Ask about ads, orders, returns, image search…",
    ),
    "aiAssistantImageSearchHint": MessageLookupByLibrary.simpleMessage(
      "Image search: upload a product photo from the search bar to find similar catalog matches. See “Image-search model training” under Help & Support for details.",
    ),
    "aiAssistantListening": MessageLookupByLibrary.simpleMessage(
      "Listening… speak now",
    ),
    "aiAssistantOutOfScope": MessageLookupByLibrary.simpleMessage(
      "I can only help with Al Ras Market topics (accounts, ads, orders, payment, returns). Please ask something about the platform.",
    ),
    "aiAssistantReturnPolicyHint": MessageLookupByLibrary.simpleMessage(
      "For damaged, expired, or materially different goods: report within 24 business hours of receipt with photos. If support approves, refund is issued within 1 business day, and the supplier balance is adjusted if it was credited.",
    ),
    "aiAssistantSubtitle": MessageLookupByLibrary.simpleMessage(
      "Alras Smart is an AI Agent and can make mistakes.",
    ),
    "aiAssistantThinking": MessageLookupByLibrary.simpleMessage("Thinking…"),
    "aiAssistantTitle": MessageLookupByLibrary.simpleMessage("Alras Smart"),
    "aiAssistantUnsupportedLanguage": MessageLookupByLibrary.simpleMessage(
      "We currently support Arabic and English. We may translate your question internally to understand it, then reply in a supported language.",
    ),
    "aiAssistantVoiceCancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "aiAssistantVoiceCorrecting": MessageLookupByLibrary.simpleMessage(
      "AI is correcting your speech…",
    ),
    "aiAssistantVoiceHint": MessageLookupByLibrary.simpleMessage(
      "Review the text, then send or cancel",
    ),
    "aiAssistantVoiceSend": MessageLookupByLibrary.simpleMessage("Send"),
    "aiAssistantVoiceUnavailable": MessageLookupByLibrary.simpleMessage(
      "Voice input is not available on this device",
    ),
    "aiAssistantWelcome": MessageLookupByLibrary.simpleMessage(
      "Welcome. I’m Alras Smart. I can help you use the platform based on your account type. Live chat with a support agent is available from Profile.",
    ),
    "aiCorrectedSearch": m3,
    "aiIdentifiedProduct": m4,
    "aiIdentifiedProducts": MessageLookupByLibrary.simpleMessage(
      "Our AI recognition system found matching products for your image.",
    ),
    "alRasMarket": MessageLookupByLibrary.simpleMessage("Al Ras Smart App"),
    "allOffers": MessageLookupByLibrary.simpleMessage("All Offers"),
    "allOrders": MessageLookupByLibrary.simpleMessage("All Orders"),
    "alreadyHaveAnAccount": MessageLookupByLibrary.simpleMessage(
      "Already have an account?",
    ),
    "amendment1": MessageLookupByLibrary.simpleMessage(
      "Merge Spice reserves the right to modify these terms and conditions at any time; updates will be published in the app, and continued use implies acceptance.",
    ),
    "analyzingImage": MessageLookupByLibrary.simpleMessage(
      "Identifying the product...",
    ),
    "analyzingImageHint": MessageLookupByLibrary.simpleMessage(
      "Our AI is identifying the product from your photo.",
    ),
    "appName": MessageLookupByLibrary.simpleMessage("Ecovera"),
    "appWord": MessageLookupByLibrary.simpleMessage("App"),
    "approved": MessageLookupByLibrary.simpleMessage("Approved"),
    "arabicLabel": MessageLookupByLibrary.simpleMessage("Arabic"),
    "availableQuantity": MessageLookupByLibrary.simpleMessage(
      "Available Quantity",
    ),
    "awaitingAdminApproval": MessageLookupByLibrary.simpleMessage(
      "Awaiting app approval",
    ),
    "awaitingApproval": MessageLookupByLibrary.simpleMessage(
      "Awaiting Approval",
    ),
    "awaitingSellerApproval": MessageLookupByLibrary.simpleMessage(
      "Awaiting seller approval",
    ),
    "backToHome": MessageLookupByLibrary.simpleMessage("Back to Home"),
    "balanceDeposit": MessageLookupByLibrary.simpleMessage("Deposit"),
    "balanceDepositsSection": MessageLookupByLibrary.simpleMessage("Deposits"),
    "balanceOrderLabel": m5,
    "balanceWithdrawal": MessageLookupByLibrary.simpleMessage("Withdrawal"),
    "balanceWithdrawalsSection": MessageLookupByLibrary.simpleMessage(
      "Withdrawals",
    ),
    "beauty": MessageLookupByLibrary.simpleMessage("Beauty"),
    "beforeDiscount": MessageLookupByLibrary.simpleMessage("Before Discount"),
    "biometricAuthReason": MessageLookupByLibrary.simpleMessage(
      "Confirm it is you to continue",
    ),
    "biometricDisabledSuccess": MessageLookupByLibrary.simpleMessage(
      "Biometric unlock disabled",
    ),
    "biometricEnableReason": MessageLookupByLibrary.simpleMessage(
      "Confirm it is you to enable biometric unlock",
    ),
    "biometricEnabledSuccess": MessageLookupByLibrary.simpleMessage(
      "Biometric unlock enabled",
    ),
    "biometricNoEnrolled": MessageLookupByLibrary.simpleMessage(
      "Set up Face ID or a fingerprint in device settings first",
    ),
    "biometricNotAvailable": MessageLookupByLibrary.simpleMessage(
      "Biometrics are not available on this device",
    ),
    "biometricUnlockFailed": MessageLookupByLibrary.simpleMessage(
      "Biometric unlock failed. Please sign in normally.",
    ),
    "biometricUnlockSubtitle": MessageLookupByLibrary.simpleMessage(
      "Sign back in quickly after logout using Face ID or fingerprint. Only for this saved account.",
    ),
    "booking": MessageLookupByLibrary.simpleMessage("Booking"),
    "callNow": MessageLookupByLibrary.simpleMessage("Call Now"),
    "camera": MessageLookupByLibrary.simpleMessage("Camera"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelOrder": MessageLookupByLibrary.simpleMessage("Cancel Order"),
    "cancelOrderConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to cancel this order?",
    ),
    "cancelOrderConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Cancel this order?",
    ),
    "canned": MessageLookupByLibrary.simpleMessage("Canned"),
    "cannotOrderOwnProduct": MessageLookupByLibrary.simpleMessage(
      "You cannot place an order on your own product.",
    ),
    "cardamom": MessageLookupByLibrary.simpleMessage("Cardamom"),
    "cart": MessageLookupByLibrary.simpleMessage("Cart"),
    "cartItemsCount": m6,
    "cartMaxAvailableInStock": m7,
    "cartSubtitle": MessageLookupByLibrary.simpleMessage(
      "View and manage your cart",
    ),
    "cashOnDelivery": MessageLookupByLibrary.simpleMessage("Cash on delivery"),
    "categories": MessageLookupByLibrary.simpleMessage("Categories"),
    "category": MessageLookupByLibrary.simpleMessage("Category"),
    "changeLanguageSubtitle": MessageLookupByLibrary.simpleMessage(
      "Change language",
    ),
    "changePassword": MessageLookupByLibrary.simpleMessage("Change Password"),
    "changePasswordSubtitle": MessageLookupByLibrary.simpleMessage(
      "Update your password",
    ),
    "chatE2eNoticeBody": MessageLookupByLibrary.simpleMessage(
      "Only people in this conversation can read or listen to these messages.",
    ),
    "chatE2eNoticeReadMore": MessageLookupByLibrary.simpleMessage("Learn more"),
    "chatE2eNoticeTitle": MessageLookupByLibrary.simpleMessage(
      "Messages are end-to-end encrypted",
    ),
    "chatSessionActiveWith": m8,
    "chatSessionClosedBy": m9,
    "chatSessionStartedWith": m10,
    "chatWithTheSupportTeamNow": MessageLookupByLibrary.simpleMessage(
      "Chat with the support team now.",
    ),
    "chooseFromGallery": MessageLookupByLibrary.simpleMessage(
      "Choose from gallery",
    ),
    "chooseFromGalleryHint": MessageLookupByLibrary.simpleMessage(
      "Pick an existing image from your device",
    ),
    "chooseImageSource": MessageLookupByLibrary.simpleMessage("Add a photo"),
    "chooseImageSourceHint": MessageLookupByLibrary.simpleMessage(
      "Take a new photo or choose one from your gallery",
    ),
    "city": MessageLookupByLibrary.simpleMessage("City"),
    "clearAll": MessageLookupByLibrary.simpleMessage("Clear all"),
    "clientConfirmationHeader": MessageLookupByLibrary.simpleMessage(
      "After client confirmation:",
    ),
    "clientObligation1": MessageLookupByLibrary.simpleMessage(
      "The client must provide accurate data in the app.",
    ),
    "clientObligation2": MessageLookupByLibrary.simpleMessage(
      "The client is not responsible for any weight shortage upon receipt; any discrepancy will be deducted from the invoice value if applicable.",
    ),
    "clientObligation3": MessageLookupByLibrary.simpleMessage(
      "The client agrees to pay the order value as agreed (cash, credit, on delivery or receipt).",
    ),
    "closed": MessageLookupByLibrary.simpleMessage("Closed"),
    "cocoa": MessageLookupByLibrary.simpleMessage("Cocoa"),
    "codeValidFor10Minutes": MessageLookupByLibrary.simpleMessage(
      "Code valid for 10 minutes",
    ),
    "coffee": MessageLookupByLibrary.simpleMessage("Coffee"),
    "commercialRegister": MessageLookupByLibrary.simpleMessage(
      "Commercial register",
    ),
    "commercialRegistration": MessageLookupByLibrary.simpleMessage(
      "Commercial Registration",
    ),
    "commissionBooking": MessageLookupByLibrary.simpleMessage("Booking"),
    "commissionCategoriesTitle": MessageLookupByLibrary.simpleMessage(
      "By category:",
    ),
    "commissionChangeNotice": MessageLookupByLibrary.simpleMessage(
      "Service fees may change from time to time according to platform policy.",
    ),
    "commissionExample": MessageLookupByLibrary.simpleMessage(
      "Simple example: if you list a product at a certain price, that price appears as you entered it in My Ads, while the public listings feed may show a higher price because the service fee is added.",
    ),
    "commissionIntro": MessageLookupByLibrary.simpleMessage(
      "Service fees and rates are applied to product prices shown inside the app only. Specific percentages are not listed here.",
    ),
    "commissionLoadError": MessageLookupByLibrary.simpleMessage(
      "Could not load commission rates right now. Please try again later.",
    ),
    "commissionLoading": MessageLookupByLibrary.simpleMessage(
      "Loading commission rates...",
    ),
    "commissionOffers": MessageLookupByLibrary.simpleMessage("Offers"),
    "commissionPercentValue": m11,
    "commissionRequests": MessageLookupByLibrary.simpleMessage("Requests"),
    "commissionRetail": MessageLookupByLibrary.simpleMessage("Retail"),
    "commissionSectionTitle": MessageLookupByLibrary.simpleMessage(
      "App fees on product prices",
    ),
    "commissionShipping": MessageLookupByLibrary.simpleMessage("Shipping"),
    "company": MessageLookupByLibrary.simpleMessage("company"),
    "companyCustomerAccount": MessageLookupByLibrary.simpleMessage(
      "Company Account",
    ),
    "companyGuest": MessageLookupByLibrary.simpleMessage("Company Guest"),
    "companyName": MessageLookupByLibrary.simpleMessage("Company Name"),
    "companyNameIsRequired": MessageLookupByLibrary.simpleMessage(
      "Company name is required",
    ),
    "companyNoLiabilityHeader": MessageLookupByLibrary.simpleMessage(
      "Merge Spice bears no responsibility for:",
    ),
    "companyRights": MessageLookupByLibrary.simpleMessage(
      "The company reserves the right to suspend or delete any account violating terms without prior notice.",
    ),
    "companySiteImageSelected": MessageLookupByLibrary.simpleMessage(
      "Company site image selected",
    ),
    "completeOriginDestination": MessageLookupByLibrary.simpleMessage(
      "Please complete origin and destination details.",
    ),
    "completeShippingCompanyRegistration": MessageLookupByLibrary.simpleMessage(
      "Complete Shipping Company Registration",
    ),
    "completedOrders": MessageLookupByLibrary.simpleMessage("Completed"),
    "compressingImage": MessageLookupByLibrary.simpleMessage(
      "Compressing image...",
    ),
    "compressingVideo": MessageLookupByLibrary.simpleMessage(
      "Compressing video...",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirmNewPassword": MessageLookupByLibrary.simpleMessage(
      "Confirm new password",
    ),
    "confirmOrder": MessageLookupByLibrary.simpleMessage("Confirm Order"),
    "confirmPassword": MessageLookupByLibrary.simpleMessage("Confirm Password"),
    "confirmPasswordIsRequired": MessageLookupByLibrary.simpleMessage(
      "Confirm password is required",
    ),
    "confirmPasswordMustBeSame": MessageLookupByLibrary.simpleMessage(
      "Confirm password must match password",
    ),
    "contactSupport": MessageLookupByLibrary.simpleMessage("Contact Support"),
    "container20f": MessageLookupByLibrary.simpleMessage("20f container"),
    "container40f": MessageLookupByLibrary.simpleMessage("40f container"),
    "continueShopping": MessageLookupByLibrary.simpleMessage(
      "Continue shopping",
    ),
    "continueWithApple": MessageLookupByLibrary.simpleMessage(
      "Continue with Apple",
    ),
    "continueWithFacebook": MessageLookupByLibrary.simpleMessage(
      "Continue with Facebook",
    ),
    "continueWithGoogle": MessageLookupByLibrary.simpleMessage(
      "Continue with Google",
    ),
    "costCalculation": MessageLookupByLibrary.simpleMessage("Cost Calculation"),
    "countdown": MessageLookupByLibrary.simpleMessage("Count"),
    "counterfeitProducts": MessageLookupByLibrary.simpleMessage(
      "Counterfeit or fake products.",
    ),
    "country": MessageLookupByLibrary.simpleMessage("Country"),
    "countryCode": MessageLookupByLibrary.simpleMessage("Country Code"),
    "countryOfOrigin": MessageLookupByLibrary.simpleMessage(
      "Country of Origin",
    ),
    "createAccount": MessageLookupByLibrary.simpleMessage("Create Account"),
    "createAds": MessageLookupByLibrary.simpleMessage("Create Ad"),
    "createOrder": MessageLookupByLibrary.simpleMessage("Create Order"),
    "currency": MessageLookupByLibrary.simpleMessage("Currency"),
    "currencyAedFull": MessageLookupByLibrary.simpleMessage("UAE Dirham (AED)"),
    "currencyUsdFull": MessageLookupByLibrary.simpleMessage("US Dollar (USD)"),
    "currentAds": MessageLookupByLibrary.simpleMessage("Current ads"),
    "currentBalance": MessageLookupByLibrary.simpleMessage("Current balance"),
    "currentPassword": MessageLookupByLibrary.simpleMessage("Current Password"),
    "customerService": MessageLookupByLibrary.simpleMessage("Customer Service"),
    "dataSafeSubtitle": MessageLookupByLibrary.simpleMessage(
      "We use advanced security to protect your information.",
    ),
    "dataSafeTitle": MessageLookupByLibrary.simpleMessage(
      "Your data is safe with us",
    ),
    "dateOfBirth": MessageLookupByLibrary.simpleMessage("Date of Birth"),
    "dates": MessageLookupByLibrary.simpleMessage("Dates"),
    "dayUnit": MessageLookupByLibrary.simpleMessage("day"),
    "daysAgo": m12,
    "defApp": MessageLookupByLibrary.simpleMessage(
      "The app refers to the Souq Al Ras electronic platform.",
    ),
    "defClient": MessageLookupByLibrary.simpleMessage(
      "The client refers to any user purchasing products through the app.",
    ),
    "defCompany": MessageLookupByLibrary.simpleMessage(
      "The company refers to Merge Spice Foodstuff Trading LLC.",
    ),
    "defSupplier": MessageLookupByLibrary.simpleMessage(
      "The supplier refers to any company or individual offering products through the app.",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteAccount": MessageLookupByLibrary.simpleMessage("Delete Account"),
    "deleteAccountConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "This will permanently delete your account, ads, orders, messages, addresses, and all related data. This action cannot be undone.",
    ),
    "deleteAccountSubtitle": MessageLookupByLibrary.simpleMessage(
      "Permanently delete your account",
    ),
    "deleteAccountSuccess": MessageLookupByLibrary.simpleMessage(
      "Your account has been deleted successfully.",
    ),
    "deleteAdConfirmMessage": m13,
    "deleteAdConfirmTitle": MessageLookupByLibrary.simpleMessage("Delete ad?"),
    "deleteAddress": MessageLookupByLibrary.simpleMessage("Delete Address"),
    "deleteAddressConfirm": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this address?",
    ),
    "deleteShippingAdConfirm": MessageLookupByLibrary.simpleMessage(
      "Delete this shipping ad?",
    ),
    "deletedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Deleted successfully",
    ),
    "delivered": MessageLookupByLibrary.simpleMessage("Delivered"),
    "delivery": MessageLookupByLibrary.simpleMessage("Delivery"),
    "deliveryAddress": MessageLookupByLibrary.simpleMessage("Delivery Address"),
    "deliveryEmirate": MessageLookupByLibrary.simpleMessage("Delivery emirate"),
    "deliveryFee": MessageLookupByLibrary.simpleMessage("Delivery Fee"),
    "deliveryMethod": MessageLookupByLibrary.simpleMessage("Delivery Method"),
    "deliveryTimeDays": MessageLookupByLibrary.simpleMessage(
      "Delivery Time (days)",
    ),
    "deliveryToAddressHint": MessageLookupByLibrary.simpleMessage(
      "We will deliver to your address",
    ),
    "description": MessageLookupByLibrary.simpleMessage("Description"),
    "destination": MessageLookupByLibrary.simpleMessage("Destination"),
    "destinationCountry": MessageLookupByLibrary.simpleMessage(
      "Destination Country",
    ),
    "destinationPort": MessageLookupByLibrary.simpleMessage("Destination Port"),
    "details": MessageLookupByLibrary.simpleMessage("Details"),
    "documentFormatsHint": MessageLookupByLibrary.simpleMessage(
      "JPG, PNG, PDF, DOC, DOCX, XLS, PPT",
    ),
    "dollar": MessageLookupByLibrary.simpleMessage("USD"),
    "domesticShippingWeightDisclaimer": MessageLookupByLibrary.simpleMessage(
      "This shipping price may include additional fees if the total weight exceeds 10 kg.",
    ),
    "dontHaveAnAccount": MessageLookupByLibrary.simpleMessage(
      "Don\'t have an account?",
    ),
    "dragDropOrTapToUpload": MessageLookupByLibrary.simpleMessage(
      "Drag, drop, or tap to upload",
    ),
    "dubaiUae": MessageLookupByLibrary.simpleMessage("Dubai, UAE"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editAddress": MessageLookupByLibrary.simpleMessage("Edit Address"),
    "editCart": MessageLookupByLibrary.simpleMessage("Edit Cart"),
    "editProfile": MessageLookupByLibrary.simpleMessage("Edit Profile"),
    "editShippingAd": MessageLookupByLibrary.simpleMessage("Edit Shipping Ad"),
    "eighthAmendments": MessageLookupByLibrary.simpleMessage(
      "Eighth: Amendments",
    ),
    "email": MessageLookupByLibrary.simpleMessage("Email"),
    "emailIsRequired": MessageLookupByLibrary.simpleMessage(
      "Email is required",
    ),
    "enableBiometricUnlock": MessageLookupByLibrary.simpleMessage(
      "Face ID / Fingerprint",
    ),
    "endingSoon": MessageLookupByLibrary.simpleMessage("Ending Soon"),
    "englishLabel": MessageLookupByLibrary.simpleMessage("English"),
    "enterAddress": MessageLookupByLibrary.simpleMessage("Enter address"),
    "enterAddressLine1": MessageLookupByLibrary.simpleMessage(
      "Enter address line 1",
    ),
    "enterAddressLine2Optional": MessageLookupByLibrary.simpleMessage(
      "Enter address line 2 (optional)",
    ),
    "enterCompanyName": MessageLookupByLibrary.simpleMessage(
      "Enter company name",
    ),
    "enterCountry": MessageLookupByLibrary.simpleMessage("Enter country"),
    "enterCurrentPassword": MessageLookupByLibrary.simpleMessage(
      "Enter current password",
    ),
    "enterDate": MessageLookupByLibrary.simpleMessage("Enter Date"),
    "enterDeliveryTimeInDays": MessageLookupByLibrary.simpleMessage(
      "Enter delivery time in days",
    ),
    "enterDetails": MessageLookupByLibrary.simpleMessage("Enter details"),
    "enterFullName": MessageLookupByLibrary.simpleMessage("Enter full name"),
    "enterNewPassword": MessageLookupByLibrary.simpleMessage(
      "Enter new password",
    ),
    "enterOfferDurationInDays": MessageLookupByLibrary.simpleMessage(
      "Enter offer duration in days",
    ),
    "enterPasswordToConfirm": MessageLookupByLibrary.simpleMessage(
      "Enter your password to confirm",
    ),
    "enterPort": MessageLookupByLibrary.simpleMessage("Enter port"),
    "enterPrice": MessageLookupByLibrary.simpleMessage("Enter price"),
    "enterPricePerUnit": m14,
    "enterPricePerUnitGeneric": MessageLookupByLibrary.simpleMessage(
      "Enter price per unit",
    ),
    "enterProductPrice": MessageLookupByLibrary.simpleMessage(
      "Enter product price",
    ),
    "enterQuantity": MessageLookupByLibrary.simpleMessage("Enter Quantity"),
    "enterShippingCompanyName": MessageLookupByLibrary.simpleMessage(
      "Enter shipping company name",
    ),
    "enterShippingDurationInDays": MessageLookupByLibrary.simpleMessage(
      "Enter shipping duration in days",
    ),
    "enterTheRequiredSpecificationsInDetail":
        MessageLookupByLibrary.simpleMessage(
          "Enter the required specifications in detail...",
        ),
    "enterTradeLicenseNumber": MessageLookupByLibrary.simpleMessage(
      "Enter trade license number",
    ),
    "enterValidPrice": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid price greater than zero.",
    ),
    "enterValidQuantity": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid quantity.",
    ),
    "enterValidQuantityAndPrice": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid quantity and price.",
    ),
    "enterYourEmail": MessageLookupByLibrary.simpleMessage("Enter your email"),
    "enterYourOffer": MessageLookupByLibrary.simpleMessage("Enter your offer"),
    "enterYourPassword": MessageLookupByLibrary.simpleMessage(
      "Enter your password",
    ),
    "enterYourTargetPrice": MessageLookupByLibrary.simpleMessage(
      "Enter your target price",
    ),
    "examplePremiumIranianSaffron": MessageLookupByLibrary.simpleMessage(
      "Green cardamom",
    ),
    "exclusiveAgents": MessageLookupByLibrary.simpleMessage(
      "Products belonging to exclusive agents without official authorization.",
    ),
    "faceIdFingerprintSubtitle": MessageLookupByLibrary.simpleMessage(
      "Sign back in quickly after logout using Face ID or fingerprint. Only for this saved account.",
    ),
    "failedToAddProductToCart": MessageLookupByLibrary.simpleMessage(
      "Failed to add product to cart.",
    ),
    "failedToConfirmOrder": MessageLookupByLibrary.simpleMessage(
      "Failed to confirm order.",
    ),
    "failedToLoadBalance": MessageLookupByLibrary.simpleMessage(
      "Failed to load balance statement.",
    ),
    "failedToLoadCart": MessageLookupByLibrary.simpleMessage(
      "Failed to load cart.",
    ),
    "failedToLoadSavedAds": MessageLookupByLibrary.simpleMessage(
      "Failed to load saved ads.",
    ),
    "failedToReduceCartQuantity": MessageLookupByLibrary.simpleMessage(
      "Failed to reduce quantity.",
    ),
    "failedToRemoveCartItem": MessageLookupByLibrary.simpleMessage(
      "Failed to remove item from cart.",
    ),
    "featured": MessageLookupByLibrary.simpleMessage("Featured Offers"),
    "featuredProducts": MessageLookupByLibrary.simpleMessage(
      "Featured Products",
    ),
    "fifthSalesMechanism": MessageLookupByLibrary.simpleMessage(
      "Fifth: Sales and Payment Mechanism",
    ),
    "files": MessageLookupByLibrary.simpleMessage("Files"),
    "filter": MessageLookupByLibrary.simpleMessage("Filter"),
    "filterAll": MessageLookupByLibrary.simpleMessage("All"),
    "firstDefinitions": MessageLookupByLibrary.simpleMessage(
      "First: Definitions",
    ),
    "flour": MessageLookupByLibrary.simpleMessage("Flour"),
    "forbiddenBackgrounds": MessageLookupByLibrary.simpleMessage(
      "Using images or backgrounds indicating the supplier\'s location or identity is forbidden.",
    ),
    "forgotPassword": MessageLookupByLibrary.simpleMessage("Forgot password?"),
    "fourthClientObligations": MessageLookupByLibrary.simpleMessage(
      "Fourth: Client Obligations",
    ),
    "free": MessageLookupByLibrary.simpleMessage("Free"),
    "frequentlyAskedQuestions": MessageLookupByLibrary.simpleMessage(
      "Frequently Asked Questions",
    ),
    "friday": MessageLookupByLibrary.simpleMessage("Friday:"),
    "fromDay": MessageLookupByLibrary.simpleMessage("From day"),
    "fromLabel": MessageLookupByLibrary.simpleMessage("From:"),
    "frozenFoods": MessageLookupByLibrary.simpleMessage("Frozen Foods"),
    "fullName": MessageLookupByLibrary.simpleMessage("Full Name"),
    "gallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "googleAccount": MessageLookupByLibrary.simpleMessage("Google Account"),
    "gotIt": MessageLookupByLibrary.simpleMessage("Got it"),
    "governingLawText": MessageLookupByLibrary.simpleMessage(
      "These terms and conditions are governed by UAE laws, and Dubai courts have jurisdiction over any disputes.",
    ),
    "helpSupport": MessageLookupByLibrary.simpleMessage("Help & Support"),
    "helpSupportSubtitle": MessageLookupByLibrary.simpleMessage(
      "Get help and contact support",
    ),
    "herbs": MessageLookupByLibrary.simpleMessage("Herbs"),
    "highlightAd": MessageLookupByLibrary.simpleMessage("Highlight Ad"),
    "highlightAdDescription": MessageLookupByLibrary.simpleMessage(
      "Highlight your ad to appear at the top of search results and get more views",
    ),
    "highlightAdNewPrice": MessageLookupByLibrary.simpleMessage("99 AED/month"),
    "highlightAdOldPrice": MessageLookupByLibrary.simpleMessage("199 AED"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "hoursAgo": MessageLookupByLibrary.simpleMessage("hours ago"),
    "howCanIPlaceAnOrder": MessageLookupByLibrary.simpleMessage(
      "How can I place an order?",
    ),
    "howCanIPlaceAnOrderAnswer": MessageLookupByLibrary.simpleMessage(
      "Browse products, open the item you want, then tap Add to Cart. Go to Cart, review your items, choose shipping if needed, and complete checkout.",
    ),
    "howCanWeHelpYou": MessageLookupByLibrary.simpleMessage(
      "How can we help you?",
    ),
    "howDoITrackMyOrder": MessageLookupByLibrary.simpleMessage(
      "How do I track my order?",
    ),
    "howDoITrackMyOrderAnswer": MessageLookupByLibrary.simpleMessage(
      "Open My Orders from your profile, select the order, then tap Track Order to follow its current status.",
    ),
    "imageSelectedFromGallery": MessageLookupByLibrary.simpleMessage(
      "Image selected from gallery",
    ),
    "imageVideoFormatsHint": m15,
    "inProgress": MessageLookupByLibrary.simpleMessage("In Progress"),
    "invalidEmail": MessageLookupByLibrary.simpleMessage("Invalid email"),
    "invalidWebsite": MessageLookupByLibrary.simpleMessage(
      "Enter a valid website URL",
    ),
    "justNow": MessageLookupByLibrary.simpleMessage("Just now"),
    "landlinePhone": MessageLookupByLibrary.simpleMessage("Landline Number"),
    "language": MessageLookupByLibrary.simpleMessage("English"),
    "languagePreferenceHint": MessageLookupByLibrary.simpleMessage(
      "Choose your preferred language. The app will update immediately.",
    ),
    "languageTitle": MessageLookupByLibrary.simpleMessage("Language"),
    "liabilityQuality": MessageLookupByLibrary.simpleMessage("Quality"),
    "liabilityQuantity": MessageLookupByLibrary.simpleMessage("Quantity"),
    "liabilitySpecs": MessageLookupByLibrary.simpleMessage(
      "Compliance with specifications",
    ),
    "liabilityWeight": MessageLookupByLibrary.simpleMessage("Weight"),
    "limitedTime": MessageLookupByLibrary.simpleMessage("Limited Time"),
    "limitedTimeDeal": MessageLookupByLibrary.simpleMessage("Limited time"),
    "listingActive": MessageLookupByLibrary.simpleMessage("Active"),
    "listingPaused": MessageLookupByLibrary.simpleMessage("Paused"),
    "liveChat": MessageLookupByLibrary.simpleMessage("Live Chat"),
    "liveChatSubtitle": MessageLookupByLibrary.simpleMessage(
      "Chat with our support team",
    ),
    "loadingEllipsis": MessageLookupByLibrary.simpleMessage("Loading..."),
    "loadingPort": MessageLookupByLibrary.simpleMessage("Loading Port"),
    "logOut": MessageLookupByLibrary.simpleMessage("Log Out"),
    "logOutSubtitle": MessageLookupByLibrary.simpleMessage(
      "Sign out from your account",
    ),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "loginAsGuest": MessageLookupByLibrary.simpleMessage("Login as Guest"),
    "loginError": MessageLookupByLibrary.simpleMessage("Login failed"),
    "loginSubtitle": MessageLookupByLibrary.simpleMessage(
      "Sign in to your account",
    ),
    "loginSuccess": MessageLookupByLibrary.simpleMessage("Login successful"),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "manageShippingOffers": MessageLookupByLibrary.simpleMessage(
      "Manage Shipping Offers",
    ),
    "manageShippingOffersHint": MessageLookupByLibrary.simpleMessage(
      "View and edit your current shipping offers",
    ),
    "markAllAsRead": MessageLookupByLibrary.simpleMessage("Mark all as read"),
    "maxProductImagesExceeded": MessageLookupByLibrary.simpleMessage(
      "You can upload at most 15 images.",
    ),
    "maxProductVideosExceeded": m16,
    "maximumOrderQuantityIs": m17,
    "mechanismAmountCollected": MessageLookupByLibrary.simpleMessage(
      "The amount is collected from the client.",
    ),
    "mechanismCodPolicy": MessageLookupByLibrary.simpleMessage(
      "Online card payment is available for Retail orders only. Cash on delivery applies to other deal types per platform process. Supplier payouts follow the approved verification policy.",
    ),
    "mechanismCompanyCommitment": MessageLookupByLibrary.simpleMessage(
      "The company pays the supplier only after the client receives the goods.",
    ),
    "mechanismDeliveryConfirm": MessageLookupByLibrary.simpleMessage(
      "Successful receipt confirmation.",
    ),
    "mechanismFinancialIntermediary": MessageLookupByLibrary.simpleMessage(
      "The company acts as a financial intermediary between the parties (collecting from client – transferring to supplier).",
    ),
    "mechanismInvoiceIssue": MessageLookupByLibrary.simpleMessage(
      "Merge Spice issues an invoice including the agreed quantity and price.",
    ),
    "mechanismInvoiceSend": MessageLookupByLibrary.simpleMessage(
      "The invoice is sent to the client for confirmation.",
    ),
    "mechanismSupplierNotified": MessageLookupByLibrary.simpleMessage(
      "The supplier is notified to start delivery.",
    ),
    "milk": MessageLookupByLibrary.simpleMessage("Milk"),
    "minimumOrder": MessageLookupByLibrary.simpleMessage("Minimum order"),
    "minimumOrderQuantityIs": m18,
    "modelTrainingTitle": MessageLookupByLibrary.simpleMessage(
      "Image-search model training",
    ),
    "mustAcceptTermsAndPrivacy": MessageLookupByLibrary.simpleMessage(
      "Please accept the terms and privacy policy.",
    ),
    "muteVideo": MessageLookupByLibrary.simpleMessage("Mute"),
    "myAds": MessageLookupByLibrary.simpleMessage("My Ads"),
    "myAdsSubtitle": MessageLookupByLibrary.simpleMessage(
      "Manage your advertisements",
    ),
    "myBalance": MessageLookupByLibrary.simpleMessage("My Balance"),
    "myBalanceSubtitle": MessageLookupByLibrary.simpleMessage(
      "Track your balance and withdrawals",
    ),
    "myOffers": MessageLookupByLibrary.simpleMessage("My Offers"),
    "myOrders": MessageLookupByLibrary.simpleMessage("My Orders"),
    "myOrdersSubtitle": MessageLookupByLibrary.simpleMessage(
      "Track and manage all your orders in one place.",
    ),
    "natureIntermediary": MessageLookupByLibrary.simpleMessage(
      "Merge Spice acts as an intermediary between the supplier and the client, with all sales and purchases conducted through the app.",
    ),
    "natureMediator": MessageLookupByLibrary.simpleMessage(
      "The company is not the owner of the displayed goods but acts as a mediator to organize commercial operations and ensure smooth transactions.",
    ),
    "negotiable": MessageLookupByLibrary.simpleMessage("Negotiable"),
    "newPassword": MessageLookupByLibrary.simpleMessage("New Password"),
    "next": MessageLookupByLibrary.simpleMessage("Next"),
    "ninthGoverningLaw": MessageLookupByLibrary.simpleMessage(
      "Ninth: Applicable Laws",
    ),
    "noAccount": MessageLookupByLibrary.simpleMessage("No account?"),
    "noAdsMatchFilter": MessageLookupByLibrary.simpleMessage(
      "No ads match this filter.",
    ),
    "noBalanceTransactions": MessageLookupByLibrary.simpleMessage(
      "No balance transactions yet.",
    ),
    "noDepositsYet": MessageLookupByLibrary.simpleMessage(
      "No deposits from the platform yet.",
    ),
    "noDetailsAvailable": MessageLookupByLibrary.simpleMessage("No details"),
    "noLiabilityAppLosses": MessageLookupByLibrary.simpleMessage(
      "Any losses due to misuse of the app",
    ),
    "noLiabilityDisputes": MessageLookupByLibrary.simpleMessage(
      "Any disputes between supplier and client",
    ),
    "noLiabilityProductQuality": MessageLookupByLibrary.simpleMessage(
      "Product quality",
    ),
    "noOffersOnAd": MessageLookupByLibrary.simpleMessage(
      "No offers on this ad yet.",
    ),
    "noOffersYet": MessageLookupByLibrary.simpleMessage(
      "You have not submitted any offers yet",
    ),
    "noOrdersMatchFilter": MessageLookupByLibrary.simpleMessage(
      "No orders match this filter.",
    ),
    "noProductsInCategory": MessageLookupByLibrary.simpleMessage(
      "No products found in this category.",
    ),
    "noSavedAddresses": MessageLookupByLibrary.simpleMessage(
      "No saved addresses yet.",
    ),
    "noSavedAds": MessageLookupByLibrary.simpleMessage("No saved ads yet"),
    "noSavedAdsHint": MessageLookupByLibrary.simpleMessage(
      "Open any ad and tap the bookmark icon to save it here.",
    ),
    "noSearchResults": MessageLookupByLibrary.simpleMessage(
      "No products found for your search.",
    ),
    "noShippingOffers": MessageLookupByLibrary.simpleMessage(
      "No shipping offers",
    ),
    "noShippingOffersAvailable": MessageLookupByLibrary.simpleMessage(
      "No shipping offers available right now.",
    ),
    "noShippingOffersMatch": MessageLookupByLibrary.simpleMessage(
      "No shipping offers match your filters.",
    ),
    "noWithdrawalsYet": MessageLookupByLibrary.simpleMessage(
      "No withdrawal requests yet.",
    ),
    "nonNegotiable": MessageLookupByLibrary.simpleMessage("Non-Negotiable"),
    "notificationSettings": MessageLookupByLibrary.simpleMessage(
      "Notification Settings",
    ),
    "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
    "nuts": MessageLookupByLibrary.simpleMessage("Nuts"),
    "offerDetails": MessageLookupByLibrary.simpleMessage("Offer Details"),
    "offerDuration": MessageLookupByLibrary.simpleMessage("Offer Duration"),
    "offerPrice": MessageLookupByLibrary.simpleMessage("Offer Price"),
    "offerPricePerUnit": m19,
    "offerSentNotifyWhenReviewed": MessageLookupByLibrary.simpleMessage(
      "We will notify you when the offer is accepted or rejected",
    ),
    "offerSentSuccessfullySubtitle": MessageLookupByLibrary.simpleMessage(
      "Your offer has been successfully sent to the requester",
    ),
    "offerSentSuccessfullyTitle": MessageLookupByLibrary.simpleMessage(
      "The offer has been sent\nsuccessfully",
    ),
    "offers": MessageLookupByLibrary.simpleMessage("Offers"),
    "offersAvailable": m20,
    "offersInfo": MessageLookupByLibrary.simpleMessage("Offers"),
    "oneDayAgo": MessageLookupByLibrary.simpleMessage("1 day ago"),
    "optional": MessageLookupByLibrary.simpleMessage(" (optional)"),
    "or": MessageLookupByLibrary.simpleMessage("Or"),
    "order": MessageLookupByLibrary.simpleMessage("Order"),
    "orderAgain": MessageLookupByLibrary.simpleMessage("Products"),
    "orderCancelledStatus": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "orderCancelledSuccess": MessageLookupByLibrary.simpleMessage(
      "Order cancelled successfully",
    ),
    "orderConfirmationHeader": MessageLookupByLibrary.simpleMessage(
      "Upon order confirmation between supplier and client:",
    ),
    "orderDate": MessageLookupByLibrary.simpleMessage("Order Date"),
    "orderDetails": MessageLookupByLibrary.simpleMessage("Order Details"),
    "orderInformation": MessageLookupByLibrary.simpleMessage(
      "Order Information",
    ),
    "orderNumber": MessageLookupByLibrary.simpleMessage("Order Number"),
    "orderRefundCompleted": MessageLookupByLibrary.simpleMessage(
      "Refund completed",
    ),
    "orderRefundNotice": MessageLookupByLibrary.simpleMessage(
      "The amount will be refunded to your original payment method within one business day.",
    ),
    "orderRefundPending": MessageLookupByLibrary.simpleMessage(
      "Refund in progress",
    ),
    "orderReturnSuccess": MessageLookupByLibrary.simpleMessage(
      "Return request submitted successfully",
    ),
    "orderSentNotifyWhenRespond": MessageLookupByLibrary.simpleMessage(
      "You will be notified once they respond.",
    ),
    "orderSentSuccessfullySubtitle": MessageLookupByLibrary.simpleMessage(
      "Your request has been sent to management for review.",
    ),
    "orderSentSuccessfullyTitle": MessageLookupByLibrary.simpleMessage(
      "Order sent successfully",
    ),
    "orderSummary": MessageLookupByLibrary.simpleMessage("Order Summary"),
    "ordered": MessageLookupByLibrary.simpleMessage("Ordered"),
    "orders": MessageLookupByLibrary.simpleMessage("Orders"),
    "ordersAvailable": m21,
    "ordersInfo": MessageLookupByLibrary.simpleMessage("Orders Info"),
    "otherPhone": MessageLookupByLibrary.simpleMessage(
      "Other Phone (optional)",
    ),
    "otherPhoneIsRequired": MessageLookupByLibrary.simpleMessage(
      "Other phone is required",
    ),
    "otpCode": MessageLookupByLibrary.simpleMessage("OTP Code"),
    "packagingCartons": MessageLookupByLibrary.simpleMessage(
      "Packaging: Cartons",
    ),
    "packagingType": MessageLookupByLibrary.simpleMessage("Packaging Type"),
    "paid": MessageLookupByLibrary.simpleMessage("Paid to Merge Spice"),
    "paidByCustomer": MessageLookupByLibrary.simpleMessage(
      "Paid to Merge Spice",
    ),
    "paidToSupplier": MessageLookupByLibrary.simpleMessage(
      "Paid to supplier from Merge Spice",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "passwordIsRequired": MessageLookupByLibrary.simpleMessage(
      "Password is required",
    ),
    "passwordMustBeAtLeast6Characters": MessageLookupByLibrary.simpleMessage(
      "Password must be at least 6 characters",
    ),
    "payWithVisa": MessageLookupByLibrary.simpleMessage("Visa / Card"),
    "payWithVisaButton": MessageLookupByLibrary.simpleMessage("Pay with Visa"),
    "paymentCodAll": MessageLookupByLibrary.simpleMessage(
      "Cash on delivery applies to other deal types according to platform process and the Al Ras team.",
    ),
    "paymentMethods": MessageLookupByLibrary.simpleMessage("Payment Methods"),
    "paymentOnDelivery": MessageLookupByLibrary.simpleMessage(
      "Payment on delivery",
    ),
    "paymentOnDeliveryDescription": MessageLookupByLibrary.simpleMessage(
      "Payment is collected automatically when you receive the order. No online payment is required.",
    ),
    "paymentRetailOnline": MessageLookupByLibrary.simpleMessage(
      "Online card payment is available for Retail orders only.",
    ),
    "pdfJpgPngMax10Mb": MessageLookupByLibrary.simpleMessage(
      "PDF, JPG, PNG max 10MB",
    ),
    "pendingRequests": MessageLookupByLibrary.simpleMessage("Pending Requests"),
    "person": MessageLookupByLibrary.simpleMessage("person"),
    "personalAccount": MessageLookupByLibrary.simpleMessage("Personal Account"),
    "personalInformation": MessageLookupByLibrary.simpleMessage(
      "Personal Information",
    ),
    "personalInformationSubtitle": MessageLookupByLibrary.simpleMessage(
      "Manage your personal details",
    ),
    "phoneCall": MessageLookupByLibrary.simpleMessage("Phone Call"),
    "phoneNumber": MessageLookupByLibrary.simpleMessage("Phone Number"),
    "phoneNumberIsRequired": MessageLookupByLibrary.simpleMessage(
      "Phone number is required",
    ),
    "pickupDateOptional": MessageLookupByLibrary.simpleMessage(
      "Pickup Date (Optional)",
    ),
    "platformForWholesaleTradeBetweenCompanies":
        MessageLookupByLibrary.simpleMessage(
          "Platform for wholesale trade between companies",
        ),
    "pleaseLoginToChatWithSupport": MessageLookupByLibrary.simpleMessage(
      "Please login to chat with support.",
    ),
    "pleaseLoginToConfirmYourOrder": MessageLookupByLibrary.simpleMessage(
      "Please login to confirm your order.",
    ),
    "pleaseLoginToContinue": MessageLookupByLibrary.simpleMessage(
      "Please login to continue.",
    ),
    "pleaseLoginToCreateAnOrder": MessageLookupByLibrary.simpleMessage(
      "Please login to create an order.",
    ),
    "pleaseLoginToManageYourCart": MessageLookupByLibrary.simpleMessage(
      "Please login to manage your cart.",
    ),
    "pleaseLoginToPublish": MessageLookupByLibrary.simpleMessage(
      "Please login to publish your ad.",
    ),
    "pleaseLoginToStartChat": MessageLookupByLibrary.simpleMessage(
      "Please login to start chat.",
    ),
    "pleaseLoginToUploadImages": MessageLookupByLibrary.simpleMessage(
      "Please login to upload images.",
    ),
    "pleaseLoginToUploadVideos": MessageLookupByLibrary.simpleMessage(
      "Please login to upload videos.",
    ),
    "pleaseLoginToViewYourAds": MessageLookupByLibrary.simpleMessage(
      "Please login to view your ads.",
    ),
    "pleaseLoginToViewYourCart": MessageLookupByLibrary.simpleMessage(
      "Please login to view your cart.",
    ),
    "pleaseLoginToViewYourOrders": MessageLookupByLibrary.simpleMessage(
      "Please login to view your orders.",
    ),
    "policyAndPrivacy": MessageLookupByLibrary.simpleMessage(
      "Policy and Privacy",
    ),
    "policyAndPrivacySubtitle": MessageLookupByLibrary.simpleMessage(
      "Read our policy and privacy",
    ),
    "portOfArrival": MessageLookupByLibrary.simpleMessage("Port of Arrival"),
    "postingDate": MessageLookupByLibrary.simpleMessage("Posting Date"),
    "poultry": MessageLookupByLibrary.simpleMessage("Poultry"),
    "premiumIranianSaffron": MessageLookupByLibrary.simpleMessage(
      "Premium Iranian Saffron",
    ),
    "premiumSaffron": MessageLookupByLibrary.simpleMessage("Premium Saffron"),
    "price": MessageLookupByLibrary.simpleMessage("Price"),
    "price20ftLabel": MessageLookupByLibrary.simpleMessage("Price 20ft"),
    "price40ftLabel": MessageLookupByLibrary.simpleMessage("Price 40ft"),
    "pricePerUnit": m22,
    "pricePerUnitGeneric": MessageLookupByLibrary.simpleMessage(
      "Price per unit",
    ),
    "pricePerUnitTimesQuantity": MessageLookupByLibrary.simpleMessage(
      "Price per unit × quantity",
    ),
    "product": MessageLookupByLibrary.simpleMessage("Product"),
    "productAddedToCart": MessageLookupByLibrary.simpleMessage(
      "Product added to cart.",
    ),
    "productCode": MessageLookupByLibrary.simpleMessage("Product code"),
    "productDetails": MessageLookupByLibrary.simpleMessage("Product Details"),
    "productDocuments": MessageLookupByLibrary.simpleMessage(
      "Product Documents",
    ),
    "productIdMissing": MessageLookupByLibrary.simpleMessage(
      "Product id is missing.",
    ),
    "productImages": MessageLookupByLibrary.simpleMessage("Product Images"),
    "productImagesConsent": MessageLookupByLibrary.simpleMessage(
      "By publishing an ad, the supplier grants the platform the right to use product images for these operational and training purposes.",
    ),
    "productImagesOwnership": MessageLookupByLibrary.simpleMessage(
      "Once you publish an ad in the app, the product images linked to that ad become owned by the app and the platform.",
    ),
    "productImagesSectionTitle": MessageLookupByLibrary.simpleMessage(
      "Product image ownership and use",
    ),
    "productImagesTraining": MessageLookupByLibrary.simpleMessage(
      "We use these images to train our image-search model so we can deliver more accurate visual search results, because correct and precise results always matter to us.",
    ),
    "productInformation": MessageLookupByLibrary.simpleMessage(
      "Product Information",
    ),
    "productName": MessageLookupByLibrary.simpleMessage("Product Name"),
    "productNotInCatalogNoted": MessageLookupByLibrary.simpleMessage(
      "We currently do not have this product, but your request was noted. Please try searching again in about an hour and we will try to stock it.",
    ),
    "productOwnerMissingCannotSubmitOrder":
        MessageLookupByLibrary.simpleMessage(
          "Product owner is missing. Cannot submit order.",
        ),
    "productPrice": MessageLookupByLibrary.simpleMessage("Product Price"),
    "productUnavailable": MessageLookupByLibrary.simpleMessage(
      "This ad is unavailable.",
    ),
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "prohibitedProducts": MessageLookupByLibrary.simpleMessage(
      "Products prohibited by law.",
    ),
    "publish": MessageLookupByLibrary.simpleMessage("Publish"),
    "publishPleaseWait": MessageLookupByLibrary.simpleMessage(
      "Please wait until publishing finishes. Do not close the app.",
    ),
    "publishProgressDone": MessageLookupByLibrary.simpleMessage("Done"),
    "publishProgressTitle": MessageLookupByLibrary.simpleMessage(
      "Publishing your ad",
    ),
    "publishRequest": MessageLookupByLibrary.simpleMessage("Publish Request"),
    "publishStepCreatingAd": MessageLookupByLibrary.simpleMessage(
      "Creating the ad",
    ),
    "publishStepFinishing": MessageLookupByLibrary.simpleMessage("Finishing…"),
    "publishStepPreparingImages": MessageLookupByLibrary.simpleMessage(
      "Preparing photos…",
    ),
    "publishStepPreparingVideo": m23,
    "publishStepUploadingDocuments": MessageLookupByLibrary.simpleMessage(
      "Uploading files…",
    ),
    "publishStepUploadingImages": MessageLookupByLibrary.simpleMessage(
      "Uploading photos…",
    ),
    "publishStepUploadingVideo": MessageLookupByLibrary.simpleMessage(
      "Uploading video…",
    ),
    "pulses": MessageLookupByLibrary.simpleMessage("Pulses"),
    "purchaseOrder": MessageLookupByLibrary.simpleMessage("Purchase Order"),
    "quantity": MessageLookupByLibrary.simpleMessage("Quantity"),
    "quantityExceedsRequired": m24,
    "quantityTypeManuallyHint": MessageLookupByLibrary.simpleMessage(
      "You can also type the quantity manually",
    ),
    "quickActions": MessageLookupByLibrary.simpleMessage("Quick Actions"),
    "reEnterNewPassword": MessageLookupByLibrary.simpleMessage(
      "Re-enter new password",
    ),
    "receiveOffers": MessageLookupByLibrary.simpleMessage("Receive Offers"),
    "received": MessageLookupByLibrary.simpleMessage("Received"),
    "receivedOffers": MessageLookupByLibrary.simpleMessage("Received Offers"),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "registerClient": MessageLookupByLibrary.simpleMessage("Customer Sign-up"),
    "registerClientSubtitle": MessageLookupByLibrary.simpleMessage(
      "Browse and order easily",
    ),
    "registerSupplier": MessageLookupByLibrary.simpleMessage(
      "Supplier Sign-up",
    ),
    "registerSupplierSubtitle": MessageLookupByLibrary.simpleMessage(
      "List your products and reach customers",
    ),
    "rejectOffer": MessageLookupByLibrary.simpleMessage("Reject"),
    "rejectOfferAction": MessageLookupByLibrary.simpleMessage("Reject Offer"),
    "rejectOrderAction": MessageLookupByLibrary.simpleMessage("Reject order"),
    "rejectedAds": MessageLookupByLibrary.simpleMessage("Rejected ads"),
    "rejectionReason": MessageLookupByLibrary.simpleMessage("Rejection reason"),
    "requestCardSampleDescription": MessageLookupByLibrary.simpleMessage(
      "Looking for premium authentic Iranian saffron for import",
    ),
    "requestFulfillment": MessageLookupByLibrary.simpleMessage("Price Type"),
    "requestFulfillmentBooking": MessageLookupByLibrary.simpleMessage(
      "Booking",
    ),
    "requestFulfillmentLocal": MessageLookupByLibrary.simpleMessage("Local"),
    "requestFulfillmentReexport": MessageLookupByLibrary.simpleMessage(
      "Rexport",
    ),
    "requestOwnerMissingCannotSubmitOffer":
        MessageLookupByLibrary.simpleMessage(
          "Request owner is missing. Cannot submit offer.",
        ),
    "requestPublishedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Request published successfully.",
    ),
    "requestedQuantity": MessageLookupByLibrary.simpleMessage(
      "Requested Quantity",
    ),
    "requestedQuantityExceedsAvailable": m25,
    "requestedReceiptDate": MessageLookupByLibrary.simpleMessage(
      "Requested Receipt Date",
    ),
    "requests": MessageLookupByLibrary.simpleMessage("Requests"),
    "requiredDeliveryDate": MessageLookupByLibrary.simpleMessage(
      "Required Delivery Date",
    ),
    "requiredQuantity": MessageLookupByLibrary.simpleMessage(
      "Required Quantity",
    ),
    "requiredSpecifications": MessageLookupByLibrary.simpleMessage(
      "Required Specifications",
    ),
    "resendCode": MessageLookupByLibrary.simpleMessage("Resend code"),
    "restartApplication": MessageLookupByLibrary.simpleMessage(
      "Restart Application",
    ),
    "restriction1": MessageLookupByLibrary.simpleMessage(
      "Publishing or requesting any products banned by UAE law or any country involved.",
    ),
    "restriction2": MessageLookupByLibrary.simpleMessage(
      "Offering non-original or counterfeit products.",
    ),
    "restriction3": MessageLookupByLibrary.simpleMessage(
      "Manipulating prices, quantities, or product information.",
    ),
    "restriction4": MessageLookupByLibrary.simpleMessage(
      "Using the app for direct communication outside the platform to complete deals outside the app.",
    ),
    "restrictionsHeader": MessageLookupByLibrary.simpleMessage(
      "Strictly prohibited:",
    ),
    "retail": MessageLookupByLibrary.simpleMessage("Retail"),
    "retailPriceLabel": MessageLookupByLibrary.simpleMessage("Retail price"),
    "retailPricingInfoBody": MessageLookupByLibrary.simpleMessage(
      "If you add a retail price, this product will appear in its category with the wholesale price, and also in Retail with a separate retail price, unit, and quantity. Buyers can place orders from either channel. Make sure retail rates and fields are valid.",
    ),
    "retailPricingInfoTitle": MessageLookupByLibrary.simpleMessage(
      "Retail pricing",
    ),
    "retailVisaPaymentHint": MessageLookupByLibrary.simpleMessage(
      "Online card payment is available for retail orders only.",
    ),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "returnOrder": MessageLookupByLibrary.simpleMessage("Return Order"),
    "returnOrderConfirmMessage": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to return this order?",
    ),
    "returnOrderConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Return this order?",
    ),
    "returnPolicyAccepted": MessageLookupByLibrary.simpleMessage(
      "Usually accepted: damaged/spoiled goods, expired goods inconsistent with the listing, materially different product, or clear quantity shortage.",
    ),
    "returnPolicyPayout": MessageLookupByLibrary.simpleMessage(
      "Approved supplier earnings transfers are completed within 7 business days per platform process.",
    ),
    "returnPolicyRefund": MessageLookupByLibrary.simpleMessage(
      "If support approves the return, funds are refunded within 1 business day of approval, and the supplier balance is deducted if it was credited from the same order.",
    ),
    "returnPolicyRejected": MessageLookupByLibrary.simpleMessage(
      "Usually not accepted: change of mind without defect, poor storage after delivery, or consuming most of the quantity then requesting a return without a proven defect.",
    ),
    "returnPolicySectionTitle": MessageLookupByLibrary.simpleMessage(
      "Returns and refunds policy",
    ),
    "returnPolicyWindow": MessageLookupByLibrary.simpleMessage(
      "Return requests must be reported within 24 business hours of confirmed receipt, with photos/video showing the issue.",
    ),
    "returnsFilter": MessageLookupByLibrary.simpleMessage("Returns"),
    "rice": MessageLookupByLibrary.simpleMessage("Rice"),
    "saturdayThursday": MessageLookupByLibrary.simpleMessage(
      "Saturday - Thursday:",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Save changes"),
    "savePassword": MessageLookupByLibrary.simpleMessage("Save Password"),
    "savedAddresses": MessageLookupByLibrary.simpleMessage("Saved Addresses"),
    "savedAddressesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Manage your saved addresses",
    ),
    "savedAds": MessageLookupByLibrary.simpleMessage("Saved Ads"),
    "savedAdsSubtitle": MessageLookupByLibrary.simpleMessage(
      "View your saved advertisements",
    ),
    "savedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Saved successfully",
    ),
    "searchAgain": MessageLookupByLibrary.simpleMessage("Search again with AI"),
    "searchByImage": MessageLookupByLibrary.simpleMessage("Search by image"),
    "searchForProducts": MessageLookupByLibrary.simpleMessage(
      "Search for products",
    ),
    "searchHistory": MessageLookupByLibrary.simpleMessage("Search history"),
    "searchHistoryEmpty": MessageLookupByLibrary.simpleMessage(
      "Your recent searches will appear here.",
    ),
    "searchHistoryNotFound": MessageLookupByLibrary.simpleMessage(
      "Saved search results are no longer available.",
    ),
    "searchOrTypeCity": MessageLookupByLibrary.simpleMessage(
      "Search or type your city",
    ),
    "searchResults": MessageLookupByLibrary.simpleMessage("Search Results"),
    "secondNature": MessageLookupByLibrary.simpleMessage(
      "Second: Nature of the App\'s Work",
    ),
    "selectAnOption": MessageLookupByLibrary.simpleMessage("Select an option"),
    "selectCategory": MessageLookupByLibrary.simpleMessage("Select Category"),
    "selectCountryFirst": MessageLookupByLibrary.simpleMessage(
      "Select a country first",
    ),
    "selectCurrency": MessageLookupByLibrary.simpleMessage(
      "Please select a currency.",
    ),
    "selectDeliveryAddress": MessageLookupByLibrary.simpleMessage(
      "Please select a delivery address.",
    ),
    "selectDeliveryEmirate": MessageLookupByLibrary.simpleMessage(
      "Select delivery emirate",
    ),
    "selectPort": MessageLookupByLibrary.simpleMessage("Select port"),
    "selectRequestFulfillment": MessageLookupByLibrary.simpleMessage(
      "Select local or rexport",
    ),
    "selectedDocuments": m26,
    "selectedMedia": m27,
    "selection": MessageLookupByLibrary.simpleMessage("Selection"),
    "selfPickup": MessageLookupByLibrary.simpleMessage("Self Pickup"),
    "selfPickupHint": MessageLookupByLibrary.simpleMessage(
      "Pick up from our store",
    ),
    "sendEmail": MessageLookupByLibrary.simpleMessage("Send Email"),
    "sendPurchaseOrder": MessageLookupByLibrary.simpleMessage(
      "Send Purchase Order",
    ),
    "sensitiveAccessBalanceWarningBody": MessageLookupByLibrary.simpleMessage(
      "Opening Balance shows your deposits and lets you add IBANs or request withdrawals. Verify your identity before continuing.",
    ),
    "sensitiveAccessBalanceWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Balance access",
    ),
    "sensitiveAccessBiometricReason": MessageLookupByLibrary.simpleMessage(
      "Verify it’s you to open this page",
    ),
    "sensitiveAccessContinue": MessageLookupByLibrary.simpleMessage("Continue"),
    "sensitiveAccessPasswordHint": MessageLookupByLibrary.simpleMessage(
      "Enter your password to continue",
    ),
    "sensitiveAccessPasswordRequired": MessageLookupByLibrary.simpleMessage(
      "This account has no password. Enable Face ID / Fingerprint in Profile, or set a password from Change Password, then try again.",
    ),
    "sensitiveAccessVerifyFailed": MessageLookupByLibrary.simpleMessage(
      "Verification failed. Please try again.",
    ),
    "sensitiveAccessVerifyTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm it’s you",
    ),
    "sensitiveAccessWarningBody": MessageLookupByLibrary.simpleMessage(
      "Alras Smart is an AI agent that can control important account actions such as creating withdrawal requests, changing prices, and deleting ads. Security verification is required. Thank you for your patience.",
    ),
    "sensitiveAccessWarningTitle": MessageLookupByLibrary.simpleMessage(
      "Security check",
    ),
    "setPassword": MessageLookupByLibrary.simpleMessage("Set Password"),
    "setPasswordSocialHint": MessageLookupByLibrary.simpleMessage(
      "You signed in with Google or Apple, so there is no current password. Choose a password to also sign in with your email.",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "seventhLiability": MessageLookupByLibrary.simpleMessage(
      "Seventh: Legal Responsibility",
    ),
    "shareProduct": MessageLookupByLibrary.simpleMessage("Share product"),
    "shareProductHint": MessageLookupByLibrary.simpleMessage(
      "Find this product on Al Ras Market.",
    ),
    "shareProductSearchHint": MessageLookupByLibrary.simpleMessage(
      "Search for this code in the app to open the product.",
    ),
    "shippedBySupplier": MessageLookupByLibrary.simpleMessage(
      "Shipped by supplier",
    ),
    "shipping": MessageLookupByLibrary.simpleMessage("Shipping"),
    "shippingCompany": MessageLookupByLibrary.simpleMessage("Shipping Company"),
    "shippingCompanyAccount": MessageLookupByLibrary.simpleMessage(
      "Shipping Company Account",
    ),
    "shippingCompanyDashboard": MessageLookupByLibrary.simpleMessage(
      "Shipping Dashboard",
    ),
    "shippingCompanyLogin": MessageLookupByLibrary.simpleMessage(
      "Shipping Company Login",
    ),
    "shippingCompanyLoginSubtitle": MessageLookupByLibrary.simpleMessage(
      "Sign in to manage your shipping offers and requests",
    ),
    "shippingCompanyName": MessageLookupByLibrary.simpleMessage(
      "Shipping Company Name",
    ),
    "shippingCompanyRegister": MessageLookupByLibrary.simpleMessage(
      "Create Shipping Company Account",
    ),
    "shippingCompanyRegisterSubtitle": MessageLookupByLibrary.simpleMessage(
      "Register your shipping company on Al Ras Market",
    ),
    "shippingCompanySubtitle": MessageLookupByLibrary.simpleMessage(
      "Reliable and fast shipping solutions",
    ),
    "shippingDetails": MessageLookupByLibrary.simpleMessage("Shipping Details"),
    "shippingDurationDays": MessageLookupByLibrary.simpleMessage(
      "Shipping Duration (days)",
    ),
    "shippingInformation": MessageLookupByLibrary.simpleMessage(
      "Shipping Information",
    ),
    "shippingOffersSection": MessageLookupByLibrary.simpleMessage(
      "Shipping offers",
    ),
    "shippingPrice": MessageLookupByLibrary.simpleMessage("Shipping \n Price"),
    "shippingProfileReviewNote": MessageLookupByLibrary.simpleMessage(
      "Please ensure the entered data is correct. Any changes to shipping company data will be reviewed before approval.",
    ),
    "shippingTimeRange": m28,
    "showAll": MessageLookupByLibrary.simpleMessage("Show All"),
    "showAllRequests": MessageLookupByLibrary.simpleMessage(
      "Show all requests",
    ),
    "showNumber": MessageLookupByLibrary.simpleMessage("Show number"),
    "signInToContinue": MessageLookupByLibrary.simpleMessage(
      "Sign in to continue",
    ),
    "signInWithApple": MessageLookupByLibrary.simpleMessage(
      "Sign in with Apple",
    ),
    "signInWithBiometrics": MessageLookupByLibrary.simpleMessage(
      "Sign in with fingerprint or face",
    ),
    "signInWithGoogle": MessageLookupByLibrary.simpleMessage(
      "Sign in with Google",
    ),
    "signUp": MessageLookupByLibrary.simpleMessage("Sign Up"),
    "similarAds": MessageLookupByLibrary.simpleMessage("Similar ads"),
    "sinceHoursAgo": m29,
    "sinceMinutesAgo": m30,
    "sixthRestrictions": MessageLookupByLibrary.simpleMessage(
      "Sixth: Restrictions and Prohibitions",
    ),
    "skip": MessageLookupByLibrary.simpleMessage("Skip"),
    "skipLogin": MessageLookupByLibrary.simpleMessage("Skip Login"),
    "smartAlRasAppFull": MessageLookupByLibrary.simpleMessage(
      "Al Ras Smart App",
    ),
    "smartAlRasBrand": MessageLookupByLibrary.simpleMessage("Al Ras Smart"),
    "soldOut": MessageLookupByLibrary.simpleMessage("Sold out"),
    "specifications": MessageLookupByLibrary.simpleMessage("Specifications"),
    "specifyQuantity": MessageLookupByLibrary.simpleMessage("Require quantity"),
    "specifyRequiredSpecifications": MessageLookupByLibrary.simpleMessage(
      "Specify required specifications",
    ),
    "spices": MessageLookupByLibrary.simpleMessage("Spices"),
    "startChat": MessageLookupByLibrary.simpleMessage("Start Chat"),
    "subjectToReconfirm": MessageLookupByLibrary.simpleMessage(
      "Subject to reconfirm",
    ),
    "submitOffer": MessageLookupByLibrary.simpleMessage("Submit Offer"),
    "sugar": MessageLookupByLibrary.simpleMessage("Sugar"),
    "suggestedNames": MessageLookupByLibrary.simpleMessage("Suggested names"),
    "supplierAccount": MessageLookupByLibrary.simpleMessage("Supplier Account"),
    "supplierCollectionPolicy": MessageLookupByLibrary.simpleMessage(
      "A supplier handing goods to the Al Ras Market app or team does not trigger immediate payment. Supplier funds are released only after the order value is actually collected from the buyer/customer. After collection, approved earnings are transferred within 7 business days.",
    ),
    "supplierCommitmentHeader": MessageLookupByLibrary.simpleMessage(
      "The supplier commits not to display or sell:",
    ),
    "supplierIdentifyingInfo": MessageLookupByLibrary.simpleMessage(
      "Publishing any supplier-identifying information within product images or descriptions (e.g., name, phone number, address, email) is prohibited.",
    ),
    "supplierLiabilityHeader": MessageLookupByLibrary.simpleMessage(
      "The supplier bears full responsibility for products regarding:",
    ),
    "supplierNotes": MessageLookupByLibrary.simpleMessage("Supplier Notes"),
    "supplierObligation1": MessageLookupByLibrary.simpleMessage(
      "The supplier guarantees the accuracy and validity of their company data and contact methods, and that the commercial license is valid.",
    ),
    "supplierObligation2": MessageLookupByLibrary.simpleMessage(
      "The supplier must ensure all displayed products are available, under their full control, and ready for immediate sale.",
    ),
    "supplierObligation3": MessageLookupByLibrary.simpleMessage(
      "Displaying products not in stock or unavailable after order confirmation is prohibited.",
    ),
    "supplierObligation4": MessageLookupByLibrary.simpleMessage(
      "The supplier must continuously update available quantities in the app.",
    ),
    "supplierObligation5": MessageLookupByLibrary.simpleMessage(
      "If a product is sold out, it must be immediately removed from the app.",
    ),
    "supplierObligation6": MessageLookupByLibrary.simpleMessage(
      "The supplier bears full responsibility for product quality, quantity, weight, and packaging until delivery.",
    ),
    "suppliersApplied": MessageLookupByLibrary.simpleMessage(
      "suppliers applied",
    ),
    "sweets": MessageLookupByLibrary.simpleMessage("Sweets"),
    "takePhoto": MessageLookupByLibrary.simpleMessage("Take photo"),
    "takePhotoHint": MessageLookupByLibrary.simpleMessage(
      "Use the camera to capture the product",
    ),
    "tapToUploadImageOrFile": MessageLookupByLibrary.simpleMessage(
      "Tap to upload image or file",
    ),
    "tapToUploadImageOrVideo": MessageLookupByLibrary.simpleMessage(
      "Tap to upload image or video",
    ),
    "targetPrice": MessageLookupByLibrary.simpleMessage("Target Price"),
    "targetPricePerUnit": m31,
    "targetPricePerUnitGeneric": MessageLookupByLibrary.simpleMessage(
      "Target price per unit",
    ),
    "taxNumber": MessageLookupByLibrary.simpleMessage("Tax Number"),
    "tenthAcceptance": MessageLookupByLibrary.simpleMessage(
      "Tenth: Acceptance",
    ),
    "termsTitle": MessageLookupByLibrary.simpleMessage(
      "Terms of Use and Conditions for the \"Souq Al Ras\" App",
    ),
    "theSupportTeamIsAlwaysHereToAssistYou":
        MessageLookupByLibrary.simpleMessage(
          "The support team is always here to assist you.",
        ),
    "thirdSupplierObligations": MessageLookupByLibrary.simpleMessage(
      "Third: Supplier Obligations",
    ),
    "thisFieldIsRequired": MessageLookupByLibrary.simpleMessage(
      "This field is required",
    ),
    "toDay": MessageLookupByLibrary.simpleMessage("To day"),
    "toLabel": MessageLookupByLibrary.simpleMessage("To"),
    "todayShipping": MessageLookupByLibrary.simpleMessage("Today\'s Shipping"),
    "topDiscount": MessageLookupByLibrary.simpleMessage("Top Discount"),
    "total": MessageLookupByLibrary.simpleMessage("Total"),
    "trackOrder": MessageLookupByLibrary.simpleMessage("Track Order"),
    "trackYourOrder": MessageLookupByLibrary.simpleMessage("Track your order:"),
    "tradeLicenseNumber": MessageLookupByLibrary.simpleMessage(
      "Trade License Number",
    ),
    "tradeLicenseNumberIsRequired": MessageLookupByLibrary.simpleMessage(
      "Trade license number is required",
    ),
    "tradeLicenseSelected": MessageLookupByLibrary.simpleMessage(
      "Trade license selected",
    ),
    "underReview": MessageLookupByLibrary.simpleMessage("Under Review"),
    "underReviewAds": MessageLookupByLibrary.simpleMessage("Under review"),
    "unitBag": MessageLookupByLibrary.simpleMessage("Bag"),
    "unitBox": MessageLookupByLibrary.simpleMessage("Box"),
    "unitBoxes": MessageLookupByLibrary.simpleMessage("Boxes"),
    "unitCarton": MessageLookupByLibrary.simpleMessage("Carton"),
    "unitDozen": MessageLookupByLibrary.simpleMessage("Dozen"),
    "unitDozens": MessageLookupByLibrary.simpleMessage("Dozens"),
    "unitGram": MessageLookupByLibrary.simpleMessage("Gram"),
    "unitGrams": MessageLookupByLibrary.simpleMessage("Grams"),
    "unitKg": MessageLookupByLibrary.simpleMessage("Kg"),
    "unitKilograms": MessageLookupByLibrary.simpleMessage("Kg"),
    "unitLabel": MessageLookupByLibrary.simpleMessage("Unit"),
    "unitLiter": MessageLookupByLibrary.simpleMessage("Liter"),
    "unitLiters": MessageLookupByLibrary.simpleMessage("Liters"),
    "unitPiece": MessageLookupByLibrary.simpleMessage("Piece"),
    "unitPieces": MessageLookupByLibrary.simpleMessage("Pieces"),
    "unitTon": MessageLookupByLibrary.simpleMessage("Ton"),
    "unitTons": MessageLookupByLibrary.simpleMessage("Tons"),
    "unlockWithBiometrics": MessageLookupByLibrary.simpleMessage(
      "Unlock with biometrics",
    ),
    "unlockWithFaceId": MessageLookupByLibrary.simpleMessage(
      "Unlock with Face ID",
    ),
    "unlockWithFingerprint": MessageLookupByLibrary.simpleMessage(
      "Unlock with fingerprint",
    ),
    "unmuteVideo": MessageLookupByLibrary.simpleMessage("Unmute"),
    "uploadCompanySiteImages": MessageLookupByLibrary.simpleMessage(
      "Upload Company Site Images",
    ),
    "uploadProfilePhoto": MessageLookupByLibrary.simpleMessage(
      "Upload profile photo",
    ),
    "uploadTradeLicense": MessageLookupByLibrary.simpleMessage(
      "Upload Trade License",
    ),
    "vatFivePercent": MessageLookupByLibrary.simpleMessage("VAT (5%)"),
    "video": MessageLookupByLibrary.simpleMessage("Video"),
    "videoCompressFailed": m32,
    "videoCompressedToMb": m33,
    "videoDurationUnreadable": MessageLookupByLibrary.simpleMessage(
      "Could not read video duration. Please try another file.",
    ),
    "videoFileNotFound": MessageLookupByLibrary.simpleMessage(
      "Video file not found. Please try again.",
    ),
    "videoMaxDurationSeconds": MessageLookupByLibrary.simpleMessage(
      "Video must be 3 minutes (180 seconds) or less.",
    ),
    "videoPlaybackFailed": MessageLookupByLibrary.simpleMessage(
      "Could not play video",
    ),
    "videoSelectedFromGallery": MessageLookupByLibrary.simpleMessage(
      "Video selected from gallery",
    ),
    "videoSizeExceeded": m34,
    "viewAll": MessageLookupByLibrary.simpleMessage("View All"),
    "viewDetails": MessageLookupByLibrary.simpleMessage("View Details"),
    "viewOffers": MessageLookupByLibrary.simpleMessage("View Offers"),
    "website": MessageLookupByLibrary.simpleMessage("Website"),
    "websiteHint": MessageLookupByLibrary.simpleMessage("https://"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("Welcome"),
    "welcomeShippingCompany": MessageLookupByLibrary.simpleMessage(
      "Welcome to your shipping company dashboard",
    ),
    "welcomeShippingDashboard": MessageLookupByLibrary.simpleMessage(
      "Welcome to your shipping company control panel",
    ),
    "welcomeTagline": MessageLookupByLibrary.simpleMessage(
      "A smart platform connecting suppliers and buyers inside and outside Al Ras market",
    ),
    "welcomeTo": MessageLookupByLibrary.simpleMessage("Welcome to"),
    "whatPaymentMethodsAreAvailable": MessageLookupByLibrary.simpleMessage(
      "What payment methods are available?",
    ),
    "whatPaymentMethodsAreAvailableAnswer": MessageLookupByLibrary.simpleMessage(
      "You can pay online with Visa or Mastercard, or choose Cash on Delivery when available at checkout.",
    ),
    "wholeBlackPepper": MessageLookupByLibrary.simpleMessage(
      "Whole Black Pepper",
    ),
    "wholesalePrice": MessageLookupByLibrary.simpleMessage("Wholesale price"),
    "workingHours": MessageLookupByLibrary.simpleMessage("Working Hours"),
    "yourAccountIsUnderReviewWeWillNotifyYouOnceItIsApproved":
        MessageLookupByLibrary.simpleMessage(
          "Your account is under review. We will notify you once it is approved.",
        ),
    "yourCart": MessageLookupByLibrary.simpleMessage("Your Cart"),
    "yourCartIsEmpty": MessageLookupByLibrary.simpleMessage(
      "Your cart is empty.",
    ),
    "yourOffer": MessageLookupByLibrary.simpleMessage("Your Offer"),
    "yourOfferWillBeSentToTheRequesterWhoCanReviewAndRespond":
        MessageLookupByLibrary.simpleMessage(
          "Your offer will be sent to the requester who can review and respond",
        ),
    "yourRequestWillBePublishedAndApprovedSuppliersCanSubmitTheirOffersYouWillReceiveANotificationWhenOffersArrive":
        MessageLookupByLibrary.simpleMessage(
          "Your request will be published and approved suppliers can submit their offers. You will receive a notification when offers arrive.",
        ),
  };
}
