import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booking_app/utils/database_helper.dart';

class StorageManager {
  static const _dbPathKey = 'database_path';

  static Future<String> getDatabasePath() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString(_dbPathKey);
    if (savedPath == null || savedPath.isEmpty) {
      final directory = await getApplicationDocumentsDirectory();
      savedPath = join(directory.path, 'appointments.db');
      await prefs.setString(_dbPathKey, savedPath);
    }
    return savedPath;
  }

  static Future<void> setStoragePath(String newPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dbPathKey, newPath);
  }

  static Future<void> backupDatabase(String backupFolderPath) async {
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw Exception("Database file not found.");
    }
    final backupFolder = Directory(backupFolderPath);
    if (!await backupFolder.exists()) {
      await backupFolder.create(recursive: true);
    }
    // Create a backup file name with a timestamp.
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFilePath =
        join(backupFolderPath, 'appointments_backup_$timestamp.db');
    await dbFile.copy(backupFilePath);
  }

  static Future<void> loadBackupDatabase(String backupFilePath) async {
    await DatabaseHelper().closeDatabase();
    final directory = await getApplicationDocumentsDirectory();
    final newDbPath = join(directory.path, 'appointments.db');
    final backupFile = File(backupFilePath);
    if (!await backupFile.exists()) {
      throw Exception("Backup file does not exist.");
    }
    final currentDbFile = File(newDbPath);
    if (await currentDbFile.exists()) {
      await currentDbFile.delete();
    }
    await backupFile.copy(newDbPath);
    await DatabaseHelper().database;
  }
}
