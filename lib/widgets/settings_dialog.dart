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
