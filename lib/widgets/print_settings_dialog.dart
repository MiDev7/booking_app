import 'package:booking_app/providers/print_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PrintSettingsDialog extends StatefulWidget {
  const PrintSettingsDialog({super.key});

  @override
  State<PrintSettingsDialog> createState() => _PrintSettingsDialogState();
}

class _PrintSettingsDialogState extends State<PrintSettingsDialog> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController widthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the controllers with default values if needed
    // Default width
    final printProvider = Provider.of<PrintProvider>(context, listen: false);
    heightController.text = printProvider.heightPrintingLabel.toString();
    widthController.text = printProvider.widthPrintingLabel.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.print, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 10),
          Text('Printing Settings')
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Height Input
            TextField(
              decoration: InputDecoration(
                labelText: 'Height',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: heightController,
            ),
            SizedBox(height: 25),

            // Width Input
            TextField(
              decoration: InputDecoration(
                labelText: 'Width',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              controller: widthController,
            ),
            SizedBox(height: 25),

            // Dropdown unit displaying the current unit
            Consumer<PrintProvider>(
              builder: (context, printProvider, child) {
                return DropdownButton<String>(
                  value: printProvider.unit == PdfPageFormat.mm ? 'mm' : 'cm',
                  items: <String>['cm', 'mm'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    printProvider.setUnit(newValue!);
                  },
                );
              },
            ),

            const SizedBox(
              height: 25,
            ),
            Text(
                "Printer Name: ${Provider.of<PrintProvider>(context).printer}"),

            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () async {
                final Printer? printer =
                    await Printing.pickPrinter(context: context);
                Provider.of<PrintProvider>(context, listen: false).setPrinter(printer!.name);
              },
              child: Text("Select Printer"),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('Save'),
          onPressed: () {
            Provider.of<PrintProvider>(context, listen: false)
                .setWidthPrintingLabel(double.parse(widthController.text));
            Provider.of<PrintProvider>(context, listen: false)
                .setHeightPrintingLabel(double.parse(heightController.text));
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
