import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'database_service.dart';
import 'firestore_sync_service.dart';

/// Service for product CRUD operations
class ProductService {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreSyncService _syncService = FirestoreSyncService();

  /// Get all products from local database
  Future<List<ProductModel>> getAllProducts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('products', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => ProductModel.fromJson(maps[i]));
  }

  /// Get product by ID
  Future<ProductModel?> getProductById(String id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ProductModel.fromJson(maps.first);
    }
    return null;
  }

  /// Search products by name or SKU
  Future<List<ProductModel>> searchProducts(String query) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'name LIKE ? OR sku LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => ProductModel.fromJson(maps[i]));
  }

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => ProductModel.fromJson(maps[i]));
  }

  /// Get low stock products
  Future<List<ProductModel>> getLowStockProducts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM products WHERE quantity <= minStock ORDER BY quantity ASC',
    );
    return List.generate(maps.length, (i) => ProductModel.fromJson(maps[i]));
  }

  /// Get total products count
  Future<int> getTotalProductsCount() async {
    final db = await _dbService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get total stock value
  Future<double> getTotalStockValue() async {
    final db = await _dbService.database;
    final result = await db.rawQuery('SELECT SUM(quantity * price) as total FROM products');
    final value = result.first['total'];
    return value != null ? (value as num).toDouble() : 0.0;
  }

  /// Create new product
  Future<bool> createProduct(ProductModel product) async {
    try {
      final db = await _dbService.database;
      await db.insert(
        'products',
        product.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Sync to Firestore in background to avoid blocking UI
      _syncService.syncProduct(product).catchError((e) {
        print('Error syncing product to Firestore: $e');
      });

      return true;
    } catch (e) {
      print('Error creating product: $e');
      return false;
    }
  }

  /// Update product
  Future<bool> updateProduct(ProductModel product) async {
    try {
      final db = await _dbService.database;
      await db.update(
        'products',
        product.toJson(),
        where: 'id = ?',
        whereArgs: [product.id],
      );

      // Sync to Firestore in background
      _syncService.syncProduct(product).catchError((e) {
        print('Error syncing product to Firestore: $e');
      });

      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String id) async {
    try {
      final db = await _dbService.database;
      await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Delete from Firestore in background
      _syncService.deleteProductFromCloud(id).catchError((e) {
        print('Error deleting product from Firestore: $e');
      });

      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  /// Update product quantity (for stock changes and sales)
  Future<bool> updateProductQuantity(String productId, int quantityChange) async {
    try {
      final db = await _dbService.database;
      
      // Get current product
      final product = await getProductById(productId);
      if (product == null) {
        print('Product not found: $productId');
        return false;
      }
      
      // Calculate new quantity
      final newQuantity = product.quantity + quantityChange;
      
      // Prevent negative quantities
      if (newQuantity < 0) {
        print('Cannot reduce quantity below 0');
        return false;
      }
      
      // Update quantity in database
      await db.rawUpdate(
        'UPDATE products SET quantity = ?, updatedAt = ? WHERE id = ?',
        [newQuantity, DateTime.now().toIso8601String(), productId],
      );
      
      return true;
    } catch (e) {
      print('Error updating product quantity: $e');
      return false;
    }
  }

  /// Sync products from Firebase to local database
  Future<void> syncFromFirebase(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('userId', isEqualTo: userId)
          .get();

      final db = await _dbService.database;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        await db.insert(
          'products',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print('Error syncing from Firebase: $e');
    }
  }

  /// Sync products from local database to Firebase
  Future<void> syncToFirebase() async {
    try {
      final pendingOps = await _dbService.getPendingSyncOperations();

      for (var op in pendingOps) {
        if (op['table_name'] == 'products') {
          final operation = op['operation'];
          final data = op['data'] as Map<String, dynamic>;

          if (operation == 'insert' || operation == 'update') {
            await _firestore.collection('products').doc(data['id']).set(data);
          } else if (operation == 'delete') {
            await _firestore.collection('products').doc(data['id']).delete();
          }

          await _dbService.markAsSynced(op['id']);
        }
      }
    } catch (e) {
      print('Error syncing to Firebase: $e');
    }
  }
}
