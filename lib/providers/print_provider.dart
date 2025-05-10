import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PrintProvider extends ChangeNotifier {
  double _widthPrintingLabel = 0.0;
  double _heightPrintingLabel = 0.0;

  double _unit = PdfPageFormat.mm;

  double get widthPrintingLabel => _widthPrintingLabel;
  double get heightPrintingLabel => _heightPrintingLabel;
  double get unit => _unit;

  PrintProvider() {
    _loadPrintingLabelDimensions();
  }

  Future<void> _loadPrintingLabelDimensions() async {
    final prefs = await SharedPreferences.getInstance();
    _widthPrintingLabel = prefs.getDouble('widthPrintingLabel') ?? 50.0;
    _heightPrintingLabel = prefs.getDouble('heightPrintingLabel') ?? 25.0;
    _unit = prefs.getDouble('unit') ?? PdfPageFormat.mm;
    notifyListeners();
  }

  void setWidthPrintingLabel(double newWidth) {
    _widthPrintingLabel = newWidth;
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      prefs.setDouble('widthPrintingLabel', newWidth);
    });
    notifyListeners();
  }

  void setHeightPrintingLabel(double newHeight) {
    _heightPrintingLabel = newHeight;
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      prefs.setDouble('heightPrintingLabel', newHeight);
    });
    notifyListeners();
  }

  void setUnit(String newUnit) {
    if (newUnit == 'cm') {
      _unit = PdfPageFormat.cm;
    } else if (newUnit == 'mm') {
      _unit = PdfPageFormat.mm;
    } else {
      throw Exception('Invalid unit');
    }

    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      prefs.setDouble('unit', _unit);
    });

    notifyListeners();
  }

  void resetPrintingLabelDimensions() {
    _widthPrintingLabel = 50.0;
    _heightPrintingLabel = 25.0;
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      prefs.setDouble('widthPrintingLabel', _widthPrintingLabel);
      prefs.setDouble('heightPrintingLabel', _heightPrintingLabel);
    });
    notifyListeners();
  }
}
