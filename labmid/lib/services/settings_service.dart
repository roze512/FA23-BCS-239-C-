import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

/// Service for managing app settings
class SettingsService {
  final DatabaseService _databaseService = DatabaseService();

  /// Get setting value
  Future<String?> getSetting(String key) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> results = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );
      return results.isNotEmpty ? results.first['value'] as String? : null;
    } catch (e) {
      throw Exception('Failed to get setting: $e');
    }
  }

  /// Set setting value
  Future<void> setSetting(String key, String value) async {
    try {
      final db = await _databaseService.database;
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to set setting: $e');
    }
  }

  /// Delete setting
  Future<void> deleteSetting(String key) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );
    } catch (e) {
      throw Exception('Failed to delete setting: $e');
    }
  }

  /// Get auto backup enabled
  Future<bool> getAutoBackupEnabled() async {
    final value = await getSetting('auto_backup_enabled');
    return value == 'true';
  }

  /// Set auto backup enabled
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await setSetting('auto_backup_enabled', enabled.toString());
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTime() async {
    final value = await getSetting('last_backup_time');
    return value != null ? DateTime.tryParse(value) : null;
  }

  /// Set last backup timestamp
  Future<void> setLastBackupTime(DateTime time) async {
    await setSetting('last_backup_time', time.toIso8601String());
  }

  /// Get Google Drive email
  Future<String?> getGoogleDriveEmail() async {
    return await getSetting('google_drive_email');
  }

  /// Set Google Drive email
  Future<void> setGoogleDriveEmail(String email) async {
    await setSetting('google_drive_email', email);
  }

  /// Clear Google Drive email
  Future<void> clearGoogleDriveEmail() async {
    await deleteSetting('google_drive_email');
  }

  /// Get selected currency code
  Future<String?> getCurrencyCode() async {
    return await getSetting('currency_code');
  }

  /// Get selected currency symbol
  Future<String?> getCurrencySymbol() async {
    return await getSetting('currency_symbol');
  }

  /// Set currency preference
  Future<void> setCurrency(String code, String symbol) async {
    await setSetting('currency_code', code);
    await setSetting('currency_symbol', symbol);
  }
}
