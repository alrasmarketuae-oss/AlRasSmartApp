import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

class NavigationService extends ChangeNotifier {
  // Singleton pattern
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Store the current bottom nav index across screens
  int currentIndex = 0;

  set setCurrentIndex(int index) {
    currentIndex = index;
    notifyListeners(); // Notify listeners when the index changes
  }

 

  // Reset to home when logging out
  void resetToHome() {
    currentIndex = 0; // Reset to home tab
    notifyListeners();
  }

  void resetToFavorites() {
    currentIndex = 1; // Reset to favorites tab
    notifyListeners();
  }

  void resetToPostAds() {
    currentIndex = 2; // Reset to favorites tab
    notifyListeners();
  }
}
