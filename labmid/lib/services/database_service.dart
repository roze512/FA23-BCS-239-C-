import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';

/// Database service for SQLite (offline mode)
class DatabaseService {
  static Database? _database;

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT NOT NULL,
        photoUrl TEXT,
        createdAt TEXT,
        lastLoginAt TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        imageUrl TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Products table (updated with new fields)
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        sku TEXT,
        barcode TEXT,
        price REAL NOT NULL,
        costPrice REAL,
        quantity INTEGER NOT NULL DEFAULT 0,
        minStock INTEGER DEFAULT 10,
        unitType TEXT DEFAULT 'item',
        categoryId TEXT,
        imageUrl TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        syncStatus INTEGER DEFAULT 0,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    // Stock movements table
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        supplier TEXT,
        reference TEXT,
        notes TEXT,
        previousStock INTEGER,
        newStock INTEGER,
        createdAt TEXT,
        syncStatus INTEGER DEFAULT 0,
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        city TEXT,
        pincode TEXT,
        dateOfBirth TEXT,
        photoUrl TEXT,
        balance REAL DEFAULT 0,
        isActive INTEGER DEFAULT 1,
        lastPurchaseAt TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Sales table
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        customerId TEXT,
        customerName TEXT,
        items TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0,
        discountType TEXT,
        tax REAL DEFAULT 0,
        taxRate REAL DEFAULT 8,
        total REAL NOT NULL,
        paymentMethod TEXT,
        paymentStatus TEXT,
        cashierId TEXT,
        cashierName TEXT,
        createdAt TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        status TEXT NOT NULL,
        items TEXT NOT NULL,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    // Sync queue table (for offline operations)
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        table_name TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        data TEXT,
        isRead INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Ledger table for customer account tracking
    await db.execute('''
      CREATE TABLE ledger (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        balanceBefore REAL NOT NULL,
        balanceAfter REAL NOT NULL,
        saleId TEXT,
        createdAt TEXT,
        FOREIGN KEY (customerId) REFERENCES customers(id)
      )
    ''');
  }

  /// Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add categories table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          imageUrl TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          syncStatus INTEGER DEFAULT 0
        )
      ''');

      // Add new columns to products table
      try {
        await db.execute('ALTER TABLE products ADD COLUMN sku TEXT');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE products ADD COLUMN costPrice REAL');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE products ADD COLUMN minStock INTEGER DEFAULT 10');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE products ADD COLUMN unitType TEXT DEFAULT "item"');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE products ADD COLUMN categoryId TEXT');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE products ADD COLUMN syncStatus INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE products ADD COLUMN imageUrl TEXT');
      } catch (e) {
        // Column might already exist
      }

      // Add stock movements table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_movements (
          id TEXT PRIMARY KEY,
          productId TEXT NOT NULL,
          type TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          reason TEXT,
          supplier TEXT,
          reference TEXT,
          notes TEXT,
          previousStock INTEGER,
          newStock INTEGER,
          createdAt TEXT,
          syncStatus INTEGER DEFAULT 0,
          FOREIGN KEY (productId) REFERENCES products(id)
        )
      ''');
    }

    // Add customers and sales tables if upgrading from version < 3
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS customers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          address TEXT,
          city TEXT,
          pincode TEXT,
          dateOfBirth TEXT,
          photoUrl TEXT,
          balance REAL DEFAULT 0,
          isActive INTEGER DEFAULT 1,
          lastPurchaseAt TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          syncStatus INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales (
          id TEXT PRIMARY KEY,
          customerId TEXT,
          customerName TEXT,
          items TEXT NOT NULL,
          subtotal REAL NOT NULL,
          discount REAL DEFAULT 0,
          discountType TEXT,
          tax REAL DEFAULT 0,
          taxRate REAL DEFAULT 8,
          total REAL NOT NULL,
          paymentMethod TEXT,
          paymentStatus TEXT,
          cashierId TEXT,
          cashierName TEXT,
          createdAt TEXT,
          syncStatus INTEGER DEFAULT 0
        )
      ''');
    }

    // Add notifications and settings tables if upgrading from version < 4
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          data TEXT,
          isRead INTEGER DEFAULT 0,
          createdAt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
    
    // Add ledger table if upgrading from version < 5
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ledger (
          id TEXT PRIMARY KEY,
          customerId TEXT NOT NULL,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          balanceBefore REAL NOT NULL,
          balanceAfter REAL NOT NULL,
          saleId TEXT,
          createdAt TEXT,
          FOREIGN KEY (customerId) REFERENCES customers(id)
        )
      ''');
    }
    
    // Add isActive column to customers if upgrading from version < 6
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN isActive INTEGER DEFAULT 1');
      } catch (e) {
        // Column might already exist
      }
    }
  }

  /// Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Clear all data (for full reset only)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('products');
    await db.delete('categories');
    await db.delete('stock_movements');
    await db.delete('customers');
    await db.delete('sales');
    await db.delete('orders');
    await db.delete('sync_queue');
    await db.delete('notifications');
    await db.delete('settings');
    await db.delete('ledger');
  }

  /// Clear only session data on logout (preserves sales, products, customers, settings)
  Future<void> clearSessionData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('sync_queue');
    await db.delete('notifications');
  }

  /// Insert or update user
  Future<void> saveUser(Map<String, dynamic> userData) async {
    final db = await database;
    await db.insert(
      'users',
      userData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user by uid
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Add operation to sync queue
  Future<void> addToSyncQueue(
    String operation,
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    await db.insert('sync_queue', {
      'operation': operation,
      'table_name': tableName,
      'data': data.toString(),
      'createdAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  /// Get pending sync operations
  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
  }

  /// Mark sync operation as completed
  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
