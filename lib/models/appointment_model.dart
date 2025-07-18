import 'package:intl/intl.dart';

enum Location { portLouis, quatreBornes }

class AppointmentModel {
  String? id;
  final String patientFirstName;
  final String patientLastName;
  final DateTime date;
  final String time;
  final Location location;
  final String? description;
  final int? patientId;

  AppointmentModel({
    this.id,
    required this.patientFirstName,
    required this.patientLastName,
    required this.date,
    required this.time,
    required this.location,
    this.description,
    this.patientId,
  });

  Map<String, dynamic> toJson() {
    // Use the same formatted date as used in queries: yyyy-MM-dd.
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return {
      if (id != null) 'id': id,
      'patientFirstName': patientFirstName,
      'patientLastName': patientLastName,
      'date': formattedDate,
      'time': time,
      'location':
          location == Location.portLouis ? 'Port-Louis' : 'Quatre-Bornes',
      if (description != null) 'description': description,
      if (patientId != null) 'patientId': patientId,
    };
  }
}
