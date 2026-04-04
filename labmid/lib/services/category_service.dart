import 'package:sqflite/sqflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import 'database_service.dart';
import 'firestore_sync_service.dart';

/// Service for category CRUD operations
class CategoryService {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreSyncService _syncService = FirestoreSyncService();

  /// Get all categories from local database
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => CategoryModel.fromJson(maps[i]));
  }

  /// Get category by ID
  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CategoryModel.fromJson(maps.first);
    }
    return null;
  }

  /// Get category with product count
  Future<Map<String, dynamic>> getCategoryWithCount(String id) async {
    final db = await _dbService.database;
    
    // Get category
    final categoryMaps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (categoryMaps.isEmpty) {
      return {};
    }
    
    final category = CategoryModel.fromJson(categoryMaps.first);
    
    // Get product count
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE categoryId = ?',
      [id],
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    
    return {
      'category': category,
      'productCount': count,
    };
  }

  /// Get all categories with product counts
  Future<List<Map<String, dynamic>>> getAllCategoriesWithCounts() async {
    final categories = await getAllCategories();
    final List<Map<String, dynamic>> result = [];
    
    for (var category in categories) {
      final data = await getCategoryWithCount(category.id);
      if (data.isNotEmpty) {
        result.add(data);
      }
    }
    
    return result;
  }

  /// Get total categories count
  Future<int> getTotalCategoriesCount() async {
    final db = await _dbService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Create new category
  Future<bool> createCategory(CategoryModel category) async {
    try {
      final db = await _dbService.database;
      await db.insert(
        'categories',
        category.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Sync to Firestore (if online)
      await _syncService.syncCategory(category);

      return true;
    } catch (e) {
      print('Error creating category: $e');
      return false;
    }
  }

  /// Update category
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      final db = await _dbService.database;
      await db.update(
        'categories',
        category.toJson(),
        where: 'id = ?',
        whereArgs: [category.id],
      );

      // Sync to Firestore (if online)
      await _syncService.syncCategory(category);

      return true;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String id) async {
    try {
      final db = await _dbService.database;
      
      // Check if category has products
      final products = await db.query(
        'products',
        where: 'categoryId = ?',
        whereArgs: [id],
      );
      
      if (products.isNotEmpty) {
        print('Cannot delete category with products');
        return false;
      }
      
      await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Delete from Firestore (if online)
      await _syncService.deleteCategoryFromCloud(id);

      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  /// Sync categories from Firebase to local database
  Future<void> syncFromFirebase(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();

      final db = await _dbService.database;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        await db.insert(
          'categories',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print('Error syncing from Firebase: $e');
    }
  }

  /// Sync categories from local database to Firebase
  Future<void> syncToFirebase() async {
    try {
      final pendingOps = await _dbService.getPendingSyncOperations();

      for (var op in pendingOps) {
        if (op['table_name'] == 'categories') {
          final operation = op['operation'];
          final data = op['data'] as Map<String, dynamic>;

          if (operation == 'insert' || operation == 'update') {
            await _firestore.collection('categories').doc(data['id']).set(data);
          } else if (operation == 'delete') {
            await _firestore.collection('categories').doc(data['id']).delete();
          }

          await _dbService.markAsSynced(op['id']);
        }
      }
    } catch (e) {
      print('Error syncing to Firebase: $e');
    }
  }
}
