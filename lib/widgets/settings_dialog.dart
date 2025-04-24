import 'package:booking_app/utils/database_helper.dart';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/database_manager.dart';
import '../providers/storage_provider.dart';
import 'package:provider/provider.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late Future<String?> _currentPath;

  @override
  void initState() {
    super.initState();
    _currentPath = StorageManager.getDatabasePath();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.storage, color: Colors.blue),
          SizedBox(width: 10),
          Text('Storage Configuration')
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<StorageNotifier>(
              builder: (context, storageNotifier, child) {
                return Text(
                  'Current Location: \n ${storageNotifier.storagePath}',
                  style: TextStyle(fontSize: 14),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.folder_open),
              label: Text('Change Storage Location'),
              onPressed: () async {
                final newPath = await StorageService.pickDirectory(context);
                if (newPath != null) {
                  await StorageService.handleStorageMigration(context, newPath);
                  Provider.of<StorageNotifier>(context, listen: false)
                      .updatePath(newPath);
                  setState(() {
                    _currentPath = StorageManager.getDatabasePath();
                  });
                }

                print(newPath);
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.download),
              label: Text('Load Storage '),
              onPressed: () async {
                // Replace this with your actual directory picker:
                String? chosenDirectory = await StorageService.pickDirectory(context);
                if (chosenDirectory != null &&
                    await StorageManager.validateStoragePath(chosenDirectory)) {
                  await DatabaseHelper().migrateDatabase(chosenDirectory);
                  // Optionally update your StorageNotifier or show a success message.
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text("Database loaded from new location successfully."),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Invalid directory or unable to access it."),
                  ));
                }
              },
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
