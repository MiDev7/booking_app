import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HolidayProvider extends ChangeNotifier {
  List<String> _holidays = [];

  List<String> get holidays => _holidays;

  HolidayProvider() {
    loadHolidays();
  }

  Future<void> loadHolidays() async {
    final prefs = await SharedPreferences.getInstance();
    final holidaysString = prefs.getStringList('holidays') ?? [];
    _holidays = holidaysString;
    notifyListeners();
  }

  Future<void> addHoliday(String holiday) async {
    if (!_holidays.contains(holiday)) {
      _holidays.add(holiday);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('holidays', _holidays);
      notifyListeners();
    }
  }

  Future<void> removeHoliday(String holiday) async {
    if (_holidays.contains(holiday)) {
      _holidays.remove(holiday);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('holidays', _holidays);
      notifyListeners();
    }
  }

  Future<void> clearHolidays() async {
    _holidays.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('holidays');
    notifyListeners();
  }

  Future<bool> isHoliday(String date) async {
    return _holidays.contains(date);
  }
}
