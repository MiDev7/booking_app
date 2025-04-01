import 'package:booking_app/widgets/edit_alert_dialog.dart';
import 'package:flutter/material.dart';
import '../utils/database_helper.dart';

class EditAppointmentScreen extends StatefulWidget {
  final String date;
  final String time;
  final String location;

  const EditAppointmentScreen(
      {super.key,
      required this.date,
      required this.time,
      required this.location});

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  late Future<List<Map<String, dynamic>>> _appointmentsFuture;

  void _fetchAppointments() {
    _appointmentsFuture =
        DatabaseHelper().getAppointmentsByDateAndTimeAndLocation(
      widget.date,
      widget.time,
      widget.location,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Edit Appointment ${widget.date} ${widget.time} ${widget.location.toLowerCase()}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final List<Map<String, dynamic>> appointments = snapshot.data!;
            if (appointments.isEmpty) {
              return const Center(child: Text('No appointments found'));
            } else {
              return ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final Map<String, dynamic> appointment = appointments[index];
                  return Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    elevation: 0.2,
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                " ${appointment['patientFirstName']} ${appointment['patientLastName'] ?? ""}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Date: ${appointment['date']}'),
                              Text('Time: ${appointment['time']}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  showEditAppointmentDialog(
                                      context: context,
                                      appointment: appointment,
                                      onUpdated: () {
                                        setState(() {
                                          _fetchAppointments();
                                        });
                                      });
                                },
                                child: const Text('Edit'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  DatabaseHelper().deleteAppointment(
                                      appointment['id'] as int);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Appointment deleted'),
                                    ),
                                  );
                                  setState(() {
                                    _fetchAppointments();
                                  });
                                },
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          }
        },
      ),
    );
  }
}
