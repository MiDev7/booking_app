import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageManager {
  static const _dbPathKey = 'database_path';

  // Get the database path from SharedPreferences or return a default value.
  static Future<String> getDatabasePath() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString(_dbPathKey);
    if (savedPath == null || savedPath.isEmpty) {
      // Return default path if not set, e.g. documents directory + 'appointments.db'
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

  static Future<bool> validateStoragePath(String storagePath) async {
    try {
      final testFile = await File(join(storagePath, 'test.txt')).create();
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> moveDatabaseFile(String oldPath, String newPath) async {
    final oldFile = File(oldPath);
    final newFile = File(newPath);
    if (await oldFile.exists()) {
      await oldFile.rename(newPath);
    }
  }

  // Returns a default directory (e.g. the application documents directory).
  static Future<Directory> getDefaultDirectory() async {
    // Use path_provider package for documents directory.
    // For example:
    // final dir = await getApplicationDocumentsDirectory();
    // return dir;
    throw UnimplementedError('Implement getDefaultDirectory');
  }
}
