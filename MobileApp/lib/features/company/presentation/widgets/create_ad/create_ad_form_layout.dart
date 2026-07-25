import 'package:flutter/material.dart';

class CreateAdFormLayout {
  CreateAdFormLayout._();

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;
}
