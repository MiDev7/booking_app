import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/date_provider.dart';
import '../utils/database_helper.dart';
import '../models/appointment_model.dart';
import 'package:booking_app/utils/utils.dart';
import 'package:booking_app/services/pdf_appointment.dart';
import 'package:booking_app/screens/pdf_preview_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:booking_app/screens/edit_appointment_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late List<String> timeList;
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  // Default appointment location.
  Location _selectedLocation = Location.portLouis;

  TextEditingController patientNameController = TextEditingController();
  int _bookingRefresh = 0;

  List<String> timeGenerator() {
    List<String> times = [];
    for (int i = 13; i < 18; i++) {
      times.add('$i:30');
      times.add('${i + 1}:00');
    }
    return times;
  }

  @override
  void initState() {
    super.initState();
    timeList = timeGenerator();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      _bookingRefresh++; // This updates any FutureBuilders keyed by _bookingRefresh.
    });
  }

  //* Inserts an appointment using AppointmentModel.
  Future<void> _bookAppointment(
      String date, String time, String patientName) async {
    final appointment = AppointmentModel(
      id: null, // id will be auto-assigned by the database.
      patientFirstName: patientName.split(' ')[0],
      patientLastName: patientName.split(' ').length > 1
          ? patientName.split(' ').sublist(1).join(' ')
          : '',
      date: DateTime.parse(date),
      time: time,
      location: _selectedLocation,
    );
    await DatabaseHelper().insertAppointment(appointment);
    setState(() {
      _bookingRefresh++;
    });
  }

  //* Opens a PDF preview screen with the appointments for the selected day.
  Future<void> _openPdfPreview(DateTime day) async {
    final formattedDate = formatter.format(day);
    final appointments = await DatabaseHelper()
        .getAppointmentsByDateAndLocation(
            formattedDate, Util.formatLocation(_selectedLocation));
    final pdf = await PdfAppointment.generatePdf(
      day,
      appointments,
      location: Util.formatLocation(_selectedLocation),
    );

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(pdfData: pdf)));
  }

  //* Navigate to Edit Appointment Screen

  //* Builds a booking cell that displays the booked count or a Book button.
  Widget _buildBookingCell(DateTime day, String timeSlot) {
    final formattedDate = formatter.format(day);
    final future = DatabaseHelper().isAppointmentBookedCount(
      formattedDate,
      timeSlot,
      Util.formatLocation(_selectedLocation),
    );
    return FutureBuilder<int>(
      key: ValueKey('$_bookingRefresh-$formattedDate-$timeSlot'),
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 50,
            child: Center(child: Icon(Icons.error, color: Colors.red)),
          );
        } else {
          final int bookedCount = snapshot.data ?? 0;
          if (bookedCount > 0) {
            return SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      TextEditingController patientNameController =
                          TextEditingController();
                      return AlertDialog(
                        title: const Text('Book Appointment'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                'Book appointment on $formattedDate at $timeSlot?'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: patientNameController,
                              decoration: const InputDecoration(
                                labelText: 'Patient Name',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (patientNameController.text.isEmpty) {
                                return;
                              }
                              await _bookAppointment(formattedDate, timeSlot,
                                  patientNameController.text);
                              // Increment the refresh counter so that all FutureBuilders update.
                              setState(() {
                                _bookingRefresh++;
                              });
                              Navigator.of(context).pop();
                            },
                            child: const Text('Book'),
                          ),
                          TextButton(
                              onPressed: () {
                                // Print in 20x20cm format.
                                Printing.layoutPdf(
                                  onLayout: (format) async {
                                    final pdf =
                                        await PdfAppointment.generatePdf(
                                      day,
                                      await DatabaseHelper()
                                          .getAppointmentsByDateAndLocation(
                                              formattedDate,
                                              Util.formatLocation(
                                                  _selectedLocation)),
                                      location: Util.formatLocation(
                                          _selectedLocation),
                                    );
                                    return pdf;
                                  },
                                  name: 'appointments.pdf',
                                  format: PdfPageFormat(
                                    20 * PdfPageFormat.cm,
                                    25 * PdfPageFormat.cm,
                                  ),
                                );
                              },
                              child: const Text("Print"))
                        ],
                      );
                    },
                  );
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    bookedCount >= 3
                        ? Colors.red
                        : (bookedCount >= 2)
                            ? Colors.orange
                            : Theme.of(context).colorScheme.primary,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Patients: $bookedCount",
                        style: const TextStyle(color: Colors.white)),
                    IconButton(
                        onPressed: () {
                          // Redirect to view appointment list screen

                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => EditAppointmentScreen(
                                  date: formattedDate,
                                  time: timeSlot,
                                  location:
                                      Util.formatLocation(_selectedLocation))));
                        },
                        icon: Icon(Icons.remove_red_eye, color: Colors.white))
                  ],
                ),
              ),
            );
          }
          return SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    TextEditingController patientNameController =
                        TextEditingController();
                    return AlertDialog(
                      title: const Text('Book Appointment'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              'Book appointment on $formattedDate at $timeSlot?'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: patientNameController,
                            decoration: const InputDecoration(
                              labelText: 'Patient Name',
                            ),
                            autofocus: true,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (patientNameController.text.isEmpty) {
                              return;
                            }
                            await _bookAppointment(formattedDate, timeSlot,
                                patientNameController.text);
                            // Increment the refresh counter so that all FutureBuilders update.
                            setState(() {
                              _bookingRefresh++;
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('Book'),
                        ),
                        TextButton(
                            onPressed: () {
                              // Print in 20x20cm format.
                              Printing.layoutPdf(
                                onLayout: (format) async {
                                  final pdf = await PdfAppointment.generatePdf(
                                    day,
                                    await DatabaseHelper()
                                        .getAppointmentsByDateAndLocation(
                                            formattedDate,
                                            Util.formatLocation(
                                                _selectedLocation)),
                                    location:
                                        Util.formatLocation(_selectedLocation),
                                  );
                                  return pdf;
                                },
                                name: 'appointments.pdf',
                                format: PdfPageFormat(
                                  20 * PdfPageFormat.cm,
                                  20 * PdfPageFormat.cm,
                                ),
                              );
                            },
                            child: const Text("Print"))
                      ],
                    );
                  },
                );
              },
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              child: const Text("Book"),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateProvider = Provider.of<DateProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Week ${dateProvider.currentWeekNumber} - ${dateProvider.currentFullDate}'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: Location.values.map((location) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<Location>(
                    value: location,
                    groupValue: _selectedLocation,
                    onChanged: (Location? newLocation) {
                      if (newLocation != null) {
                        setState(() {
                          _selectedLocation = newLocation;
                        });
                      }
                    },
                  ),
                  Text(Util.formatLocation(location)),
                  const SizedBox(width: 10),
                ],
              );
            }).toList(),
          ),

          SizedBox(
            width: 1000,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search appointments...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    Navigator.of(context).pushNamed('/search', arguments: {
                      'name': value,
                    });
                  }
                },
              ),
            ),
          ),

          // Navigation and location switch controls.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      dateProvider.previousWeek();
                      setState(() {});
                    },
                    child: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      dateProvider.nextWeek();
                      setState(() {});
                    },
                    child: const Icon(Icons.arrow_forward),
                  ),
                  const SizedBox(width: 50),
                  ElevatedButton(
                    onPressed: () {
                      dateProvider.currentDate(DateTime.now());
                      setState(() {});
                    },
                    child: const Text("Now"),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      dateProvider.jumpWeeks(1);
                      setState(() {});
                    },
                    child: const Text("1"),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      dateProvider.jumpWeeks(2);
                      setState(() {});
                    },
                    child: const Text("2"),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      dateProvider.jumpWeeks(3);
                      setState(() {});
                    },
                    child: const Text("3"),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      dateProvider.jumpWeeks(4);
                      setState(() {});
                    },
                    child: const Text("4"),
                  ),
                ],
              ),
            ),
          ),
          // Display the location switch.

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.white,
                  ),
                  // Increased column width from 120 to 200.
                  defaultColumnWidth: const FixedColumnWidth(200),
                  children: [
                    // Table Header
                    TableRow(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Time",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        for (var day
                            in Provider.of<DateProvider>(context).workingDays)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "${Util.dayName(day.weekday)} ${day.day}/${day.month}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.print, color: Colors.white),
                                onPressed: () {
                                  _openPdfPreview(day);
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Table Rows
                    ...timeList.map((timeSlot) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              timeSlot,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          for (var day
                              in Provider.of<DateProvider>(context).workingDays)
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: _buildBookingCell(day, timeSlot),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
