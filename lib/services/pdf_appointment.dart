import 'dart:typed_data';
import 'package:pdf/widgets.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:booking_app/utils/utils.dart';

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

  static Widget _buildHeader(DateTime date, {String? location}) {
    return Column(
      children: [
        Text(
            'Appointment ${Util.dayName(date.weekday)} ${date.day}/${date.month}/${date.year}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Container(
          margin: EdgeInsets.only(left: 0),
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
