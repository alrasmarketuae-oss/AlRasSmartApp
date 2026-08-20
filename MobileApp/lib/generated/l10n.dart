// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Ecovera`
  String get appName {
    return Intl.message('Ecovera', name: 'appName', desc: '', args: []);
  }

  /// `English`
  String get language {
    return Intl.message('English', name: 'language', desc: '', args: []);
  }

  /// `Google Account`
  String get googleAccount {
    return Intl.message(
      'Google Account',
      name: 'googleAccount',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `Sign Up`
  String get signUp {
    return Intl.message('Sign Up', name: 'signUp', desc: '', args: []);
  }

  /// `Don't have an account?`
  String get dontHaveAnAccount {
    return Intl.message(
      'Don\'t have an account?',
      name: 'dontHaveAnAccount',
      desc: '',
      args: [],
    );
  }

  /// `Already have an account?`
  String get alreadyHaveAnAccount {
    return Intl.message(
      'Already have an account?',
      name: 'alreadyHaveAnAccount',
      desc: '',
      args: [],
    );
  }

  /// `Or`
  String get or {
    return Intl.message('Or', name: 'or', desc: '', args: []);
  }

  /// `Skip Login`
  String get skipLogin {
    return Intl.message('Skip Login', name: 'skipLogin', desc: '', args: []);
  }

  /// `Login successful`
  String get loginSuccess {
    return Intl.message(
      'Login successful',
      name: 'loginSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Login failed`
  String get loginError {
    return Intl.message('Login failed', name: 'loginError', desc: '', args: []);
  }

  /// `This field is required`
  String get thisFieldIsRequired {
    return Intl.message(
      'This field is required',
      name: 'thisFieldIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Continue with Google`
  String get continueWithGoogle {
    return Intl.message(
      'Continue with Google',
      name: 'continueWithGoogle',
      desc: '',
      args: [],
    );
  }

  /// `Continue with Facebook`
  String get continueWithFacebook {
    return Intl.message(
      'Continue with Facebook',
      name: 'continueWithFacebook',
      desc: '',
      args: [],
    );
  }

  /// `Continue with Apple`
  String get continueWithApple {
    return Intl.message(
      'Continue with Apple',
      name: 'continueWithApple',
      desc: '',
      args: [],
    );
  }

  /// `Unlock with Face ID`
  String get unlockWithFaceId {
    return Intl.message(
      'Unlock with Face ID',
      name: 'unlockWithFaceId',
      desc: '',
      args: [],
    );
  }

  /// `Unlock with fingerprint`
  String get unlockWithFingerprint {
    return Intl.message(
      'Unlock with fingerprint',
      name: 'unlockWithFingerprint',
      desc: '',
      args: [],
    );
  }

  /// `Unlock with biometrics`
  String get unlockWithBiometrics {
    return Intl.message(
      'Unlock with biometrics',
      name: 'unlockWithBiometrics',
      desc: '',
      args: [],
    );
  }

  /// `Welcome`
  String get welcomeBack {
    return Intl.message('Welcome', name: 'welcomeBack', desc: '', args: []);
  }

  /// `Sign in to continue`
  String get signInToContinue {
    return Intl.message(
      'Sign in to continue',
      name: 'signInToContinue',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Google`
  String get signInWithGoogle {
    return Intl.message(
      'Sign in with Google',
      name: 'signInWithGoogle',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Apple`
  String get signInWithApple {
    return Intl.message(
      'Sign in with Apple',
      name: 'signInWithApple',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with fingerprint or face`
  String get signInWithBiometrics {
    return Intl.message(
      'Sign in with fingerprint or face',
      name: 'signInWithBiometrics',
      desc: '',
      args: [],
    );
  }

  /// `Face ID / Fingerprint`
  String get enableBiometricUnlock {
    return Intl.message(
      'Face ID / Fingerprint',
      name: 'enableBiometricUnlock',
      desc: '',
      args: [],
    );
  }

  /// `Sign back in quickly after logout using Face ID or fingerprint. Only for this saved account.`
  String get biometricUnlockSubtitle {
    return Intl.message(
      'Sign back in quickly after logout using Face ID or fingerprint. Only for this saved account.',
      name: 'biometricUnlockSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Confirm it is you to continue`
  String get biometricAuthReason {
    return Intl.message(
      'Confirm it is you to continue',
      name: 'biometricAuthReason',
      desc: '',
      args: [],
    );
  }

  /// `Confirm it is you to enable biometric unlock`
  String get biometricEnableReason {
    return Intl.message(
      'Confirm it is you to enable biometric unlock',
      name: 'biometricEnableReason',
      desc: '',
      args: [],
    );
  }

  /// `Biometrics are not available on this device`
  String get biometricNotAvailable {
    return Intl.message(
      'Biometrics are not available on this device',
      name: 'biometricNotAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Set up Face ID or a fingerprint in device settings first`
  String get biometricNoEnrolled {
    return Intl.message(
      'Set up Face ID or a fingerprint in device settings first',
      name: 'biometricNoEnrolled',
      desc: '',
      args: [],
    );
  }

  /// `Biometric unlock enabled`
  String get biometricEnabledSuccess {
    return Intl.message(
      'Biometric unlock enabled',
      name: 'biometricEnabledSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Biometric unlock disabled`
  String get biometricDisabledSuccess {
    return Intl.message(
      'Biometric unlock disabled',
      name: 'biometricDisabledSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Biometric unlock failed. Please sign in normally.`
  String get biometricUnlockFailed {
    return Intl.message(
      'Biometric unlock failed. Please sign in normally.',
      name: 'biometricUnlockFailed',
      desc: '',
      args: [],
    );
  }

  /// `Forgot password?`
  String get forgotPassword {
    return Intl.message(
      'Forgot password?',
      name: 'forgotPassword',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email`
  String get enterYourEmail {
    return Intl.message(
      'Enter your email',
      name: 'enterYourEmail',
      desc: '',
      args: [],
    );
  }

  /// `Enter your password`
  String get enterYourPassword {
    return Intl.message(
      'Enter your password',
      name: 'enterYourPassword',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Phone Number`
  String get phoneNumber {
    return Intl.message(
      'Phone Number',
      name: 'phoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Country Code`
  String get countryCode {
    return Intl.message(
      'Country Code',
      name: 'countryCode',
      desc: '',
      args: [],
    );
  }

  /// `Other Phone (optional)`
  String get otherPhone {
    return Intl.message(
      'Other Phone (optional)',
      name: 'otherPhone',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email`
  String get invalidEmail {
    return Intl.message(
      'Invalid email',
      name: 'invalidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Password must be at least 6 characters`
  String get passwordMustBeAtLeast6Characters {
    return Intl.message(
      'Password must be at least 6 characters',
      name: 'passwordMustBeAtLeast6Characters',
      desc: '',
      args: [],
    );
  }

  /// `Next`
  String get next {
    return Intl.message('Next', name: 'next', desc: '', args: []);
  }

  /// `Create Account`
  String get createAccount {
    return Intl.message(
      'Create Account',
      name: 'createAccount',
      desc: '',
      args: [],
    );
  }

  /// `Account created successfully`
  String get accountCreatedSuccessfully {
    return Intl.message(
      'Account created successfully',
      name: 'accountCreatedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Account creation failed`
  String get accountCreationFailed {
    return Intl.message(
      'Account creation failed',
      name: 'accountCreationFailed',
      desc: '',
      args: [],
    );
  }

  /// `Company Name`
  String get companyName {
    return Intl.message(
      'Company Name',
      name: 'companyName',
      desc: '',
      args: [],
    );
  }

  /// `Enter company name`
  String get enterCompanyName {
    return Intl.message(
      'Enter company name',
      name: 'enterCompanyName',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message('Address', name: 'address', desc: '', args: []);
  }

  /// `Enter address`
  String get enterAddress {
    return Intl.message(
      'Enter address',
      name: 'enterAddress',
      desc: '',
      args: [],
    );
  }

  /// `Trade License Number`
  String get tradeLicenseNumber {
    return Intl.message(
      'Trade License Number',
      name: 'tradeLicenseNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter trade license number`
  String get enterTradeLicenseNumber {
    return Intl.message(
      'Enter trade license number',
      name: 'enterTradeLicenseNumber',
      desc: '',
      args: [],
    );
  }

  /// `No account?`
  String get noAccount {
    return Intl.message('No account?', name: 'noAccount', desc: '', args: []);
  }

  /// ` (optional)`
  String get optional {
    return Intl.message(' (optional)', name: 'optional', desc: '', args: []);
  }

  /// `Landline Number`
  String get landlinePhone {
    return Intl.message(
      'Landline Number',
      name: 'landlinePhone',
      desc: '',
      args: [],
    );
  }

  /// `Skip`
  String get skip {
    return Intl.message('Skip', name: 'skip', desc: '', args: []);
  }

  /// `Confirm`
  String get confirm {
    return Intl.message('Confirm', name: 'confirm', desc: '', args: []);
  }

  /// `Upload Trade License`
  String get uploadTradeLicense {
    return Intl.message(
      'Upload Trade License',
      name: 'uploadTradeLicense',
      desc: '',
      args: [],
    );
  }

  /// `Upload Company Site Images`
  String get uploadCompanySiteImages {
    return Intl.message(
      'Upload Company Site Images',
      name: 'uploadCompanySiteImages',
      desc: '',
      args: [],
    );
  }

  /// `Drag, drop, or tap to upload`
  String get dragDropOrTapToUpload {
    return Intl.message(
      'Drag, drop, or tap to upload',
      name: 'dragDropOrTapToUpload',
      desc: '',
      args: [],
    );
  }

  /// `Trade license selected`
  String get tradeLicenseSelected {
    return Intl.message(
      'Trade license selected',
      name: 'tradeLicenseSelected',
      desc: '',
      args: [],
    );
  }

  /// `Company site image selected`
  String get companySiteImageSelected {
    return Intl.message(
      'Company site image selected',
      name: 'companySiteImageSelected',
      desc: '',
      args: [],
    );
  }

  /// `PDF, JPG, PNG max 10MB`
  String get pdfJpgPngMax10Mb {
    return Intl.message(
      'PDF, JPG, PNG max 10MB',
      name: 'pdfJpgPngMax10Mb',
      desc: '',
      args: [],
    );
  }

  /// `OTP Code`
  String get otpCode {
    return Intl.message('OTP Code', name: 'otpCode', desc: '', args: []);
  }

  /// `Count`
  String get countdown {
    return Intl.message('Count', name: 'countdown', desc: '', args: []);
  }

  /// `Resend code`
  String get resendCode {
    return Intl.message('Resend code', name: 'resendCode', desc: '', args: []);
  }

  /// `Code valid for 10 minutes`
  String get codeValidFor10Minutes {
    return Intl.message(
      'Code valid for 10 minutes',
      name: 'codeValidFor10Minutes',
      desc: '',
      args: [],
    );
  }

  /// `Under Review`
  String get underReview {
    return Intl.message(
      'Under Review',
      name: 'underReview',
      desc: '',
      args: [],
    );
  }

  /// `Rejection reason`
  String get rejectionReason {
    return Intl.message(
      'Rejection reason',
      name: 'rejectionReason',
      desc: '',
      args: [],
    );
  }

  /// `{count} views`
  String adViewsCount(int count) {
    return Intl.message(
      '$count views',
      name: 'adViewsCount',
      desc: '',
      args: [count],
    );
  }

  /// `Your account is under review. We will notify you once it is approved.`
  String get yourAccountIsUnderReviewWeWillNotifyYouOnceItIsApproved {
    return Intl.message(
      'Your account is under review. We will notify you once it is approved.',
      name: 'yourAccountIsUnderReviewWeWillNotifyYouOnceItIsApproved',
      desc: '',
      args: [],
    );
  }

  /// `Contact Support`
  String get contactSupport {
    return Intl.message(
      'Contact Support',
      name: 'contactSupport',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to`
  String get welcomeTo {
    return Intl.message('Welcome to', name: 'welcomeTo', desc: '', args: []);
  }

  /// `Al Ras Smart App`
  String get alRasMarket {
    return Intl.message(
      'Al Ras Smart App',
      name: 'alRasMarket',
      desc: '',
      args: [],
    );
  }

  /// `Al Ras Smart`
  String get smartAlRasBrand {
    return Intl.message(
      'Al Ras Smart',
      name: 'smartAlRasBrand',
      desc: '',
      args: [],
    );
  }

  /// `Al Ras Smart App`
  String get smartAlRasAppFull {
    return Intl.message(
      'Al Ras Smart App',
      name: 'smartAlRasAppFull',
      desc: '',
      args: [],
    );
  }

  /// `App`
  String get appWord {
    return Intl.message('App', name: 'appWord', desc: '', args: []);
  }

  /// `Platform for wholesale trade between companies`
  String get platformForWholesaleTradeBetweenCompanies {
    return Intl.message(
      'Platform for wholesale trade between companies',
      name: 'platformForWholesaleTradeBetweenCompanies',
      desc: '',
      args: [],
    );
  }

  /// `A smart platform connecting suppliers and buyers inside and outside Al Ras Smart`
  String get welcomeTagline {
    return Intl.message(
      'A smart platform connecting suppliers and buyers inside and outside Al Ras Smart',
      name: 'welcomeTagline',
      desc: '',
      args: [],
    );
  }

  /// `Supplier Sign-up`
  String get registerSupplier {
    return Intl.message(
      'Supplier Sign-up',
      name: 'registerSupplier',
      desc: '',
      args: [],
    );
  }

  /// `List your products and reach customers`
  String get registerSupplierSubtitle {
    return Intl.message(
      'List your products and reach customers',
      name: 'registerSupplierSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Customer Sign-up`
  String get registerClient {
    return Intl.message(
      'Customer Sign-up',
      name: 'registerClient',
      desc: '',
      args: [],
    );
  }

  /// `Browse and order easily`
  String get registerClientSubtitle {
    return Intl.message(
      'Browse and order easily',
      name: 'registerClientSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to your account`
  String get loginSubtitle {
    return Intl.message(
      'Sign in to your account',
      name: 'loginSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Reliable and fast shipping solutions`
  String get shippingCompanySubtitle {
    return Intl.message(
      'Reliable and fast shipping solutions',
      name: 'shippingCompanySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Login as Guest`
  String get loginAsGuest {
    return Intl.message(
      'Login as Guest',
      name: 'loginAsGuest',
      desc: '',
      args: [],
    );
  }

  /// `Sorry`
  String get loginRequiredTitle {
    return Intl.message(
      'Sorry',
      name: 'loginRequiredTitle',
      desc: '',
      args: [],
    );
  }

  /// `You must log in to continue.`
  String get loginRequiredMessage {
    return Intl.message(
      'You must log in to continue.',
      name: 'loginRequiredMessage',
      desc: '',
      args: [],
    );
  }

  /// `Enter full name`
  String get enterFullName {
    return Intl.message(
      'Enter full name',
      name: 'enterFullName',
      desc: '',
      args: [],
    );
  }

  /// `Full Name`
  String get fullName {
    return Intl.message('Full Name', name: 'fullName', desc: '', args: []);
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Create Order`
  String get createOrder {
    return Intl.message(
      'Create Order',
      name: 'createOrder',
      desc: '',
      args: [],
    );
  }

  /// `My Orders`
  String get myOrders {
    return Intl.message('My Orders', name: 'myOrders', desc: '', args: []);
  }

  /// `Incoming sales and your purchases in one place.`
  String get myOrdersSubtitle {
    return Intl.message(
      'Incoming sales and your purchases in one place.',
      name: 'myOrdersSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Incoming`
  String get incomingOrders {
    return Intl.message('Incoming', name: 'incomingOrders', desc: '', args: []);
  }

  /// `Orders and offers received on your ads.`
  String get incomingOrdersSubtitle {
    return Intl.message(
      'Orders and offers received on your ads.',
      name: 'incomingOrdersSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Incoming offers`
  String get companyCustomerRequestsTab {
    return Intl.message(
      'Incoming offers',
      name: 'companyCustomerRequestsTab',
      desc: '',
      args: [],
    );
  }

  /// `Orders`
  String get companyCustomerOrdersTab {
    return Intl.message(
      'Orders',
      name: 'companyCustomerOrdersTab',
      desc: '',
      args: [],
    );
  }

  /// `Purchases`
  String get purchases {
    return Intl.message('Purchases', name: 'purchases', desc: '', args: []);
  }

  /// `Orders you placed as a buyer.`
  String get purchasesSubtitle {
    return Intl.message(
      'Orders you placed as a buyer.',
      name: 'purchasesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `No incoming orders yet.`
  String get noIncomingOrdersYet {
    return Intl.message(
      'No incoming orders yet.',
      name: 'noIncomingOrdersYet',
      desc: '',
      args: [],
    );
  }

  /// `No purchases yet.`
  String get noPurchasesYet {
    return Intl.message(
      'No purchases yet.',
      name: 'noPurchasesYet',
      desc: '',
      args: [],
    );
  }

  /// `Supplier offers received on your Request ads.`
  String get companyCustomerRequestsSubtitle {
    return Intl.message(
      'Supplier offers received on your Request ads.',
      name: 'companyCustomerRequestsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `My Request ads`
  String get companyCustomerRequestAdsHeader {
    return Intl.message(
      'My Request ads',
      name: 'companyCustomerRequestAdsHeader',
      desc: '',
      args: [],
    );
  }

  /// `Offers on my requests`
  String get companyCustomerIncomingOffersHeader {
    return Intl.message(
      'Offers on my requests',
      name: 'companyCustomerIncomingOffersHeader',
      desc: '',
      args: [],
    );
  }

  /// `You have not published any Request ads yet.`
  String get noRequestAdsYet {
    return Intl.message(
      'You have not published any Request ads yet.',
      name: 'noRequestAdsYet',
      desc: '',
      args: [],
    );
  }

  /// `All Orders`
  String get allOrders {
    return Intl.message('All Orders', name: 'allOrders', desc: '', args: []);
  }

  /// `Awaiting Approval`
  String get awaitingApproval {
    return Intl.message(
      'Awaiting Approval',
      name: 'awaitingApproval',
      desc: '',
      args: [],
    );
  }

  /// `Completed`
  String get completedOrders {
    return Intl.message(
      'Completed',
      name: 'completedOrders',
      desc: '',
      args: [],
    );
  }

  /// `Supplier Account`
  String get supplierAccount {
    return Intl.message(
      'Supplier Account',
      name: 'supplierAccount',
      desc: '',
      args: [],
    );
  }

  /// `Company Account`
  String get companyCustomerAccount {
    return Intl.message(
      'Company Account',
      name: 'companyCustomerAccount',
      desc: '',
      args: [],
    );
  }

  /// `Personal Account`
  String get personalAccount {
    return Intl.message(
      'Personal Account',
      name: 'personalAccount',
      desc: '',
      args: [],
    );
  }

  /// `Mark all as read`
  String get markAllAsRead {
    return Intl.message(
      'Mark all as read',
      name: 'markAllAsRead',
      desc: '',
      args: [],
    );
  }

  /// `Order Date`
  String get orderDate {
    return Intl.message('Order Date', name: 'orderDate', desc: '', args: []);
  }

  /// `Profile`
  String get profile {
    return Intl.message('Profile', name: 'profile', desc: '', args: []);
  }

  /// `Shipping`
  String get shippingPrice {
    return Intl.message(
      'Shipping',
      name: 'shippingPrice',
      desc: '',
      args: [],
    );
  }

  /// `Booking`
  String get booking {
    return Intl.message('Booking', name: 'booking', desc: '', args: []);
  }

  /// `Offers`
  String get offers {
    return Intl.message('Offers', name: 'offers', desc: '', args: []);
  }

  /// `Retail`
  String get retail {
    return Intl.message('Retail', name: 'retail', desc: '', args: []);
  }

  /// `Search for products`
  String get searchForProducts {
    return Intl.message(
      'Search for products',
      name: 'searchForProducts',
      desc: '',
      args: [],
    );
  }

  /// `Track your order:`
  String get trackYourOrder {
    return Intl.message(
      'Track your order:',
      name: 'trackYourOrder',
      desc: '',
      args: [],
    );
  }

  /// `Premium Saffron`
  String get premiumSaffron {
    return Intl.message(
      'Premium Saffron',
      name: 'premiumSaffron',
      desc: '',
      args: [],
    );
  }

  /// `Whole Black Pepper`
  String get wholeBlackPepper {
    return Intl.message(
      'Whole Black Pepper',
      name: 'wholeBlackPepper',
      desc: '',
      args: [],
    );
  }

  /// `Quantity`
  String get quantity {
    return Intl.message('Quantity', name: 'quantity', desc: '', args: []);
  }

  /// `Ordered`
  String get ordered {
    return Intl.message('Ordered', name: 'ordered', desc: '', args: []);
  }

  /// `Approved`
  String get approved {
    return Intl.message('Approved', name: 'approved', desc: '', args: []);
  }

  /// `Paid to Merge Spice`
  String get paid {
    return Intl.message(
      'Paid to Merge Spice',
      name: 'paid',
      desc: '',
      args: [],
    );
  }

  /// `Shipping`
  String get shipping {
    return Intl.message('Shipping', name: 'shipping', desc: '', args: []);
  }

  /// `Delivered`
  String get delivered {
    return Intl.message('Delivered', name: 'delivered', desc: '', args: []);
  }

  /// `Paid to Merge Spice`
  String get paidByCustomer {
    return Intl.message(
      'Paid to Merge Spice',
      name: 'paidByCustomer',
      desc: '',
      args: [],
    );
  }

  /// `Shipped by supplier`
  String get shippedBySupplier {
    return Intl.message(
      'Shipped by supplier',
      name: 'shippedBySupplier',
      desc: '',
      args: [],
    );
  }

  /// `Received`
  String get received {
    return Intl.message('Received', name: 'received', desc: '', args: []);
  }

  /// `Paid to supplier from Merge Spice`
  String get paidToSupplier {
    return Intl.message(
      'Paid to supplier from Merge Spice',
      name: 'paidToSupplier',
      desc: '',
      args: [],
    );
  }

  /// `View Details`
  String get viewDetails {
    return Intl.message(
      'View Details',
      name: 'viewDetails',
      desc: '',
      args: [],
    );
  }

  /// `Categories`
  String get categories {
    return Intl.message('Categories', name: 'categories', desc: '', args: []);
  }

  /// `View All`
  String get viewAll {
    return Intl.message('View All', name: 'viewAll', desc: '', args: []);
  }

  /// `Products`
  String get orderAgain {
    return Intl.message('Products', name: 'orderAgain', desc: '', args: []);
  }

  /// `Herbs`
  String get herbs {
    return Intl.message('Herbs', name: 'herbs', desc: '', args: []);
  }

  /// `Pulses`
  String get pulses {
    return Intl.message('Pulses', name: 'pulses', desc: '', args: []);
  }

  /// `Spices`
  String get spices {
    return Intl.message('Spices', name: 'spices', desc: '', args: []);
  }

  /// `Nuts`
  String get nuts {
    return Intl.message('Nuts', name: 'nuts', desc: '', args: []);
  }

  /// `Coffee`
  String get coffee {
    return Intl.message('Coffee', name: 'coffee', desc: '', args: []);
  }

  /// `Cardamom`
  String get cardamom {
    return Intl.message('Cardamom', name: 'cardamom', desc: '', args: []);
  }

  /// `Cocoa`
  String get cocoa {
    return Intl.message('Cocoa', name: 'cocoa', desc: '', args: []);
  }

  /// `Acids`
  String get acids {
    return Intl.message('Acids', name: 'acids', desc: '', args: []);
  }

  /// `Milk`
  String get milk {
    return Intl.message('Milk', name: 'milk', desc: '', args: []);
  }

  /// `Dates`
  String get dates {
    return Intl.message('Dates', name: 'dates', desc: '', args: []);
  }

  /// `Sugar`
  String get sugar {
    return Intl.message('Sugar', name: 'sugar', desc: '', args: []);
  }

  /// `Rice`
  String get rice {
    return Intl.message('Rice', name: 'rice', desc: '', args: []);
  }

  /// `Sweets`
  String get sweets {
    return Intl.message('Sweets', name: 'sweets', desc: '', args: []);
  }

  /// `Canned`
  String get canned {
    return Intl.message('Canned', name: 'canned', desc: '', args: []);
  }

  /// `Flour`
  String get flour {
    return Intl.message('Flour', name: 'flour', desc: '', args: []);
  }

  /// `Beauty`
  String get beauty {
    return Intl.message('Beauty', name: 'beauty', desc: '', args: []);
  }

  /// `Poultry`
  String get poultry {
    return Intl.message('Poultry', name: 'poultry', desc: '', args: []);
  }

  /// `Frozen Foods`
  String get frozenFoods {
    return Intl.message(
      'Frozen Foods',
      name: 'frozenFoods',
      desc: '',
      args: [],
    );
  }

  /// `Premium Iranian Saffron`
  String get premiumIranianSaffron {
    return Intl.message(
      'Premium Iranian Saffron',
      name: 'premiumIranianSaffron',
      desc: '',
      args: [],
    );
  }

  /// `Receive Offers`
  String get receiveOffers {
    return Intl.message(
      'Receive Offers',
      name: 'receiveOffers',
      desc: '',
      args: [],
    );
  }

  /// `Packaging: Cartons`
  String get packagingCartons {
    return Intl.message(
      'Packaging: Cartons',
      name: 'packagingCartons',
      desc: '',
      args: [],
    );
  }

  /// `Minimum order`
  String get minimumOrder {
    return Intl.message(
      'Minimum order',
      name: 'minimumOrder',
      desc: '',
      args: [],
    );
  }

  /// `Purchase Order`
  String get purchaseOrder {
    return Intl.message(
      'Purchase Order',
      name: 'purchaseOrder',
      desc: '',
      args: [],
    );
  }

  /// `hours ago`
  String get hoursAgo {
    return Intl.message('hours ago', name: 'hoursAgo', desc: '', args: []);
  }

  /// `View Offers`
  String get viewOffers {
    return Intl.message('View Offers', name: 'viewOffers', desc: '', args: []);
  }

  /// `Accept`
  String get acceptOffer {
    return Intl.message('Accept', name: 'acceptOffer', desc: '', args: []);
  }

  /// `Reject`
  String get rejectOffer {
    return Intl.message('Reject', name: 'rejectOffer', desc: '', args: []);
  }

  /// `Accept Offer`
  String get acceptOfferAction {
    return Intl.message(
      'Accept Offer',
      name: 'acceptOfferAction',
      desc: '',
      args: [],
    );
  }

  /// `Reject Offer`
  String get rejectOfferAction {
    return Intl.message(
      'Reject Offer',
      name: 'rejectOfferAction',
      desc: '',
      args: [],
    );
  }

  /// `Accept order`
  String get acceptOrderAction {
    return Intl.message(
      'Accept order',
      name: 'acceptOrderAction',
      desc: '',
      args: [],
    );
  }

  /// `Reject order`
  String get rejectOrderAction {
    return Intl.message(
      'Reject order',
      name: 'rejectOrderAction',
      desc: '',
      args: [],
    );
  }

  /// `No offers on this ad yet.`
  String get noOffersOnAd {
    return Intl.message(
      'No offers on this ad yet.',
      name: 'noOffersOnAd',
      desc: '',
      args: [],
    );
  }

  /// `Offers`
  String get offersInfo {
    return Intl.message('Offers', name: 'offersInfo', desc: '', args: []);
  }

  /// `Order Information`
  String get orderInformation {
    return Intl.message(
      'Order Information',
      name: 'orderInformation',
      desc: '',
      args: [],
    );
  }

  /// `Packaging Type`
  String get packagingType {
    return Intl.message(
      'Packaging Type',
      name: 'packagingType',
      desc: '',
      args: [],
    );
  }

  /// `Requested Receipt Date`
  String get requestedReceiptDate {
    return Intl.message(
      'Requested Receipt Date',
      name: 'requestedReceiptDate',
      desc: '',
      args: [],
    );
  }

  /// `Received Offers`
  String get receivedOffers {
    return Intl.message(
      'Received Offers',
      name: 'receivedOffers',
      desc: '',
      args: [],
    );
  }

  /// `{count} offers available`
  String offersAvailable(Object count) {
    return Intl.message(
      '$count offers available',
      name: 'offersAvailable',
      desc: '',
      args: [count],
    );
  }

  /// `{count} orders available`
  String ordersAvailable(Object count) {
    return Intl.message(
      '$count orders available',
      name: 'ordersAvailable',
      desc: '',
      args: [count],
    );
  }

  /// `suppliers applied`
  String get suppliersApplied {
    return Intl.message(
      'suppliers applied',
      name: 'suppliersApplied',
      desc: '',
      args: [],
    );
  }

  /// `Today's Shipping`
  String get todayShipping {
    return Intl.message(
      'Today\'s Shipping',
      name: 'todayShipping',
      desc: '',
      args: [],
    );
  }

  /// `All Offers`
  String get allOffers {
    return Intl.message('All Offers', name: 'allOffers', desc: '', args: []);
  }

  /// `Restart Application`
  String get restartApplication {
    return Intl.message(
      'Restart Application',
      name: 'restartApplication',
      desc: '',
      args: [],
    );
  }

  /// `Top Discount`
  String get topDiscount {
    return Intl.message(
      'Top Discount',
      name: 'topDiscount',
      desc: '',
      args: [],
    );
  }

  /// `Ending Soon`
  String get endingSoon {
    return Intl.message('Ending Soon', name: 'endingSoon', desc: '', args: []);
  }

  /// `Limited Time`
  String get limitedTime {
    return Intl.message(
      'Limited Time',
      name: 'limitedTime',
      desc: '',
      args: [],
    );
  }

  /// `Limited time`
  String get limitedTimeDeal {
    return Intl.message(
      'Limited time',
      name: 'limitedTimeDeal',
      desc: '',
      args: [],
    );
  }

  /// `Order`
  String get order {
    return Intl.message('Order', name: 'order', desc: '', args: []);
  }

  /// `Featured Offers`
  String get featured {
    return Intl.message(
      'Featured Offers',
      name: 'featured',
      desc: '',
      args: [],
    );
  }

  /// `Featured Products`
  String get featuredProducts {
    return Intl.message(
      'Featured Products',
      name: 'featuredProducts',
      desc: '',
      args: [],
    );
  }

  /// `Orders`
  String get orders {
    return Intl.message('Orders', name: 'orders', desc: '', args: []);
  }

  /// `Requests`
  String get requests {
    return Intl.message('Requests', name: 'requests', desc: '', args: []);
  }

  /// `Order Details`
  String get orderDetails {
    return Intl.message(
      'Order Details',
      name: 'orderDetails',
      desc: '',
      args: [],
    );
  }

  /// `Looking for premium authentic Iranian saffron for import`
  String get requestCardSampleDescription {
    return Intl.message(
      'Looking for premium authentic Iranian saffron for import',
      name: 'requestCardSampleDescription',
      desc: '',
      args: [],
    );
  }

  /// `Dubai, UAE`
  String get dubaiUae {
    return Intl.message('Dubai, UAE', name: 'dubaiUae', desc: '', args: []);
  }

  /// `{hours} hours ago`
  String sinceHoursAgo(Object hours) {
    return Intl.message(
      '$hours hours ago',
      name: 'sinceHoursAgo',
      desc: '',
      args: [hours],
    );
  }

  /// `Show All`
  String get showAll {
    return Intl.message('Show All', name: 'showAll', desc: '', args: []);
  }

  /// `Show number`
  String get showNumber {
    return Intl.message('Show number', name: 'showNumber', desc: '', args: []);
  }

  /// `40f container`
  String get container40f {
    return Intl.message(
      '40f container',
      name: 'container40f',
      desc: '',
      args: [],
    );
  }

  /// `20f container`
  String get container20f {
    return Intl.message(
      '20f container',
      name: 'container20f',
      desc: '',
      args: [],
    );
  }

  /// `Shipping time: {from}-{to} days`
  String shippingTimeRange(Object from, Object to) {
    return Intl.message(
      'Shipping time: $from-$to days',
      name: 'shippingTimeRange',
      desc: '',
      args: [from, to],
    );
  }

  /// `Enter country`
  String get enterCountry {
    return Intl.message(
      'Enter country',
      name: 'enterCountry',
      desc: '',
      args: [],
    );
  }

  /// `From:`
  String get fromLabel {
    return Intl.message('From:', name: 'fromLabel', desc: '', args: []);
  }

  /// `To`
  String get toLabel {
    return Intl.message('To', name: 'toLabel', desc: '', args: []);
  }

  /// `Filter`
  String get filter {
    return Intl.message('Filter', name: 'filter', desc: '', args: []);
  }

  /// `All`
  String get filterAll {
    return Intl.message('All', name: 'filterAll', desc: '', args: []);
  }

  /// `Returns`
  String get returnsFilter {
    return Intl.message('Returns', name: 'returnsFilter', desc: '', args: []);
  }

  /// `Awaiting app approval`
  String get awaitingAdminApproval {
    return Intl.message(
      'Awaiting app approval',
      name: 'awaitingAdminApproval',
      desc: '',
      args: [],
    );
  }

  /// `Awaiting seller approval`
  String get awaitingSellerApproval {
    return Intl.message(
      'Awaiting seller approval',
      name: 'awaitingSellerApproval',
      desc: '',
      args: [],
    );
  }

  /// `Awaiting your approval`
  String get awaitingYourApproval {
    return Intl.message(
      'Awaiting your approval',
      name: 'awaitingYourApproval',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get listingActive {
    return Intl.message('Active', name: 'listingActive', desc: '', args: []);
  }

  /// `Paused`
  String get listingPaused {
    return Intl.message('Paused', name: 'listingPaused', desc: '', args: []);
  }

  /// `No orders match this filter.`
  String get noOrdersMatchFilter {
    return Intl.message(
      'No orders match this filter.',
      name: 'noOrdersMatchFilter',
      desc: '',
      args: [],
    );
  }

  /// `No ads match this filter.`
  String get noAdsMatchFilter {
    return Intl.message(
      'No ads match this filter.',
      name: 'noAdsMatchFilter',
      desc: '',
      args: [],
    );
  }

  /// `Similar ads`
  String get similarAds {
    return Intl.message('Similar ads', name: 'similarAds', desc: '', args: []);
  }

  /// `This ad is unavailable.`
  String get productUnavailable {
    return Intl.message(
      'This ad is unavailable.',
      name: 'productUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `No shipping offers match your filters.`
  String get noShippingOffersMatch {
    return Intl.message(
      'No shipping offers match your filters.',
      name: 'noShippingOffersMatch',
      desc: '',
      args: [],
    );
  }

  /// `No shipping offers available right now.`
  String get noShippingOffersAvailable {
    return Intl.message(
      'No shipping offers available right now.',
      name: 'noShippingOffersAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Orders Info`
  String get ordersInfo {
    return Intl.message('Orders Info', name: 'ordersInfo', desc: '', args: []);
  }

  /// `Account`
  String get account {
    return Intl.message('Account', name: 'account', desc: '', args: []);
  }

  /// `Personal Information`
  String get personalInformation {
    return Intl.message(
      'Personal Information',
      name: 'personalInformation',
      desc: '',
      args: [],
    );
  }

  /// `Change Password`
  String get changePassword {
    return Intl.message(
      'Change Password',
      name: 'changePassword',
      desc: '',
      args: [],
    );
  }

  /// `Set Password`
  String get setPassword {
    return Intl.message(
      'Set Password',
      name: 'setPassword',
      desc: '',
      args: [],
    );
  }

  /// `You signed in with Google or Apple, so there is no current password. Choose a password to also sign in with your email.`
  String get setPasswordSocialHint {
    return Intl.message(
      'You signed in with Google or Apple, so there is no current password. Choose a password to also sign in with your email.',
      name: 'setPasswordSocialHint',
      desc: '',
      args: [],
    );
  }

  /// `Payment Methods`
  String get paymentMethods {
    return Intl.message(
      'Payment Methods',
      name: 'paymentMethods',
      desc: '',
      args: [],
    );
  }

  /// `Saved Addresses`
  String get savedAddresses {
    return Intl.message(
      'Saved Addresses',
      name: 'savedAddresses',
      desc: '',
      args: [],
    );
  }

  /// `Saved Ads`
  String get savedAds {
    return Intl.message('Saved Ads', name: 'savedAds', desc: '', args: []);
  }

  /// `No saved ads yet`
  String get noSavedAds {
    return Intl.message(
      'No saved ads yet',
      name: 'noSavedAds',
      desc: '',
      args: [],
    );
  }

  /// `Open any ad and tap the bookmark icon to save it here.`
  String get noSavedAdsHint {
    return Intl.message(
      'Open any ad and tap the bookmark icon to save it here.',
      name: 'noSavedAdsHint',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load saved ads.`
  String get failedToLoadSavedAds {
    return Intl.message(
      'Failed to load saved ads.',
      name: 'failedToLoadSavedAds',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Notifications`
  String get notifications {
    return Intl.message(
      'Notifications',
      name: 'notifications',
      desc: '',
      args: [],
    );
  }

  /// `Help & Support`
  String get helpSupport {
    return Intl.message(
      'Help & Support',
      name: 'helpSupport',
      desc: '',
      args: [],
    );
  }

  /// `Currency`
  String get currency {
    return Intl.message('Currency', name: 'currency', desc: '', args: []);
  }

  /// `Unit`
  String get unitLabel {
    return Intl.message('Unit', name: 'unitLabel', desc: '', args: []);
  }

  /// `UAE Dirham (AED)`
  String get currencyAedFull {
    return Intl.message(
      'UAE Dirham (AED)',
      name: 'currencyAedFull',
      desc: '',
      args: [],
    );
  }

  /// `US Dollar (USD)`
  String get currencyUsdFull {
    return Intl.message(
      'US Dollar (USD)',
      name: 'currencyUsdFull',
      desc: '',
      args: [],
    );
  }

  /// `Policy and Privacy`
  String get policyAndPrivacy {
    return Intl.message(
      'Policy and Privacy',
      name: 'policyAndPrivacy',
      desc: '',
      args: [],
    );
  }

  /// `Log Out`
  String get logOut {
    return Intl.message('Log Out', name: 'logOut', desc: '', args: []);
  }

  /// `Delete Account`
  String get deleteAccount {
    return Intl.message(
      'Delete Account',
      name: 'deleteAccount',
      desc: '',
      args: [],
    );
  }

  /// `This will permanently delete your account, ads, orders, messages, addresses, and all related data. This action cannot be undone.`
  String get deleteAccountConfirmMessage {
    return Intl.message(
      'This will permanently delete your account, ads, orders, messages, addresses, and all related data. This action cannot be undone.',
      name: 'deleteAccountConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Enter your password to confirm`
  String get enterPasswordToConfirm {
    return Intl.message(
      'Enter your password to confirm',
      name: 'enterPasswordToConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Your account has been deleted successfully.`
  String get deleteAccountSuccess {
    return Intl.message(
      'Your account has been deleted successfully.',
      name: 'deleteAccountSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Edit Profile`
  String get editProfile {
    return Intl.message(
      'Edit Profile',
      name: 'editProfile',
      desc: '',
      args: [],
    );
  }

  /// `Change language`
  String get changeLanguageSubtitle {
    return Intl.message(
      'Change language',
      name: 'changeLanguageSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Get help and contact support`
  String get helpSupportSubtitle {
    return Intl.message(
      'Get help and contact support',
      name: 'helpSupportSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Complaints & Suggestions`
  String get complaintsSuggestions {
    return Intl.message(
      'Complaints & Suggestions',
      name: 'complaintsSuggestions',
      desc: '',
      args: [],
    );
  }

  /// `Share a complaint or suggest an improvement`
  String get complaintsSuggestionsSubtitle {
    return Intl.message(
      'Share a complaint or suggest an improvement',
      name: 'complaintsSuggestionsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Tell us about a problem or share your idea to improve Al Ras Smart. Our team will review your message.`
  String get complaintsSuggestionsHint {
    return Intl.message(
      'Tell us about a problem or share your idea to improve Al Ras Smart. Our team will review your message.',
      name: 'complaintsSuggestionsHint',
      desc: '',
      args: [],
    );
  }

  /// `Type`
  String get feedbackTypeLabel {
    return Intl.message('Type', name: 'feedbackTypeLabel', desc: '', args: []);
  }

  /// `Complaint`
  String get feedbackTypeComplaint {
    return Intl.message(
      'Complaint',
      name: 'feedbackTypeComplaint',
      desc: '',
      args: [],
    );
  }

  /// `Suggestion`
  String get feedbackTypeSuggestion {
    return Intl.message(
      'Suggestion',
      name: 'feedbackTypeSuggestion',
      desc: '',
      args: [],
    );
  }

  /// `Subject`
  String get feedbackSubjectLabel {
    return Intl.message(
      'Subject',
      name: 'feedbackSubjectLabel',
      desc: '',
      args: [],
    );
  }

  /// `Brief title for your message`
  String get feedbackSubjectHint {
    return Intl.message(
      'Brief title for your message',
      name: 'feedbackSubjectHint',
      desc: '',
      args: [],
    );
  }

  /// `Message`
  String get feedbackMessageLabel {
    return Intl.message(
      'Message',
      name: 'feedbackMessageLabel',
      desc: '',
      args: [],
    );
  }

  /// `Describe your complaint or suggestion in detail`
  String get feedbackMessageHint {
    return Intl.message(
      'Describe your complaint or suggestion in detail',
      name: 'feedbackMessageHint',
      desc: '',
      args: [],
    );
  }

  /// `Order reference (optional)`
  String get feedbackOrderRefLabel {
    return Intl.message(
      'Order reference (optional)',
      name: 'feedbackOrderRefLabel',
      desc: '',
      args: [],
    );
  }

  /// `Order number if related to a specific order`
  String get feedbackOrderRefHint {
    return Intl.message(
      'Order number if related to a specific order',
      name: 'feedbackOrderRefHint',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submitFeedback {
    return Intl.message('Submit', name: 'submitFeedback', desc: '', args: []);
  }

  /// `Your message was sent successfully.`
  String get feedbackSubmittedSuccess {
    return Intl.message(
      'Your message was sent successfully.',
      name: 'feedbackSubmittedSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Could not send your message. Please try again.`
  String get feedbackSubmittedError {
    return Intl.message(
      'Could not send your message. Please try again.',
      name: 'feedbackSubmittedError',
      desc: '',
      args: [],
    );
  }

  /// `Read our policy and privacy`
  String get policyAndPrivacySubtitle {
    return Intl.message(
      'Read our policy and privacy',
      name: 'policyAndPrivacySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Permanently delete your account`
  String get deleteAccountSubtitle {
    return Intl.message(
      'Permanently delete your account',
      name: 'deleteAccountSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Sign out from your account`
  String get logOutSubtitle {
    return Intl.message(
      'Sign out from your account',
      name: 'logOutSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `View and manage your cart`
  String get cartSubtitle {
    return Intl.message(
      'View and manage your cart',
      name: 'cartSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Manage your personal details`
  String get personalInformationSubtitle {
    return Intl.message(
      'Manage your personal details',
      name: 'personalInformationSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Update your password`
  String get changePasswordSubtitle {
    return Intl.message(
      'Update your password',
      name: 'changePasswordSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Change prices`
  String get changePrices {
    return Intl.message(
      'Change prices',
      name: 'changePrices',
      desc: '',
      args: [],
    );
  }

  /// `Update and manage product prices easily`
  String get changePricesSubtitle {
    return Intl.message(
      'Update and manage product prices easily',
      name: 'changePricesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Change target prices`
  String get changeTargetPrices {
    return Intl.message(
      'Change target prices',
      name: 'changeTargetPrices',
      desc: '',
      args: [],
    );
  }

  /// `Update and manage target prices easily`
  String get changeTargetPricesSubtitle {
    return Intl.message(
      'Update and manage target prices easily',
      name: 'changeTargetPricesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Account Overview`
  String get accountOverview {
    return Intl.message(
      'Account Overview',
      name: 'accountOverview',
      desc: '',
      args: [],
    );
  }

  /// `Manage & track your advertisements`
  String get myAdsOverviewSubtitle {
    return Intl.message(
      'Manage & track your advertisements',
      name: 'myAdsOverviewSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `View & manage your offers`
  String get myOffersOverviewSubtitle {
    return Intl.message(
      'View & manage your offers',
      name: 'myOffersOverviewSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Recent Listings`
  String get recentListings {
    return Intl.message(
      'Recent Listings',
      name: 'recentListings',
      desc: '',
      args: [],
    );
  }

  /// `Edit Price`
  String get editPrice {
    return Intl.message('Edit Price', name: 'editPrice', desc: '', args: []);
  }

  /// `Search ads`
  String get changePricesSearchHint {
    return Intl.message(
      'Search ads',
      name: 'changePricesSearchHint',
      desc: '',
      args: [],
    );
  }

  /// `Prices updated`
  String get pricesUpdated {
    return Intl.message(
      'Prices updated',
      name: 'pricesUpdated',
      desc: '',
      args: [],
    );
  }

  /// `You have no ads yet`
  String get noAdsToChangePrices {
    return Intl.message(
      'You have no ads yet',
      name: 'noAdsToChangePrices',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid price greater than zero`
  String get invalidPrice {
    return Intl.message(
      'Enter a valid price greater than zero',
      name: 'invalidPrice',
      desc: '',
      args: [],
    );
  }

  /// `Manage your saved addresses`
  String get savedAddressesSubtitle {
    return Intl.message(
      'Manage your saved addresses',
      name: 'savedAddressesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `View your saved advertisements`
  String get savedAdsSubtitle {
    return Intl.message(
      'View your saved advertisements',
      name: 'savedAdsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Manage your advertisements`
  String get myAdsSubtitle {
    return Intl.message(
      'Manage your advertisements',
      name: 'myAdsSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Smart help at your fingertips`
  String get aiAssistantCardSubtitle {
    return Intl.message(
      'Smart help at your fingertips',
      name: 'aiAssistantCardSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Chat with our support team`
  String get liveChatSubtitle {
    return Intl.message(
      'Chat with our support team',
      name: 'liveChatSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Sign back in quickly after logout using Face ID or fingerprint. Only for this saved account.`
  String get faceIdFingerprintSubtitle {
    return Intl.message(
      'Sign back in quickly after logout using Face ID or fingerprint. Only for this saved account.',
      name: 'faceIdFingerprintSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Your data is safe with us`
  String get dataSafeTitle {
    return Intl.message(
      'Your data is safe with us',
      name: 'dataSafeTitle',
      desc: '',
      args: [],
    );
  }

  /// `We use advanced security to protect your information.`
  String get dataSafeSubtitle {
    return Intl.message(
      'We use advanced security to protect your information.',
      name: 'dataSafeSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Date of Birth`
  String get dateOfBirth {
    return Intl.message(
      'Date of Birth',
      name: 'dateOfBirth',
      desc: '',
      args: [],
    );
  }

  /// `Commercial Registration`
  String get commercialRegistration {
    return Intl.message(
      'Commercial Registration',
      name: 'commercialRegistration',
      desc: '',
      args: [],
    );
  }

  /// `Tax Number`
  String get taxNumber {
    return Intl.message('Tax Number', name: 'taxNumber', desc: '', args: []);
  }

  /// `Website`
  String get website {
    return Intl.message('Website', name: 'website', desc: '', args: []);
  }

  /// `https://`
  String get websiteHint {
    return Intl.message('https://', name: 'websiteHint', desc: '', args: []);
  }

  /// `Enter a valid website URL`
  String get invalidWebsite {
    return Intl.message(
      'Enter a valid website URL',
      name: 'invalidWebsite',
      desc: '',
      args: [],
    );
  }

  /// `Notification Settings`
  String get notificationSettings {
    return Intl.message(
      'Notification Settings',
      name: 'notificationSettings',
      desc: '',
      args: [],
    );
  }

  /// `Save Password`
  String get savePassword {
    return Intl.message(
      'Save Password',
      name: 'savePassword',
      desc: '',
      args: [],
    );
  }

  /// `Enter current password`
  String get enterCurrentPassword {
    return Intl.message(
      'Enter current password',
      name: 'enterCurrentPassword',
      desc: '',
      args: [],
    );
  }

  /// `Enter new password`
  String get enterNewPassword {
    return Intl.message(
      'Enter new password',
      name: 'enterNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `Confirm new password`
  String get confirmNewPassword {
    return Intl.message(
      'Confirm new password',
      name: 'confirmNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `Re-enter new password`
  String get reEnterNewPassword {
    return Intl.message(
      'Re-enter new password',
      name: 'reEnterNewPassword',
      desc: '',
      args: [],
    );
  }

  /// `New Password`
  String get newPassword {
    return Intl.message(
      'New Password',
      name: 'newPassword',
      desc: '',
      args: [],
    );
  }

  /// `Current Password`
  String get currentPassword {
    return Intl.message(
      'Current Password',
      name: 'currentPassword',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get languageTitle {
    return Intl.message('Language', name: 'languageTitle', desc: '', args: []);
  }

  /// `Arabic`
  String get arabicLabel {
    return Intl.message('Arabic', name: 'arabicLabel', desc: '', args: []);
  }

  /// `English`
  String get englishLabel {
    return Intl.message('English', name: 'englishLabel', desc: '', args: []);
  }

  /// `Choose your preferred language. The app will update immediately.`
  String get languagePreferenceHint {
    return Intl.message(
      'Choose your preferred language. The app will update immediately.',
      name: 'languagePreferenceHint',
      desc: '',
      args: [],
    );
  }

  /// `Dark mode`
  String get darkMode {
    return Intl.message('Dark mode', name: 'darkMode', desc: '', args: []);
  }

  /// `Use a darker background that's easier on the eyes`
  String get darkModeSubtitle {
    return Intl.message(
      'Use a darker background that\'s easier on the eyes',
      name: 'darkModeSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Policy and Privacy`
  String get PolicyandPrivacy {
    return Intl.message(
      'Policy and Privacy',
      name: 'PolicyandPrivacy',
      desc: '',
      args: [],
    );
  }

  /// `Terms of Use and Conditions for the "Al Ras Smart" App`
  String get termsTitle {
    return Intl.message(
      'Terms of Use and Conditions for the "Al Ras Smart" App',
      name: 'termsTitle',
      desc: '',
      args: [],
    );
  }

  /// `First: Definitions`
  String get firstDefinitions {
    return Intl.message(
      'First: Definitions',
      name: 'firstDefinitions',
      desc: '',
      args: [],
    );
  }

  /// `The app refers to the Al Ras Smart electronic platform.`
  String get defApp {
    return Intl.message(
      'The app refers to the Al Ras Smart electronic platform.',
      name: 'defApp',
      desc: '',
      args: [],
    );
  }

  /// `The company refers to Merge Spice Foodstuff Trading LLC.`
  String get defCompany {
    return Intl.message(
      'The company refers to Merge Spice Foodstuff Trading LLC.',
      name: 'defCompany',
      desc: '',
      args: [],
    );
  }

  /// `The supplier refers to any company or individual offering products through the app.`
  String get defSupplier {
    return Intl.message(
      'The supplier refers to any company or individual offering products through the app.',
      name: 'defSupplier',
      desc: '',
      args: [],
    );
  }

  /// `The client refers to any user purchasing products through the app.`
  String get defClient {
    return Intl.message(
      'The client refers to any user purchasing products through the app.',
      name: 'defClient',
      desc: '',
      args: [],
    );
  }

  /// `Second: Nature of the App's Work`
  String get secondNature {
    return Intl.message(
      'Second: Nature of the App\'s Work',
      name: 'secondNature',
      desc: '',
      args: [],
    );
  }

  /// `Merge Spice acts as an intermediary between the supplier and the client, with all sales and purchases conducted through the app.`
  String get natureIntermediary {
    return Intl.message(
      'Merge Spice acts as an intermediary between the supplier and the client, with all sales and purchases conducted through the app.',
      name: 'natureIntermediary',
      desc: '',
      args: [],
    );
  }

  /// `The company is not the owner of the displayed goods but acts as a mediator to organize commercial operations and ensure smooth transactions.`
  String get natureMediator {
    return Intl.message(
      'The company is not the owner of the displayed goods but acts as a mediator to organize commercial operations and ensure smooth transactions.',
      name: 'natureMediator',
      desc: '',
      args: [],
    );
  }

  /// `Third: Supplier Obligations`
  String get thirdSupplierObligations {
    return Intl.message(
      'Third: Supplier Obligations',
      name: 'thirdSupplierObligations',
      desc: '',
      args: [],
    );
  }

  /// `The supplier guarantees the accuracy and validity of their company data and contact methods, and that the commercial license is valid.`
  String get supplierObligation1 {
    return Intl.message(
      'The supplier guarantees the accuracy and validity of their company data and contact methods, and that the commercial license is valid.',
      name: 'supplierObligation1',
      desc: '',
      args: [],
    );
  }

  /// `The supplier must ensure all displayed products are available, under their full control, and ready for immediate sale.`
  String get supplierObligation2 {
    return Intl.message(
      'The supplier must ensure all displayed products are available, under their full control, and ready for immediate sale.',
      name: 'supplierObligation2',
      desc: '',
      args: [],
    );
  }

  /// `Displaying products not in stock or unavailable after order confirmation is prohibited.`
  String get supplierObligation3 {
    return Intl.message(
      'Displaying products not in stock or unavailable after order confirmation is prohibited.',
      name: 'supplierObligation3',
      desc: '',
      args: [],
    );
  }

  /// `The supplier must continuously update available quantities in the app.`
  String get supplierObligation4 {
    return Intl.message(
      'The supplier must continuously update available quantities in the app.',
      name: 'supplierObligation4',
      desc: '',
      args: [],
    );
  }

  /// `If a product is sold out, it must be immediately removed from the app.`
  String get supplierObligation5 {
    return Intl.message(
      'If a product is sold out, it must be immediately removed from the app.',
      name: 'supplierObligation5',
      desc: '',
      args: [],
    );
  }

  /// `The supplier bears full responsibility for product quality, quantity, weight, and packaging until delivery.`
  String get supplierObligation6 {
    return Intl.message(
      'The supplier bears full responsibility for product quality, quantity, weight, and packaging until delivery.',
      name: 'supplierObligation6',
      desc: '',
      args: [],
    );
  }

  /// `The supplier commits not to display or sell:`
  String get supplierCommitmentHeader {
    return Intl.message(
      'The supplier commits not to display or sell:',
      name: 'supplierCommitmentHeader',
      desc: '',
      args: [],
    );
  }

  /// `Products prohibited by law.`
  String get prohibitedProducts {
    return Intl.message(
      'Products prohibited by law.',
      name: 'prohibitedProducts',
      desc: '',
      args: [],
    );
  }

  /// `Counterfeit or fake products.`
  String get counterfeitProducts {
    return Intl.message(
      'Counterfeit or fake products.',
      name: 'counterfeitProducts',
      desc: '',
      args: [],
    );
  }

  /// `Products belonging to exclusive agents without official authorization.`
  String get exclusiveAgents {
    return Intl.message(
      'Products belonging to exclusive agents without official authorization.',
      name: 'exclusiveAgents',
      desc: '',
      args: [],
    );
  }

  /// `Publishing any supplier-identifying information within product images or descriptions (e.g., name, phone number, address, email) is prohibited.`
  String get supplierIdentifyingInfo {
    return Intl.message(
      'Publishing any supplier-identifying information within product images or descriptions (e.g., name, phone number, address, email) is prohibited.',
      name: 'supplierIdentifyingInfo',
      desc: '',
      args: [],
    );
  }

  /// `Using images or backgrounds indicating the supplier's location or identity is forbidden.`
  String get forbiddenBackgrounds {
    return Intl.message(
      'Using images or backgrounds indicating the supplier\'s location or identity is forbidden.',
      name: 'forbiddenBackgrounds',
      desc: '',
      args: [],
    );
  }

  /// `Fourth: Client Obligations`
  String get fourthClientObligations {
    return Intl.message(
      'Fourth: Client Obligations',
      name: 'fourthClientObligations',
      desc: '',
      args: [],
    );
  }

  /// `The client must provide accurate data in the app.`
  String get clientObligation1 {
    return Intl.message(
      'The client must provide accurate data in the app.',
      name: 'clientObligation1',
      desc: '',
      args: [],
    );
  }

  /// `The client is not responsible for any weight shortage upon receipt; any discrepancy will be deducted from the invoice value if applicable.`
  String get clientObligation2 {
    return Intl.message(
      'The client is not responsible for any weight shortage upon receipt; any discrepancy will be deducted from the invoice value if applicable.',
      name: 'clientObligation2',
      desc: '',
      args: [],
    );
  }

  /// `The client agrees to pay the order value as agreed (cash, credit, on delivery or receipt).`
  String get clientObligation3 {
    return Intl.message(
      'The client agrees to pay the order value as agreed (cash, credit, on delivery or receipt).',
      name: 'clientObligation3',
      desc: '',
      args: [],
    );
  }

  /// `Fifth: Sales and Payment Mechanism`
  String get fifthSalesMechanism {
    return Intl.message(
      'Fifth: Sales and Payment Mechanism',
      name: 'fifthSalesMechanism',
      desc: '',
      args: [],
    );
  }

  /// `Upon order confirmation between supplier and client:`
  String get orderConfirmationHeader {
    return Intl.message(
      'Upon order confirmation between supplier and client:',
      name: 'orderConfirmationHeader',
      desc: '',
      args: [],
    );
  }

  /// `Merge Spice issues an invoice including the agreed quantity and price.`
  String get mechanismInvoiceIssue {
    return Intl.message(
      'Merge Spice issues an invoice including the agreed quantity and price.',
      name: 'mechanismInvoiceIssue',
      desc: '',
      args: [],
    );
  }

  /// `The invoice is sent to the client for confirmation.`
  String get mechanismInvoiceSend {
    return Intl.message(
      'The invoice is sent to the client for confirmation.',
      name: 'mechanismInvoiceSend',
      desc: '',
      args: [],
    );
  }

  /// `After client confirmation:`
  String get clientConfirmationHeader {
    return Intl.message(
      'After client confirmation:',
      name: 'clientConfirmationHeader',
      desc: '',
      args: [],
    );
  }

  /// `The amount is collected from the client.`
  String get mechanismAmountCollected {
    return Intl.message(
      'The amount is collected from the client.',
      name: 'mechanismAmountCollected',
      desc: '',
      args: [],
    );
  }

  /// `The supplier is notified to start delivery.`
  String get mechanismSupplierNotified {
    return Intl.message(
      'The supplier is notified to start delivery.',
      name: 'mechanismSupplierNotified',
      desc: '',
      args: [],
    );
  }

  /// `The company pays the supplier only after the client receives the goods.`
  String get mechanismCompanyCommitment {
    return Intl.message(
      'The company pays the supplier only after the client receives the goods.',
      name: 'mechanismCompanyCommitment',
      desc: '',
      args: [],
    );
  }

  /// `Successful receipt confirmation.`
  String get mechanismDeliveryConfirm {
    return Intl.message(
      'Successful receipt confirmation.',
      name: 'mechanismDeliveryConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Online card payment is available for Retail orders only. Cash on delivery applies to other deal types per platform process.`
  String get mechanismCodPolicy {
    return Intl.message(
      'Online card payment is available for Retail orders only. Cash on delivery applies to other deal types per platform process.',
      name: 'mechanismCodPolicy',
      desc: '',
      args: [],
    );
  }

  /// `The company acts as a financial intermediary between the parties (collecting from client – transferring to supplier).`
  String get mechanismFinancialIntermediary {
    return Intl.message(
      'The company acts as a financial intermediary between the parties (collecting from client – transferring to supplier).',
      name: 'mechanismFinancialIntermediary',
      desc: '',
      args: [],
    );
  }

  /// `Sixth: Restrictions and Prohibitions`
  String get sixthRestrictions {
    return Intl.message(
      'Sixth: Restrictions and Prohibitions',
      name: 'sixthRestrictions',
      desc: '',
      args: [],
    );
  }

  /// `Strictly prohibited:`
  String get restrictionsHeader {
    return Intl.message(
      'Strictly prohibited:',
      name: 'restrictionsHeader',
      desc: '',
      args: [],
    );
  }

  /// `Publishing or requesting any products banned by UAE law or any country involved.`
  String get restriction1 {
    return Intl.message(
      'Publishing or requesting any products banned by UAE law or any country involved.',
      name: 'restriction1',
      desc: '',
      args: [],
    );
  }

  /// `Offering non-original or counterfeit products.`
  String get restriction2 {
    return Intl.message(
      'Offering non-original or counterfeit products.',
      name: 'restriction2',
      desc: '',
      args: [],
    );
  }

  /// `Manipulating prices, quantities, or product information.`
  String get restriction3 {
    return Intl.message(
      'Manipulating prices, quantities, or product information.',
      name: 'restriction3',
      desc: '',
      args: [],
    );
  }

  /// `Using the app for direct communication outside the platform to complete deals outside the app.`
  String get restriction4 {
    return Intl.message(
      'Using the app for direct communication outside the platform to complete deals outside the app.',
      name: 'restriction4',
      desc: '',
      args: [],
    );
  }

  /// `Seventh: Legal Responsibility`
  String get seventhLiability {
    return Intl.message(
      'Seventh: Legal Responsibility',
      name: 'seventhLiability',
      desc: '',
      args: [],
    );
  }

  /// `The supplier bears full responsibility for products regarding:`
  String get supplierLiabilityHeader {
    return Intl.message(
      'The supplier bears full responsibility for products regarding:',
      name: 'supplierLiabilityHeader',
      desc: '',
      args: [],
    );
  }

  /// `Quality`
  String get liabilityQuality {
    return Intl.message(
      'Quality',
      name: 'liabilityQuality',
      desc: '',
      args: [],
    );
  }

  /// `Quantity`
  String get liabilityQuantity {
    return Intl.message(
      'Quantity',
      name: 'liabilityQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Weight`
  String get liabilityWeight {
    return Intl.message('Weight', name: 'liabilityWeight', desc: '', args: []);
  }

  /// `Compliance with specifications`
  String get liabilitySpecs {
    return Intl.message(
      'Compliance with specifications',
      name: 'liabilitySpecs',
      desc: '',
      args: [],
    );
  }

  /// `Merge Spice bears no responsibility for:`
  String get companyNoLiabilityHeader {
    return Intl.message(
      'Merge Spice bears no responsibility for:',
      name: 'companyNoLiabilityHeader',
      desc: '',
      args: [],
    );
  }

  /// `Product quality`
  String get noLiabilityProductQuality {
    return Intl.message(
      'Product quality',
      name: 'noLiabilityProductQuality',
      desc: '',
      args: [],
    );
  }

  /// `Any disputes between supplier and client`
  String get noLiabilityDisputes {
    return Intl.message(
      'Any disputes between supplier and client',
      name: 'noLiabilityDisputes',
      desc: '',
      args: [],
    );
  }

  /// `Any losses due to misuse of the app`
  String get noLiabilityAppLosses {
    return Intl.message(
      'Any losses due to misuse of the app',
      name: 'noLiabilityAppLosses',
      desc: '',
      args: [],
    );
  }

  /// `The company reserves the right to suspend or delete any account violating terms without prior notice.`
  String get companyRights {
    return Intl.message(
      'The company reserves the right to suspend or delete any account violating terms without prior notice.',
      name: 'companyRights',
      desc: '',
      args: [],
    );
  }

  /// `Inactive user accounts`
  String get inactiveAccountSectionTitle {
    return Intl.message(
      'Inactive user accounts',
      name: 'inactiveAccountSectionTitle',
      desc: '',
      args: [],
    );
  }

  /// `Your account may be automatically deleted if there is no meaningful activity — such as completing a purchase or adding/publishing ads — for three (3) consecutive months.`
  String get inactiveAccountPolicy1 {
    return Intl.message(
      'Your account may be automatically deleted if there is no meaningful activity — such as completing a purchase or adding/publishing ads — for three (3) consecutive months.',
      name: 'inactiveAccountPolicy1',
      desc: '',
      args: [],
    );
  }

  /// `Logging in alone, without a purchase or published ad, is not sufficient activity to prevent automatic deletion under this policy.`
  String get inactiveAccountPolicy2 {
    return Intl.message(
      'Logging in alone, without a purchase or published ad, is not sufficient activity to prevent automatic deletion under this policy.',
      name: 'inactiveAccountPolicy2',
      desc: '',
      args: [],
    );
  }

  /// `Eighth: Amendments`
  String get eighthAmendments {
    return Intl.message(
      'Eighth: Amendments',
      name: 'eighthAmendments',
      desc: '',
      args: [],
    );
  }

  /// `Merge Spice reserves the right to modify these terms and conditions at any time; updates will be published in the app, and continued use implies acceptance.`
  String get amendment1 {
    return Intl.message(
      'Merge Spice reserves the right to modify these terms and conditions at any time; updates will be published in the app, and continued use implies acceptance.',
      name: 'amendment1',
      desc: '',
      args: [],
    );
  }

  /// `Ninth: Applicable Laws`
  String get ninthGoverningLaw {
    return Intl.message(
      'Ninth: Applicable Laws',
      name: 'ninthGoverningLaw',
      desc: '',
      args: [],
    );
  }

  /// `These terms and conditions are governed by UAE laws, and Dubai courts have jurisdiction over any disputes.`
  String get governingLawText {
    return Intl.message(
      'These terms and conditions are governed by UAE laws, and Dubai courts have jurisdiction over any disputes.',
      name: 'governingLawText',
      desc: '',
      args: [],
    );
  }

  /// `Tenth: Acceptance`
  String get tenthAcceptance {
    return Intl.message(
      'Tenth: Acceptance',
      name: 'tenthAcceptance',
      desc: '',
      args: [],
    );
  }

  /// `By using the app, the user (supplier or client) fully agrees to all the above terms and conditions.`
  String get acceptanceText {
    return Intl.message(
      'By using the app, the user (supplier or client) fully agrees to all the above terms and conditions.',
      name: 'acceptanceText',
      desc: '',
      args: [],
    );
  }

  /// `App fees on product prices`
  String get commissionSectionTitle {
    return Intl.message(
      'App fees on product prices',
      name: 'commissionSectionTitle',
      desc: '',
      args: [],
    );
  }

  /// `Service fees and rates are applied to product prices shown inside the app only. Specific percentages are not listed here.`
  String get commissionIntro {
    return Intl.message(
      'Service fees and rates are applied to product prices shown inside the app only. Specific percentages are not listed here.',
      name: 'commissionIntro',
      desc: '',
      args: [],
    );
  }

  /// `Simple example: if you list a product at a certain price, that price appears as you entered it in My Ads, while the public listings feed may show a higher price because the service fee is added.`
  String get commissionExample {
    return Intl.message(
      'Simple example: if you list a product at a certain price, that price appears as you entered it in My Ads, while the public listings feed may show a higher price because the service fee is added.',
      name: 'commissionExample',
      desc: '',
      args: [],
    );
  }

  /// `Service fees may change from time to time according to platform policy.`
  String get commissionChangeNotice {
    return Intl.message(
      'Service fees may change from time to time according to platform policy.',
      name: 'commissionChangeNotice',
      desc: '',
      args: [],
    );
  }

  /// `Product image ownership and use`
  String get productImagesSectionTitle {
    return Intl.message(
      'Product image ownership and use',
      name: 'productImagesSectionTitle',
      desc: '',
      args: [],
    );
  }

  /// `Once you publish an ad in the app, the product images linked to that ad become owned by the app and the platform.`
  String get productImagesOwnership {
    return Intl.message(
      'Once you publish an ad in the app, the product images linked to that ad become owned by the app and the platform.',
      name: 'productImagesOwnership',
      desc: '',
      args: [],
    );
  }

  /// `We use these images to train our image-search model so we can deliver more accurate visual search results, because correct and precise results always matter to us.`
  String get productImagesTraining {
    return Intl.message(
      'We use these images to train our image-search model so we can deliver more accurate visual search results, because correct and precise results always matter to us.',
      name: 'productImagesTraining',
      desc: '',
      args: [],
    );
  }

  /// `By publishing an ad, the supplier grants the platform the right to use product images for these operational and training purposes.`
  String get productImagesConsent {
    return Intl.message(
      'By publishing an ad, the supplier grants the platform the right to use product images for these operational and training purposes.',
      name: 'productImagesConsent',
      desc: '',
      args: [],
    );
  }

  /// `Retail`
  String get commissionRetail {
    return Intl.message('Retail', name: 'commissionRetail', desc: '', args: []);
  }

  /// `Booking`
  String get commissionBooking {
    return Intl.message(
      'Booking',
      name: 'commissionBooking',
      desc: '',
      args: [],
    );
  }

  /// `Requests`
  String get commissionRequests {
    return Intl.message(
      'Requests',
      name: 'commissionRequests',
      desc: '',
      args: [],
    );
  }

  /// `Offers`
  String get commissionOffers {
    return Intl.message('Offers', name: 'commissionOffers', desc: '', args: []);
  }

  /// `Shipping`
  String get commissionShipping {
    return Intl.message(
      'Shipping',
      name: 'commissionShipping',
      desc: '',
      args: [],
    );
  }

  /// `By category:`
  String get commissionCategoriesTitle {
    return Intl.message(
      'By category:',
      name: 'commissionCategoriesTitle',
      desc: '',
      args: [],
    );
  }

  /// `{percent}%`
  String commissionPercentValue(String percent) {
    return Intl.message(
      '$percent%',
      name: 'commissionPercentValue',
      desc: '',
      args: [percent],
    );
  }

  /// `Loading commission rates...`
  String get commissionLoading {
    return Intl.message(
      'Loading commission rates...',
      name: 'commissionLoading',
      desc: '',
      args: [],
    );
  }

  /// `Could not load commission rates right now. Please try again later.`
  String get commissionLoadError {
    return Intl.message(
      'Could not load commission rates right now. Please try again later.',
      name: 'commissionLoadError',
      desc: '',
      args: [],
    );
  }

  /// `Working Hours`
  String get workingHours {
    return Intl.message(
      'Working Hours',
      name: 'workingHours',
      desc: '',
      args: [],
    );
  }

  /// `Saturday - Thursday:`
  String get saturdayThursday {
    return Intl.message(
      'Saturday - Thursday:',
      name: 'saturdayThursday',
      desc: '',
      args: [],
    );
  }

  /// `Friday:`
  String get friday {
    return Intl.message('Friday:', name: 'friday', desc: '', args: []);
  }

  /// `Closed`
  String get closed {
    return Intl.message('Closed', name: 'closed', desc: '', args: []);
  }

  /// `Live Chat`
  String get liveChat {
    return Intl.message('Live Chat', name: 'liveChat', desc: '', args: []);
  }

  /// `Chat with the support team now.`
  String get chatWithTheSupportTeamNow {
    return Intl.message(
      'Chat with the support team now.',
      name: 'chatWithTheSupportTeamNow',
      desc: '',
      args: [],
    );
  }

  /// `You are chatting with {name}`
  String chatSessionActiveWith(String name) {
    return Intl.message(
      'You are chatting with $name',
      name: 'chatSessionActiveWith',
      desc: '',
      args: [name],
    );
  }

  /// `Chat closed by {name}`
  String chatSessionClosedBy(String name) {
    return Intl.message(
      'Chat closed by $name',
      name: 'chatSessionClosedBy',
      desc: '',
      args: [name],
    );
  }

  /// `Conversation started with {name}`
  String chatSessionStartedWith(String name) {
    return Intl.message(
      'Conversation started with $name',
      name: 'chatSessionStartedWith',
      desc: '',
      args: [name],
    );
  }

  /// `Start Chat`
  String get startChat {
    return Intl.message('Start Chat', name: 'startChat', desc: '', args: []);
  }

  /// `Phone Call`
  String get phoneCall {
    return Intl.message('Phone Call', name: 'phoneCall', desc: '', args: []);
  }

  /// `Call Now`
  String get callNow {
    return Intl.message('Call Now', name: 'callNow', desc: '', args: []);
  }

  /// `Send Email`
  String get sendEmail {
    return Intl.message('Send Email', name: 'sendEmail', desc: '', args: []);
  }

  /// `How can we help you?`
  String get howCanWeHelpYou {
    return Intl.message(
      'How can we help you?',
      name: 'howCanWeHelpYou',
      desc: '',
      args: [],
    );
  }

  /// `The support team is always here to assist you.`
  String get theSupportTeamIsAlwaysHereToAssistYou {
    return Intl.message(
      'The support team is always here to assist you.',
      name: 'theSupportTeamIsAlwaysHereToAssistYou',
      desc: '',
      args: [],
    );
  }

  /// `Frequently Asked Questions`
  String get frequentlyAskedQuestions {
    return Intl.message(
      'Frequently Asked Questions',
      name: 'frequentlyAskedQuestions',
      desc: '',
      args: [],
    );
  }

  /// `How can I place an order?`
  String get howCanIPlaceAnOrder {
    return Intl.message(
      'How can I place an order?',
      name: 'howCanIPlaceAnOrder',
      desc: '',
      args: [],
    );
  }

  /// `Browse products, open the item you want, then tap Add to Cart. Go to Cart, review your items, choose shipping if needed, and complete checkout.`
  String get howCanIPlaceAnOrderAnswer {
    return Intl.message(
      'Browse products, open the item you want, then tap Add to Cart. Go to Cart, review your items, choose shipping if needed, and complete checkout.',
      name: 'howCanIPlaceAnOrderAnswer',
      desc: '',
      args: [],
    );
  }

  /// `What payment methods are available?`
  String get whatPaymentMethodsAreAvailable {
    return Intl.message(
      'What payment methods are available?',
      name: 'whatPaymentMethodsAreAvailable',
      desc: '',
      args: [],
    );
  }

  /// `You can pay online with Visa or Mastercard, or choose Cash on Delivery when available at checkout.`
  String get whatPaymentMethodsAreAvailableAnswer {
    return Intl.message(
      'You can pay online with Visa or Mastercard, or choose Cash on Delivery when available at checkout.',
      name: 'whatPaymentMethodsAreAvailableAnswer',
      desc: '',
      args: [],
    );
  }

  /// `How do I track my order?`
  String get howDoITrackMyOrder {
    return Intl.message(
      'How do I track my order?',
      name: 'howDoITrackMyOrder',
      desc: '',
      args: [],
    );
  }

  /// `Open My Orders from your profile, select the order, then tap Track Order to follow its current status.`
  String get howDoITrackMyOrderAnswer {
    return Intl.message(
      'Open My Orders from your profile, select the order, then tap Track Order to follow its current status.',
      name: 'howDoITrackMyOrderAnswer',
      desc: '',
      args: [],
    );
  }

  /// `Company Guest`
  String get companyGuest {
    return Intl.message(
      'Company Guest',
      name: 'companyGuest',
      desc: '',
      args: [],
    );
  }

  /// `Shipping Company`
  String get shippingCompany {
    return Intl.message(
      'Shipping Company',
      name: 'shippingCompany',
      desc: '',
      args: [],
    );
  }

  /// `Shipping Company Login`
  String get shippingCompanyLogin {
    return Intl.message(
      'Shipping Company Login',
      name: 'shippingCompanyLogin',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to manage your shipping offers and requests`
  String get shippingCompanyLoginSubtitle {
    return Intl.message(
      'Sign in to manage your shipping offers and requests',
      name: 'shippingCompanyLoginSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Create Shipping Company Account`
  String get shippingCompanyRegister {
    return Intl.message(
      'Create Shipping Company Account',
      name: 'shippingCompanyRegister',
      desc: '',
      args: [],
    );
  }

  /// `Register your shipping company on Al Ras Smart`
  String get shippingCompanyRegisterSubtitle {
    return Intl.message(
      'Register your shipping company on Al Ras Smart',
      name: 'shippingCompanyRegisterSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Shipping Company Name`
  String get shippingCompanyName {
    return Intl.message(
      'Shipping Company Name',
      name: 'shippingCompanyName',
      desc: '',
      args: [],
    );
  }

  /// `Enter shipping company name`
  String get enterShippingCompanyName {
    return Intl.message(
      'Enter shipping company name',
      name: 'enterShippingCompanyName',
      desc: '',
      args: [],
    );
  }

  /// `Shipping Dashboard`
  String get shippingCompanyDashboard {
    return Intl.message(
      'Shipping Dashboard',
      name: 'shippingCompanyDashboard',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to your shipping company dashboard`
  String get welcomeShippingCompany {
    return Intl.message(
      'Welcome to your shipping company dashboard',
      name: 'welcomeShippingCompany',
      desc: '',
      args: [],
    );
  }

  /// `Active Shipping Offers`
  String get activeShippingOffers {
    return Intl.message(
      'Active Shipping Offers',
      name: 'activeShippingOffers',
      desc: '',
      args: [],
    );
  }

  /// `Pending Requests`
  String get pendingRequests {
    return Intl.message(
      'Pending Requests',
      name: 'pendingRequests',
      desc: '',
      args: [],
    );
  }

  /// `Quick Actions`
  String get quickActions {
    return Intl.message(
      'Quick Actions',
      name: 'quickActions',
      desc: '',
      args: [],
    );
  }

  /// `Add Shipping Offer`
  String get addShippingOffer {
    return Intl.message(
      'Add Shipping Offer',
      name: 'addShippingOffer',
      desc: '',
      args: [],
    );
  }

  /// `Create a new shipping offer for clients`
  String get addShippingOfferHint {
    return Intl.message(
      'Create a new shipping offer for clients',
      name: 'addShippingOfferHint',
      desc: '',
      args: [],
    );
  }

  /// `Manage Shipping Offers`
  String get manageShippingOffers {
    return Intl.message(
      'Manage Shipping Offers',
      name: 'manageShippingOffers',
      desc: '',
      args: [],
    );
  }

  /// `View and edit your current shipping offers`
  String get manageShippingOffersHint {
    return Intl.message(
      'View and edit your current shipping offers',
      name: 'manageShippingOffersHint',
      desc: '',
      args: [],
    );
  }

  /// `Shipping Company Account`
  String get shippingCompanyAccount {
    return Intl.message(
      'Shipping Company Account',
      name: 'shippingCompanyAccount',
      desc: '',
      args: [],
    );
  }

  /// `Complete Shipping Company Registration`
  String get completeShippingCompanyRegistration {
    return Intl.message(
      'Complete Shipping Company Registration',
      name: 'completeShippingCompanyRegistration',
      desc: '',
      args: [],
    );
  }

  /// `Create Ad`
  String get createAds {
    return Intl.message('Create Ad', name: 'createAds', desc: '', args: []);
  }

  /// `company`
  String get company {
    return Intl.message('company', name: 'company', desc: '', args: []);
  }

  /// `person`
  String get person {
    return Intl.message('person', name: 'person', desc: '', args: []);
  }

  /// `My Ads`
  String get myAds {
    return Intl.message('My Ads', name: 'myAds', desc: '', args: []);
  }

  /// `My Offers`
  String get myOffers {
    return Intl.message('My Offers', name: 'myOffers', desc: '', args: []);
  }

  /// `You have not submitted any offers yet`
  String get noOffersYet {
    return Intl.message(
      'You have not submitted any offers yet',
      name: 'noOffersYet',
      desc: '',
      args: [],
    );
  }

  /// `Delivery Address`
  String get deliveryAddress {
    return Intl.message(
      'Delivery Address',
      name: 'deliveryAddress',
      desc: '',
      args: [],
    );
  }

  /// `Posting Date`
  String get postingDate {
    return Intl.message(
      'Posting Date',
      name: 'postingDate',
      desc: '',
      args: [],
    );
  }

  /// `Required Specifications`
  String get requiredSpecifications {
    return Intl.message(
      'Required Specifications',
      name: 'requiredSpecifications',
      desc: '',
      args: [],
    );
  }

  /// `Additional Notes`
  String get additionalNotes {
    return Intl.message(
      'Additional Notes',
      name: 'additionalNotes',
      desc: '',
      args: [],
    );
  }

  /// `Submit Offer`
  String get submitOffer {
    return Intl.message(
      'Submit Offer',
      name: 'submitOffer',
      desc: '',
      args: [],
    );
  }

  /// `Product`
  String get product {
    return Intl.message('Product', name: 'product', desc: '', args: []);
  }

  /// `Product code`
  String get productCode {
    return Intl.message(
      'Product code',
      name: 'productCode',
      desc: '',
      args: [],
    );
  }

  /// `Share product`
  String get shareProduct {
    return Intl.message(
      'Share product',
      name: 'shareProduct',
      desc: '',
      args: [],
    );
  }

  /// `Find this product on Al Ras Smart.`
  String get shareProductHint {
    return Intl.message(
      'Find this product on Al Ras Smart.',
      name: 'shareProductHint',
      desc: '',
      args: [],
    );
  }

  /// `Search for this code in the app to open the product.`
  String get shareProductSearchHint {
    return Intl.message(
      'Search for this code in the app to open the product.',
      name: 'shareProductSearchHint',
      desc: '',
      args: [],
    );
  }

  /// `Requested Quantity`
  String get requestedQuantity {
    return Intl.message(
      'Requested Quantity',
      name: 'requestedQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Offer Details`
  String get offerDetails {
    return Intl.message(
      'Offer Details',
      name: 'offerDetails',
      desc: '',
      args: [],
    );
  }

  /// `Your offer will be sent to the requester who can review and respond`
  String get yourOfferWillBeSentToTheRequesterWhoCanReviewAndRespond {
    return Intl.message(
      'Your offer will be sent to the requester who can review and respond',
      name: 'yourOfferWillBeSentToTheRequesterWhoCanReviewAndRespond',
      desc: '',
      args: [],
    );
  }

  /// `Enter Quantity`
  String get enterQuantity {
    return Intl.message(
      'Enter Quantity',
      name: 'enterQuantity',
      desc: '',
      args: [],
    );
  }

  /// `You can also type the quantity manually`
  String get quantityTypeManuallyHint {
    return Intl.message(
      'You can also type the quantity manually',
      name: 'quantityTypeManuallyHint',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid quantity.`
  String get enterValidQuantity {
    return Intl.message(
      'Please enter a valid quantity.',
      name: 'enterValidQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Enter price`
  String get enterPrice {
    return Intl.message('Enter price', name: 'enterPrice', desc: '', args: []);
  }

  /// `Add any special instructions here...`
  String get addAnySpecialInstructionsHere {
    return Intl.message(
      'Add any special instructions here...',
      name: 'addAnySpecialInstructionsHere',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get price {
    return Intl.message('Price', name: 'price', desc: '', args: []);
  }

  /// `Available Quantity`
  String get availableQuantity {
    return Intl.message(
      'Available Quantity',
      name: 'availableQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Sold out`
  String get soldOut {
    return Intl.message('Sold out', name: 'soldOut', desc: '', args: []);
  }

  /// `You cannot place an order on your own product.`
  String get cannotOrderOwnProduct {
    return Intl.message(
      'You cannot place an order on your own product.',
      name: 'cannotOrderOwnProduct',
      desc: '',
      args: [],
    );
  }

  /// `The offer has been sent\nsuccessfully`
  String get offerSentSuccessfullyTitle {
    return Intl.message(
      'The offer has been sent\nsuccessfully',
      name: 'offerSentSuccessfullyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Your offer has been successfully sent to the requester`
  String get offerSentSuccessfullySubtitle {
    return Intl.message(
      'Your offer has been successfully sent to the requester',
      name: 'offerSentSuccessfullySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `We will notify you when the offer is accepted or rejected`
  String get offerSentNotifyWhenReviewed {
    return Intl.message(
      'We will notify you when the offer is accepted or rejected',
      name: 'offerSentNotifyWhenReviewed',
      desc: '',
      args: [],
    );
  }

  /// `Show all requests`
  String get showAllRequests {
    return Intl.message(
      'Show all requests',
      name: 'showAllRequests',
      desc: '',
      args: [],
    );
  }

  /// `Back to Home`
  String get backToHome {
    return Intl.message('Back to Home', name: 'backToHome', desc: '', args: []);
  }

  /// `Product Details`
  String get productDetails {
    return Intl.message(
      'Product Details',
      name: 'productDetails',
      desc: '',
      args: [],
    );
  }

  /// `Specifications`
  String get specifications {
    return Intl.message(
      'Specifications',
      name: 'specifications',
      desc: '',
      args: [],
    );
  }

  /// `Shipping Information`
  String get shippingInformation {
    return Intl.message(
      'Shipping Information',
      name: 'shippingInformation',
      desc: '',
      args: [],
    );
  }

  /// `Shipping Details`
  String get shippingDetails {
    return Intl.message(
      'Shipping Details',
      name: 'shippingDetails',
      desc: '',
      args: [],
    );
  }

  /// `Supplier Notes`
  String get supplierNotes {
    return Intl.message(
      'Supplier Notes',
      name: 'supplierNotes',
      desc: '',
      args: [],
    );
  }

  /// `Enter your offer`
  String get enterYourOffer {
    return Intl.message(
      'Enter your offer',
      name: 'enterYourOffer',
      desc: '',
      args: [],
    );
  }

  /// `USD`
  String get dollar {
    return Intl.message('USD', name: 'dollar', desc: '', args: []);
  }

  /// `Require quantity`
  String get specifyQuantity {
    return Intl.message(
      'Require quantity',
      name: 'specifyQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Port of Arrival`
  String get portOfArrival {
    return Intl.message(
      'Port of Arrival',
      name: 'portOfArrival',
      desc: '',
      args: [],
    );
  }

  /// `Enter port`
  String get enterPort {
    return Intl.message('Enter port', name: 'enterPort', desc: '', args: []);
  }

  /// `Cost Calculation`
  String get costCalculation {
    return Intl.message(
      'Cost Calculation',
      name: 'costCalculation',
      desc: '',
      args: [],
    );
  }

  /// `Price per unit × quantity`
  String get pricePerUnitTimesQuantity {
    return Intl.message(
      'Price per unit × quantity',
      name: 'pricePerUnitTimesQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Price per unit`
  String get pricePerUnitGeneric {
    return Intl.message(
      'Price per unit',
      name: 'pricePerUnitGeneric',
      desc: '',
      args: [],
    );
  }

  /// `Enter price per unit`
  String get enterPricePerUnitGeneric {
    return Intl.message(
      'Enter price per unit',
      name: 'enterPricePerUnitGeneric',
      desc: '',
      args: [],
    );
  }

  /// `Price per {unit}`
  String pricePerUnit(String unit) {
    return Intl.message(
      'Price per $unit',
      name: 'pricePerUnit',
      desc: '',
      args: [unit],
    );
  }

  /// `Enter price per {unit}`
  String enterPricePerUnit(String unit) {
    return Intl.message(
      'Enter price per $unit',
      name: 'enterPricePerUnit',
      desc: '',
      args: [unit],
    );
  }

  /// `Offer price per {unit}`
  String offerPricePerUnit(String unit) {
    return Intl.message(
      'Offer price per $unit',
      name: 'offerPricePerUnit',
      desc: '',
      args: [unit],
    );
  }

  /// `Total`
  String get total {
    return Intl.message('Total', name: 'total', desc: '', args: []);
  }

  /// `Send Purchase Order`
  String get sendPurchaseOrder {
    return Intl.message(
      'Send Purchase Order',
      name: 'sendPurchaseOrder',
      desc: '',
      args: [],
    );
  }

  /// `Order sent successfully`
  String get orderSentSuccessfullyTitle {
    return Intl.message(
      'Order sent successfully',
      name: 'orderSentSuccessfullyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Your request has been sent to management for review.`
  String get orderSentSuccessfullySubtitle {
    return Intl.message(
      'Your request has been sent to management for review.',
      name: 'orderSentSuccessfullySubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Order Number`
  String get orderNumber {
    return Intl.message(
      'Order Number',
      name: 'orderNumber',
      desc: '',
      args: [],
    );
  }

  /// `You will be notified once they respond.`
  String get orderSentNotifyWhenRespond {
    return Intl.message(
      'You will be notified once they respond.',
      name: 'orderSentNotifyWhenRespond',
      desc: '',
      args: [],
    );
  }

  /// `Track Order`
  String get trackOrder {
    return Intl.message('Track Order', name: 'trackOrder', desc: '', args: []);
  }

  /// `Cancel Order`
  String get cancelOrder {
    return Intl.message(
      'Cancel Order',
      name: 'cancelOrder',
      desc: '',
      args: [],
    );
  }

  /// `Return Order`
  String get returnOrder {
    return Intl.message(
      'Return Order',
      name: 'returnOrder',
      desc: '',
      args: [],
    );
  }

  /// `Cancel this order?`
  String get cancelOrderConfirmTitle {
    return Intl.message(
      'Cancel this order?',
      name: 'cancelOrderConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to cancel this order?`
  String get cancelOrderConfirmMessage {
    return Intl.message(
      'Are you sure you want to cancel this order?',
      name: 'cancelOrderConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Return this order?`
  String get returnOrderConfirmTitle {
    return Intl.message(
      'Return this order?',
      name: 'returnOrderConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to return this order?`
  String get returnOrderConfirmMessage {
    return Intl.message(
      'Are you sure you want to return this order?',
      name: 'returnOrderConfirmMessage',
      desc: '',
      args: [],
    );
  }

  /// `Order cancelled successfully`
  String get orderCancelledSuccess {
    return Intl.message(
      'Order cancelled successfully',
      name: 'orderCancelledSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Return request submitted successfully`
  String get orderReturnSuccess {
    return Intl.message(
      'Return request submitted successfully',
      name: 'orderReturnSuccess',
      desc: '',
      args: [],
    );
  }

  /// `The amount will be refunded to your original payment method within one business day.`
  String get orderRefundNotice {
    return Intl.message(
      'The amount will be refunded to your original payment method within one business day.',
      name: 'orderRefundNotice',
      desc: '',
      args: [],
    );
  }

  /// `Refund in progress`
  String get orderRefundPending {
    return Intl.message(
      'Refund in progress',
      name: 'orderRefundPending',
      desc: '',
      args: [],
    );
  }

  /// `Refund completed`
  String get orderRefundCompleted {
    return Intl.message(
      'Refund completed',
      name: 'orderRefundCompleted',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get orderCancelledStatus {
    return Intl.message(
      'Cancelled',
      name: 'orderCancelledStatus',
      desc: '',
      args: [],
    );
  }

  /// `Your Offer`
  String get yourOffer {
    return Intl.message('Your Offer', name: 'yourOffer', desc: '', args: []);
  }

  /// `Description`
  String get description {
    return Intl.message('Description', name: 'description', desc: '', args: []);
  }

  /// `Add to Cart`
  String get addToCart {
    return Intl.message('Add to Cart', name: 'addToCart', desc: '', args: []);
  }

  /// `Cart`
  String get cart {
    return Intl.message('Cart', name: 'cart', desc: '', args: []);
  }

  /// `Only {quantity} available for this product. Please review your cart.`
  String cartMaxAvailableInStock(String quantity) {
    return Intl.message(
      'Only $quantity available for this product. Please review your cart.',
      name: 'cartMaxAvailableInStock',
      desc: '',
      args: [quantity],
    );
  }

  /// `Destination`
  String get destination {
    return Intl.message('Destination', name: 'destination', desc: '', args: []);
  }

  /// `Customer Service`
  String get customerService {
    return Intl.message(
      'Customer Service',
      name: 'customerService',
      desc: '',
      args: [],
    );
  }

  /// `In Progress`
  String get inProgress {
    return Intl.message('In Progress', name: 'inProgress', desc: '', args: []);
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `Product Name`
  String get productName {
    return Intl.message(
      'Product Name',
      name: 'productName',
      desc: '',
      args: [],
    );
  }

  /// `eg. Green cardamom`
  String get examplePremiumIranianSaffron {
    return Intl.message(
      'eg. Green cardamom',
      name: 'examplePremiumIranianSaffron',
      desc: '',
      args: [],
    );
  }

  /// `Selection`
  String get selection {
    return Intl.message('Selection', name: 'selection', desc: '', args: []);
  }

  /// `Select an option`
  String get selectAnOption {
    return Intl.message(
      'Select an option',
      name: 'selectAnOption',
      desc: '',
      args: [],
    );
  }

  /// `Select Category`
  String get selectCategory {
    return Intl.message(
      'Select Category',
      name: 'selectCategory',
      desc: '',
      args: [],
    );
  }

  /// `Select local or rexport`
  String get selectRequestFulfillment {
    return Intl.message(
      'Select local or rexport',
      name: 'selectRequestFulfillment',
      desc: '',
      args: [],
    );
  }

  /// `Price Type`
  String get requestFulfillment {
    return Intl.message(
      'Price Type',
      name: 'requestFulfillment',
      desc: '',
      args: [],
    );
  }

  /// `Local`
  String get requestFulfillmentLocal {
    return Intl.message(
      'Local',
      name: 'requestFulfillmentLocal',
      desc: '',
      args: [],
    );
  }

  /// `Booking`
  String get requestFulfillmentBooking {
    return Intl.message(
      'Booking',
      name: 'requestFulfillmentBooking',
      desc: '',
      args: [],
    );
  }

  /// `Rexport`
  String get requestFulfillmentReexport {
    return Intl.message(
      'Rexport',
      name: 'requestFulfillmentReexport',
      desc: '',
      args: [],
    );
  }

  /// `Category`
  String get category {
    return Intl.message('Category', name: 'category', desc: '', args: []);
  }

  /// `Negotiable`
  String get negotiable {
    return Intl.message('Negotiable', name: 'negotiable', desc: '', args: []);
  }

  /// `Non-Negotiable`
  String get nonNegotiable {
    return Intl.message(
      'Non-Negotiable',
      name: 'nonNegotiable',
      desc: '',
      args: [],
    );
  }

  /// `Offer Price`
  String get offerPrice {
    return Intl.message('Offer Price', name: 'offerPrice', desc: '', args: []);
  }

  /// `Before Discount`
  String get beforeDiscount {
    return Intl.message(
      'Before Discount',
      name: 'beforeDiscount',
      desc: '',
      args: [],
    );
  }

  /// `After Discount`
  String get afterDiscount {
    return Intl.message(
      'After Discount',
      name: 'afterDiscount',
      desc: '',
      args: [],
    );
  }

  /// `Product Price`
  String get productPrice {
    return Intl.message(
      'Product Price',
      name: 'productPrice',
      desc: '',
      args: [],
    );
  }

  /// `Enter product price`
  String get enterProductPrice {
    return Intl.message(
      'Enter product price',
      name: 'enterProductPrice',
      desc: '',
      args: [],
    );
  }

  /// `Target Price`
  String get targetPrice {
    return Intl.message(
      'Target Price',
      name: 'targetPrice',
      desc: '',
      args: [],
    );
  }

  /// `Target price per {unit}`
  String targetPricePerUnit(String unit) {
    return Intl.message(
      'Target price per $unit',
      name: 'targetPricePerUnit',
      desc: '',
      args: [unit],
    );
  }

  /// `Target price per unit`
  String get targetPricePerUnitGeneric {
    return Intl.message(
      'Target price per unit',
      name: 'targetPricePerUnitGeneric',
      desc: '',
      args: [],
    );
  }

  /// `Ad details`
  String get adDetails {
    return Intl.message('Ad details', name: 'adDetails', desc: '', args: []);
  }

  /// `Enter your target price`
  String get enterYourTargetPrice {
    return Intl.message(
      'Enter your target price',
      name: 'enterYourTargetPrice',
      desc: '',
      args: [],
    );
  }

  /// `Specify required specifications`
  String get specifyRequiredSpecifications {
    return Intl.message(
      'Specify required specifications',
      name: 'specifyRequiredSpecifications',
      desc: '',
      args: [],
    );
  }

  /// `Product Images`
  String get productImages {
    return Intl.message(
      'Product Images',
      name: 'productImages',
      desc: '',
      args: [],
    );
  }

  /// `Tap to upload image or video`
  String get tapToUploadImageOrVideo {
    return Intl.message(
      'Tap to upload image or video',
      name: 'tapToUploadImageOrVideo',
      desc: '',
      args: [],
    );
  }

  /// `jpg, png, mp4 (max {maxSize} MB for video)`
  String imageVideoFormatsHint(int maxSize) {
    return Intl.message(
      'jpg, png, mp4 (max $maxSize MB for video)',
      name: 'imageVideoFormatsHint',
      desc: '',
      args: [maxSize],
    );
  }

  /// `Selected Media ({count})`
  String selectedMedia(String count) {
    return Intl.message(
      'Selected Media ($count)',
      name: 'selectedMedia',
      desc: '',
      args: [count],
    );
  }

  /// `Product Documents`
  String get productDocuments {
    return Intl.message(
      'Product Documents',
      name: 'productDocuments',
      desc: '',
      args: [],
    );
  }

  /// `Tap to upload image or file`
  String get tapToUploadImageOrFile {
    return Intl.message(
      'Tap to upload image or file',
      name: 'tapToUploadImageOrFile',
      desc: '',
      args: [],
    );
  }

  /// `JPG, PNG, PDF, DOC, DOCX, XLS, PPT`
  String get documentFormatsHint {
    return Intl.message(
      'JPG, PNG, PDF, DOC, DOCX, XLS, PPT',
      name: 'documentFormatsHint',
      desc: '',
      args: [],
    );
  }

  /// `Selected Documents ({count})`
  String selectedDocuments(String count) {
    return Intl.message(
      'Selected Documents ($count)',
      name: 'selectedDocuments',
      desc: '',
      args: [count],
    );
  }

  /// `Country of Origin`
  String get countryOfOrigin {
    return Intl.message(
      'Country of Origin',
      name: 'countryOfOrigin',
      desc: '',
      args: [],
    );
  }

  /// `Exporting Country`
  String get bookingExportingCountry {
    return Intl.message(
      'Exporting Country',
      name: 'bookingExportingCountry',
      desc: '',
      args: [],
    );
  }

  /// `Loading Port`
  String get loadingPort {
    return Intl.message(
      'Loading Port',
      name: 'loadingPort',
      desc: '',
      args: [],
    );
  }

  /// `Destination Country`
  String get destinationCountry {
    return Intl.message(
      'Destination Country',
      name: 'destinationCountry',
      desc: '',
      args: [],
    );
  }

  /// `Destination Port`
  String get destinationPort {
    return Intl.message(
      'Destination Port',
      name: 'destinationPort',
      desc: '',
      args: [],
    );
  }

  /// `Required Delivery Date`
  String get requiredDeliveryDate {
    return Intl.message(
      'Required Delivery Date',
      name: 'requiredDeliveryDate',
      desc: '',
      args: [],
    );
  }

  /// `Enter Date`
  String get enterDate {
    return Intl.message('Enter Date', name: 'enterDate', desc: '', args: []);
  }

  /// `Offer Duration`
  String get offerDuration {
    return Intl.message(
      'Offer Duration',
      name: 'offerDuration',
      desc: '',
      args: [],
    );
  }

  /// `Enter offer duration in days`
  String get enterOfferDurationInDays {
    return Intl.message(
      'Enter offer duration in days',
      name: 'enterOfferDurationInDays',
      desc: '',
      args: [],
    );
  }

  /// `Shipping Duration (days)`
  String get shippingDurationDays {
    return Intl.message(
      'Shipping Duration (days)',
      name: 'shippingDurationDays',
      desc: '',
      args: [],
    );
  }

  /// `Enter shipping duration in days`
  String get enterShippingDurationInDays {
    return Intl.message(
      'Enter shipping duration in days',
      name: 'enterShippingDurationInDays',
      desc: '',
      args: [],
    );
  }

  /// `Delivery Time (days)`
  String get deliveryTimeDays {
    return Intl.message(
      'Delivery Time (days)',
      name: 'deliveryTimeDays',
      desc: '',
      args: [],
    );
  }

  /// `Enter delivery time in days`
  String get enterDeliveryTimeInDays {
    return Intl.message(
      'Enter delivery time in days',
      name: 'enterDeliveryTimeInDays',
      desc: '',
      args: [],
    );
  }

  /// `Publish`
  String get publish {
    return Intl.message('Publish', name: 'publish', desc: '', args: []);
  }

  /// `Highlight Ad`
  String get highlightAd {
    return Intl.message(
      'Highlight Ad',
      name: 'highlightAd',
      desc: '',
      args: [],
    );
  }

  /// `Highlight your ad to appear at the top of search results and get more views`
  String get highlightAdDescription {
    return Intl.message(
      'Highlight your ad to appear at the top of search results and get more views',
      name: 'highlightAdDescription',
      desc: '',
      args: [],
    );
  }

  /// `199 AED`
  String get highlightAdOldPrice {
    return Intl.message(
      '199 AED',
      name: 'highlightAdOldPrice',
      desc: '',
      args: [],
    );
  }

  /// `99 AED/month`
  String get highlightAdNewPrice {
    return Intl.message(
      '99 AED/month',
      name: 'highlightAdNewPrice',
      desc: '',
      args: [],
    );
  }

  /// `Gallery`
  String get gallery {
    return Intl.message('Gallery', name: 'gallery', desc: '', args: []);
  }

  /// `Camera`
  String get camera {
    return Intl.message('Camera', name: 'camera', desc: '', args: []);
  }

  /// `Add a photo`
  String get chooseImageSource {
    return Intl.message(
      'Add a photo',
      name: 'chooseImageSource',
      desc: '',
      args: [],
    );
  }

  /// `Take a new photo or choose one from your gallery`
  String get chooseImageSourceHint {
    return Intl.message(
      'Take a new photo or choose one from your gallery',
      name: 'chooseImageSourceHint',
      desc: '',
      args: [],
    );
  }

  /// `Take photo`
  String get takePhoto {
    return Intl.message('Take photo', name: 'takePhoto', desc: '', args: []);
  }

  /// `Use the camera to capture the product`
  String get takePhotoHint {
    return Intl.message(
      'Use the camera to capture the product',
      name: 'takePhotoHint',
      desc: '',
      args: [],
    );
  }

  /// `Choose from gallery`
  String get chooseFromGallery {
    return Intl.message(
      'Choose from gallery',
      name: 'chooseFromGallery',
      desc: '',
      args: [],
    );
  }

  /// `Pick an existing image from your device`
  String get chooseFromGalleryHint {
    return Intl.message(
      'Pick an existing image from your device',
      name: 'chooseFromGalleryHint',
      desc: '',
      args: [],
    );
  }

  /// `Video`
  String get video {
    return Intl.message('Video', name: 'video', desc: '', args: []);
  }

  /// `Files`
  String get files {
    return Intl.message('Files', name: 'files', desc: '', args: []);
  }

  /// `Please login to publish your ad.`
  String get pleaseLoginToPublish {
    return Intl.message(
      'Please login to publish your ad.',
      name: 'pleaseLoginToPublish',
      desc: '',
      args: [],
    );
  }

  /// `Please complete origin and destination details.`
  String get completeOriginDestination {
    return Intl.message(
      'Please complete origin and destination details.',
      name: 'completeOriginDestination',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid price greater than zero.`
  String get enterValidPrice {
    return Intl.message(
      'Please enter a valid price greater than zero.',
      name: 'enterValidPrice',
      desc: '',
      args: [],
    );
  }

  /// `Please select a currency.`
  String get selectCurrency {
    return Intl.message(
      'Please select a currency.',
      name: 'selectCurrency',
      desc: '',
      args: [],
    );
  }

  /// `Ad published successfully.`
  String get adPublishedSuccessfully {
    return Intl.message(
      'Ad published successfully.',
      name: 'adPublishedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Your ad was submitted for review successfully.`
  String get adSubmittedForReview {
    return Intl.message(
      'Your ad was submitted for review successfully.',
      name: 'adSubmittedForReview',
      desc: '',
      args: [],
    );
  }

  /// `Your ad was received. Video and photos are uploading now.`
  String get adReceivedUploadingMedia {
    return Intl.message(
      'Your ad was received. Video and photos are uploading now.',
      name: 'adReceivedUploadingMedia',
      desc: '',
      args: [],
    );
  }

  /// `Please wait until publishing finishes. Do not close the app.`
  String get publishPleaseWait {
    return Intl.message(
      'Please wait until publishing finishes. Do not close the app.',
      name: 'publishPleaseWait',
      desc: '',
      args: [],
    );
  }

  /// `Creating the ad`
  String get publishStepCreatingAd {
    return Intl.message(
      'Creating the ad',
      name: 'publishStepCreatingAd',
      desc: '',
      args: [],
    );
  }

  /// `Preparing photos…`
  String get publishStepPreparingImages {
    return Intl.message(
      'Preparing photos…',
      name: 'publishStepPreparingImages',
      desc: '',
      args: [],
    );
  }

  /// `Uploading photos…`
  String get publishStepUploadingImages {
    return Intl.message(
      'Uploading photos…',
      name: 'publishStepUploadingImages',
      desc: '',
      args: [],
    );
  }

  /// `Preparing video… {percent}%`
  String publishStepPreparingVideo(int percent) {
    return Intl.message(
      'Preparing video… $percent%',
      name: 'publishStepPreparingVideo',
      desc: '',
      args: [percent],
    );
  }

  /// `Uploading video…`
  String get publishStepUploadingVideo {
    return Intl.message(
      'Uploading video…',
      name: 'publishStepUploadingVideo',
      desc: '',
      args: [],
    );
  }

  /// `Uploading files…`
  String get publishStepUploadingDocuments {
    return Intl.message(
      'Uploading files…',
      name: 'publishStepUploadingDocuments',
      desc: '',
      args: [],
    );
  }

  /// `Finishing…`
  String get publishStepFinishing {
    return Intl.message(
      'Finishing…',
      name: 'publishStepFinishing',
      desc: '',
      args: [],
    );
  }

  /// `Publishing your ad`
  String get publishProgressTitle {
    return Intl.message(
      'Publishing your ad',
      name: 'publishProgressTitle',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get publishProgressDone {
    return Intl.message(
      'Done',
      name: 'publishProgressDone',
      desc: '',
      args: [],
    );
  }

  /// `Uploading ad media`
  String get adUploadNotificationTitle {
    return Intl.message(
      'Uploading ad media',
      name: 'adUploadNotificationTitle',
      desc: '',
      args: [],
    );
  }

  /// `Compressing and uploading in the background`
  String get adUploadNotificationText {
    return Intl.message(
      'Compressing and uploading in the background',
      name: 'adUploadNotificationText',
      desc: '',
      args: [],
    );
  }

  /// `Compressing photos…`
  String get adUploadProgressCompressingImages {
    return Intl.message(
      'Compressing photos…',
      name: 'adUploadProgressCompressingImages',
      desc: '',
      args: [],
    );
  }

  /// `Uploading photos…`
  String get adUploadProgressUploadingImages {
    return Intl.message(
      'Uploading photos…',
      name: 'adUploadProgressUploadingImages',
      desc: '',
      args: [],
    );
  }

  /// `Compressing video… {percent}%`
  String adUploadProgressCompressingVideo(int percent) {
    return Intl.message(
      'Compressing video… $percent%',
      name: 'adUploadProgressCompressingVideo',
      desc: '',
      args: [percent],
    );
  }

  /// `Uploading video…`
  String get adUploadProgressUploadingVideo {
    return Intl.message(
      'Uploading video…',
      name: 'adUploadProgressUploadingVideo',
      desc: '',
      args: [],
    );
  }

  /// `Attaching media to your ad…`
  String get adUploadProgressAttachingMedia {
    return Intl.message(
      'Attaching media to your ad…',
      name: 'adUploadProgressAttachingMedia',
      desc: '',
      args: [],
    );
  }

  /// `Media upload complete`
  String get adUploadProgressDone {
    return Intl.message(
      'Media upload complete',
      name: 'adUploadProgressDone',
      desc: '',
      args: [],
    );
  }

  /// `Failed to upload ad "{name}". Please try again.`
  String adBackgroundUploadFailed(String name) {
    return Intl.message(
      'Failed to upload ad "$name". Please try again.',
      name: 'adBackgroundUploadFailed',
      desc: '',
      args: [name],
    );
  }

  /// `Failed to upload your ad. Please try again.`
  String get adBackgroundUploadFailedGeneric {
    return Intl.message(
      'Failed to upload your ad. Please try again.',
      name: 'adBackgroundUploadFailedGeneric',
      desc: '',
      args: [],
    );
  }

  /// `Ad updated successfully.`
  String get adUpdatedSuccessfully {
    return Intl.message(
      'Ad updated successfully.',
      name: 'adUpdatedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Request published successfully.`
  String get requestPublishedSuccessfully {
    return Intl.message(
      'Request published successfully.',
      name: 'requestPublishedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Video file not found. Please try again.`
  String get videoFileNotFound {
    return Intl.message(
      'Video file not found. Please try again.',
      name: 'videoFileNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Video size is {sizeMb} MB. Maximum allowed size is {maxMb} MB.`
  String videoSizeExceeded(String sizeMb, int maxMb) {
    return Intl.message(
      'Video size is $sizeMb MB. Maximum allowed size is $maxMb MB.',
      name: 'videoSizeExceeded',
      desc: '',
      args: [sizeMb, maxMb],
    );
  }

  /// `Compressing video...`
  String get compressingVideo {
    return Intl.message(
      'Compressing video...',
      name: 'compressingVideo',
      desc: '',
      args: [],
    );
  }

  /// `Ton`
  String get unitTon {
    return Intl.message('Ton', name: 'unitTon', desc: '', args: []);
  }

  /// `Tons`
  String get unitTons {
    return Intl.message('Tons', name: 'unitTons', desc: '', args: []);
  }

  /// `Gram`
  String get unitGram {
    return Intl.message('Gram', name: 'unitGram', desc: '', args: []);
  }

  /// `Grams`
  String get unitGrams {
    return Intl.message('Grams', name: 'unitGrams', desc: '', args: []);
  }

  /// `Kg`
  String get unitKg {
    return Intl.message('Kg', name: 'unitKg', desc: '', args: []);
  }

  /// `Kg`
  String get unitKilograms {
    return Intl.message('Kg', name: 'unitKilograms', desc: '', args: []);
  }

  /// `Piece`
  String get unitPiece {
    return Intl.message('Piece', name: 'unitPiece', desc: '', args: []);
  }

  /// `Pieces`
  String get unitPieces {
    return Intl.message('Pieces', name: 'unitPieces', desc: '', args: []);
  }

  /// `Carton`
  String get unitCarton {
    return Intl.message('Carton', name: 'unitCarton', desc: '', args: []);
  }

  /// `Bag`
  String get unitBag {
    return Intl.message('Bag', name: 'unitBag', desc: '', args: []);
  }

  /// `Dozen`
  String get unitDozen {
    return Intl.message('Dozen', name: 'unitDozen', desc: '', args: []);
  }

  /// `Dozens`
  String get unitDozens {
    return Intl.message('Dozens', name: 'unitDozens', desc: '', args: []);
  }

  /// `Box`
  String get unitBox {
    return Intl.message('Box', name: 'unitBox', desc: '', args: []);
  }

  /// `Boxes`
  String get unitBoxes {
    return Intl.message('Boxes', name: 'unitBoxes', desc: '', args: []);
  }

  /// `Liter`
  String get unitLiter {
    return Intl.message('Liter', name: 'unitLiter', desc: '', args: []);
  }

  /// `Liters`
  String get unitLiters {
    return Intl.message('Liters', name: 'unitLiters', desc: '', args: []);
  }

  /// `Packet`
  String get unitPacket {
    return Intl.message('Packet', name: 'unitPacket', desc: '', args: []);
  }

  /// `Bundle`
  String get unitBundle {
    return Intl.message('Bundle', name: 'unitBundle', desc: '', args: []);
  }

  /// `Drum`
  String get unitDrum {
    return Intl.message('Drum', name: 'unitDrum', desc: '', args: []);
  }

  /// `Bottle`
  String get unitBottle {
    return Intl.message('Bottle', name: 'unitBottle', desc: '', args: []);
  }

  /// `Tin`
  String get unitTin {
    return Intl.message('Tin', name: 'unitTin', desc: '', args: []);
  }

  /// `Sack`
  String get unitSack {
    return Intl.message('Sack', name: 'unitSack', desc: '', args: []);
  }

  /// `Case`
  String get unitCase {
    return Intl.message('Case', name: 'unitCase', desc: '', args: []);
  }

  /// `Pallet`
  String get unitPallet {
    return Intl.message('Pallet', name: 'unitPallet', desc: '', args: []);
  }

  /// `Ml`
  String get unitMl {
    return Intl.message('Ml', name: 'unitMl', desc: '', args: []);
  }

  /// `Jar`
  String get unitJar {
    return Intl.message('Jar', name: 'unitJar', desc: '', args: []);
  }

  /// `Video must be 3 minutes (180 seconds) or less.`
  String get videoMaxDurationSeconds {
    return Intl.message(
      'Video must be 3 minutes (180 seconds) or less.',
      name: 'videoMaxDurationSeconds',
      desc: '',
      args: [],
    );
  }

  /// `You can upload at most 15 images.`
  String get maxProductImagesExceeded {
    return Intl.message(
      'You can upload at most 15 images.',
      name: 'maxProductImagesExceeded',
      desc: '',
      args: [],
    );
  }

  /// `You can upload at most {maxCount} videos.`
  String maxProductVideosExceeded(int maxCount) {
    return Intl.message(
      'You can upload at most $maxCount videos.',
      name: 'maxProductVideosExceeded',
      desc: '',
      args: [maxCount],
    );
  }

  /// `Could not read video duration. Please try another file.`
  String get videoDurationUnreadable {
    return Intl.message(
      'Could not read video duration. Please try another file.',
      name: 'videoDurationUnreadable',
      desc: '',
      args: [],
    );
  }

  /// `Company name is required`
  String get companyNameIsRequired {
    return Intl.message(
      'Company name is required',
      name: 'companyNameIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Trade license number is required`
  String get tradeLicenseNumberIsRequired {
    return Intl.message(
      'Trade license number is required',
      name: 'tradeLicenseNumberIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Address is required`
  String get addressIsRequired {
    return Intl.message(
      'Address is required',
      name: 'addressIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Phone number is required`
  String get phoneNumberIsRequired {
    return Intl.message(
      'Phone number is required',
      name: 'phoneNumberIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Other phone is required`
  String get otherPhoneIsRequired {
    return Intl.message(
      'Other phone is required',
      name: 'otherPhoneIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Email is required`
  String get emailIsRequired {
    return Intl.message(
      'Email is required',
      name: 'emailIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Password is required`
  String get passwordIsRequired {
    return Intl.message(
      'Password is required',
      name: 'passwordIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Password`
  String get confirmPassword {
    return Intl.message(
      'Confirm Password',
      name: 'confirmPassword',
      desc: '',
      args: [],
    );
  }

  /// `Confirm password is required`
  String get confirmPasswordIsRequired {
    return Intl.message(
      'Confirm password is required',
      name: 'confirmPasswordIsRequired',
      desc: '',
      args: [],
    );
  }

  /// `Confirm password must match password`
  String get confirmPasswordMustBeSame {
    return Intl.message(
      'Confirm password must match password',
      name: 'confirmPasswordMustBeSame',
      desc: '',
      args: [],
    );
  }

  /// `Select port`
  String get selectPort {
    return Intl.message('Select port', name: 'selectPort', desc: '', args: []);
  }

  /// `Product Information`
  String get productInformation {
    return Intl.message(
      'Product Information',
      name: 'productInformation',
      desc: '',
      args: [],
    );
  }

  /// `Enter the required specifications in detail...`
  String get enterTheRequiredSpecificationsInDetail {
    return Intl.message(
      'Enter the required specifications in detail...',
      name: 'enterTheRequiredSpecificationsInDetail',
      desc: '',
      args: [],
    );
  }

  /// `Required Quantity`
  String get requiredQuantity {
    return Intl.message(
      'Required Quantity',
      name: 'requiredQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Video selected from gallery`
  String get videoSelectedFromGallery {
    return Intl.message(
      'Video selected from gallery',
      name: 'videoSelectedFromGallery',
      desc: '',
      args: [],
    );
  }

  /// `Image selected from gallery`
  String get imageSelectedFromGallery {
    return Intl.message(
      'Image selected from gallery',
      name: 'imageSelectedFromGallery',
      desc: '',
      args: [],
    );
  }

  /// `Delivery`
  String get delivery {
    return Intl.message('Delivery', name: 'delivery', desc: '', args: []);
  }

  /// `Add New Address`
  String get addNewAddress {
    return Intl.message(
      'Add New Address',
      name: 'addNewAddress',
      desc: '',
      args: [],
    );
  }

  /// `Pickup Date (Optional)`
  String get pickupDateOptional {
    return Intl.message(
      'Pickup Date (Optional)',
      name: 'pickupDateOptional',
      desc: '',
      args: [],
    );
  }

  /// `Publish Request`
  String get publishRequest {
    return Intl.message(
      'Publish Request',
      name: 'publishRequest',
      desc: '',
      args: [],
    );
  }

  /// `Your request will be published and approved suppliers can submit their offers. You will receive a notification when offers arrive.`
  String
  get yourRequestWillBePublishedAndApprovedSuppliersCanSubmitTheirOffersYouWillReceiveANotificationWhenOffersArrive {
    return Intl.message(
      'Your request will be published and approved suppliers can submit their offers. You will receive a notification when offers arrive.',
      name:
          'yourRequestWillBePublishedAndApprovedSuppliersCanSubmitTheirOffersYouWillReceiveANotificationWhenOffersArrive',
      desc: '',
      args: [],
    );
  }

  /// `Add any notes or special requirements... (Optional)`
  String get addAnyNotesOrSpecialRequirementsOptional {
    return Intl.message(
      'Add any notes or special requirements... (Optional)',
      name: 'addAnyNotesOrSpecialRequirementsOptional',
      desc: '',
      args: [],
    );
  }

  /// `Please login to view your ads.`
  String get pleaseLoginToViewYourAds {
    return Intl.message(
      'Please login to view your ads.',
      name: 'pleaseLoginToViewYourAds',
      desc: '',
      args: [],
    );
  }

  /// `Please login to continue.`
  String get pleaseLoginToContinue {
    return Intl.message(
      'Please login to continue.',
      name: 'pleaseLoginToContinue',
      desc: '',
      args: [],
    );
  }

  /// `Please login to create an order.`
  String get pleaseLoginToCreateAnOrder {
    return Intl.message(
      'Please login to create an order.',
      name: 'pleaseLoginToCreateAnOrder',
      desc: '',
      args: [],
    );
  }

  /// `Please login to upload images.`
  String get pleaseLoginToUploadImages {
    return Intl.message(
      'Please login to upload images.',
      name: 'pleaseLoginToUploadImages',
      desc: '',
      args: [],
    );
  }

  /// `Please login to upload videos.`
  String get pleaseLoginToUploadVideos {
    return Intl.message(
      'Please login to upload videos.',
      name: 'pleaseLoginToUploadVideos',
      desc: '',
      args: [],
    );
  }

  /// `Please login to confirm your order.`
  String get pleaseLoginToConfirmYourOrder {
    return Intl.message(
      'Please login to confirm your order.',
      name: 'pleaseLoginToConfirmYourOrder',
      desc: '',
      args: [],
    );
  }

  /// `Please login to view your cart.`
  String get pleaseLoginToViewYourCart {
    return Intl.message(
      'Please login to view your cart.',
      name: 'pleaseLoginToViewYourCart',
      desc: '',
      args: [],
    );
  }

  /// `Please login to view your orders.`
  String get pleaseLoginToViewYourOrders {
    return Intl.message(
      'Please login to view your orders.',
      name: 'pleaseLoginToViewYourOrders',
      desc: '',
      args: [],
    );
  }

  /// `Please login to manage your cart.`
  String get pleaseLoginToManageYourCart {
    return Intl.message(
      'Please login to manage your cart.',
      name: 'pleaseLoginToManageYourCart',
      desc: '',
      args: [],
    );
  }

  /// `Please login to start chat.`
  String get pleaseLoginToStartChat {
    return Intl.message(
      'Please login to start chat.',
      name: 'pleaseLoginToStartChat',
      desc: '',
      args: [],
    );
  }

  /// `Please login to chat with support.`
  String get pleaseLoginToChatWithSupport {
    return Intl.message(
      'Please login to chat with support.',
      name: 'pleaseLoginToChatWithSupport',
      desc: '',
      args: [],
    );
  }

  /// `Reply`
  String get chatReply {
    return Intl.message('Reply', name: 'chatReply', desc: '', args: []);
  }

  /// `Forward`
  String get chatForward {
    return Intl.message('Forward', name: 'chatForward', desc: '', args: []);
  }

  /// `Delete for me`
  String get chatDeleteForMe {
    return Intl.message(
      'Delete for me',
      name: 'chatDeleteForMe',
      desc: '',
      args: [],
    );
  }

  /// `Delete for everyone`
  String get chatDeleteForEveryone {
    return Intl.message(
      'Delete for everyone',
      name: 'chatDeleteForEveryone',
      desc: '',
      args: [],
    );
  }

  /// `This message was deleted`
  String get chatDeletedMessage {
    return Intl.message(
      'This message was deleted',
      name: 'chatDeletedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Forwarded`
  String get chatForwarded {
    return Intl.message(
      'Forwarded',
      name: 'chatForwarded',
      desc: '',
      args: [],
    );
  }

  /// `Reply to`
  String get chatReplyTo {
    return Intl.message('Reply to', name: 'chatReplyTo', desc: '', args: []);
  }

  /// `Messages are end-to-end encrypted`
  String get chatE2eNoticeTitle {
    return Intl.message(
      'Messages are end-to-end encrypted',
      name: 'chatE2eNoticeTitle',
      desc: '',
      args: [],
    );
  }

  /// `Only people in this conversation can read or listen to these messages.`
  String get chatE2eNoticeBody {
    return Intl.message(
      'Only people in this conversation can read or listen to these messages.',
      name: 'chatE2eNoticeBody',
      desc: '',
      args: [],
    );
  }

  /// `Learn more`
  String get chatE2eNoticeReadMore {
    return Intl.message(
      'Learn more',
      name: 'chatE2eNoticeReadMore',
      desc: '',
      args: [],
    );
  }

  /// `City`
  String get city {
    return Intl.message('City', name: 'city', desc: '', args: []);
  }

  /// `Country`
  String get country {
    return Intl.message('Country', name: 'country', desc: '', args: []);
  }

  /// `Edit Address`
  String get editAddress {
    return Intl.message(
      'Edit Address',
      name: 'editAddress',
      desc: '',
      args: [],
    );
  }

  /// `Delete Address`
  String get deleteAddress {
    return Intl.message(
      'Delete Address',
      name: 'deleteAddress',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this address?`
  String get deleteAddressConfirm {
    return Intl.message(
      'Are you sure you want to delete this address?',
      name: 'deleteAddressConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Search or type your city`
  String get searchOrTypeCity {
    return Intl.message(
      'Search or type your city',
      name: 'searchOrTypeCity',
      desc: '',
      args: [],
    );
  }

  /// `Select a country first`
  String get selectCountryFirst {
    return Intl.message(
      'Select a country first',
      name: 'selectCountryFirst',
      desc: '',
      args: [],
    );
  }

  /// `Address Line 1`
  String get addressLine1 {
    return Intl.message(
      'Address Line 1',
      name: 'addressLine1',
      desc: '',
      args: [],
    );
  }

  /// `Enter address line 1`
  String get enterAddressLine1 {
    return Intl.message(
      'Enter address line 1',
      name: 'enterAddressLine1',
      desc: '',
      args: [],
    );
  }

  /// `Address Line 2 (Optional)`
  String get addressLine2Optional {
    return Intl.message(
      'Address Line 2 (Optional)',
      name: 'addressLine2Optional',
      desc: '',
      args: [],
    );
  }

  /// `Enter address line 2 (optional)`
  String get enterAddressLine2Optional {
    return Intl.message(
      'Enter address line 2 (optional)',
      name: 'enterAddressLine2Optional',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `No saved addresses yet.`
  String get noSavedAddresses {
    return Intl.message(
      'No saved addresses yet.',
      name: 'noSavedAddresses',
      desc: '',
      args: [],
    );
  }

  /// `Please select a delivery address.`
  String get selectDeliveryAddress {
    return Intl.message(
      'Please select a delivery address.',
      name: 'selectDeliveryAddress',
      desc: '',
      args: [],
    );
  }

  /// `Payment on delivery`
  String get paymentOnDelivery {
    return Intl.message(
      'Payment on delivery',
      name: 'paymentOnDelivery',
      desc: '',
      args: [],
    );
  }

  /// `Payment is collected automatically when you receive the order. No online payment is required.`
  String get paymentOnDeliveryDescription {
    return Intl.message(
      'Payment is collected automatically when you receive the order. No online payment is required.',
      name: 'paymentOnDeliveryDescription',
      desc: '',
      args: [],
    );
  }

  /// `Visa / Card`
  String get payWithVisa {
    return Intl.message('Visa / Card', name: 'payWithVisa', desc: '', args: []);
  }

  /// `Cash on delivery`
  String get cashOnDelivery {
    return Intl.message(
      'Cash on delivery',
      name: 'cashOnDelivery',
      desc: '',
      args: [],
    );
  }

  /// `Pay with Visa`
  String get payWithVisaButton {
    return Intl.message(
      'Pay with Visa',
      name: 'payWithVisaButton',
      desc: '',
      args: [],
    );
  }

  /// `Continue shopping`
  String get continueShopping {
    return Intl.message(
      'Continue shopping',
      name: 'continueShopping',
      desc: '',
      args: [],
    );
  }

  /// `Online card payment is available for retail orders only.`
  String get retailVisaPaymentHint {
    return Intl.message(
      'Online card payment is available for retail orders only.',
      name: 'retailVisaPaymentHint',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Order`
  String get confirmOrder {
    return Intl.message(
      'Confirm Order',
      name: 'confirmOrder',
      desc: '',
      args: [],
    );
  }

  /// `Search by image`
  String get searchByImage {
    return Intl.message(
      'Search by image',
      name: 'searchByImage',
      desc: '',
      args: [],
    );
  }

  /// `Select an area of the photo to search again.`
  String get imageSearchCropHint {
    return Intl.message(
      'Select an area of the photo to search again.',
      name: 'imageSearchCropHint',
      desc: '',
      args: [],
    );
  }

  /// `Similar products`
  String get imageSearchPeekTitle {
    return Intl.message(
      'Similar products',
      name: 'imageSearchPeekTitle',
      desc: '',
      args: [],
    );
  }

  /// `View results`
  String get imageSearchViewResults {
    return Intl.message(
      'View results',
      name: 'imageSearchViewResults',
      desc: '',
      args: [],
    );
  }

  /// `Subject to reconfirm`
  String get subjectToReconfirm {
    return Intl.message(
      'Subject to reconfirm',
      name: 'subjectToReconfirm',
      desc: '',
      args: [],
    );
  }

  /// `Search Results`
  String get searchResults {
    return Intl.message(
      'Search Results',
      name: 'searchResults',
      desc: '',
      args: [],
    );
  }

  /// `No products found for your search.`
  String get noSearchResults {
    return Intl.message(
      'No products found for your search.',
      name: 'noSearchResults',
      desc: '',
      args: [],
    );
  }

  /// `Suggested names`
  String get suggestedNames {
    return Intl.message(
      'Suggested names',
      name: 'suggestedNames',
      desc: '',
      args: [],
    );
  }

  /// `Identifying the product...`
  String get analyzingImage {
    return Intl.message(
      'Identifying the product...',
      name: 'analyzingImage',
      desc: '',
      args: [],
    );
  }

  /// `Our AI is identifying the product from your photo.`
  String get analyzingImageHint {
    return Intl.message(
      'Our AI is identifying the product from your photo.',
      name: 'analyzingImageHint',
      desc: '',
      args: [],
    );
  }

  /// `Our AI recognition system identified your product as {name}.`
  String aiIdentifiedProduct(String name) {
    return Intl.message(
      'Our AI recognition system identified your product as $name.',
      name: 'aiIdentifiedProduct',
      desc: '',
      args: [name],
    );
  }

  /// `Our AI recognition system found matching products for your image.`
  String get aiIdentifiedProducts {
    return Intl.message(
      'Our AI recognition system found matching products for your image.',
      name: 'aiIdentifiedProducts',
      desc: '',
      args: [],
    );
  }

  /// `Did you mean "{name}"? Showing results for the corrected name.`
  String aiCorrectedSearch(String name) {
    return Intl.message(
      'Did you mean "$name"? Showing results for the corrected name.',
      name: 'aiCorrectedSearch',
      desc: '',
      args: [name],
    );
  }

  /// `We currently do not have this product, but your request was noted. Please try searching again in about an hour and we will try to stock it.`
  String get productNotInCatalogNoted {
    return Intl.message(
      'We currently do not have this product, but your request was noted. Please try searching again in about an hour and we will try to stock it.',
      name: 'productNotInCatalogNoted',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retry {
    return Intl.message('Retry', name: 'retry', desc: '', args: []);
  }

  /// `Search again with AI`
  String get searchAgain {
    return Intl.message(
      'Search again with AI',
      name: 'searchAgain',
      desc: '',
      args: [],
    );
  }

  /// `Search history`
  String get searchHistory {
    return Intl.message(
      'Search history',
      name: 'searchHistory',
      desc: '',
      args: [],
    );
  }

  /// `Your recent searches will appear here.`
  String get searchHistoryEmpty {
    return Intl.message(
      'Your recent searches will appear here.',
      name: 'searchHistoryEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Saved search results are no longer available.`
  String get searchHistoryNotFound {
    return Intl.message(
      'Saved search results are no longer available.',
      name: 'searchHistoryNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Upload profile photo`
  String get uploadProfilePhoto {
    return Intl.message(
      'Upload profile photo',
      name: 'uploadProfilePhoto',
      desc: '',
      args: [],
    );
  }

  /// `Clear all`
  String get clearAll {
    return Intl.message('Clear all', name: 'clearAll', desc: '', args: []);
  }

  /// `Just now`
  String get justNow {
    return Intl.message('Just now', name: 'justNow', desc: '', args: []);
  }

  /// `1 second ago`
  String get oneSecondAgo {
    return Intl.message(
      '1 second ago',
      name: 'oneSecondAgo',
      desc: '',
      args: [],
    );
  }

  /// `{count} seconds ago`
  String secondsAgo(int count) {
    return Intl.message(
      '$count seconds ago',
      name: 'secondsAgo',
      desc: '',
      args: [count],
    );
  }

  /// `1 minute ago`
  String get oneMinuteAgo {
    return Intl.message(
      '1 minute ago',
      name: 'oneMinuteAgo',
      desc: '',
      args: [],
    );
  }

  /// `{count} minutes ago`
  String minutesAgo(int count) {
    return Intl.message(
      '$count minutes ago',
      name: 'minutesAgo',
      desc: '',
      args: [count],
    );
  }

  /// `1 hour ago`
  String get oneHourAgo {
    return Intl.message('1 hour ago', name: 'oneHourAgo', desc: '', args: []);
  }

  /// `{count} hours ago`
  String hoursAgoRelative(int count) {
    return Intl.message(
      '$count hours ago',
      name: 'hoursAgoRelative',
      desc: '',
      args: [count],
    );
  }

  /// `1 day ago`
  String get oneDayAgo {
    return Intl.message('1 day ago', name: 'oneDayAgo', desc: '', args: []);
  }

  /// `{days} days ago`
  String daysAgo(Object days) {
    return Intl.message(
      '$days days ago',
      name: 'daysAgo',
      desc: '',
      args: [days],
    );
  }

  /// `1 week ago`
  String get oneWeekAgo {
    return Intl.message('1 week ago', name: 'oneWeekAgo', desc: '', args: []);
  }

  /// `{count} weeks ago`
  String weeksAgo(int count) {
    return Intl.message(
      '$count weeks ago',
      name: 'weeksAgo',
      desc: '',
      args: [count],
    );
  }

  /// `1 month ago`
  String get oneMonthAgo {
    return Intl.message('1 month ago', name: 'oneMonthAgo', desc: '', args: []);
  }

  /// `2 months ago`
  String get twoMonthsAgo {
    return Intl.message(
      '2 months ago',
      name: 'twoMonthsAgo',
      desc: '',
      args: [],
    );
  }

  /// `{count} months ago`
  String monthsAgo(int count) {
    return Intl.message(
      '$count months ago',
      name: 'monthsAgo',
      desc: '',
      args: [count],
    );
  }

  /// `1 year ago`
  String get oneYearAgo {
    return Intl.message('1 year ago', name: 'oneYearAgo', desc: '', args: []);
  }

  /// `{count} years ago`
  String yearsAgo(int count) {
    return Intl.message(
      '$count years ago',
      name: 'yearsAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{minutes} min ago`
  String sinceMinutesAgo(Object minutes) {
    return Intl.message(
      '$minutes min ago',
      name: 'sinceMinutesAgo',
      desc: '',
      args: [minutes],
    );
  }

  /// `Delivery emirate`
  String get deliveryEmirate {
    return Intl.message(
      'Delivery emirate',
      name: 'deliveryEmirate',
      desc: '',
      args: [],
    );
  }

  /// `Select delivery emirate`
  String get selectDeliveryEmirate {
    return Intl.message(
      'Select delivery emirate',
      name: 'selectDeliveryEmirate',
      desc: '',
      args: [],
    );
  }

  /// `Additional shipping fees may apply if products weigh more than 10 kg. Each kg above 10 kg is AED 2; the first 10 kg are free.`
  String get domesticShippingWeightDisclaimer {
    return Intl.message(
      'Additional shipping fees may apply if products weigh more than 10 kg. Each kg above 10 kg is AED 2; the first 10 kg are free.',
      name: 'domesticShippingWeightDisclaimer',
      desc: '',
      args: [],
    );
  }

  /// `Room / unit number`
  String get retailRoomOrUnitNumber {
    return Intl.message(
      'Room / unit number',
      name: 'retailRoomOrUnitNumber',
      desc: '',
      args: [],
    );
  }

  /// `Enter room or unit number`
  String get enterRetailRoomOrUnitNumber {
    return Intl.message(
      'Enter room or unit number',
      name: 'enterRetailRoomOrUnitNumber',
      desc: '',
      args: [],
    );
  }

  /// `Building name`
  String get retailBuildingName {
    return Intl.message(
      'Building name',
      name: 'retailBuildingName',
      desc: '',
      args: [],
    );
  }

  /// `Enter building name`
  String get enterRetailBuildingName {
    return Intl.message(
      'Enter building name',
      name: 'enterRetailBuildingName',
      desc: '',
      args: [],
    );
  }

  /// `Additional shipping fees may apply if products weigh more than 10 kg. Each kg above 10 kg is AED 2; the first 10 kg are free.`
  String get retailAddressExcessWeightHint {
    return Intl.message(
      'Additional shipping fees may apply if products weigh more than 10 kg. Each kg above 10 kg is AED 2; the first 10 kg are free.',
      name: 'retailAddressExcessWeightHint',
      desc: '',
      args: [],
    );
  }

  /// `Delivery Method`
  String get deliveryMethod {
    return Intl.message(
      'Delivery Method',
      name: 'deliveryMethod',
      desc: '',
      args: [],
    );
  }

  /// `Self Pickup`
  String get selfPickup {
    return Intl.message('Self Pickup', name: 'selfPickup', desc: '', args: []);
  }

  /// `We will deliver to your address`
  String get deliveryToAddressHint {
    return Intl.message(
      'We will deliver to your address',
      name: 'deliveryToAddressHint',
      desc: '',
      args: [],
    );
  }

  /// `Pick up from our store`
  String get selfPickupHint {
    return Intl.message(
      'Pick up from our store',
      name: 'selfPickupHint',
      desc: '',
      args: [],
    );
  }

  /// `Your Cart`
  String get yourCart {
    return Intl.message('Your Cart', name: 'yourCart', desc: '', args: []);
  }

  /// `Edit Cart`
  String get editCart {
    return Intl.message('Edit Cart', name: 'editCart', desc: '', args: []);
  }

  /// `{count} Items`
  String cartItemsCount(int count) {
    return Intl.message(
      '$count Items',
      name: 'cartItemsCount',
      desc: '',
      args: [count],
    );
  }

  /// `Order Summary`
  String get orderSummary {
    return Intl.message(
      'Order Summary',
      name: 'orderSummary',
      desc: '',
      args: [],
    );
  }

  /// `Delivery Fee`
  String get deliveryFee {
    return Intl.message(
      'Delivery Fee',
      name: 'deliveryFee',
      desc: '',
      args: [],
    );
  }

  /// `VAT (5%)`
  String get vatFivePercent {
    return Intl.message('VAT (5%)', name: 'vatFivePercent', desc: '', args: []);
  }

  /// `Free`
  String get free {
    return Intl.message('Free', name: 'free', desc: '', args: []);
  }

  /// `I agree to the `
  String get agreeToTermsPrefix {
    return Intl.message(
      'I agree to the ',
      name: 'agreeToTermsPrefix',
      desc: '',
      args: [],
    );
  }

  /// `Please accept the terms and privacy policy.`
  String get mustAcceptTermsAndPrivacy {
    return Intl.message(
      'Please accept the terms and privacy policy.',
      name: 'mustAcceptTermsAndPrivacy',
      desc: '',
      args: [],
    );
  }

  /// `Add Shipping Ad`
  String get addShippingAd {
    return Intl.message(
      'Add Shipping Ad',
      name: 'addShippingAd',
      desc: '',
      args: [],
    );
  }

  /// `Edit Shipping Ad`
  String get editShippingAd {
    return Intl.message(
      'Edit Shipping Ad',
      name: 'editShippingAd',
      desc: '',
      args: [],
    );
  }

  /// `From day`
  String get fromDay {
    return Intl.message('From day', name: 'fromDay', desc: '', args: []);
  }

  /// `To day`
  String get toDay {
    return Intl.message('To day', name: 'toDay', desc: '', args: []);
  }

  /// `day`
  String get dayUnit {
    return Intl.message('day', name: 'dayUnit', desc: '', args: []);
  }

  /// `Price 20ft`
  String get price20ftLabel {
    return Intl.message(
      'Price 20ft',
      name: 'price20ftLabel',
      desc: '',
      args: [],
    );
  }

  /// `Price 40ft`
  String get price40ftLabel {
    return Intl.message(
      'Price 40ft',
      name: 'price40ftLabel',
      desc: '',
      args: [],
    );
  }

  /// `Enter details`
  String get enterDetails {
    return Intl.message(
      'Enter details',
      name: 'enterDetails',
      desc: '',
      args: [],
    );
  }

  /// `Details`
  String get details {
    return Intl.message('Details', name: 'details', desc: '', args: []);
  }

  /// `Saved successfully`
  String get savedSuccessfully {
    return Intl.message(
      'Saved successfully',
      name: 'savedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `No shipping offers`
  String get noShippingOffers {
    return Intl.message(
      'No shipping offers',
      name: 'noShippingOffers',
      desc: '',
      args: [],
    );
  }

  /// `Delete ad?`
  String get deleteAdConfirmTitle {
    return Intl.message(
      'Delete ad?',
      name: 'deleteAdConfirmTitle',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete "{name}"? This action cannot be undone.`
  String deleteAdConfirmMessage(String name) {
    return Intl.message(
      'Are you sure you want to delete "$name"? This action cannot be undone.',
      name: 'deleteAdConfirmMessage',
      desc: '',
      args: [name],
    );
  }

  /// `Ad deleted successfully.`
  String get adDeletedSuccessfully {
    return Intl.message(
      'Ad deleted successfully.',
      name: 'adDeletedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Product id is missing.`
  String get productIdMissing {
    return Intl.message(
      'Product id is missing.',
      name: 'productIdMissing',
      desc: '',
      args: [],
    );
  }

  /// `Delete this shipping ad?`
  String get deleteShippingAdConfirm {
    return Intl.message(
      'Delete this shipping ad?',
      name: 'deleteShippingAdConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Deleted successfully`
  String get deletedSuccessfully {
    return Intl.message(
      'Deleted successfully',
      name: 'deletedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Please ensure the entered data is correct. Any changes to shipping company data will be reviewed before approval.`
  String get shippingProfileReviewNote {
    return Intl.message(
      'Please ensure the entered data is correct. Any changes to shipping company data will be reviewed before approval.',
      name: 'shippingProfileReviewNote',
      desc: '',
      args: [],
    );
  }

  /// `Current ads`
  String get currentAds {
    return Intl.message('Current ads', name: 'currentAds', desc: '', args: []);
  }

  /// `Under review`
  String get underReviewAds {
    return Intl.message(
      'Under review',
      name: 'underReviewAds',
      desc: '',
      args: [],
    );
  }

  /// `Rejected ads`
  String get rejectedAds {
    return Intl.message(
      'Rejected ads',
      name: 'rejectedAds',
      desc: '',
      args: [],
    );
  }

  /// `Commercial register`
  String get commercialRegister {
    return Intl.message(
      'Commercial register',
      name: 'commercialRegister',
      desc: '',
      args: [],
    );
  }

  /// `Save changes`
  String get saveChanges {
    return Intl.message(
      'Save changes',
      name: 'saveChanges',
      desc: '',
      args: [],
    );
  }

  /// `No details`
  String get noDetailsAvailable {
    return Intl.message(
      'No details',
      name: 'noDetailsAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to your shipping company control panel`
  String get welcomeShippingDashboard {
    return Intl.message(
      'Welcome to your shipping company control panel',
      name: 'welcomeShippingDashboard',
      desc: '',
      args: [],
    );
  }

  /// `Shipping offers`
  String get shippingOffersSection {
    return Intl.message(
      'Shipping offers',
      name: 'shippingOffersSection',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Failed to add product to cart.`
  String get failedToAddProductToCart {
    return Intl.message(
      'Failed to add product to cart.',
      name: 'failedToAddProductToCart',
      desc: '',
      args: [],
    );
  }

  /// `No products found in this category.`
  String get noProductsInCategory {
    return Intl.message(
      'No products found in this category.',
      name: 'noProductsInCategory',
      desc: '',
      args: [],
    );
  }

  /// `Could not compress video below {maxMb} MB. Try a shorter video.`
  String videoCompressFailed(int maxMb) {
    return Intl.message(
      'Could not compress video below $maxMb MB. Try a shorter video.',
      name: 'videoCompressFailed',
      desc: '',
      args: [maxMb],
    );
  }

  /// `Video compressed to {sizeMb} MB.`
  String videoCompressedToMb(String sizeMb) {
    return Intl.message(
      'Video compressed to $sizeMb MB.',
      name: 'videoCompressedToMb',
      desc: '',
      args: [sizeMb],
    );
  }

  /// `Compressing image...`
  String get compressingImage {
    return Intl.message(
      'Compressing image...',
      name: 'compressingImage',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loadingEllipsis {
    return Intl.message(
      'Loading...',
      name: 'loadingEllipsis',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid quantity and price.`
  String get enterValidQuantityAndPrice {
    return Intl.message(
      'Please enter a valid quantity and price.',
      name: 'enterValidQuantityAndPrice',
      desc: '',
      args: [],
    );
  }

  /// `Requested quantity ({requested}) exceeds available quantity ({available}).`
  String requestedQuantityExceedsAvailable(String requested, String available) {
    return Intl.message(
      'Requested quantity ($requested) exceeds available quantity ($available).',
      name: 'requestedQuantityExceedsAvailable',
      desc: '',
      args: [requested, available],
    );
  }

  /// `Maximum order quantity is {quantity}.`
  String maximumOrderQuantityIs(String quantity) {
    return Intl.message(
      'Maximum order quantity is $quantity.',
      name: 'maximumOrderQuantityIs',
      desc: '',
      args: [quantity],
    );
  }

  /// `Minimum order quantity is {quantity}.`
  String minimumOrderQuantityIs(String quantity) {
    return Intl.message(
      'Minimum order quantity is $quantity.',
      name: 'minimumOrderQuantityIs',
      desc: '',
      args: [quantity],
    );
  }

  /// `Quantity cannot exceed the required quantity ({required}).`
  String quantityExceedsRequired(String required) {
    return Intl.message(
      'Quantity cannot exceed the required quantity ($required).',
      name: 'quantityExceedsRequired',
      desc: '',
      args: [required],
    );
  }

  /// `Product added to cart.`
  String get productAddedToCart {
    return Intl.message(
      'Product added to cart.',
      name: 'productAddedToCart',
      desc: '',
      args: [],
    );
  }

  /// `Your cart is empty.`
  String get yourCartIsEmpty {
    return Intl.message(
      'Your cart is empty.',
      name: 'yourCartIsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get refresh {
    return Intl.message('Refresh', name: 'refresh', desc: '', args: []);
  }

  /// `Failed to load cart.`
  String get failedToLoadCart {
    return Intl.message(
      'Failed to load cart.',
      name: 'failedToLoadCart',
      desc: '',
      args: [],
    );
  }

  /// `Failed to remove item from cart.`
  String get failedToRemoveCartItem {
    return Intl.message(
      'Failed to remove item from cart.',
      name: 'failedToRemoveCartItem',
      desc: '',
      args: [],
    );
  }

  /// `Failed to reduce quantity.`
  String get failedToReduceCartQuantity {
    return Intl.message(
      'Failed to reduce quantity.',
      name: 'failedToReduceCartQuantity',
      desc: '',
      args: [],
    );
  }

  /// `Failed to confirm order.`
  String get failedToConfirmOrder {
    return Intl.message(
      'Failed to confirm order.',
      name: 'failedToConfirmOrder',
      desc: '',
      args: [],
    );
  }

  /// `Request owner is missing. Cannot submit offer.`
  String get requestOwnerMissingCannotSubmitOffer {
    return Intl.message(
      'Request owner is missing. Cannot submit offer.',
      name: 'requestOwnerMissingCannotSubmitOffer',
      desc: '',
      args: [],
    );
  }

  /// `Product owner is missing. Cannot submit order.`
  String get productOwnerMissingCannotSubmitOrder {
    return Intl.message(
      'Product owner is missing. Cannot submit order.',
      name: 'productOwnerMissingCannotSubmitOrder',
      desc: '',
      args: [],
    );
  }

  /// `Mute`
  String get muteVideo {
    return Intl.message('Mute', name: 'muteVideo', desc: '', args: []);
  }

  /// `Unmute`
  String get unmuteVideo {
    return Intl.message('Unmute', name: 'unmuteVideo', desc: '', args: []);
  }

  /// `Could not play video`
  String get videoPlaybackFailed {
    return Intl.message(
      'Could not play video',
      name: 'videoPlaybackFailed',
      desc: '',
      args: [],
    );
  }

  /// `Wholesale price`
  String get wholesalePrice {
    return Intl.message(
      'Wholesale price',
      name: 'wholesalePrice',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to add a retail price?`
  String get addRetailPriceQuestion {
    return Intl.message(
      'Do you want to add a retail price?',
      name: 'addRetailPriceQuestion',
      desc: '',
      args: [],
    );
  }

  /// `Retail price`
  String get retailPriceLabel {
    return Intl.message(
      'Retail price',
      name: 'retailPriceLabel',
      desc: '',
      args: [],
    );
  }

  /// `Retail pricing`
  String get retailPricingInfoTitle {
    return Intl.message(
      'Retail pricing',
      name: 'retailPricingInfoTitle',
      desc: '',
      args: [],
    );
  }

  /// `If you add a retail price, this product will appear in its category with the wholesale price, and also in Retail with a separate retail price, unit, and quantity. Buyers can place orders from either channel. Make sure retail rates and fields are valid.`
  String get retailPricingInfoBody {
    return Intl.message(
      'If you add a retail price, this product will appear in its category with the wholesale price, and also in Retail with a separate retail price, unit, and quantity. Buyers can place orders from either channel. Make sure retail rates and fields are valid.',
      name: 'retailPricingInfoBody',
      desc: '',
      args: [],
    );
  }

  /// `Got it`
  String get gotIt {
    return Intl.message('Got it', name: 'gotIt', desc: '', args: []);
  }

  /// `Al-Ras Agent`
  String get aiAssistantTitle {
    return Intl.message(
      'Al-Ras Agent',
      name: 'aiAssistantTitle',
      desc: '',
      args: [],
    );
  }

  String get aiAssistantHubSubtitle {
    return Intl.message(
      'Your smart assistant for Al-Ras Market',
      name: 'aiAssistantHubSubtitle',
      desc: '',
      args: [],
    );
  }

  String get aiAssistantHubHello {
    return Intl.message(
      'Hello! I’m Al-Ras Agent',
      name: 'aiAssistantHubHello',
      desc: '',
      args: [],
    );
  }

  String get aiAssistantHubIntro {
    return Intl.message(
      'You can chat with me or talk to me by voice. I can help you with ads, orders, shipping prices, and more.',
      name: 'aiAssistantHubIntro',
      desc: '',
      args: [],
    );
  }

  String get aiAssistantHowToStart {
    return Intl.message(
      'How would you like to start?',
      name: 'aiAssistantHowToStart',
      desc: '',
      args: [],
    );
  }

  String get aiAssistantChatWithAi {
    return Intl.message(
      'Chat with AI',
      name: 'aiAssistantChatWithAi',
      desc: '',
      args: [],
    );
  }

  String get aiAssistantChatWithAiSubtitle {
    return Intl.message(
      'Type your questions and get instant answers',
      name: 'aiAssistantChatWithAiSubtitle',
      desc: '',
      args: [],
    );
  }

  String get aiAssistantTalkWithAi {
    return Intl.message(
      'Talk with AI',
      name: 'aiAssistantTalkWithAi',
      desc: '',
      args: [],
    );
  }

  String get aiAssistantTalkWithAiSubtitle {
    return Intl.message(
      'Speak with me using your voice',
      name: 'aiAssistantTalkWithAiSubtitle',
      desc: '',
      args: [],
    );
  }

  String get aiAssistantVoiceSetting {
    return Intl.message(
      'AI voice',
      name: 'aiAssistantVoiceSetting',
      desc: '',
      args: [],
    );
  }

  String get aiAssistantVoiceSettingSubtitle {
    return Intl.message(
      'Choose a female or male assistant voice',
      name: 'aiAssistantVoiceSettingSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `AI`
  String get aiAssistantFabLabel {
    return Intl.message('AI', name: 'aiAssistantFabLabel', desc: '', args: []);
  }

  /// `Al-Ras Agent is an AI Agent and can make mistakes.`
  String get aiAssistantSubtitle {
    return Intl.message(
      'Al-Ras Agent is an AI Agent and can make mistakes.',
      name: 'aiAssistantSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Ask about ads, orders, returns, image search…`
  String get aiAssistantHint {
    return Intl.message(
      'Ask about ads, orders, returns, image search…',
      name: 'aiAssistantHint',
      desc: '',
      args: [],
    );
  }

  /// `Replying to`
  String get aiAssistantReplyTo {
    return Intl.message(
      'Replying to',
      name: 'aiAssistantReplyTo',
      desc: '',
      args: [],
    );
  }

  /// `Cancel reply`
  String get aiAssistantCancelReply {
    return Intl.message(
      'Cancel reply',
      name: 'aiAssistantCancelReply',
      desc: '',
      args: [],
    );
  }

  /// `Welcome. I’m Al-Ras Agent. Depending on your account type, I can create ads, update prices and quantities, search and compare products, find cheapest/most expensive listings, check shipping prices to a country, and show your ads, orders, sales, and pending orders. Live chat with support is available from Profile.`
  String get aiAssistantWelcome {
    return Intl.message(
      'Welcome. I’m Al-Ras Agent. Depending on your account type, I can create ads, update prices and quantities, search and compare products, find cheapest/most expensive listings, check shipping prices to a country, and show your ads, orders, sales, and pending orders. Live chat with support is available from Profile.',
      name: 'aiAssistantWelcome',
      desc: '',
      args: [],
    );
  }

  /// `Thinking…`
  String get aiAssistantThinking {
    return Intl.message(
      'Thinking…',
      name: 'aiAssistantThinking',
      desc: '',
      args: [],
    );
  }

  /// `Listening… speak now`
  String get aiAssistantListening {
    return Intl.message(
      'Listening… speak now',
      name: 'aiAssistantListening',
      desc: '',
      args: [],
    );
  }

  /// `AI is correcting your speech…`
  String get aiAssistantVoiceCorrecting {
    return Intl.message(
      'AI is correcting your speech…',
      name: 'aiAssistantVoiceCorrecting',
      desc: '',
      args: [],
    );
  }

  /// `Review the text, then send or cancel`
  String get aiAssistantVoiceHint {
    return Intl.message(
      'Review the text, then send or cancel',
      name: 'aiAssistantVoiceHint',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get aiAssistantVoiceCancel {
    return Intl.message(
      'Cancel',
      name: 'aiAssistantVoiceCancel',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get aiAssistantVoiceSend {
    return Intl.message(
      'Send',
      name: 'aiAssistantVoiceSend',
      desc: '',
      args: [],
    );
  }

  /// `Voice input is not available on this device`
  String get aiAssistantVoiceUnavailable {
    return Intl.message(
      'Voice input is not available on this device',
      name: 'aiAssistantVoiceUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Conversation history`
  String get aiAssistantHistoryTitle {
    return Intl.message(
      'Conversation history',
      name: 'aiAssistantHistoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `Search conversations…`
  String get aiAssistantHistorySearchHint {
    return Intl.message(
      'Search conversations…',
      name: 'aiAssistantHistorySearchHint',
      desc: '',
      args: [],
    );
  }

  /// `No saved conversations yet.`
  String get aiAssistantHistoryEmpty {
    return Intl.message(
      'No saved conversations yet.',
      name: 'aiAssistantHistoryEmpty',
      desc: '',
      args: [],
    );
  }

  /// `No conversations match your search.`
  String get aiAssistantHistoryNoResults {
    return Intl.message(
      'No conversations match your search.',
      name: 'aiAssistantHistoryNoResults',
      desc: '',
      args: [],
    );
  }

  /// `Could not load conversation history.`
  String get aiAssistantHistoryLoadError {
    return Intl.message(
      'Could not load conversation history.',
      name: 'aiAssistantHistoryLoadError',
      desc: '',
      args: [],
    );
  }

  /// `Could not load conversation messages.`
  String get aiAssistantHistoryLoadMessagesError {
    return Intl.message(
      'Could not load conversation messages.',
      name: 'aiAssistantHistoryLoadMessagesError',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get aiAssistantHistoryRetry {
    return Intl.message(
      'Retry',
      name: 'aiAssistantHistoryRetry',
      desc: '',
      args: [],
    );
  }

  /// `Untitled conversation`
  String get aiAssistantHistoryUntitled {
    return Intl.message(
      'Untitled conversation',
      name: 'aiAssistantHistoryUntitled',
      desc: '',
      args: [],
    );
  }

  /// `messages`
  String get aiAssistantHistoryMessages {
    return Intl.message(
      'messages',
      name: 'aiAssistantHistoryMessages',
      desc: '',
      args: [],
    );
  }

  /// `We currently support Arabic and English. We may translate your question internally to understand it, then reply in a supported language.`
  String get aiAssistantUnsupportedLanguage {
    return Intl.message(
      'We currently support Arabic and English. We may translate your question internally to understand it, then reply in a supported language.',
      name: 'aiAssistantUnsupportedLanguage',
      desc: '',
      args: [],
    );
  }

  /// `I can only help with Al Ras Smart topics (accounts, ads, orders, payment, returns). Please ask something about the platform.`
  String get aiAssistantOutOfScope {
    return Intl.message(
      'I can only help with Al Ras Smart topics (accounts, ads, orders, payment, returns). Please ask something about the platform.',
      name: 'aiAssistantOutOfScope',
      desc: '',
      args: [],
    );
  }

  /// `Image search: upload a product photo from the search bar to find similar catalog matches. See “Image-search model training” under Help & Support for details.`
  String get aiAssistantImageSearchHint {
    return Intl.message(
      'Image search: upload a product photo from the search bar to find similar catalog matches. See “Image-search model training” under Help & Support for details.',
      name: 'aiAssistantImageSearchHint',
      desc: '',
      args: [],
    );
  }

  /// `For damaged, expired, or materially different goods: report within 24 business hours of receipt with photos. If support approves, refund is issued within 1 business day.`
  String get aiAssistantReturnPolicyHint {
    return Intl.message(
      'For damaged, expired, or materially different goods: report within 24 business hours of receipt with photos. If support approves, refund is issued within 1 business day.',
      name: 'aiAssistantReturnPolicyHint',
      desc: '',
      args: [],
    );
  }

  /// `Security check`
  String get sensitiveAccessWarningTitle {
    return Intl.message(
      'Security check',
      name: 'sensitiveAccessWarningTitle',
      desc: '',
      args: [],
    );
  }

  /// `Al-Ras Agent is an AI agent that can control important account actions such as changing prices and deleting ads. Security verification is required. Thank you for your patience.`
  String get sensitiveAccessWarningBody {
    return Intl.message(
      'Al-Ras Agent is an AI agent that can control important account actions such as changing prices and deleting ads. Security verification is required. Thank you for your patience.',
      name: 'sensitiveAccessWarningBody',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get sensitiveAccessContinue {
    return Intl.message(
      'Continue',
      name: 'sensitiveAccessContinue',
      desc: '',
      args: [],
    );
  }

  /// `Confirm it’s you`
  String get sensitiveAccessVerifyTitle {
    return Intl.message(
      'Confirm it’s you',
      name: 'sensitiveAccessVerifyTitle',
      desc: '',
      args: [],
    );
  }

  /// `Enter your password to continue`
  String get sensitiveAccessPasswordHint {
    return Intl.message(
      'Enter your password to continue',
      name: 'sensitiveAccessPasswordHint',
      desc: '',
      args: [],
    );
  }

  /// `Verification failed. Please try again.`
  String get sensitiveAccessVerifyFailed {
    return Intl.message(
      'Verification failed. Please try again.',
      name: 'sensitiveAccessVerifyFailed',
      desc: '',
      args: [],
    );
  }

  /// `This account has no password. Enable Face ID / Fingerprint in Profile, or set a password from Change Password, then try again.`
  String get sensitiveAccessPasswordRequired {
    return Intl.message(
      'This account has no password. Enable Face ID / Fingerprint in Profile, or set a password from Change Password, then try again.',
      name: 'sensitiveAccessPasswordRequired',
      desc: '',
      args: [],
    );
  }

  /// `Verify it’s you to open this page`
  String get sensitiveAccessBiometricReason {
    return Intl.message(
      'Verify it’s you to open this page',
      name: 'sensitiveAccessBiometricReason',
      desc: '',
      args: [],
    );
  }

  /// `Image-search model training`
  String get modelTrainingTitle {
    return Intl.message(
      'Image-search model training',
      name: 'modelTrainingTitle',
      desc: '',
      args: [],
    );
  }

  /// `Returns and refunds policy`
  String get returnPolicySectionTitle {
    return Intl.message(
      'Returns and refunds policy',
      name: 'returnPolicySectionTitle',
      desc: '',
      args: [],
    );
  }

  /// `Return requests must be reported within 24 business hours of confirmed receipt, with photos/video showing the issue.`
  String get returnPolicyWindow {
    return Intl.message(
      'Return requests must be reported within 24 business hours of confirmed receipt, with photos/video showing the issue.',
      name: 'returnPolicyWindow',
      desc: '',
      args: [],
    );
  }

  /// `Usually accepted: damaged/spoiled goods, expired goods inconsistent with the listing, materially different product, or clear quantity shortage.`
  String get returnPolicyAccepted {
    return Intl.message(
      'Usually accepted: damaged/spoiled goods, expired goods inconsistent with the listing, materially different product, or clear quantity shortage.',
      name: 'returnPolicyAccepted',
      desc: '',
      args: [],
    );
  }

  /// `Usually not accepted: change of mind without defect, poor storage after delivery, or consuming most of the quantity then requesting a return without a proven defect.`
  String get returnPolicyRejected {
    return Intl.message(
      'Usually not accepted: change of mind without defect, poor storage after delivery, or consuming most of the quantity then requesting a return without a proven defect.',
      name: 'returnPolicyRejected',
      desc: '',
      args: [],
    );
  }

  /// `If support approves the return, funds are refunded within 1 business day of approval.`
  String get returnPolicyRefund {
    return Intl.message(
      'If support approves the return, funds are refunded within 1 business day of approval.',
      name: 'returnPolicyRefund',
      desc: '',
      args: [],
    );
  }

  /// `Online card payment is available for Retail orders only.`
  String get paymentRetailOnline {
    return Intl.message(
      'Online card payment is available for Retail orders only.',
      name: 'paymentRetailOnline',
      desc: '',
      args: [],
    );
  }

  /// `Cash on delivery applies to other deal types according to platform process and the Al Ras team.`
  String get paymentCodAll {
    return Intl.message(
      'Cash on delivery applies to other deal types according to platform process and the Al Ras team.',
      name: 'paymentCodAll',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
