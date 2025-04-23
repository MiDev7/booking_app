import 'package:flutter/material.dart';
import '../utils/database_manager.dart';

class StorageNotifier extends ChangeNotifier {
  String _storagePath = '';
  bool _initialized = false;

  String get storagePath => _storagePath;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    _storagePath = await StorageManager.getDatabasePath();
    _initialized = true;
    notifyListeners();
  }

  Future<void> updatePath(String newPath) async {
    await StorageManager.setStoragePath(newPath);
    _storagePath = newPath;
    
    notifyListeners();
  }
}
