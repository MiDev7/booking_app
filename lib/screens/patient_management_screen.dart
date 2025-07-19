import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../utils/database_helper.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final patients = await _databaseHelper.getPatients();
      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading patients: $e')),
      );
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((patient) {
          final firstName = patient['firstName']?.toLowerCase() ?? '';
          final lastName = patient['lastName']?.toLowerCase() ?? '';
          final phoneNumber = patient['phoneNumber']?.toLowerCase() ?? '';
          final phoneNumber2 = patient['phoneNumber2']?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return firstName.contains(searchQuery) ||
              lastName.contains(searchQuery) ||
              phoneNumber.contains(searchQuery) ||
              phoneNumber2.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _showAddPatientDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final phone2Controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Patient'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number 1 (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phone2Controller,
                decoration: const InputDecoration(
                  labelText: 'Phone Number 2 (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  // Check for duplicate patient
                  final existingPatient =
                      await _databaseHelper.findDuplicatePatient(
                    firstNameController.text.trim(),
                    lastNameController.text.trim(),
                  );

                  if (existingPatient != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Patient "${firstNameController.text.trim()} ${lastNameController.text.trim()}" already exists!',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final patient = {
                    'firstName': firstNameController.text.trim(),
                    'lastName': lastNameController.text.trim(),
                    'phoneNumber': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'phoneNumber2': phone2Controller.text.trim().isEmpty
                        ? null
                        : phone2Controller.text.trim(),
                  };

                  await _databaseHelper.insertPatient(patient);
                  Navigator.of(context).pop();
                  _loadPatients();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Patient added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding patient: $e')),
                  );
                }
              }
            },
            child: const Text('Add Patient'),
          ),
        ],
      ),
    );
  }

  void _showEditPatientDialog(Map<String, dynamic> patient) {
    final firstNameController =
        TextEditingController(text: patient['firstName']);
    final lastNameController = TextEditingController(text: patient['lastName']);
    final phoneController =
        TextEditingController(text: patient['phoneNumber'] ?? '');
    final phone2Controller =
        TextEditingController(text: patient['phoneNumber2'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Patient'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number 1 (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phone2Controller,
                decoration: const InputDecoration(
                  labelText: 'Phone Number 2 (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final updatedPatient = {
                    'firstName': firstNameController.text.trim(),
                    'lastName': lastNameController.text.trim(),
                    'phoneNumber': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'phoneNumber2': phone2Controller.text.trim().isEmpty
                        ? null
                        : phone2Controller.text.trim(),
                  };

                  await _databaseHelper.updatePatient(
                      patient['id'], updatedPatient);
                  Navigator.of(context).pop();
                  _loadPatients();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Patient updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating patient: $e')),
                  );
                }
              }
            },
            child: const Text('Update Patient'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text(
          'Are you sure you want to delete ${patient['firstName']} ${patient['lastName']}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _databaseHelper.deletePatient(patient['id']);
                Navigator.of(context).pop();
                _loadPatients();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patient deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting patient: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showCSVFormatDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('CSV Import Format'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expected CSV format:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: const Text(
                      'QR Imprimer, Surnom, Prenom, Tel. Domicile, Tel. Mobile',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('The following fields will be imported:'),
                  const SizedBox(height: 8),
                  const Text('• Surnom → Last Name (required)'),
                  const Text('• Prenom → First Name (required)'),
                  const Text('• Tel. Domicile → Phone Number 2 (optional)'),
                  const Text('• Tel. Mobile → Phone Number 1 (optional)'),
                  const SizedBox(height: 16),
                  const Text(
                    'Note: Duplicate patients will be skipped.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _importFromCSV() async {
    // Show format info first
    final confirmed = await _showCSVFormatDialog();
    if (!confirmed) return;

    try {
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString(encoding: utf8);

        // Parse CSV
        final lines = contents.split('\n');
        if (lines.isEmpty) {
          throw Exception('CSV file is empty');
        }

        int importedCount = 0;
        int skippedCount = 0;
        List<String> errors = [];

        // Skip header row and process data rows
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          try {
            // Split by comma and handle quoted fields
            final fields = _parseCSVLine(line);

            if (fields.length < 4) {
              errors.add('Line ${i + 1}: Not enough columns');
              skippedCount++;
              continue;
            }

            // Extract: Surnom (index 1), Prenom (index 2), Tel. Domicile (index 3), Tel. Mobile (index 4)
            final surnom = fields.length > 1 ? fields[1].trim() : '';
            final prenom = fields.length > 2 ? fields[2].trim() : '';
            final telDomicile = fields.length > 3 ? fields[3].trim() : '';
            final telMobile = fields.length > 4 ? fields[4].trim() : '';

            // Validate required fields
            if (surnom.isEmpty || prenom.isEmpty) {
              errors.add('Line ${i + 1}: Missing required name fields');
              skippedCount++;
              continue;
            }

            // Check if patient already exists
            final existingPatient =
                await _databaseHelper.findDuplicatePatient(prenom, surnom);
            if (existingPatient != null) {
              // Update phone numbers if they're missing in existing record
              bool updated = false;
              if (existingPatient['phoneNumber'] == null &&
                  telMobile.isNotEmpty) {
                await _databaseHelper.updatePatientPhoneNumbers(
                  existingPatient['id'],
                  telMobile,
                  existingPatient['phoneNumber2'],
                );
                updated = true;
              }
              if (existingPatient['phoneNumber2'] == null &&
                  telDomicile.isNotEmpty) {
                await _databaseHelper.updatePatientPhoneNumbers(
                  existingPatient['id'],
                  existingPatient['phoneNumber'],
                  telDomicile,
                );
                updated = true;
              }

              if (!updated) {
                errors.add(
                    'Line ${i + 1}: Patient "$prenom $surnom" already exists');
                skippedCount++;
              } else {
                importedCount++;
              }
              continue;
            }

            // Create patient
            final patient = {
              'firstName': prenom,
              'lastName': surnom,
              'phoneNumber': telMobile.isEmpty ? null : telMobile,
              'phoneNumber2': telDomicile.isEmpty ? null : telDomicile,
            };

            await _databaseHelper.insertPatient(patient);
            importedCount++;
          } catch (e) {
            errors.add('Line ${i + 1}: ${e.toString()}');
            skippedCount++;
          }
        }

        // Refresh the patient list
        await _loadPatients();

        // Show import results
        _showImportResultDialog(importedCount, skippedCount, errors);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing CSV: $e')),
      );
    }
  }

  Future<void> _showClearDatabaseDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Patients'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'This will permanently delete ALL patients from the database.'),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseHelper.deleteAllPatients();
        await _loadPatients();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All patients deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _parseCSVLine(String line) {
    List<String> fields = [];
    bool inQuotes = false;
    String currentField = '';

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }

    // Add the last field
    fields.add(currentField.trim());

    return fields;
  }

  void _showImportResultDialog(int imported, int skipped, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Successfully imported: $imported patients'),
              if (skipped > 0) Text('⚠️ Skipped: $skipped entries'),
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Errors:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Flexible(
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: errors.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          errors[index],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patient Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        elevation: 3,
        actions: [
          ElevatedButton.icon(
            onPressed: _showAddPatientDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Patient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _importFromCSV,
            icon: const Icon(Icons.upload_file),
            label: const Text('Import CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _showClearDatabaseDialog,
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Clear All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _loadPatients,
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients by name or phone...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterPatients('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: _filterPatients,
            ),
          ),

          // Stats Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Patients',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${_patients.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_filteredPatients.length != _patients.length)
                      Text(
                        'Showing ${_filteredPatients.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Patient List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _patients.isEmpty
                                  ? 'No patients found\nAdd your first patient!'
                                  : 'No patients match your search',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = _filteredPatients[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: Text(
                                  '${patient['firstName'][0]}${patient['lastName'][0]}'
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${patient['firstName']} ${patient['lastName']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (patient['phoneNumber'] != null ||
                                      patient['phoneNumber2'] != null) ...[
                                    if (patient['phoneNumber'] != null)
                                      Row(
                                        children: [
                                          Icon(Icons.phone,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          SizedBox(width: 4),
                                          Text(
                                            'Mobile: ${patient['phoneNumber']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (patient['phoneNumber2'] != null)
                                      Row(
                                        children: [
                                          Icon(Icons.home,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          SizedBox(width: 4),
                                          Text(
                                            'Home: ${patient['phoneNumber2']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ] else
                                    Text(
                                      'No phone numbers',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) {
                                  switch (action) {
                                    case 'edit':
                                      _showEditPatientDialog(patient);
                                      break;
                                    case 'delete':
                                      _showDeleteConfirmationDialog(patient);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
