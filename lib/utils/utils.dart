import 'package:booking_app/models/appointment_model.dart';

class Util {
  static String dayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Monday";
      case DateTime.tuesday:
        return "Tuesday";
      case DateTime.wednesday:
        return "Wednesday";
      case DateTime.thursday:
        return "Thursday";
      case DateTime.friday:
        return "Friday";
      default:
        return "";
    }
  }

  static String formatLocation(Location location) {
    switch (location) {
      case Location.portLouis:
        return "Port-Louis";
      case Location.quatreBornes:
        return "Quatre-Bornes";
    }
  }

  static Location parseLocation(String location) {
    switch (location) {
      case "Port-Louis":
        return Location.portLouis;
      case "Quatre-Bornes":
        return Location.quatreBornes;
      default:
        throw Exception("Unknown location: $location");
    }
  }
}
