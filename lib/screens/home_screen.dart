import 'package:booking_app/providers/storage_provider.dart';
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
import '../widgets/settings_dialog.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late List<String> timeList;
  late List<String> morningTimeList;
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  // Default appointment location.
  Location _selectedLocation = Location.portLouis;
  TextEditingController patientNameController = TextEditingController();
  int _bookingRefresh = 0;
  late String _weekKey;

  List<String> timeGenerator() {
    List<String> times = [];
    for (int i = 13; i < 18; i++) {
      times.add('$i:30');
      times.add('${i + 1}:00');
    }
    return times;
  }

  List<String> morningTimeGenerator() {
    List<String> times = [];
    for (int i = 7; i < 12; i++) {
      times.add('$i:00');
      times.add('$i:30');
    }
    return times;
  }

  @override
  void initState() {
    super.initState();
    timeList = timeGenerator();
    morningTimeList = morningTimeGenerator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dateProvider = Provider.of<DateProvider>(context, listen: false);
      // Get Monday's date from the working days
      final monday = dateProvider.workingDays
          .firstWhere((day) => day.weekday == DateTime.monday);
      _weekKey = formatter.format(monday);
      _loadWeekPreference();
    });
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

  Future<void> _loadWeekPreference() async {
    final saved = await DatabaseHelper().getWeekPreference(_weekKey);
    setState(() {
      if (saved != null) {
        _selectedLocation = Util.parseLocation(saved);
      }
    });
  }

  Future<void> _updateWeekPreference(Location newLocation) async {
    await DatabaseHelper()
        .setWeekPreference(_weekKey, Util.formatLocation(newLocation));
    setState(() {
      _selectedLocation = newLocation;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Preferred location updated: ${Util.formatLocation(newLocation)}')),
    );
  }

  void _updateWeekKeyAndLoadPreference() {
    final dateProvider = Provider.of<DateProvider>(context, listen: false);
    // Get Monday's date from the new working days.
    final monday = dateProvider.workingDays.firstWhere(
      (day) => day.weekday == DateTime.monday,
      orElse: () => DateTime.now(),
    );
    _weekKey = formatter.format(monday);
    _loadWeekPreference();
  }

  //* Inserts an appointment using AppointmentModel.
  Future<void> _bookAppointment(
      String date, String time, String patientName) async {
    final appointment = AppointmentModel(
      id: null,
      // id will be auto-assigned by the database.
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
                    bookedCount >= 10
                        ? Colors.red
                        : (bookedCount >= 5)
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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateProvider = Provider.of<DateProvider>(context);
    final allWorkingDays = dateProvider.workingDays;
    final filteredDays =
        allWorkingDays.where((day) => day.weekday != DateTime.monday).toList();
    // Monday will be used for the Morning column.
    final monday =
        allWorkingDays.firstWhere((day) => day.weekday == DateTime.monday);
    // Saturday is computed as Monday + 5 days.
    final saturday = monday.add(const Duration(days: 5));
    return Consumer<StorageNotifier>(
        builder: (context, storageNotifier, child) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          elevation: 3,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Week ${dateProvider.currentWeekNumber} - ${dateProvider.currentFullDate}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF18BBB9),
                ),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: 'Port-Louis',
                    groupValue: Util.formatLocation(_selectedLocation),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _updateWeekPreference(Util.parseLocation(newValue));
                      }
                    },
                  ),
                  Text('Port-Louis'),
                  const SizedBox(width: 10),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<String>(
                    value: 'Quatre-Bornes',
                    groupValue: Util.formatLocation(_selectedLocation),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _updateWeekPreference(Util.parseLocation(newValue));
                      }
                    },
                  ),
                  Text('Quatre-Bornes'),
                  const SizedBox(width: 10),
                ],
              ),
            ],
          ),
            // actions: [
            //   PopupMenuButton<String>(
            //       icon: Icon(Icons.more_vert),
            //       itemBuilder: (context) => [
            //         PopupMenuItem(
            //           value: 'settings',
            //           child: Row(
            //             children: [
            //               Icon(Icons.settings, size: 20),
            //               SizedBox(width: 10),
            //               Text('Storage Settings')
            //             ],
            //           ),
            //         ),
            //       ],
            //       onSelected: (value) {
            //         if (value == 'settings') {
            //           _showSettingsDialog(context);
            //         }
            //       },
            //       )
            //   ]
        ),
        body: Row(
          children: <Widget>[
            Expanded(flex: 1, child: Container()),
            Expanded(
                flex: 15,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 1000,
                      height: 50,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search appointments...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF18BBB9),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              Navigator.of(context)
                                  .pushNamed('/search', arguments: {
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
                                _updateWeekKeyAndLoadPreference();
                                setState(() {});
                              },
                              child: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: () {
                                dateProvider.nextWeek();
                                _updateWeekKeyAndLoadPreference();
                                setState(() {});
                              },
                              child: const Icon(Icons.arrow_forward),
                            ),
                            const SizedBox(width: 50),
                            ElevatedButton(
                              onPressed: () {
                                dateProvider.currentDate(DateTime.now());
                                _updateWeekKeyAndLoadPreference();
                                setState(() {});
                              },
                              child: const Text("Now"),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: () {
                                dateProvider.jumpWeeks(1);
                                _updateWeekKeyAndLoadPreference();
                                setState(() {});
                              },
                              child: const Text("1"),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: () {
                                dateProvider.jumpWeeks(2);
                                _updateWeekKeyAndLoadPreference();
                                setState(() {});
                              },
                              child: const Text("2"),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: () {
                                dateProvider.jumpWeeks(3);
                                _updateWeekKeyAndLoadPreference();
                                setState(() {});
                              },
                              child: const Text("3"),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: () {
                                dateProvider.jumpWeeks(4);
                                _updateWeekKeyAndLoadPreference();
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
                            defaultColumnWidth: const FixedColumnWidth(180),
                            children: [
                              // Table Header
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                children: [
                                  Container(
                                    height: 55,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(8))),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "WeekDay Time",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  //* Table Column for WeekDays ( Tuesday to Friday )
                                  for (var day in filteredDays)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                          icon: Icon(Icons.print,
                                              color: Colors.white),
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                                '/appointment-day',
                                                arguments: {
                                                  'location':
                                                      Util.formatLocation(
                                                          _selectedLocation),
                                                  'date': formatter.format(day),
                                                });
                                          },
                                        ),
                                      ],
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Morning Time",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                  //* Table Column for Saturday
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "Saturday ${saturday.day}/${saturday.month}",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.print,
                                            color: Colors.white),
                                        onPressed: () {
                                          _openPdfPreview(saturday);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Table Rows
                              ...List.generate(timeList.length, (index) {
                                final afternoonTimeSlot = timeList[index];
                                final morningTimeSlot = morningTimeList[index];
                                return TableRow(
                                  // (Intentionally left empty)
                                  children: [
                                    // First cell: afternoon time label.
                                    // Change bg color for first columns
                                    Container(
                                      alignment: Alignment.center,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        borderRadius: index == 0
                                            ? BorderRadius.only(
                                                bottomLeft: Radius.circular(8),
                                                bottomRight: Radius.circular(8))
                                            : BorderRadius.circular(8),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withAlpha(50),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          afternoonTimeSlot,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ),
                                      ),
                                    ),

                                    // For each filtered day (Tuesday to Friday) show the afternoon booking cell.
                                    for (var day in filteredDays)
                                      Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: _buildBookingCell(
                                            day, afternoonTimeSlot),
                                      ),
                                    // Extra cell for Monday morning (using morningTimeSlot)
                                    Container(
                                      alignment: Alignment.center,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        borderRadius: index == 0
                                            ? BorderRadius.only(
                                                bottomLeft: Radius.circular(8),
                                                bottomRight: Radius.circular(8))
                                            : BorderRadius.circular(8),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withAlpha(50),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          morningTimeSlot,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ),
                                      ),
                                    ),
                                    // Extra cell for Saturday (using afternoonTimeSlot)
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: _buildBookingCell(
                                          saturday, morningTimeSlot),
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
                )),
            Expanded(flex: 1, child: Container()),
          ],
        ),
      );
    });
  }
}
