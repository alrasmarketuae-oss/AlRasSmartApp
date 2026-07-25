// /// ============================================
// /// 📱 iOS LOCATION HELPER
// /// ============================================
// /// iOS-specific location permission handling
// /// Extracted from location_helper_standalone.dart
// /// ============================================

// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';

// class IOSLocationHelper {
//   // ==========================================
//   // iOS PERMISSION FUNCTIONS
//   // ==========================================

//   /// Open iOS App Settings
//   /// Takes user directly to app settings where they can enable location
//   static Future<void> openAppSettings() async {
//     try {
//       debugPrint('⚙️ [iOS] Opening app settings...');
//       await Geolocator.openAppSettings();
//     } catch (e) {
//       debugPrint('❌ [iOS] Error opening app settings: $e');
//     }
//   }

//   /// Open iOS Location Settings (System Settings → Privacy → Location)
//   static Future<void> openLocationSettings() async {
//     try {
//       debugPrint('⚙️ [iOS] Opening location settings...');
//       await Geolocator.openLocationSettings();
//     } catch (e) {
//       debugPrint('❌ [iOS] Error opening location settings: $e');
//     }
//   }

//   // ==========================================
//   // iOS PERMISSION CHECKING
//   // ==========================================

//   /// Check current iOS location permission status
//   static Future<LocationPermission> checkPermission() async {
//     return await Geolocator.checkPermission();
//   }

//   /// Request location permission from iOS
//   static Future<LocationPermission> requestPermission() async {
//     debugPrint('📍 [iOS] Requesting location permission...');
//     return await Geolocator.requestPermission();
//   }

//   /// Check if location services are enabled on iOS
//   static Future<bool> isLocationServiceEnabled() async {
//     return await Geolocator.isLocationServiceEnabled();
//   }

//   /// Check if location permission is granted
//   static Future<bool> isPermissionGranted() async {
//     LocationPermission permission = await checkPermission();
//     return permission == LocationPermission.whileInUse ||
//         permission == LocationPermission.always;
//   }

//   // ==========================================
//   // iOS COMPLETE PERMISSION HANDLER
//   // ==========================================

//   /// Complete iOS location permission handler
//   /// Handles all cases: denied, permanently denied, disabled services
//   /// Returns Position if successful, null if failed
//   static Future<Position?> getLocationWithIOSPermission(
//     BuildContext context, {
//     bool showDialogs = true,
//     bool autoOpenSettings = true,
//     LocationAccuracy accuracy = LocationAccuracy.high,
//   }) async {
//     // Step 1: Check if location services are enabled
//     bool serviceEnabled = await isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       debugPrint('❌ [iOS] Location services are disabled');

//       if (autoOpenSettings) {
//         debugPrint('⚙️ [iOS] Opening location settings...');
//         await openLocationSettings();
//       }

//       if (showDialogs && context.mounted) {
//         _showIOSLocationDisabledDialog(context, autoOpenSettings);
//       }
//       return null;
//     }

//     // Step 2: Check current permission
//     LocationPermission permission = await checkPermission();
//     debugPrint('📍 [iOS] Current permission: $permission');

//     // Step 3: Request permission if denied
//     if (permission == LocationPermission.denied) {
//       permission = await requestPermission();
//       debugPrint('📍 [iOS] Permission after request: $permission');

//       if (permission == LocationPermission.denied) {
//         debugPrint('❌ [iOS] Permission denied by user');
//         if (showDialogs && context.mounted) {
//           _showIOSPermissionDeniedSnackBar(context);
//         }
//         return null;
//       }
//     }

//     // Step 4: Handle permanently denied (iOS)
//     if (permission == LocationPermission.deniedForever) {
//       debugPrint('❌ [iOS] Permission permanently denied');
//       debugPrint(
//         '⚙️ [iOS] User must enable in Settings → Recovery Plus → Location',
//       );

//       if (autoOpenSettings) {
//         debugPrint('⚙️ [iOS] Opening app settings...');
//         await openAppSettings();
//       }

//       if (showDialogs && context.mounted) {
//         _showIOSPermanentlyDeniedDialog(context, autoOpenSettings);
//       }
//       return null;
//     }

//     // Step 5: Get current position
//     debugPrint('✅ [iOS] Permission granted, getting position...');
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: accuracy,
//       );

//       debugPrint('✅ [iOS] Location obtained successfully');
//       debugPrint('   📍 Latitude: ${position.latitude}');
//       debugPrint('   📍 Longitude: ${position.longitude}');

//       return position;
//     } catch (e) {
//       debugPrint('❌ [iOS] Error getting position: $e');
//       return null;
//     }
//   }

