import 'package:flutter/material.dart';
import '../utils/database_helper.dart';

Future<void> showEditAppointmentDialog({
  required BuildContext context,
  required Map<String, dynamic> appointment,
  required VoidCallback onUpdated, // Called after successful update.
}) async {
  final _formKey = GlobalKey<FormState>();
  // Initialize default date and time from the appointment.
  DateTime? selectedDate = DateTime.tryParse(appointment['date']);
  List<String> timeParts = appointment['time'].split(':');
  TimeOfDay? selectedTime = timeParts.length == 2
      ? TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? 0,
          minute: int.tryParse(timeParts[1]) ?? 0,
        )
      : null;
  // Location dropdown options.
  final List<String> locationOptions = ['Port-Louis', 'Quatre-Bornes'];
  String? selectedLocation = appointment['location'];

  // Helper to round a TimeOfDay to the nearest 30 minutes.
  TimeOfDay roundToNearest30(TimeOfDay time) {
    int mod = time.minute % 30;
    int roundedMinute = mod < 15 ? time.minute - mod : time.minute + (30 - mod);
    int hour = time.hour;
    if (roundedMinute >= 60) {
      roundedMinute = 0;
      hour = (hour + 1) % 24;
    }
    return TimeOfDay(hour: hour, minute: roundedMinute);
  }

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Edit Appointment"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final initial = selectedDate ?? DateTime.now();
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(DateTime.now().year + 5),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Date",
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedDate == null
                              ? "Select Date"
                              : "${selectedDate!.toLocal()}".split(' ')[0],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time Picker with rounding.
                    InkWell(
                      onTap: () async {
                        final initial = selectedTime ?? TimeOfDay.now();
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: initial,
                        );
                        if (pickedTime != null) {
                          final rounded = roundToNearest30(pickedTime);
                          if (selectedDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please select a date first."),
                              ),
                            );
                          } else {
                            setState(() {
                              selectedTime = rounded;
                            });
                          }
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Time",
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedTime == null
                              ? "Select Time"
                              : selectedTime!.format(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Location Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Location",
                        border: OutlineInputBorder(),
                      ),
                      value: selectedLocation,
                      items: locationOptions.map((loc) {
                        return DropdownMenuItem(
                          value: loc,
                          child: Text(loc),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLocation = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please select a location.";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              if (selectedDate == null || selectedTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select both date and time."),
                  ),
                );
                return;
              }
              DatabaseHelper()
                  .updateAppointmentDateTimeLocation(
                appointment['id'].toString(),
                "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
                selectedLocation ?? "",
              )
                  .then((value) {
                if (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Appointment updated successfully.")),
                  );
                  onUpdated();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Failed to update appointment.")),
                  );
                }
              });
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}
