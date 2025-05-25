import 'package:booking_app/providers/print_provider.dart';
import 'package:booking_app/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../providers/date_provider.dart';
import '../providers/location_provider.dart';
import '../utils/database_helper.dart';
import '../models/appointment_model.dart';
import 'package:booking_app/utils/utils.dart';
import 'package:booking_app/services/pdf_appointment.dart';
import 'package:pdf/pdf.dart';
import 'package:booking_app/screens/edit_appointment_screen.dart';

import 'package:booking_app/widgets/print_settings_dialog.dart';
import 'package:booking_app/widgets/settings_dialog.dart';
import 'package:booking_app/widgets/display_settings_dialog.dart';
import 'package:booking_app/widgets/holiday_settings_dialog.dart';

import 'package:booking_app/widgets/booking_table.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booking_app/providers/theme_provider.dart';
import 'package:booking_app/providers/holiday_provider.dart';

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
  bool _isLocationEditable = false;

  TextEditingController patientNameController = TextEditingController();
  int _bookingRefresh = 0;
  late String _weekKey;

  late String _storedPassword;

  // * Load the week preference from the database.
  Future<void> _loadWeekPreference() async {
    await Provider.of<LocationProvider>(context, listen: false)
        .loadLocation(_weekKey);
    // Update the theme color based on the provider’s location.
    _updateColorTheme(
      Provider.of<LocationProvider>(context, listen: false).selectedLocation,
    );
  }

  // * Check if the password is set and prompt the user to set it if not.
  Future<void> _checkAndPromptPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('userPassword');
    if (storedPassword == null) {
      // Delay to ensure context is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSetPasswordDialog();
      });
    }
  }

  // * Load the stored password from SharedPreferences.
  Future<void> _loadStoredPassword() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storedPassword = prefs.getString('userPassword') ?? 'defaultPass';
    });
  }

  // * Show a dialog to set the password.
  void _showSetPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, // force the user to enter a password
      builder: (context) {
        return AlertDialog(
          title: const Text("Set Your Password"),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Enter password",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (passwordController.text.trim().isNotEmpty) {
                  final newPassword = passwordController.text.trim();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userPassword', newPassword);
                  setState(() {
                    _storedPassword = newPassword;
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter a valid password")),
                  );
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  // * Update color theme based on the selected location.
  void _updateColorTheme(Location location) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.updateColorBasedOnLocation(Util.formatLocation(location));
  }

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

    _checkAndPromptPassword();
    _loadStoredPassword();
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

  // * Updates the preferred location in the database and shows a snackbar.
  // Future<void> _updateWeekPreference(Location newLocation) async {
  //   await Provider.of<LocationProvider>(context, listen: false)
  //       .updateLocation(_weekKey, newLocation);
  //   _updateColorTheme(newLocation);
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //           'Preferred location updated: ${Util.formatLocation(newLocation)}'),
  //     ),
  //   );
  // }

  // * Updates the week key and loads the preference.
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
    // Check if time hour is less than 10
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = timeParts[1];
    if (hour < 10) {
      time = '0$hour:$minute';
    }

    final appointment = AppointmentModel(
        id: null,
        // id will be auto-assigned by the database.
        patientFirstName: patientName.split(' ')[0],
        patientLastName: patientName.split(' ').length > 1
            ? patientName.split(' ').sublist(1).join(' ')
            : '',
        date: DateTime.parse(date),
        time: time,
        location: Provider.of<LocationProvider>(context, listen: false)
            .selectedLocation);
    await DatabaseHelper().insertAppointment(appointment);
    setState(() {
      _bookingRefresh++;
    });
  }

  // * Return printer from string
  Future<Printer?> getPrinter(String printerName) async {
    final List<Printer> printers = await Printing.listPrinters();

    try {
      return printers.firstWhere((printer) => printer.name == printerName);
    } catch (e) {
      print(e);
      return null;
    }
  }

  //* Builds a booking cell that displays the booked count or a Book button.
  Widget _buildBookingCell(DateTime day, String timeSlot, String location) {
    final formattedDate = formatter.format(day);
    final future = DatabaseHelper().isAppointmentBookedCount(
      formattedDate,
      timeSlot,
      location,
    );
    return Consumer<HolidayProvider>(
        builder: (context, holidayProvider, child) {
      bool isHoliday = holidayProvider.holidays.any((holiday) {
        final holidayDate = DateTime.parse(holiday);
        return holidayDate.year == day.year &&
            holidayDate.month == day.month &&
            holidayDate.day == day.day;
      });
      if (isHoliday) {
        return Container(
          height: 50,
          color: Theme.of(context).colorScheme.primary,
        );
      } else {
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
                                  autofocus: true,
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
                                  await _bookAppointment(formattedDate,
                                      timeSlot, patientNameController.text);
                                  // Increment the refresh counter so that all FutureBuilders update.
                                  setState(() {
                                    _bookingRefresh++;
                                  });
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Book'),
                              ),
                              Consumer<PrintProvider>(
                                builder: (context, printProvider, child) {
                                  return TextButton(
                                    onPressed: () async {
                                      final currentLocation =
                                          Provider.of<LocationProvider>(context,
                                                  listen: false)
                                              .selectedLocation;
                                      final Printer? printer = await getPrinter(
                                          printProvider.printer);
                                      await Printing.directPrintPdf(
                                        printer: printer!,
                                        onLayout: (format) async {
                                          final pdf = await PdfAppointment
                                              .generateSingleAppointment(
                                                  format,
                                                  day,
                                                  patientNameController.text,
                                                  timeSlot,
                                                  Util.formatLocation(
                                                      currentLocation));
                                          return pdf;
                                        },
                                        name: 'appointments_${timeSlot}.pdf',
                                        format: PdfPageFormat(
                                          printProvider.widthPrintingLabel *
                                              printProvider.unit,
                                          printProvider.heightPrintingLabel *
                                              printProvider.unit,
                                          marginAll: 0,
                                        ),
                                      );
                                    },
                                    child: const Text("Print"),
                                  );
                                },
                              ),
                              Consumer<PrintProvider>(
                                builder: (context, printProvider, child) {
                                  return TextButton(
                                    onPressed: () async {


                                      final currentLocation =
                                          Provider.of<LocationProvider>(context,
                                              listen: false)
                                              .selectedLocation;
                                      final Printer? printer = await getPrinter(
                                          printProvider.printer);
                                      final copies = 2;
                                      for (int i = 0; i < copies; i++) {
                                        await Printing.directPrintPdf(
                                          printer: printer!,
                                          onLayout: (format) async {
                                            final pdf = await PdfAppointment
                                                .generateSingleAppointment(
                                                format,
                                                day,
                                                patientNameController.text,
                                                timeSlot,
                                                Util.formatLocation(
                                                    currentLocation));
                                            return pdf;
                                          },
                                          name: 'appointments_${timeSlot}.pdf',
                                          format: PdfPageFormat(
                                            printProvider.widthPrintingLabel *
                                                printProvider.unit,
                                            printProvider.heightPrintingLabel *
                                                printProvider.unit,
                                            marginAll: 0,
                                          ),
                                        );
                                        await Future.delayed(Duration(milliseconds: 100));
                                      }



                                    },
                                    child: Text("Print 2"),
                                  );
                                },
                              ),
                              Consumer<PrintProvider>(
                                builder: (context, printProvider, child) {
                                  return TextButton(
                                    onPressed: () async {
                                      if (patientNameController.text.isEmpty) {
                                        return;
                                      }
                                      await _bookAppointment(formattedDate, timeSlot,
                                          patientNameController.text);
                                      final currentLocation =
                                          Provider.of<LocationProvider>(context,
                                              listen: false)
                                              .selectedLocation;
                                      final Printer? printer = await getPrinter(
                                          printProvider.printer);
                                      final copies = 2;
                                      for (int i = 0; i < copies; i++) {
                                        await Printing.directPrintPdf(
                                          printer: printer!,
                                          onLayout: (format) async {
                                            final pdf = await PdfAppointment
                                                .generateSingleAppointment(
                                                format,
                                                day,
                                                patientNameController.text,
                                                timeSlot,
                                                Util.formatLocation(
                                                    currentLocation));
                                            return pdf;
                                          },
                                          name: 'appointments_${timeSlot}.pdf',
                                          format: PdfPageFormat(
                                            printProvider.widthPrintingLabel *
                                                printProvider.unit,
                                            printProvider.heightPrintingLabel *
                                                printProvider.unit,
                                            marginAll: 0,
                                          ),
                                        );
                                        await Future.delayed(Duration(milliseconds: 50));
                                      }

                                      setState(() {
                                        _bookingRefresh++;
                                      });

                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Book/Print"),
                                  );
                                },
                              )

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
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14)),
                        IconButton(
                            onPressed: () {
                              // Redirect to view appointment list screen

                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => EditAppointmentScreen(
                                      date: formattedDate,
                                      time: timeSlot,
                                      location: Util.formatLocation(
                                          Provider.of<LocationProvider>(context,
                                                  listen: false)
                                              .selectedLocation))));
                            },
                            icon:
                                Icon(Icons.remove_red_eye, color: Colors.white))
                      ],
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 50,
                child: GestureDetector(
                  onTap: () {
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
                                autofocus: true,
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
                              child: const Text(
                                'Book',
                              ),
                            ),
                            Consumer<PrintProvider>(
                              builder: (context, printProvider, child) {
                                return TextButton(
                                  onPressed: () async {
                                    final currentLocation =
                                        Provider.of<LocationProvider>(context,
                                                listen: false)
                                            .selectedLocation;
                                    final Printer? printer =
                                        await getPrinter(printProvider.printer);
                                    await Printing.directPrintPdf(
                                      printer: printer!,
                                      onLayout: (format) async {
                                        final pdf = await PdfAppointment
                                            .generateSingleAppointment(
                                                format,
                                                day,
                                                patientNameController.text,
                                                timeSlot,
                                                Util.formatLocation(
                                                    currentLocation));
                                        return pdf;
                                      },
                                      name: 'appointments_${timeSlot}.pdf',
                                      format: PdfPageFormat(
                                        printProvider.widthPrintingLabel *
                                            printProvider.unit,
                                        printProvider.heightPrintingLabel *
                                            printProvider.unit,
                                        marginAll: 0,
                                      ),
                                    );
                                  },
                                  child: const Text("Print"),
                                );
                              },
                            ),
                            Consumer<PrintProvider>(
                              builder: (context, printProvider, child) {
                                return TextButton(
                                  onPressed: () async {


                                    final currentLocation =
                                        Provider.of<LocationProvider>(context,
                                            listen: false)
                                            .selectedLocation;
                                    final Printer? printer = await getPrinter(
                                        printProvider.printer);
                                    final copies = 2;
                                    for (int i = 0; i < copies; i++) {
                                      await Printing.directPrintPdf(
                                        printer: printer!,
                                        onLayout: (format) async {
                                          final pdf = await PdfAppointment
                                              .generateSingleAppointment(
                                              format,
                                              day,
                                              patientNameController.text,
                                              timeSlot,
                                              Util.formatLocation(
                                                  currentLocation));
                                          return pdf;
                                        },
                                        name: 'appointments_${timeSlot}.pdf',
                                        format: PdfPageFormat(
                                          printProvider.widthPrintingLabel *
                                              printProvider.unit,
                                          printProvider.heightPrintingLabel *
                                              printProvider.unit,
                                          marginAll: 0,
                                        ),
                                      );
                                      await Future.delayed(Duration(milliseconds: 100));
                                    }



                                  },
                                  child: Text("Print 2"),
                                );
                              },
                            ),
                            Consumer<PrintProvider>(
                              builder: (context, printProvider, child) {
                                return TextButton(
                                  onPressed: () async {
                                    if (patientNameController.text.isEmpty) {
                                      return;
                                    }
                                    await _bookAppointment(formattedDate, timeSlot,
                                        patientNameController.text);
                                    final currentLocation =
                                        Provider.of<LocationProvider>(context,
                                            listen: false)
                                            .selectedLocation;
                                    final Printer? printer = await getPrinter(
                                        printProvider.printer);
                                    final copies = 2;
                                    for (int i = 0; i < copies; i++) {
                                      await Printing.directPrintPdf(
                                        printer: printer!,
                                        onLayout: (format) async {
                                          final pdf = await PdfAppointment
                                              .generateSingleAppointment(
                                              format,
                                              day,
                                              patientNameController.text,
                                              timeSlot,
                                              Util.formatLocation(
                                                  currentLocation));
                                          return pdf;
                                        },
                                        name: 'appointments_${timeSlot}.pdf',
                                        format: PdfPageFormat(
                                          printProvider.widthPrintingLabel *
                                              printProvider.unit,
                                          printProvider.heightPrintingLabel *
                                              printProvider.unit,
                                          marginAll: 0,
                                        ),
                                      );
                                      await Future.delayed(Duration(milliseconds: 50));
                                    }

                                    setState(() {
                                      _bookingRefresh++;
                                    });

                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("Book/Print"),
                                );
                              },
                            )
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        "Book",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ),
                  ),
                ),
              );
            }
          },
        );
      }
    });
  }

  //* Show  storage settings dialog
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SettingsDialog(),
    );
  }

  //* Show display settings dialog
  void _showDisplaySettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DisplaySettingsDialog(),
    );
  }

  void _showPrintSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PrintSettingsDialog(),
    );
  }

  void _showHolidaySettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const HolidaySettingsDialog(),
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
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 27),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: 20),
                Consumer<LocationProvider>(
                    builder: (context, locationProvider, child) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Location: ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 27),
                      ),
                      _isLocationEditable
                          ? Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              child: DropdownButton<Location>(
                                value: locationProvider.selectedLocation,
                                underline: Container(
                                  height: 40,
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onChanged: (Location? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      locationProvider.setLocation(newValue);
                                    });
                                  }
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: Location.portLouis,
                                    child: Text("Port-Louis",
                                        style: TextStyle(fontSize: 16)),
                                  ),
                                  DropdownMenuItem(
                                    value: Location.quatreBornes,
                                    child: Text("Quatre-Bornes",
                                        style: TextStyle(fontSize: 16)),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              Util.formatLocation(
                                  locationProvider.selectedLocation),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 27),
                            ),
                      IconButton(
                        icon: Icon(
                          _isLocationEditable
                              ? Icons.lock_open_rounded
                              : Icons.lock_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          // If not editable, prompt for password
                          if (!_isLocationEditable) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                final TextEditingController passwordController =
                                    TextEditingController();
                                return AlertDialog(
                                  title: Text("Enter Password"),
                                  content: TextField(
                                    controller: passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: "Password",
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (passwordController.text ==
                                            _storedPassword) {
                                          setState(() {
                                            _isLocationEditable = true;
                                          });
                                          Navigator.of(context).pop();
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text("Invalid password."),
                                          ));
                                        }
                                      },
                                      child: Text("Submit"),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                      ),
                      _isLocationEditable
                          ? IconButton(
                              icon: Icon(
                                Icons.check_box_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                Provider.of<LocationProvider>(context,
                                        listen: false)
                                    .updateLocation(
                                        _weekKey,
                                        Provider.of<LocationProvider>(context,
                                                listen: false)
                                            .selectedLocation);
                                setState(() {
                                  _isLocationEditable = false;
                                });
                                _updateColorTheme(
                                  Provider.of<LocationProvider>(context,
                                          listen: false)
                                      .selectedLocation,
                                );
                              },
                            )
                          : Container(),
                    ],
                  );
                }),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                elevation: 3,
                icon: Icon(Icons.settings,
                    color: Theme.of(context).colorScheme.primary),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'storage settings',
                    child: Row(
                      children: [
                        Icon(Icons.storage,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 10),
                        Text('Settings')
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'display settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.color_lens,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 10),
                        Text('Display Settings')
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'printing settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.print,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 10),
                        Text('Printing Settings')
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'calendar settings',
                    child: Row(children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      SizedBox(width: 10),
                      Text('Calendar Settings')
                    ]),
                  )
                ],
                onSelected: (value) {
                  if (value == 'storage settings') {
                    _showSettingsDialog(context);
                  } else if (value == 'display settings') {
                    _showDisplaySettingsDialog(context);
                  } else if (value == 'printing settings') {
                    _showPrintSettingsDialog(context);
                  } else if (value == 'calendar settings') {
                    _showHolidaySettingsDialog(context);
                  }
                },
              )
            ]),
        body: Row(
          children: <Widget>[
            Expanded(flex: 1, child: Container()),
            Expanded(
                flex: 38,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 1000,
                      height: 60,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search appointments...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
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
                      child: BookingTable(
                        timeList: timeList,
                        morningTimeList: morningTimeList,
                        filteredDays: filteredDays,
                        saturday: saturday,
                        location: Util.formatLocation(
                            Provider.of<LocationProvider>(context)
                                .selectedLocation),
                        buildBookingCell: _buildBookingCell,
                      ),
                    ),
                  ],
                )),
            Expanded(flex: 1, child: Container()),
          ],
        ),
      );
    });
  }
}
