import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import 'database_service.dart';

/// Service for managing notifications
class NotificationService {
  final DatabaseService _databaseService = DatabaseService();

  /// Get all notifications
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notifications',
        orderBy: 'createdAt DESC',
      );
      return List.generate(maps.length, (i) {
        return NotificationModel.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  /// Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notifications',
        where: 'isRead = ?',
        whereArgs: [0],
        orderBy: 'createdAt DESC',
      );
      return List.generate(maps.length, (i) {
        return NotificationModel.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to load unread notifications: $e');
    }
  }

  /// Add notification
  Future<void> addNotification(NotificationModel notification) async {
    try {
      final db = await _databaseService.database;
      await db.insert(
        'notifications',
        notification.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to add notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'notifications',
        {'isRead': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'notifications',
        {'isRead': 1},
        where: 'isRead = ?',
        whereArgs: [0],
      );
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String id) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Create low stock alert
  Future<void> createLowStockAlert(int productCount) async {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      type: 'low_stock',
      title: 'Low Stock Alert',
      message: '$productCount products below minimum stock. Review inventory.',
      createdAt: DateTime.now(),
    );
    await addNotification(notification);
  }

  /// Create payment due reminder
  Future<void> createPaymentDueReminder(String customerName, double amount) async {
    final formattedAmount = amount.toStringAsFixed(2);
    final notification = NotificationModel(
      id: const Uuid().v4(),
      type: 'payment_due',
      title: 'Payment Due Reminder',
      message: 'Customer $customerName has \$$formattedAmount pending payments overdue.',
      createdAt: DateTime.now(),
    );
    await addNotification(notification);
  }

  /// Create daily sales report notification
  Future<void> createDailySalesReport(double percentageChange) async {
    final sign = percentageChange > 0 ? '+' : '';
    final formattedPercentage = percentageChange.toStringAsFixed(1);
    final notification = NotificationModel(
      id: const Uuid().v4(),
      type: 'daily_sales',
      title: 'Daily Sales Report',
      message: 'Yesterday\'s sales summary is ready. You reached $sign$formattedPercentage% of daily goal.',
      createdAt: DateTime.now(),
    );
    await addNotification(notification);
  }

  /// Create system notification
  Future<void> createSystemNotification(String title, String message) async {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      type: 'system',
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );
    await addNotification(notification);
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM notifications WHERE isRead = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
