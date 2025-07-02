import 'package:booking_app/models/public_holidays.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booking_app/utils/database_helper.dart';
import 'package:intl/intl.dart';

class HolidayProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _holidays = [];
  final DateFormat customFormat = DateFormat('dd-MMMM-yyyy');

  List<Map<String, dynamic>> get holidays => _holidays;

  HolidayProvider() {
    loadHolidays();
  }

  Future<void> loadHolidays() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Data
    final savedPublicHolidays = await DatabaseHelper().getPublicHolidays();
    final holidaysString = prefs.getStringList('holidays') ?? [];

    var unSavedPublicHolidays = holidaysString.where((date) => !savedPublicHolidays.any((ph) => ph['date'] == date)).toList();

    for (var unsavedDate in unSavedPublicHolidays) {

      await DatabaseHelper().insertPublicHolidays(publicHolidaysModel(date: DateTime.parse(unsavedDate)));
    }
    _holidays = savedPublicHolidays;
    notifyListeners();
  }

  Future<void> addHoliday(String holiday) async {
    var isHolidayExist = _holidays.any((ph) => ph['date'] == holiday);
    if (!isHolidayExist)  {
      await DatabaseHelper().insertPublicHolidays(publicHolidaysModel(date: DateTime.parse(holiday)));
      _holidays = await DatabaseHelper().getPublicHolidays();
    }
    notifyListeners();
  }

  Future<void> removeHoliday(String holiday) async {
    var isHolidayExist = _holidays.any((ph) => ph['date'] == holiday);
    if (isHolidayExist) {
      int id = _holidays.firstWhere((ph) => ph['date'] == holiday, orElse: () => {})['id'];
      await DatabaseHelper().deletePublicHolidays(id);
      _holidays = await DatabaseHelper().getPublicHolidays();
    }
    notifyListeners();
  }

  Future<void> clearHolidays() async {
    _holidays.clear();
    await DatabaseHelper().deleteAllPublicHolidays();
    notifyListeners();
  }

  Future<bool> isHoliday(String date) async {
    return _holidays.contains(date);
  }
}
