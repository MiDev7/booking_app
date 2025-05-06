import 'package:booking_app/screens/pdf_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:booking_app/utils/database_helper.dart';
import 'package:booking_app/services/pdf_appointment.dart';

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

  //* Opens a PDF preview screen with the appointments for the selected day.
  Future<void> _openPdfPreview(DateTime day) async {
    final appointments = await _fetchAppointments();
    final mutableAppointments = List<Map<String, dynamic>>.from(appointments);
    if (appointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No appointments found for this day.'),
        ),
      );
      return;
    } else {
      // Sort alphabetically

      if (_sortAlphabetically) {
        mutableAppointments.sort((a, b) {
          final nameA =
              '${a['patientFirstName']} ${a['patientLastName']}'.toLowerCase();
          final nameB =
              '${b['patientFirstName']} ${b['patientLastName']}'.toLowerCase();
          return nameA.compareTo(nameB);
        });
      }
    }
    final pdf = await PdfAppointment.generatePdf(day, mutableAppointments,
        location: widget.location);

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(pdfData: pdf)));
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
                  width: 700, // Limit the width of the list view.
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                              onPressed: _toggleSort,
                              label: Text(_sortAlphabetically
                                  ? 'Clear Sort'
                                  : 'Sort Alphabetically'),
                              icon: Icon(
                                _sortAlphabetically
                                    ? Icons.clear_all
                                    : Icons.sort_by_alpha,
                                size: 18,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                DateTime date = DateTime.parse(widget.date);
                                _openPdfPreview(date);
                              },
                              label: Text('Print'),
                              icon: Icon(
                                Icons.print,
                                size: 18,
                              ),
                            ),
                          )
                        ],
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = appointments[index];
                            return Card(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
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
