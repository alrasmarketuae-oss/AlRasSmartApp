import 'package:flutter/material.dart';

class Global {
  static GlobalKey<NavigatorState> materialKey = GlobalKey<NavigatorState>();
}

void navigateTo(context, widget) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => widget),
  );
}
