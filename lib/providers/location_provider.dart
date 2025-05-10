import 'package:flutter/material.dart';
import 'package:booking_app/models/appointment_model.dart';
import 'package:booking_app/utils/utils.dart';
import 'package:booking_app/utils/database_helper.dart';

class LocationProvider extends ChangeNotifier {
  // Default to Quatre-Bornes.
  Location _selectedLocation = Location.quatreBornes;
  Location get selectedLocation => _selectedLocation;

  // Loads location for the provided weekKey from SQLite.
  Future<void> loadLocation(String weekKey) async {
    final saved = await DatabaseHelper().getWeekPreference(weekKey);
    _selectedLocation = (saved != null) 
        ? Util.parseLocation(saved) 
        : Location.quatreBornes;
    notifyListeners();
  }

  // Update location in SQLite for the given week.
  Future<void> updateLocation(String weekKey, Location newLocation) async {
    await DatabaseHelper().setWeekPreference(weekKey, Util.formatLocation(newLocation));
    _selectedLocation = newLocation;
    notifyListeners();
  }

  // Optionally, you can have a direct setter (useful in memory).
  void setLocation(Location newLocation) {
    _selectedLocation = newLocation;
    notifyListeners();
  }
}