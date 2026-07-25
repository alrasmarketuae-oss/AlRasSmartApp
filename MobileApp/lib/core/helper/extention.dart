import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/constants.dart';

extension Navigation on BuildContext {
  Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushReplacmentNamed(String routeName, {Object? arguments}) =>
      Navigator.of(this).pushReplacementNamed(routeName, arguments: arguments);
  Future<dynamic> pushNamedAndRemoveUntil(
    String routeName, {
    Object? arguments,
    required RoutePredicate predicate,
  }) => Navigator.of(
    this,
  ).pushNamedAndRemoveUntil(routeName, predicate, arguments: arguments);

  void pop() => Navigator.pop(this);
}

// extension ErrorState on BuildContext {
//   void showSnackBar(String message, {bool isError = false}) {
//     // In demo mode, suppress all error messages
//     if (Constants.isDemoMode && isError) {
//       return; // Don't show error snackbars in demo mode
//     }

//     ScaffoldMessenger.of(this).showSnackBar(
//       SnackBar(
//         duration: const Duration(seconds: 3),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         content: Text(
//           message,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 15.sp,
//             fontWeight: FontWeight.w500,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
// }

extension HandleScreenSize on BuildContext {
  double get deviceWidth => MediaQuery.of(this).size.width;
  double get deviceHeight => MediaQuery.of(this).size.height;
}
