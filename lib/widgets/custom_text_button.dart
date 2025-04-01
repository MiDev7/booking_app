import 'package:booking_app/providers/date_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomTextButton extends StatelessWidget {
  final String text;

  const CustomTextButton({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DateProvider>(
      builder: (context, value, child) => ElevatedButton(
        onPressed: () {
          final weekNum = context.read<DateProvider>();

          if (text == "Now") {
            weekNum.currentDate(DateTime.now());
            return;
          } else {
            try {
              int.parse(text);
            } catch (e) {
              return;
            }
            weekNum.jumpWeeks(int.parse(text));
          }
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
