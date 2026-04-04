import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/category_model.dart';
import '../models/sale_model.dart';
import '../models/ledger_model.dart';
import 'database_service.dart';
import 'product_service.dart';
import 'customer_service.dart';
import 'category_service.dart';
import 'sales_service.dart';

/// Firestore sync service for cloud synchronization
class FirestoreSyncService {
  static final FirestoreSyncService _instance = FirestoreSyncService._internal();
  factory FirestoreSyncService() => _instance;
  FirestoreSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.isNotEmpty && 
           connectivityResult.first != ConnectivityResult.none;
  }

  /// Get user's collection reference
  CollectionReference _userCollection(String collection) {
    return _firestore.collection('users').doc(_userId).collection(collection);
  }

  // ==================== PRODUCTS ====================
  
  /// Sync product to Firestore (including imageUrl)
  Future<void> syncProduct(ProductModel product) async {
    if (_userId == null || !await isOnline()) return;
    
    final data = {
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'sku': product.sku,
      'barcode': product.barcode,
      'categoryId': product.categoryId,
      'costPrice': product.costPrice,
      'sellingPrice': product.price,
      'quantity': product.quantity,
      'minStockLevel': product.minStock,
      'unit': product.unitType,
      'imageUrl': product.imageUrl,
      'isActive': true,
      'createdAt': product.createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    await _userCollection('products').doc(product.id).set(data, SetOptions(merge: true));
  }

  /// Delete product from Firestore
  Future<void> deleteProductFromCloud(String productId) async {
    if (_userId == null || !await isOnline()) return;
    await _userCollection('products').doc(productId).delete();
  }

  /// Fetch products from Firestore
  Future<List<Map<String, dynamic>>> fetchProductsFromCloud() async {
    if (_userId == null || !await isOnline()) return [];
    
    final snapshot = await _userCollection('products').get();
    return snapshot.docs.map((doc) => {
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    }).toList();
  }

  // ==================== CUSTOMERS ====================
  
  /// Sync customer to Firestore (excluding photoUrl/imageUrl)
  Future<void> syncCustomer(CustomerModel customer) async {
    if (_userId == null || !await isOnline()) return;
    
    final data = {
      'id': customer.id,
      'name': customer.name,
      'phone': customer.phone,
      'email': customer.email,
      'address': customer.address,
      'balance': customer.balance,
      'isActive': customer.isActive, // Sync active status
      'totalPurchases': 0.0, // Calculate from sales if needed
      'createdAt': customer.createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      // NOTE: photoUrl is NOT included - skip images
    };
    
    await _userCollection('customers').doc(customer.id).set(data, SetOptions(merge: true));
  }

  /// Delete customer from Firestore
  Future<void> deleteCustomerFromCloud(String customerId) async {
    if (_userId == null || !await isOnline()) return;
    await _userCollection('customers').doc(customerId).delete();
  }

  /// Fetch customers from Firestore
  Future<List<Map<String, dynamic>>> fetchCustomersFromCloud() async {
    if (_userId == null || !await isOnline()) return [];
    
    final snapshot = await _userCollection('customers').get();
    return snapshot.docs.map((doc) => {
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    }).toList();
  }

  // ==================== CATEGORIES ====================
  
  /// Sync category to Firestore
  Future<void> syncCategory(CategoryModel category) async {
    if (_userId == null || !await isOnline()) return;
    
    final data = {
      'id': category.id,
      'name': category.name,
      'description': category.description,
      'color': '#808080', // Default color
      'icon': 'category', // Default icon
      'createdAt': category.createdAt?.toIso8601String(),
    };
    
    await _userCollection('categories').doc(category.id).set(data, SetOptions(merge: true));
  }

  /// Delete category from Firestore
  Future<void> deleteCategoryFromCloud(String categoryId) async {
    if (_userId == null || !await isOnline()) return;
    await _userCollection('categories').doc(categoryId).delete();
  }

  /// Fetch categories from Firestore
  Future<List<Map<String, dynamic>>> fetchCategoriesFromCloud() async {
    if (_userId == null || !await isOnline()) return [];
    
    final snapshot = await _userCollection('categories').get();
    return snapshot.docs.map((doc) => {
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    }).toList();
  }

  // ==================== SALES ====================
  
  /// Sync sale to Firestore
  Future<void> syncSale(SaleModel sale) async {
    if (_userId == null || !await isOnline()) return;
    
    final data = {
      'id': sale.id,
      'invoiceNumber': sale.invoiceNumber,
      'customerId': sale.customerId,
      'customerName': sale.customerName,
      'items': sale.items.map((item) => {
        'productId': item.productId,
        'productName': item.productName,
        'quantity': item.quantity,
        'unitPrice': item.price,
        'lineTotal': item.total,
      }).toList(),
      'subtotal': sale.subtotal,
      'discount': sale.discount,
      'tax': sale.tax,
      'taxRate': sale.taxRate,
      'total': sale.total,
      'paymentMethod': sale.paymentMethod,
      'paymentStatus': sale.paymentStatus,
      'notes': '', // Add notes field if available
      'createdAt': sale.createdAt.toIso8601String(),
    };
    
    await _userCollection('sales').doc(sale.id).set(data, SetOptions(merge: true));
  }

  /// Delete sale from Firestore
  Future<void> deleteSaleFromCloud(String saleId) async {
    if (_userId == null || !await isOnline()) return;
    await _userCollection('sales').doc(saleId).delete();
  }

  /// Fetch sales from Firestore
  Future<List<Map<String, dynamic>>> fetchSalesFromCloud() async {
    if (_userId == null || !await isOnline()) return [];
    
    final snapshot = await _userCollection('sales').get();
    return snapshot.docs.map((doc) => {
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    }).toList();
  }

  // ==================== LEDGER ====================
  
  /// Sync ledger entry to Firestore
  Future<void> syncLedgerEntry(LedgerModel entry) async {
    if (_userId == null || !await isOnline()) return;
    
    final data = {
      'id': entry.id,
      'customerId': entry.customerId,
      'type': entry.type,
      'amount': entry.amount,
      'description': entry.description,
      'balanceBefore': entry.balanceBefore,
      'balanceAfter': entry.balanceAfter,
      'saleId': entry.saleId,
      'createdAt': entry.createdAt.toIso8601String(),
    };
    
    await _userCollection('ledger').doc(entry.id).set(data, SetOptions(merge: true));
  }

  /// Fetch ledger entries from Firestore
  Future<List<Map<String, dynamic>>> fetchLedgerFromCloud() async {
    if (_userId == null || !await isOnline()) return [];
    
    final snapshot = await _userCollection('ledger').get();
    return snapshot.docs.map((doc) => {
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    }).toList();
  }

  // ==================== SETTINGS ====================
  
  /// Sync settings to Firestore
  Future<void> syncSettings(Map<String, dynamic> settings) async {
    if (_userId == null || !await isOnline()) return;
    
    settings['updatedAt'] = DateTime.now().toIso8601String();
    await _userCollection('settings').doc('preferences').set(settings, SetOptions(merge: true));
  }

  /// Fetch settings from Firestore
  Future<Map<String, dynamic>?> fetchSettingsFromCloud() async {
    if (_userId == null || !await isOnline()) return null;
    
    final doc = await _userCollection('settings').doc('preferences').get();
    return doc.data() as Map<String, dynamic>?;
  }

  // ==================== FULL SYNC ====================
  
  /// Sync ALL local data to Firestore (when online)
  Future<void> syncAllToCloud() async {
    if (_userId == null || !await isOnline()) return;
    
    try {
      // Get services
      final productService = ProductService();
      final customerService = CustomerService();
      final categoryService = CategoryService();
      final salesService = SalesService();
      
      // Sync all products
      final products = await productService.getAllProducts();
      for (final product in products) {
        await syncProduct(product);
      }
      
      // Sync all customers
      final customers = await customerService.getAllCustomers();
      for (final customer in customers) {
        await syncCustomer(customer);
      }
      
      // Sync all categories
      final categories = await categoryService.getAllCategories();
      for (final category in categories) {
        await syncCategory(category);
      }
      
      // Sync all sales
      final sales = await salesService.getAllSales();
      for (final sale in sales) {
        await syncSale(sale);
      }
      
      // Note: Ledger entries would be synced here if the service existed
    } catch (e) {
      print('Error syncing to cloud: $e');
    }
  }

  /// Download ALL data from Firestore to local SQLite (new phone login)
  Future<void> downloadAllFromCloud() async {
    if (_userId == null || !await isOnline()) return;
    
    try {
      final db = DatabaseService();
      
      // Download categories first (products depend on them)
      final categories = await fetchCategoriesFromCloud();
      for (final cat in categories) {
        // Insert into local database
        final database = await db.database;
        await database.insert(
          'categories',
          CategoryModel.fromJson(cat).toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // Download products
      final products = await fetchProductsFromCloud();
      for (final prod in products) {
        final database = await db.database;
        // Map Firestore fields to local model fields
        final productData = {
          'id': prod['id'],
          'name': prod['name'],
          'description': prod['description'],
          'sku': prod['sku'],
          'barcode': prod['barcode'],
          'price': prod['sellingPrice'] ?? 0.0,
          'costPrice': prod['costPrice'],
          'quantity': prod['quantity'] ?? 0,
          'minStock': prod['minStockLevel'] ?? 10,
          'unitType': prod['unit'] ?? 'item',
          'categoryId': prod['categoryId'],
          'imageUrl': prod['imageUrl'],
          'createdAt': prod['createdAt'],
          'updatedAt': prod['updatedAt'],
          'syncStatus': 0,
        };
        await database.insert(
          'products',
          productData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // Download customers
      final customers = await fetchCustomersFromCloud();
      for (final cust in customers) {
        final database = await db.database;
        final customerData = {
          'id': cust['id'],
          'name': cust['name'],
          'phone': cust['phone'],
          'email': cust['email'],
          'address': cust['address'],
          'balance': cust['balance'] ?? 0.0,
          'createdAt': cust['createdAt'],
          'updatedAt': cust['updatedAt'],
          'syncStatus': 0,
        };
        await database.insert(
          'customers',
          customerData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // Download sales
      final sales = await fetchSalesFromCloud();
      for (final sale in sales) {
        final database = await db.database;
        // Convert items array to string for SQLite storage
        final itemsStr = (sale['items'] as List).toString();
        final saleData = {
          'id': sale['id'],
          'customerId': sale['customerId'],
          'customerName': sale['customerName'],
          'items': itemsStr,
          'subtotal': sale['subtotal'],
          'discount': sale['discount'] ?? 0.0,
          'tax': sale['tax'] ?? 0.0,
          'taxRate': sale['taxRate'] ?? 8.0,
          'total': sale['total'],
          'paymentMethod': sale['paymentMethod'],
          'paymentStatus': sale['paymentStatus'],
          'createdAt': sale['createdAt'],
          'syncStatus': 0,
        };
        await database.insert(
          'sales',
          saleData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // Download ledger entries
      final ledger = await fetchLedgerFromCloud();
      for (final entry in ledger) {
        // Note: Would need ledger table in database
        // Skip for now if table doesn't exist
      }
      
      // Download settings
      final settings = await fetchSettingsFromCloud();
      if (settings != null) {
        final database = await db.database;
        for (final entry in settings.entries) {
          await database.insert(
            'settings',
            {'key': entry.key, 'value': entry.value.toString()},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    } catch (e) {
      print('Error downloading from cloud: $e');
    }
  }


  /// Listen for connectivity changes and auto-sync
  void startAutoSync() {
    Connectivity().onConnectivityChanged.listen((result) async {
      if (result.isNotEmpty && result.first != ConnectivityResult.none) {
        // Device came online - sync everything
        await syncAllToCloud();
      }
    });
  }
}
