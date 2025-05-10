import 'package:flutter/material.dart';
import 'package:booking_app/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:booking_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

typedef BookingCellBuilder = Widget Function(DateTime day, String timeSlot);

class BookingTable extends StatelessWidget {
  final List<DateTime> filteredDays;
  final List<String> timeList;
  final List<String> morningTimeList;
  final DateTime saturday;
  final Widget Function(DateTime, String, String) buildBookingCell;
  final String location;

  BookingTable({
    super.key,
    required this.filteredDays,
    required this.timeList,
    required this.morningTimeList,
    required this.saturday,
    required this.buildBookingCell,
    required this.location,
  });

  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
              return Table(
                border: TableBorder.all(color: Colors.white),
                defaultColumnWidth: const FlexColumnWidth(1.0),
                children: [
                  // Table header
                  TableRow(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary),
                    children: [
                      Container(
                        height: 55,
                        decoration: const BoxDecoration(
                          borderRadius:
                              BorderRadius.only(topLeft: Radius.circular(8)),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: const Text(
                            "WeekDay Time",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      // Header cells for each filtered day
                      for (var day in filteredDays)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "${Util.dayName(day.weekday)} ${day.day}/${day.month}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.print, color: Colors.white),
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed('/appointment-day', arguments: {
                                  'location': location,
                                  'date': formatter.format(day),
                                });
                              },
                            ),
                          ],
                        ),
                      // Header cell for Morning Time
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: const Text(
                            "Morning Time",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      // Header for Saturday
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  "Saturday ${saturday.day}/${saturday.month}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.print, color: Colors.white),
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed('/appointment-day', arguments: {
                                'location': location,
                                'date': formatter.format(saturday),
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Table rows for each time slot
                  ...List.generate(timeList.length, (index) {
                    final afternoonTimeSlot = timeList[index];
                    final morningTimeSlot = morningTimeList[index];
                    // Alternate color
                    final isEvenRow = index % 2 == 0;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEvenRow
                            ? themeProvider.colorA
                            : themeProvider.colorB,
                      ),
                      children: [
                        // First cell: time label for afternoon slot.
                        Container(
                          alignment: Alignment.center,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            afternoonTimeSlot,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        // For each filtered day used to build the booking cell.
                        for (var day in filteredDays)
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: buildBookingCell(
                                day, afternoonTimeSlot, location),
                          ),
                        // Extra cell: morning time label.
                        Container(
                          alignment: Alignment.center,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            morningTimeSlot,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        // Extra cell for Saturday booking.
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: buildBookingCell(
                              saturday, morningTimeSlot, location),
                        ),
                      ],
                    );
                  }),
                ],
              );
            }),
          ),
        ),
      );
    });
  }
}
