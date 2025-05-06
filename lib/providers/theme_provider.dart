import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  Color _seedColor = const Color(0xFF18BBB9);
  Color get seedColor => _seedColor;

  ThemeProvider() {
    _loadSeedColor();
  }

  Future<void> _loadSeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final seedColorValue = prefs.getInt('seedColor') ?? 0xFF18BBB9;
    _seedColor = Color(seedColorValue);
    notifyListeners();
  }

  Future<void> updateSeedColor(Color newColor) async {
    _seedColor = newColor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', newColor.value);
    notifyListeners();
  }
}
