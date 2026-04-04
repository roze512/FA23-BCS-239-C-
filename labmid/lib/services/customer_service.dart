import 'package:sqflite/sqflite.dart';
import '../models/customer_model.dart';
import 'database_service.dart';
import 'firestore_sync_service.dart';

/// Service for managing customers
class CustomerService {
  final DatabaseService _databaseService = DatabaseService();
  final FirestoreSyncService _syncService = FirestoreSyncService();

  /// Get all customers
  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        orderBy: 'name ASC',
      );
      return maps.map((map) => CustomerModel.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  /// Get all customers (alias for compatibility)
  Future<List<CustomerModel>> getCustomers() async {
    return getAllCustomers();
  }

  /// Get customer by ID
  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return CustomerModel.fromJson(maps.first);
    } catch (e) {
      throw Exception('Failed to load customer: $e');
    }
  }

  /// Search customers by name or phone
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return maps.map((map) => CustomerModel.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  /// Get active customers (purchased in last 30 days)
  Future<List<CustomerModel>> getActiveCustomers() async {
    try {
      final db = await _databaseService.database;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        where: 'lastPurchaseAt IS NOT NULL AND lastPurchaseAt >= ?',
        whereArgs: [thirtyDaysAgo.toIso8601String()],
        orderBy: 'lastPurchaseAt DESC',
      );
      return maps.map((map) => CustomerModel.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to load active customers: $e');
    }
  }

  /// Get debtors (customers who owe us money)
  Future<List<CustomerModel>> getDebtors() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        where: 'balance < ?',
        whereArgs: [0],
        orderBy: 'balance ASC',
      );
      return maps.map((map) => CustomerModel.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to load debtors: $e');
    }
  }

  /// Get customers with credit balance (prepaid/we owe them)
  Future<List<CustomerModel>> getCreditCustomers() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        where: 'balance > ?',
        whereArgs: [0],
        orderBy: 'balance DESC',
      );
      return maps.map((map) => CustomerModel.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to load credit customers: $e');
    }
  }

  /// Get inactive customers (no purchase in 30+ days)
  Future<List<CustomerModel>> getInactiveCustomers() async {
    try {
      final db = await _databaseService.database;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final List<Map<String, dynamic>> maps = await db.query(
        'customers',
        where: 'lastPurchaseAt IS NULL OR lastPurchaseAt < ?',
        whereArgs: [thirtyDaysAgo.toIso8601String()],
        orderBy: 'name ASC',
      );
      return maps.map((map) => CustomerModel.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to load inactive customers: $e');
    }
  }

  /// Add new customer
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      final db = await _databaseService.database;
      await db.insert(
        'customers',
        customer.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // Sync to Firestore in background
      _syncService.syncCustomer(customer).catchError((e) {
        print('Error syncing customer: $e');
      });
    } catch (e) {
      throw Exception('Failed to add customer: $e');
    }
  }

  /// Update customer
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'customers',
        customer.toJson(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );
      // Sync to Firestore in background
      _syncService.syncCustomer(customer).catchError((e) {
        print('Error syncing customer: $e');
      });
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  /// Update customer balance
  Future<void> updateCustomerBalance(String customerId, double amount) async {
    try {
      final db = await _databaseService.database;
      await db.rawUpdate(
        'UPDATE customers SET balance = balance + ?, updatedAt = ? WHERE id = ?',
        [amount, DateTime.now().toIso8601String(), customerId],
      );
    } catch (e) {
      throw Exception('Failed to update customer balance: $e');
    }
  }

  /// Update last purchase date
  Future<void> updateLastPurchase(String customerId) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'customers',
        {
          'lastPurchaseAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
    } catch (e) {
      throw Exception('Failed to update last purchase: $e');
    }
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
      // Delete from Firestore in background
      _syncService.deleteCustomerFromCloud(id).catchError((e) {
        print('Error deleting customer: $e');
      });
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  /// Get customer count
  Future<int> getCustomerCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get customer count: $e');
    }
  }
}
