import 'package:flutter/material.dart';

class TimeslotCard extends StatelessWidget {
  final DateTime timeslot;
  final int patientCount;

  const TimeslotCard({
    super.key,
    required this.timeslot,
    required this.patientCount,
  });

  @override
  Widget build(BuildContext context) {
    // Format the timeslot (for simplicity, hours and minutes only)
    String formattedTime =
        "${timeslot.hour.toString().padLeft(2, '0')}:${timeslot.minute.toString().padLeft(2, '0')}";
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('Time: $formattedTime'),
        subtitle: Text('Total patients: $patientCount'),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to booking details if needed.
        },
      ),
    );
  }
}
