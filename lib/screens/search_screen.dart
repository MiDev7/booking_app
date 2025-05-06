import 'package:flutter/material.dart';
import '../utils/database_helper.dart';
import 'package:booking_app/widgets/edit_alert_dialog.dart';

class SearchScreen extends StatefulWidget {
  final String name;

  const SearchScreen({super.key, required this.name});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Map<String, dynamic>>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAppointments();
  }

  void _refreshAppointments() {
    _appointmentsFuture = DatabaseHelper().getAppointmentsByName(widget.name);
  }

  void _deleteAppointment(int id) async {
    await DatabaseHelper().deleteAppointment(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Appointment deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Handle undo if needed.
          },
        ),
      ),
    );
    setState(() {
      _refreshAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Search Result for: ${widget.name}",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary),
        ),
        centerTitle: true,
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 700,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _appointmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final filteredAppointments = snapshot.data ?? [];
                  if (filteredAppointments.isEmpty) {
                    return const Center(child: Text('No appointments found.'));
                  }
                  return ListView.builder(
                    itemCount: filteredAppointments.length,
                    itemBuilder: (context, index) {
                      final appointment = filteredAppointments[index];
                      return Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        elevation: 0.2,
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Appointment details
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Name: ${appointment['patientFirstName'].toUpperCase()} ${appointment['patientLastName'].toUpperCase() ?? ""}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Date: ${appointment['date']}'),
                                  Text('Time: ${appointment['time']}'),
                                  Text('Location: ${appointment['location']}'),
                                ],
                              ),
                              // Action buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      showEditAppointmentDialog(
                                        context: context,
                                        appointment: appointment,
                                        onUpdated: () {
                                          setState(() {
                                            _refreshAppointments();
                                          });
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _deleteAppointment(appointment['id']);
                                    },
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
