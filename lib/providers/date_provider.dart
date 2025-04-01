import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateProvider extends ChangeNotifier {
  final DateFormat format = DateFormat('dd MMMM yyyy');

  DateTime _currentDate = DateTime.now();

  int _weekNumber = 0;

  int get currentWeekNumber {
    final firstDayOfYear = DateTime(_currentDate.year, 1, 1);
    final pastDaysOfYear = _currentDate.difference(firstDayOfYear).inDays;
    _weekNumber = ((pastDaysOfYear - _currentDate.weekday + 10) ~/ 7);
    return _weekNumber;
  }

  String get currentFullDate => format.format(_currentDate);

  List<DateTime> get workingDays {
    final monday =
        _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    return List.generate(5, (index) => monday.add(Duration(days: index)));
  }

  void nextWeek() {
    final monday =
        _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    _currentDate = monday.add(const Duration(days: 7));
    _weekNumber++;
    notifyListeners();
  }

  void previousWeek() {
    final monday =
        _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    _currentDate = monday.subtract(const Duration(days: 7));
    _weekNumber--;
    notifyListeners();
  }

  void jumpWeeks(int step) {
    final monday =
        _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    _currentDate = monday.add(Duration(days: 7 * step));
    _weekNumber += step;
    notifyListeners();
  }

  void currentDate(DateTime date) {
    _currentDate = date;
    _weekNumber = currentWeekNumber;
    notifyListeners();
  }
}
