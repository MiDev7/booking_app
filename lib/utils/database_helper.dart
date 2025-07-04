import 'package:booking_app/models/public_holidays.dart';
import 'package:booking_app/utils/database_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/appointment_model.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  static String? _dbPath;

  DatabaseHelper._internal();

  // Singleton pattern
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    _dbPath = join(directory.path, 'appointments.db');
    return await openDatabase(
      _dbPath!,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create the appointments table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE appointments(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      patientFirstName TEXT,
      patientLastName TEXT,
      location TEXT,
      date TEXT,
      time TEXT
    )
  ''');

    await db.execute('''
  CREATE TABLE week_preferences (
    week TEXT PRIMARY KEY,
    location TEXT
    )
''');

    await db.execute('''
    CREATE TABLE public_holidays (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT
    )
    ''');
  }

  // Upgrade the appointments table
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
       CREATE TABLE IF NOT EXISTS week_preferences(
         week TEXT PRIMARY KEY,
         location TEXT
       )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS public_holidays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT
      )
      ''');
    }
  }

  // DATABASE FUNCTIONS
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> migrateDatabase(String newPath) async {
    await closeDatabase();

    final oldPath = await StorageManager.getDatabasePath();
    final newDbPath = join(newPath, 'appointments.db');
    if (await File(oldPath).exists()) {
      await File(oldPath).copy(newDbPath);
      await File(oldPath).delete();
    } else {
      await File(newDbPath).create(recursive: true);
    }

    _dbPath = newPath;
    await StorageManager.setStoragePath(newPath);
    _database = await _initDatabase();
  }

  // =======================================================================================
  // APPOINTMENTS

  // Insert an appointment into the database
  Future<int> insertAppointment(AppointmentModel appointment) async {
    Database db = await database;
    return await db.insert('appointments', appointment.toJson());
  }

  // Get all appointments from the database
  Future<List<Map<String, dynamic>>> getAppointments() async {
    Database db = await database;
    return await db.query('appointments');
  }

  // Get an appointment by its ID
  Future<List<Map<String, dynamic>>> getAppointmentsByDateAndLocation(
      String date, String location) async {
    Database db = await database;
    return await db.query('appointments',
        where: 'date = ? AND location = ?', whereArgs: [date, location]);
  }

  // Get an appointment by its Date
  Future<List<Map<String, dynamic>>> getAppointmentsByDate(String date) async {
    Database db = await database;
    return await db.query('appointments', where: 'date = ?', whereArgs: [date]);
  }

  // Get an appointment by date and time and location
  Future<List<Map<String, dynamic>>> getAppointmentsByDateAndTimeAndLocation(
      String date, String time, String location) async {
    Database db = await database;
    return await db.query('appointments',
        where: 'date = ? AND time = ? AND location = ?',
        whereArgs: [date, time, location]);
  }

  Future<bool> isAppointmentBooked(
      String date, String time, String location) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final DateTime startDateTime = DateTime(2000, 1, 1, hour, minute);
    final DateTime endDateTime = startDateTime.add(const Duration(minutes: 30));

    final String startTime =
        "${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}";
    final String endTime =
        "${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}";

    Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM appointments WHERE date = ? AND location = ? AND time >= ? AND time < ?",
      [date, location, startTime, endTime],
    );
    return result.isNotEmpty;
  }

  Future<bool> updateAppointmentDateTimeLocation(
      String id, String date, String time, String location) async {
    Database db = await database;
    try {
      // ignore: unused_local_variable
      int result = await db.update(
        'appointments',
        {
          'date': date,
          'time': time,
          'location': location,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return false;
    }

    return true;
  }

  Future<int> isAppointmentBookedCount(
      String date, String timeSlot, String location) async {
    // Example: For a timeSlot "16:00", count appointments between 16:00 and 16:30.
    final parts = timeSlot.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final DateTime startDateTime = DateTime(2000, 1, 1, hour, minute);
    final DateTime endDateTime = startDateTime.add(const Duration(minutes: 30));

    final String startTime =
        "${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}";
    final String endTime =
        "${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}";

    // Check if query is saturday
    final DateTime dateTime = DateTime.parse(date);
    if (dateTime.weekday == DateTime.saturday) {
      // If it's Saturday, check for appointments on the next day (Sunday)
    }

    Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM appointments WHERE date = ? AND location = ? AND time >= ? AND time < ?",
      [date, location, startTime, endTime],
    );
    return result.isNotEmpty ? result.first['count'] as int : 0;
  }

  Future<int> deleteAppointment(int id) async {
    Database db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllAppointments() async {
    Database db = await database;
    await db.delete('appointments');
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByName(String name) async {
    final trimmedName = name.trim();
    List<Map<String, dynamic>> result;
    Database db = await database;
    if (trimmedName.isEmpty) {
      result = [];
      return result;
    } else {
      final nameParts =
          trimmedName.split(' ').where((part) => part.isNotEmpty).toList();

      if (nameParts.isEmpty) {
        // This case handles if the input name was, for example, "   "
        // and somehow passed the initial trimmedName.isEmpty check (though unlikely).
        result = [];
      } else if (nameParts.length == 1) {
        // User provided a single name part (e.g., "John" or "Doe")
        // Search for this part in both patientFirstName and patientLastName
        final singleNamePart = nameParts[0];
        result = await db.rawQuery(
          "SELECT * FROM appointments WHERE patientFirstName LIKE ? OR patientLastName LIKE ?",
          ['%$singleNamePart%', '%$singleNamePart%'],
        );
      } else {
        // User provided multiple name parts (e.g., "John Doe")
        // term1 is the first word, term2 is the rest of the string
        final String term1 = nameParts[0];
        final String term2 = nameParts.sublist(1).join(' ');

        // Search for:
        // 1. patientFirstName matches term1 AND patientLastName matches term2 (e.g., FN: John, LN: Doe)
        // 2. patientFirstName matches term2 AND patientLastName matches term1 (e.g., FN: Doe, LN: John) - handles reversed order
        result = await db.rawQuery(
          "SELECT * FROM appointments WHERE (patientFirstName LIKE ? AND patientLastName LIKE ?) OR (patientFirstName LIKE ? AND patientLastName LIKE ?)",
          ['%$term1%', '%$term2%', '%$term2%', '%$term1%'],
        );
      }

      return result;
    }
  }

  // =======================================================================================
  // WEEK PREFERENCES
  Future<void> setWeekPreference(String weekKey, String location) async {
    Database db = await database;
    await db.insert(
      'week_preferences',
      {'week': weekKey, 'location': location},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getWeekPreference(String weekKey) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'week_preferences',
      where: 'week = ?',
      whereArgs: [weekKey],
    );
    if (result.isNotEmpty) {
      return result.first['location'] as String?;
    }
    return null;
  }

  // =======================================================================================
  // PUBLIC HOLIDAYS
  Future<List<Map<String, dynamic>>> getPublicHolidays() async {
    Database db = await database;
    return await db.query("public_holidays");
  }

  Future<int> deletePublicHolidays(int id) async {
    Database db = await database;
    return await db.delete('public_holidays', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertPublicHolidays(publicHolidaysModel publicHolidays) async {
    Database db = await database;
    return await db.insert('public_holidays', publicHolidays.toJson());
  }

  Future<void> deleteAllPublicHolidays() async {
    Database db = await database;
    await db.delete('public_holidays');
  }
}
