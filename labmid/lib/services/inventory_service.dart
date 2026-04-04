import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/stock_movement_model.dart';
import '../models/product_model.dart';
import 'database_service.dart';
import 'product_service.dart';
import 'sales_service.dart';

/// Service for inventory/stock management operations
class InventoryService {
  final DatabaseService _dbService = DatabaseService();
  final ProductService _productService = ProductService();
  final SalesService _salesService = SalesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all stock movements
  Future<List<StockMovementModel>> getAllStockMovements() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => StockMovementModel.fromJson(maps[i]));
  }

  /// Get stock movements for a product
  Future<List<StockMovementModel>> getStockMovementsByProduct(String productId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => StockMovementModel.fromJson(maps[i]));
  }

  /// Get stock movements by type
  Future<List<StockMovementModel>> getStockMovementsByType(String type) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_movements',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => StockMovementModel.fromJson(maps[i]));
  }

  /// Stock in operation
  Future<bool> stockIn({
    required String productId,
    required int quantity,
    String? reason,
    String? supplier,
    String? reference,
    String? notes,
  }) async {
    try {
      // Get current product
      final product = await _productService.getProductById(productId);
      if (product == null) {
        print('Product not found');
        return false;
      }

      // Calculate new stock
      final previousStock = product.quantity;
      final newStock = previousStock + quantity;

      // Create stock movement record
      final movement = StockMovementModel(
        id: const Uuid().v4(),
        productId: productId,
        type: 'in',
        quantity: quantity,
        reason: reason,
        supplier: supplier,
        reference: reference,
        notes: notes,
        previousStock: previousStock,
        newStock: newStock,
        createdAt: DateTime.now(),
      );

      // Save movement
      final db = await _dbService.database;
      await db.insert(
        'stock_movements',
        movement.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update product quantity
      final updatedProduct = product.copyWith(
        quantity: newStock,
        updatedAt: DateTime.now(),
      );
      await _productService.updateProduct(updatedProduct);

      // Add to sync queue for Firebase
      await _dbService.addToSyncQueue('insert', 'stock_movements', movement.toJson());

      return true;
    } catch (e) {
      print('Error in stock in operation: $e');
      return false;
    }
  }

  /// Stock out operation
  Future<bool> stockOut({
    required String productId,
    required int quantity,
    String? reason,
    String? notes,
  }) async {
    try {
      // Get current product
      final product = await _productService.getProductById(productId);
      if (product == null) {
        print('Product not found');
        return false;
      }

      // Check if sufficient stock
      if (product.quantity < quantity) {
        print('Insufficient stock');
        return false;
      }

      // Calculate new stock
      final previousStock = product.quantity;
      final newStock = previousStock - quantity;

      // Create stock movement record
      final movement = StockMovementModel(
        id: const Uuid().v4(),
        productId: productId,
        type: 'out',
        quantity: quantity,
        reason: reason,
        notes: notes,
        previousStock: previousStock,
        newStock: newStock,
        createdAt: DateTime.now(),
      );

      // Save movement
      final db = await _dbService.database;
      await db.insert(
        'stock_movements',
        movement.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update product quantity
      final updatedProduct = product.copyWith(
        quantity: newStock,
        updatedAt: DateTime.now(),
      );
      await _productService.updateProduct(updatedProduct);

      // Add to sync queue for Firebase
      await _dbService.addToSyncQueue('insert', 'stock_movements', movement.toJson());

      return true;
    } catch (e) {
      print('Error in stock out operation: $e');
      return false;
    }
  }

  /// Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await _dbService.database;
    
    // Total products
    final totalProductsResult = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    final totalProducts = Sqflite.firstIntValue(totalProductsResult) ?? 0;
    
    // Low stock products
    final lowStockResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE quantity <= minStock',
    );
    final lowStockCount = Sqflite.firstIntValue(lowStockResult) ?? 0;
    
    // Total stock value
    final totalValueResult = await db.rawQuery(
      'SELECT SUM(quantity * price) as total FROM products',
    );
    final totalValue = totalValueResult.first['total'];
    final stockValue = totalValue != null ? (totalValue as num).toDouble() : 0.0;
    
    // Total sales count
    final totalSalesResult = await db.rawQuery('SELECT COUNT(*) as count FROM sales');
    final totalSales = Sqflite.firstIntValue(totalSalesResult) ?? 0;
    
    // Today's sales - Get actual data from sales service
    final todaysSales = await _salesService.getTodaysSalesTotal();
    
    return {
      'totalProducts': totalProducts,
      'totalSales': totalSales,
      'lowStockCount': lowStockCount,
      'totalStockValue': stockValue,
      'todaysSales': todaysSales,
    };
  }

  /// Sync stock movements from Firebase
  Future<void> syncFromFirebase(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('stock_movements')
          .where('userId', isEqualTo: userId)
          .get();

      final db = await _dbService.database;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        await db.insert(
          'stock_movements',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print('Error syncing from Firebase: $e');
    }
  }

  /// Sync stock movements to Firebase
  Future<void> syncToFirebase() async {
    try {
      final pendingOps = await _dbService.getPendingSyncOperations();

      for (var op in pendingOps) {
        if (op['table_name'] == 'stock_movements') {
          final operation = op['operation'];
          final data = op['data'] as Map<String, dynamic>;

          if (operation == 'insert' || operation == 'update') {
            await _firestore.collection('stock_movements').doc(data['id']).set(data);
          } else if (operation == 'delete') {
            await _firestore.collection('stock_movements').doc(data['id']).delete();
          }

          await _dbService.markAsSynced(op['id']);
        }
      }
    } catch (e) {
      print('Error syncing to Firebase: $e');
    }
  }
}
