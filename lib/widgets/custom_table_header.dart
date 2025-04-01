import 'package:flutter/material.dart';

class CustomTableHeader extends StatelessWidget {
  final String text;
  final bool? isIcon;

  const CustomTableHeader({super.key, required this.text, this.isIcon = false});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: isIcon!
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    Icons.timer_outlined,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ])
              : Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
        ),
      ),
    );
  }
}
