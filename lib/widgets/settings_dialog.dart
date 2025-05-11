import 'package:flutter/material.dart';
import 'package:booking_app/services/storage_service.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.storage, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 10),
          Text('Storage Settings')
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ... other settings widgets ...
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: const Text('Backup Database'),
              onPressed: () async {
                final backupFolder =
                    await StorageService.pickBackupFolder(context);
                if (backupFolder != null) {
                  await StorageService.backupCurrentDatabase(
                      context, backupFolder);
                }
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Load Backup'),
              onPressed: () async {
                await StorageService.loadBackupDatabase(context);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
