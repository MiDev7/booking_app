import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/appointment_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  // Singleton pattern
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'appointments.db');
    return await openDatabase(
      path,
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
  }

  // Upgrade the appointments table
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS appointments');
    await _onCreate(db, newVersion);
  }

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
    print("$id $date $time $location");

    Database db = await database;
    try {
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

      print('Updated $result appointment(s) with ID: $id');
    } catch (e) {
      print('Error updating appointment: $e');
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

  Future<void> closeDatabase() async {
    Database db = await database;
    await db.close();
  }

  Future<List<Map<String, dynamic>>> getAppointmentsByName(String name) async {
    Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT * FROM appointments WHERE patientFirstName LIKE ? OR patientLastName LIKE ?",
      ['%$name%', '%$name%'],
    );

    return result;
  }
}
