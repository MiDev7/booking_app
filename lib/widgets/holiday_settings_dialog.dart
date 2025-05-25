import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:booking_app/providers/holiday_provider.dart';

class HolidaySettingsDialog extends StatefulWidget {
  const HolidaySettingsDialog({super.key});

  @override
  State<HolidaySettingsDialog> createState() => _HolidaySettingsDialogState();
}

class _HolidaySettingsDialogState extends State<HolidaySettingsDialog> {
  DateTime? _selectedDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _dateFormatWithDay = DateFormat('EEEE dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    // Initialize any necessary data or state here
    Provider.of<HolidayProvider>(context, listen: false).loadHolidays();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_month_rounded,
                color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 10),
            Text('Public Holidays Setting')
          ],
        ),
        content: SizedBox(
          height: 500,
          width: 500,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
                child: Text(_selectedDate != null
                    ? "Selected: ${_dateFormat.format(_selectedDate!)}"
                    : "Select Holiday Date"),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  if (_selectedDate != null) {
                    Provider.of<HolidayProvider>(context, listen: false)
                        .addHoliday(_dateFormat.format(_selectedDate!));

                    setState(() {
                      _selectedDate = null; // Reset the selected date
                      // SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green[900],
                          content: Text(
                              "Holiday added: ${_dateFormat.format(_selectedDate!)}"),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red[900],
                        content: Text("Please select a date first."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text("Add Holiday"),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                "List of Public Holidays:",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              Consumer<HolidayProvider>(
                  builder: (context, holidayProvider, child) {
                return Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: holidayProvider.holidays.map((holiday) {
                        // final formattedDate =
                        //     _dateFormatWithDay.format(DateTime.parse(holiday));
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                  _dateFormatWithDay
                                      .format(DateTime.parse(holiday)),
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red[900],
                                ),
                                onPressed: () {
                                  holidayProvider.removeHoliday(holiday);
                                },
                              ),
                            ),
                            Divider(
                              height: 1,
                              thickness: 2,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(25),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ]);
  }
}
