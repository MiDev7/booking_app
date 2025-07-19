import 'package:booking_app/screens/pdf_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:booking_app/utils/database_helper.dart';
import 'package:booking_app/services/pdf_appointment.dart';
// import 'package:booking_app/services/whatsapp_service.dart';

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
        .getAppointmentsWithPhoneByDateAndLocation(
            widget.date, widget.location);
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
  // TODO: To complete for cancellation functionality
  // Future<void> _cancelSingleAppointment(
  //     Map<String, dynamic> appointment) async {
  //   if (appointment['phoneNumber'] == null ||
  //       appointment['phoneNumber'].toString().isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('No phone number available for this patient.'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   final patientName =
  //       '${appointment['patientFirstName']} ${appointment['patientLastName']}';

  //   final success = await WhatsAppService.sendCancellationMessage(
  //     phoneNumber: appointment['phoneNumber'].toString(),
  //     patientName: patientName,
  //     date: appointment['date'].toString(),
  //     time: appointment['time'].toString(),
  //     location: widget.location,
  //   );

  //   if (success) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('WhatsApp message sent to $patientName'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to send message to $patientName'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  // Future<void> _cancelAllAppointments() async {
  //   final appointments = await _fetchAppointments();

  //   if (appointments.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('No appointments to cancel.'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   // Filter appointments with phone numbers
  //   final appointmentsWithPhone = appointments
  //       .where((apt) =>
  //           apt['phoneNumber'] != null &&
  //           apt['phoneNumber'].toString().isNotEmpty)
  //       .toList();

  //   if (appointmentsWithPhone.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('No appointments have phone numbers available.'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   // Show confirmation dialog
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Cancel All Appointments'),
  //       content: Text(
  //           'Send cancellation messages to ${appointmentsWithPhone.length} patient(s)?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(false),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () => Navigator.of(context).pop(true),
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: const Text('Send Messages'),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirmed == true) {
  //     // Show progress dialog
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => const AlertDialog(
  //         content: Row(
  //           children: [
  //             CircularProgressIndicator(),
  //             SizedBox(width: 16),
  //             Text('Sending messages...'),
  //           ],
  //         ),
  //       ),
  //     );

  //     final results = await WhatsAppService.sendBulkCancellationMessages(
  //       appointments: appointmentsWithPhone,
  //       location: widget.location,
  //     );

  //     Navigator.of(context).pop(); // Close progress dialog

  //     final successCount = results.where((r) => r).length;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //             'Sent $successCount out of ${appointmentsWithPhone.length} messages successfully.'),
  //         backgroundColor: successCount == appointmentsWithPhone.length
  //             ? Colors.green
  //             : Colors.orange,
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointments - ${widget.date} (${widget.location})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        elevation: 3,
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No appointments found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.date} • ${widget.location}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
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
                          Row(
                            children: [
                              // TODO: Fix Logic for w.a
                              // Padding(
                              //   padding: const EdgeInsets.all(8.0),
                              //   child: ElevatedButton.icon(
                              //     onPressed: () {
                              //       Navigator.of(context)
                              //           .pushNamed('/whatsapp-settings');
                              //     },
                              //     label: const Text('Message Settings'),
                              //     icon: const Icon(
                              //       Icons.settings,
                              //       size: 18,
                              //     ),
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: Colors.grey[300],
                              //       foregroundColor: Colors.black87,
                              //     ),
                              //   ),
                              // ),
                              // Padding(
                              //   padding: const EdgeInsets.all(8.0),
                              //   child: ElevatedButton.icon(
                              //     onPressed: _cancelAllAppointments,
                              //     label: const Text('Cancel All'),
                              //     icon: const Icon(
                              //       Icons.cancel,
                              //       size: 18,
                              //     ),
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: Colors.red[300],
                              //       foregroundColor: Colors.white,
                              //     ),
                              //   ),
                              // ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    DateTime date = DateTime.parse(widget.date);
                                    _openPdfPreview(date);
                                  },
                                  label: const Text('Print'),
                                  icon: const Icon(
                                    Icons.print,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                      fontSize: 16,
                                    )),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${appointment['date']} at ${appointment['time']}'),
                                    if (appointment['phoneNumber'] != null &&
                                        appointment['phoneNumber']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              size: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Mobile: ${appointment['phoneNumber'].toString()}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (appointment['phoneNumber2'] != null &&
                                        appointment['phoneNumber2']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.home,
                                              size: 16,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Home: ${appointment['phoneNumber2'].toString()}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (appointment['description'] != null &&
                                        appointment['description']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          appointment['description'].toString(),
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                // trailing: appointment['phoneNumber'] != null &&
                                //         appointment['phoneNumber']
                                //             .toString()
                                //             .isNotEmpty
                                // ? IconButton(
                                //         onPressed: () =>
                                //             _cancelSingleAppointment(
                                //                 appointment),
                                //         icon: const Icon(
                                //           Icons.cancel_outlined,
                                //           color: Colors.red,
                                //         ),
                                //         tooltip: 'Send cancellation message',
                                //       )
                                //     : Icon(
                                //         Icons.phone_disabled,
                                //         color: Colors.grey[400],
                                //         size: 20,
                                //       ),
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
