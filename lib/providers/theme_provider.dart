import 'package:booking_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:booking_app/providers/location_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  Color _seedColor = const Color(0xFF18BBB9);
  Color _portLouisColor = const Color(0xFF18BBB9);
  Color _quatreBornesColor = const Color(0xFF18BBB9);

  // Row Color A
  Color _colorA = const Color(0xFF18BBB9);

  // Row Color B
  Color _colorB = const Color(0xFF18BBB9);

  Color get seedColor => _seedColor;
  Color get portLouisColor => _portLouisColor;
  Color get quatreBornesColor => _quatreBornesColor;
  Color get colorA => _colorA;
  Color get colorB => _colorB;

  ThemeProvider() {
    _loadSeedColor();
  }

  Future<void> _loadSeedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final seedColorValue = prefs.getInt('seedColor') ?? 0xFF18BBB9;
    final portLouisColorValue = prefs.getInt('portLouisColor') ?? 0xFF18BBB9;
    final colorAValue = prefs.getInt('colorA') ?? 0xFF18BBB9;
    final colorBValue = prefs.getInt('colorB') ?? 0xFF18BBB9;
    _colorA = Color(colorAValue);
    _colorB = Color(colorBValue);
    final quatreBornesColorValue =
        prefs.getInt('quatreBornesColor') ?? 0xFF18BBB9;
    _portLouisColor = Color(portLouisColorValue);
    _quatreBornesColor = Color(quatreBornesColorValue);
    _seedColor = Color(seedColorValue);
    notifyListeners();
  }

  Future<void> updateSeedColor(Color newColor) async {
    _seedColor = newColor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', newColor.value);

    notifyListeners();
  }

  Future<void> updatePortLouisColor(
      BuildContext context, Color newColor) async {
    _portLouisColor = newColor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('portLouisColor', newColor.value);
    if (Provider.of<LocationProvider>(context, listen: false)
            .selectedLocation ==
        Util.parseLocation('Port-Louis')) {
      await updateSeedColor(newColor);
    }
    notifyListeners();
  }

  Future<void> updateColorA(Color newColor) async {
    _colorA = newColor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorA', newColor.value);
    notifyListeners();
  }

  Future<void> updateColorB(Color newColor) async {
    _colorB = newColor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorB', newColor.value);
    notifyListeners();
  }

  Future<void> resetColorAB() async {
    _colorA = _seedColor.withAlpha(75);
    _colorB = _seedColor.withAlpha(20);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorA', _colorA.value);
    await prefs.setInt('colorB', _colorB.value);
    notifyListeners();
  }

  Future<void> updateQuatreBornesColor(
      BuildContext context, Color newColor) async {
    _quatreBornesColor = newColor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quatreBornesColor', newColor.value);

    if (Provider.of<LocationProvider>(context, listen: false)
            .selectedLocation ==
        Util.parseLocation('Quatre-Bornes')) {
      await updateSeedColor(newColor);
    }
    notifyListeners();
  }

  Future<void> updateColorBasedOnLocation(String location) async {
    Color newColor;
    if (location == 'Port-Louis') {
      newColor = _portLouisColor;
    } else if (location == 'Quatre-Bornes') {
      newColor = _quatreBornesColor;
    } else {
      newColor = _seedColor; // Default color
    }
    _seedColor = newColor;
    // Change only color a and b if location change and that not defined
    if (location != 'Port-Louis' && location != 'Quatre-Bornes') {
      _colorA = _seedColor.withAlpha(75);
      _colorB = _seedColor.withAlpha(20);
    }

    notifyListeners(); // Immediately notify listeners

    // Then persist asynchronously.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', newColor.value);
  }
}
