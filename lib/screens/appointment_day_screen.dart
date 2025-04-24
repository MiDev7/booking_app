import 'package:flutter/material.dart';
import 'package:booking_app/utils/database_helper.dart';

class AppointmentDayScreen extends StatefulWidget {
  final String date;
  final String location;

  const AppointmentDayScreen(
      {super.key, required this.date, required this.location});

  @override
  State<AppointmentDayScreen> createState() => _AppointmentDayScreenState();
}

class _AppointmentDayScreenState extends State<AppointmentDayScreen> {
  bool _sortAlphabetically = false;
  final String _searchQuery = '';

  // Fetch all appointments for the given date, time, and location.
  Future<List<Map<String, dynamic>>> _fetchAppointments() async {
    final appointments = await DatabaseHelper()
        .getAppointmentsByDateAndLocation(widget.date, widget.location);
    return appointments;
  }

  void _toggleSort() {
    setState(() {
      _sortAlphabetically = !_sortAlphabetically;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Day'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<Map<String, dynamic>> appointments =
                List<Map<String, dynamic>>.from(snapshot.data!);
            if (appointments.isEmpty) {
              return const Center(child: Text('No appointments found'));
            } else {
              if (_sortAlphabetically) {
                appointments.sort((a, b) {
                  final nameA =
                      '${a['patientFirstName']} ${a['patientLastName']}'
                          .toLowerCase();
                  final nameB =
                      '${b['patientFirstName']} ${b['patientLastName']}'
                          .toLowerCase();
                  return nameA.compareTo(nameB);
                });
              }
              return Center(
                child: SizedBox(
                  width: 500, // Limit the width of the list view.
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: _toggleSort,
                          child: Text(_sortAlphabetically
                              ? 'Clear Sort'
                              : 'Sort Alphabetically'),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = appointments[index];
                            return Card(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              child: ListTile(
                                title: Text(
                                    '${appointment['patientFirstName'].toUpperCase()} ${appointment['patientLastName'].toUpperCase()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,

                                    )),
                                subtitle: Text(
                                    '${appointment['date']} at ${appointment['time']}'),

                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