//   // ==========================================
//   // iOS-SPECIFIC DIALOGS
//   // ==========================================

//   /// Show iOS-style dialog for location services disabled
//   static void _showIOSLocationDisabledDialog(
//     BuildContext context,
//     bool autoOpened,
//   ) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.location_off, color: Colors.orange[700]),
//             const SizedBox(width: 10),
//             const Text('Location Services Off'),
//           ],
//         ),
//         content: Text(
//           autoOpened
//               ? 'Location services are disabled. We\'ve opened Settings for you.\n\nEnable Location Services and return to the app.'
//               : 'Location services are disabled. Please enable them in:\n\nSettings → Privacy & Security → Location Services',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//           if (!autoOpened)
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 openLocationSettings();
//               },
//               child: const Text('Open Settings'),
//             ),
//         ],
//       ),
//     );
//   }

//   /// Show iOS-style dialog for permanently denied permission
//   static void _showIOSPermanentlyDeniedDialog(
//     BuildContext context,
//     bool autoOpened,
//   ) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.red[700]),
//             const SizedBox(width: 10),
//             const Text('تفعيل الموقع'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'لتفعيل خدمات الموقع، اتبع الخطوات التالية:',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             SizedBox(height: 16),
//             _buildStep('1️⃣', 'افتح الإعدادات (Settings)'),
//             _buildStep('2️⃣', 'ابحث عن تطبيق "Recovery Plus"'),
//             _buildStep('3️⃣', 'اضغط على "الموقع" (Location)'),
//             _buildStep(
//               '4️⃣',
//               'اختر "أثناء استخدام التطبيق" (While Using the App)',
//             ),
//             _buildStep('5️⃣', 'ارجع للتطبيق'),
//             SizedBox(height: 12),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.orange[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.orange.shade300),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'التطبيق لن يطلب الإذن مرة أخرى، يجب تفعيله من الإعدادات',
//                       style: TextStyle(fontSize: 12, color: Colors.orange[900]),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('إلغاء'),
//           ),
//           ElevatedButton.icon(
//             icon: Icon(Icons.settings),
//             onPressed: () {
//               Navigator.pop(context);
//               openAppSettings();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red[700],
//               foregroundColor: Colors.white,
//             ),
//             label: const Text('فتح الإعدادات'),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build step widget for instructions
//   static Widget _buildStep(String number, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(number, style: TextStyle(fontSize: 16)),
//           SizedBox(width: 8),
//           Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
//         ],
//       ),
//     );
//   }

//   /// Show simple snackbar for denied permission
//   static void _showIOSPermissionDeniedSnackBar(BuildContext context) {
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Location permission denied'),
//           behavior: SnackBarBehavior.floating,
//           duration: Duration(seconds: 3),
//         ),
//       );
//     }
//   }
// }

// // ============================================
// // 📖 iOS USAGE EXAMPLES
// // ============================================

// /*

// // ==========================================
// // Example 1: Simple Button (Auto-Open Settings)
// // ==========================================

// ElevatedButton(
//   onPressed: () async {
//     Position? position = await IOSLocationHelper.getLocationWithIOSPermission(
//       context,
//       autoOpenSettings: true, // Automatically opens settings if needed
//     );
    
//     if (position != null) {
//       print('iOS Location: ${position.latitude}, ${position.longitude}');
//     }
//   },
//   child: const Text('Get Location (iOS)'),
// )


// // ==========================================
// // Example 2: Check Permission Status
// // ==========================================

// bool hasPermission = await IOSLocationHelper.isPermissionGranted();

// if (hasPermission) {
//   print('✅ iOS has location permission');
// } else {
//   print('❌ iOS needs location permission');
// }


// // ==========================================
// // Example 3: Manually Open Settings
// // ==========================================

// // Open app settings (for location permission)
// await IOSLocationHelper.openAppSettings();

// // Open location services settings
// await IOSLocationHelper.openLocationSettings();


// // ==========================================
// // Example 4: Without Auto-Opening Settings
// // ==========================================

// Position? position = await IOSLocationHelper.getLocationWithIOSPermission(
//   context,
//   autoOpenSettings: false, // Don't automatically open settings
//   showDialogs: true,       // Show dialog with manual button
// );


// // ==========================================
// // Example 5: Silent Mode (No UI)
// // ==========================================

// Position? position = await IOSLocationHelper.getLocationWithIOSPermission(
//   context,
//   showDialogs: false,      // No dialogs
//   autoOpenSettings: false, // No auto-open
// );

// if (position == null) {
//   // Handle failure silently
//   print('Could not get location');
// }

// */
