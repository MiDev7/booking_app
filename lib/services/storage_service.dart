import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/database_manager.dart';
import '../utils/database_helper.dart';

class StorageService {
  static Future<String?> pickDirectory(BuildContext context) async {
    try {
      return await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Database Storage Location',
      );
    } on PlatformException catch (e) {
      if (e.code == 'ENTITLEMENT_NOT_FOUND') {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Permission Required'),
            content:
                Text('Please grant file access permissions in System Settings'),
          ),
        );
      }
    }
    return null;
  }

  static Future<void> handleStorageMigration(
      BuildContext context, String newPath) async {
    final isValid = await StorageManager.validateStoragePath(newPath);

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected location is not writable')),
      );
      return;
    }

    await DatabaseHelper().migrateDatabase(newPath);
    await DatabaseHelper().database;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Database moved to new location successfully')),
    );
  }
}
