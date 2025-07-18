import 'package:flutter/foundation.dart';
import '../utils/database_helper.dart';
import '../models/patient_model.dart';

class PatientProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<PatientModel> _patients = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PatientModel> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPatients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final patientsData = await _databaseHelper.getPatients();
      _patients =
          patientsData.map((data) => PatientModel.fromJson(data)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load patients: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPatient(PatientModel patient) async {
    try {
      await _databaseHelper.insertPatient(patient.toJson());
      await loadPatients(); // Refresh the list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add patient: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePatient(PatientModel patient) async {
    try {
      if (patient.id == null) {
        throw Exception('Patient ID is required for update');
      }
      await _databaseHelper.updatePatient(patient.id!, patient.toJson());
      await loadPatients(); // Refresh the list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update patient: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePatient(int patientId) async {
    try {
      await _databaseHelper.deletePatient(patientId);
      await loadPatients(); // Refresh the list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete patient: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<PatientModel>> searchPatients(String query) async {
    try {
      final searchResults = await _databaseHelper.searchPatients(query);
      return searchResults.map((data) => PatientModel.fromJson(data)).toList();
    } catch (e) {
      _errorMessage = 'Failed to search patients: $e';
      notifyListeners();
      return [];
    }
  }

  PatientModel? findPatientById(int id) {
    try {
      return _patients.firstWhere((patient) => patient.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
