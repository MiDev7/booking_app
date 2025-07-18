import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:booking_app/utils/utils.dart';
import 'package:intl/intl.dart';

class PdfAppointment {
  static Future<Uint8List> generatePdf(
      DateTime date, List<Map<String, dynamic>> appointments,
      {String? location}) async {
    final pdf = Document();
    pdf.addPage(pw.MultiPage(
        build: (context) => [
              _buildHeader(date, appointments, location: location),
              SizedBox(height: 20),
              _buildAppointment(appointments),
            ]));

    final output = await pdf.save();

    return output;
  }

  static Future<Uint8List> generateSingleAppointment(PdfPageFormat format,
      DateTime date, String name, String timeSlot, String location) async {
    final pdf = Document();
    final DateFormat formatter = DateFormat('EEEE dd/MM/yy');

    final formattedDate = formatter.format(date);

    String formatLocation = "";
    if (location == "Port-Louis") {
      formatLocation = "Port-Louis";
    } else {
      formatLocation = "Quatre-Bornes";
    }

    // Format timeslot
    String time = timeSlot.split(":")[0];
    String minutes = timeSlot.split(":")[1];
    String formattedTimeSlot = "${time}HRS$minutes";

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        orientation: PageOrientation.portrait,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text(
              name.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            pw.Text(
              '${formattedDate.toUpperCase()} at ${formattedTimeSlot.toUpperCase()}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            pw.Text(
              formatLocation.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    final output = await pdf.save();

    return output;
  }

  static Widget _buildHeader(
      DateTime date, List<Map<String, dynamic>> appointments,
      {String? location}) {
    final appointmentsWithPhone = appointments
        .where((apt) =>
            apt['phoneNumber'] != null &&
            apt['phoneNumber'].toString().isNotEmpty)
        .length;
    final totalAppointments = appointments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
            'Appointment ${Util.dayName(date.weekday)} ${date.day}/${date.month}/${date.year}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Container(
          child: Text(
            'Location: $location',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.left,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Appointments: $totalAppointments',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                'With Phone Numbers: $appointmentsWithPhone',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildAppointment(List<Map<String, dynamic>> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          'No appointments found',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const FlexColumnWidth(2), // Time
        1: const FlexColumnWidth(4), // Name
        2: const FlexColumnWidth(3), // Phone
        3: const FlexColumnWidth(3), // Description
      },
      children: [
        // Header row
        TableRow(
          decoration: const BoxDecoration(color: PdfColors.grey200),
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Time',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Patient Name',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Phone Number',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Notes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        // Data rows
        ...appointments.map((appointment) {
          final patientName =
              "${appointment['patientFirstName']} ${appointment['patientLastName']}";
          final phoneNumber = appointment['phoneNumber']?.toString() ?? '';
          final time = appointment['time']?.toString() ?? '';
          final description = appointment['description']?.toString() ?? '';

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  patientName,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  phoneNumber.isNotEmpty ? phoneNumber : 'No phone',
                  style: TextStyle(
                    fontSize: 10,
                    color: phoneNumber.isNotEmpty
                        ? PdfColors.black
                        : PdfColors.grey600,
                    fontStyle: phoneNumber.isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  description.isNotEmpty ? description : '-',
                  style: TextStyle(
                    fontSize: 10,
                    color: description.isNotEmpty
                        ? PdfColors.black
                        : PdfColors.grey600,
                    fontStyle: description.isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
