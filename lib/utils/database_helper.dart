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
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    _dbPath = join(directory.path, 'appointments.db');
    return await openDatabase(
      _dbPath!,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create the appointments table
  Future<void> _onCreate(Database db, int version) async {
    // Create patients table
    await db.execute('''
    CREATE TABLE IF NOT EXISTS patients(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      firstName TEXT NOT NULL,
      lastName TEXT NOT NULL,
      phoneNumber TEXT,
      phoneNumber2 TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS appointments(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      patientId INTEGER,
      patientFirstName TEXT,
      patientLastName TEXT,
      location TEXT,
      description TEXT,
      date TEXT,
      time TEXT,
      FOREIGN KEY (patientId) REFERENCES patients (id)
    )
  ''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS week_preferences (
    week TEXT PRIMARY KEY,
    location TEXT
    )
''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS public_holidays (
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

    if (oldVersion < 4) {
      final columns = await db.rawQuery('PRAGMA table_info(appointments)');
      final hasDescription =
          columns.any((column) => column['name'] == 'description');

      if (!hasDescription) {
        await db.execute('''
        ALTER TABLE appointments ADD COLUMN description TEXT
     ''');
      }
    }

    if (oldVersion < 5) {
      // Create patients table
      await db.execute('''
      CREATE TABLE IF NOT EXISTS patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        phoneNumber TEXT
      )
      ''');

      final columns = await db.rawQuery('PRAGMA table_info(appointments)');
      final hasPatientId =
          columns.any((column) => column['name'] == 'patientId');
      // Add patientId column to appointments table
      if (!hasPatientId) {
        await db.execute('''
      ALTER TABLE appointments ADD COLUMN patientId INTEGER
      ''');
      }
    }

    if (oldVersion < 6) {
      // Add second phone number column to patients table
      final columns = await db.rawQuery('PRAGMA table_info(patients)');
      final hasPhoneNumber2 =
          columns.any((column) => column['name'] == 'phoneNumber2');

      if (!hasPhoneNumber2) {
        await db.execute('''
        ALTER TABLE patients ADD COLUMN phoneNumber2 TEXT
        ''');
      }
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
  // PATIENTS

  // Insert a patient into the database
  Future<int> insertPatient(Map<String, dynamic> patient) async {
    Database db = await database;
    return await db.insert('patients', patient);
  }

  // Get all patients from the database
  Future<List<Map<String, dynamic>>> getPatients() async {
    Database db = await database;
    return await db.query('patients', orderBy: 'lastName, firstName');
  }

  // Get a patient by ID
  Future<Map<String, dynamic>?> getPatientById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update a patient
  Future<int> updatePatient(int id, Map<String, dynamic> patient) async {
    Database db = await database;
    return await db.update(
      'patients',
      patient,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a patient
  Future<int> deletePatient(int id) async {
    Database db = await database;
    return await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // Search patients by name or phone number
  Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    Database db = await database;
    return await db.rawQuery(
      "SELECT * FROM patients WHERE firstName LIKE ? OR lastName LIKE ? OR phoneNumber LIKE ? OR phoneNumber2 LIKE ? ORDER BY lastName, firstName",
      ['%$query%', '%$query%', '%$query%', '%$query%'],
    );
  }

  // Clear all patients from the database
  Future<void> deleteAllPatients() async {
    Database db = await database;
    await db.delete('patients');
  }

  // Check for duplicate patient (same first and last name)
  Future<Map<String, dynamic>?> findDuplicatePatient(
      String firstName, String lastName) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'patients',
      where: 'LOWER(firstName) = ? AND LOWER(lastName) = ?',
      whereArgs: [firstName.toLowerCase(), lastName.toLowerCase()],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update patient phone numbers only
  Future<int> updatePatientPhoneNumbers(
      int id, String? phoneNumber1, String? phoneNumber2) async {
    Database db = await database;
    Map<String, dynamic> updateData = {};

    if (phoneNumber1 != null && phoneNumber1.isNotEmpty) {
      updateData['phoneNumber'] = phoneNumber1;
    }
    if (phoneNumber2 != null && phoneNumber2.isNotEmpty) {
      updateData['phoneNumber2'] = phoneNumber2;
    }

    if (updateData.isNotEmpty) {
      return await db.update(
        'patients',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
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

  // Get appointments with patient phone numbers for a specific date and location
  Future<List<Map<String, dynamic>>> getAppointmentsWithPhoneByDateAndLocation(
      String date, String location) async {
    Database db = await database;

    // Join appointments with patients table to get phone numbers
    final queryResult = await db.rawQuery('''
      SELECT
        a.*,
        p.phoneNumber,
        p.phoneNumber2
      FROM appointments a
      LEFT JOIN patients p ON a.patientId = p.id
      WHERE a.date = ? AND a.location = ?
    ''', [date, location]);

    // Create mutable copies and handle phone number lookup for appointments without patientId
    final List<Map<String, dynamic>> result = [];

    for (var appointment in queryResult) {
      // Create a mutable copy of the appointment data
      final mutableAppointment = Map<String, dynamic>.from(appointment);

      if (mutableAppointment['phoneNumber'] == null &&
          mutableAppointment['patientFirstName'] != null &&
          mutableAppointment['patientLastName'] != null) {
        // Try to find phone numbers using enhanced name matching
        final phoneNumbers = await _findPhoneNumbersByName(
          db,
          mutableAppointment['patientFirstName'],
          mutableAppointment['patientLastName'],
        );

        if (phoneNumbers['phoneNumber'] != null) {
          mutableAppointment['phoneNumber'] = phoneNumbers['phoneNumber'];
        }
        if (phoneNumbers['phoneNumber2'] != null) {
          mutableAppointment['phoneNumber2'] = phoneNumbers['phoneNumber2'];
        }
      }

      result.add(mutableAppointment);
    }

    return result;
  }

  // Enhanced method to find phone numbers by name with flexible matching
  Future<Map<String, String?>> _findPhoneNumbersByName(
      Database db, String firstName, String lastName) async {
    // Try exact match first
    var searchResults = await db.rawQuery('''
      SELECT phoneNumber, phoneNumber2 FROM patients
      WHERE firstName = ? AND lastName = ?
      LIMIT 1
    ''', [firstName, lastName]);

    if (searchResults.isNotEmpty) {
      return {
        'phoneNumber': searchResults.first['phoneNumber'] as String?,
        'phoneNumber2': searchResults.first['phoneNumber2'] as String?,
      };
    }

    // If exact match fails, try parsing the name fields for embedded information
    // Handle cases like "John Doe payment 1000" where first/last names contain extra info

    // Parse first name (might contain extra words)
    final firstNameWords = firstName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    // Parse last name (might contain extra words)
    final lastNameWords = lastName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    // Combine all words to try different combinations
    final allWords = [...firstNameWords, ...lastNameWords];

    if (allWords.length >= 2) {
      // Try different combinations of words as first name and last name
      for (int i = 0; i < allWords.length - 1; i++) {
        for (int j = i + 1; j < allWords.length; j++) {
          // Try word[i] as first name, word[j] as last name
          searchResults = await db.rawQuery('''
            SELECT phoneNumber, phoneNumber2 FROM patients
            WHERE firstName LIKE ? AND lastName LIKE ?
            LIMIT 1
          ''', ['%${allWords[i]}%', '%${allWords[j]}%']);

          if (searchResults.isNotEmpty &&
              (searchResults.first['phoneNumber'] != null ||
                  searchResults.first['phoneNumber2'] != null)) {
            return {
              'phoneNumber': searchResults.first['phoneNumber'] as String?,
              'phoneNumber2': searchResults.first['phoneNumber2'] as String?,
            };
          }

          // Try word[j] as first name, word[i] as last name (reversed)
          searchResults = await db.rawQuery('''
            SELECT phoneNumber, phoneNumber2 FROM patients
            WHERE firstName LIKE ? AND lastName LIKE ?
            LIMIT 1
          ''', ['%${allWords[j]}%', '%${allWords[i]}%']);

          if (searchResults.isNotEmpty &&
              (searchResults.first['phoneNumber'] != null ||
                  searchResults.first['phoneNumber2'] != null)) {
            return {
              'phoneNumber': searchResults.first['phoneNumber'] as String?,
              'phoneNumber2': searchResults.first['phoneNumber2'] as String?,
            };
          }
        }
      }

      // Try combinations of consecutive words
      for (int startIdx = 0; startIdx < allWords.length - 1; startIdx++) {
        for (int nameLength = 1;
            nameLength <= 2 && startIdx + nameLength < allWords.length;
            nameLength++) {
          final potentialFirstName =
              allWords.sublist(startIdx, startIdx + nameLength).join(' ');

          for (int lastStartIdx = startIdx + nameLength;
              lastStartIdx < allWords.length;
              lastStartIdx++) {
            for (int lastLength = 1;
                lastLength <= 2 && lastStartIdx + lastLength <= allWords.length;
                lastLength++) {
              final potentialLastName = allWords
                  .sublist(lastStartIdx, lastStartIdx + lastLength)
                  .join(' ');

              // Try this combination
              searchResults = await db.rawQuery('''
                SELECT phoneNumber, phoneNumber2 FROM patients
                WHERE firstName LIKE ? AND lastName LIKE ?
                LIMIT 1
              ''', ['%$potentialFirstName%', '%$potentialLastName%']);

              if (searchResults.isNotEmpty &&
                  (searchResults.first['phoneNumber'] != null ||
                      searchResults.first['phoneNumber2'] != null)) {
                return {
                  'phoneNumber': searchResults.first['phoneNumber'] as String?,
                  'phoneNumber2':
                      searchResults.first['phoneNumber2'] as String?,
                };
              }
            }
          }
        }
      }

      // Last resort: try fuzzy matching with individual words
      for (final word in allWords) {
        if (word.length >= 3) {
          // Only try words with 3+ characters to avoid false matches
          searchResults = await db.rawQuery('''
            SELECT phoneNumber, phoneNumber2, firstName, lastName FROM patients
            WHERE firstName LIKE ? OR lastName LIKE ?
            LIMIT 1
          ''', ['%$word%', '%$word%']);

          if (searchResults.isNotEmpty &&
              (searchResults.first['phoneNumber'] != null ||
                  searchResults.first['phoneNumber2'] != null)) {
            return {
              'phoneNumber': searchResults.first['phoneNumber'] as String?,
              'phoneNumber2': searchResults.first['phoneNumber2'] as String?,
            };
          }
        }
      }
    }

    return {
      'phoneNumber': null,
      'phoneNumber2': null,
    }; // No phone numbers found
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
