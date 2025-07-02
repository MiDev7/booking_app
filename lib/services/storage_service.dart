import 'package:booking_app/providers/date_provider.dart';
import 'package:booking_app/providers/holiday_provider.dart';
import 'package:booking_app/providers/location_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/database_manager.dart';

class StorageService {
  // Backup the current database to a user-selected folder.
  static Future<void> backupCurrentDatabase(
      BuildContext context, String backupFolderPath) async {
    try {
      await StorageManager.backupDatabase(backupFolderPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Backup successful.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Backup failed: $e")),
      );
    }
  }

  // Let the user pick a backup file and restore it.
  static Future<void> loadBackupDatabase(BuildContext context) async {
    String? backupFilePath = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    ).then((result) => result?.files.single.path);
    if (backupFilePath != null) {
      try {
        await StorageManager.loadBackupDatabase(backupFilePath);

        // 1. Reload holidays
        await Provider.of<HolidayProvider>(context, listen: false)
            .loadHolidays();

        // 2. Reload location for the current week
        final dateProvider = Provider.of<DateProvider>(context, listen: false);
        final monday = dateProvider.workingDays
            .firstWhere((d) => d.weekday == DateTime.monday);
        final weekKey = DateFormat('yyyy-MM-dd').format(monday);
        await Provider.of<LocationProvider>(context, listen: false)
            .loadLocation(weekKey);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Database restored from backup.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Restore failed: $e")),
        );
      }
    }
  }

  // Optionally, let the user select a folder for backup.
  static Future<String?> pickBackupFolder(BuildContext context) async {
    return await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Backup Folder',
    );
  }
}
