import 'package:intl/intl.dart';

class publicHolidaysModel {
   int? id;
   DateTime date;

   publicHolidaysModel({ this.id, required this.date});

   Map<String, dynamic> toJson() {
     // Use the same formatted date as used in queries: yyyy-MM-dd.
     final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
     return {
       if (id != null) 'id': id,
       'date': formattedDate
     };
   }
}