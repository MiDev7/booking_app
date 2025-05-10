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
              _buildHeader(date, location: location),
              SizedBox(height: 20),
              _buildAppointment(appointments),
            ]));

    final output = await pdf.save();

    return output;
  }

  static Future<Uint8List> generateSingleAppointment(PdfPageFormat format,
      DateTime date, String name, String timeSlot, String location) async {
    final pdf = Document();
    final DateFormat formatter = DateFormat('dd/MM/yy');

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

  static Widget _buildHeader(DateTime date, {String? location}) {
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
      ],
    );
  }

  static Widget _buildAppointment(List<Map<String, dynamic>> appointments) {
    return TableHelper.fromTextArray(
      headers: ['Time', 'Patient'],
      data: appointments.map((appointment) {
        return [
          appointment['time'],
          "${appointment['patientFirstName']} ${appointment['patientLastName']}",
        ];
      }).toList(),
    );
  }
}
