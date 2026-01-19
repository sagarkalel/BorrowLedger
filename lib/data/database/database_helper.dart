import 'dart:developer';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.dbName);
    log('DatabaseHelper: Initializing database at $path');

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        log('DatabaseHelper: Foreign keys enabled');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    log('DatabaseHelper: Creating database tables (version $version)');

    // Contacts table
    await db.execute('''
    CREATE TABLE contacts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      email TEXT,
      avatar TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
    log('DatabaseHelper: Contacts table created');

    // Transactions table with all fields
    await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      transaction_category TEXT NOT NULL DEFAULT 'cash',
      contact_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      description TEXT,
      date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      item_name TEXT,
      quantity TEXT,
      expected_date TEXT,
      paid_amount REAL,
      is_settlement INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
    )
  ''');
    log('DatabaseHelper: Transactions table created');

    // Udhari items table
    await db.execute('''
    CREATE TABLE udhari_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_name TEXT NOT NULL UNIQUE,
      usage_count INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
    log('DatabaseHelper: Udhari items table created');

    // Expenses table
    await db.execute('''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      description TEXT,
      date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
    log('DatabaseHelper: Expenses table created');

    // Split expenses table with status column
    await db.execute('''
    CREATE TABLE split_expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      total_amount REAL NOT NULL,
      paid_by_user REAL NOT NULL,
      description TEXT,
      date TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
    log('DatabaseHelper: Split expenses table created');

    // Split participants table
    await db.execute('''
    CREATE TABLE split_participants (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      split_id INTEGER NOT NULL,
      contact_id INTEGER NOT NULL,
      share_amount REAL NOT NULL,
      paid REAL NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'pending',
      FOREIGN KEY (split_id) REFERENCES split_expenses (id) ON DELETE CASCADE,
      FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
    )
  ''');
    log('DatabaseHelper: Split participants table created');

    // Create indexes
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    log('DatabaseHelper: Creating indexes...');

    // Transaction indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_contact ON transactions(contact_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(transaction_category)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_settlement ON transactions(is_settlement)',
    );

    // Composite indexes for common queries
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_contact_date ON transactions(contact_id, date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_type_category ON transactions(type, transaction_category)',
    );

    // Contact search index
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_contacts_name ON contacts(name COLLATE NOCASE)',
    );

    // Udhari items indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_udhari_items_name ON udhari_items(item_name COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_udhari_items_usage ON udhari_items(usage_count DESC)',
    );

    // Expense indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category)',
    );

    // Split expenses indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_split_expenses_date ON split_expenses(date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_split_expenses_status ON split_expenses(status)',
    );

    // Split participants indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_split_participants_split ON split_participants(split_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_split_participants_contact ON split_participants(contact_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_split_participants_status ON split_participants(status)',
    );

    log('DatabaseHelper: All indexes created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    log(
      'DatabaseHelper: Upgrading database from version $oldVersion to $newVersion',
    );

    // Since you mentioned all users are new, we can keep this minimal
    // But keeping migration logic for safety

    if (oldVersion < 2) {
      log('DatabaseHelper: Upgrading to version 2 - Adding avatar column');
      await db.execute('ALTER TABLE contacts ADD COLUMN avatar TEXT');
    }

    if (oldVersion < 3) {
      log(
        'DatabaseHelper: Upgrading to version 3 - Recreating transactions table with foreign keys',
      );
      await db.execute('''
      CREATE TABLE transactions_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        contact_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
      )
    ''');

      await db.execute('''
      INSERT INTO transactions_new
      SELECT id, type, contact_id, amount, description, date, created_at, updated_at
      FROM transactions
    ''');

      await db.execute('DROP TABLE transactions');
      await db.execute('ALTER TABLE transactions_new RENAME TO transactions');
    }

    if (oldVersion < 4) {
      log('DatabaseHelper: Upgrading to version 4 - Adding udhari fields');

      await db.execute(
        'ALTER TABLE transactions ADD COLUMN transaction_category TEXT NOT NULL DEFAULT "cash"',
      );
      await db.execute('ALTER TABLE transactions ADD COLUMN item_name TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN quantity TEXT');
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN expected_date TEXT',
      );
      await db.execute('ALTER TABLE transactions ADD COLUMN paid_amount REAL');

      log('DatabaseHelper: Udhari fields added successfully');
    }

    if (oldVersion < 5) {
      log('DatabaseHelper: Upgrading to version 5 - Adding settlement flag');

      await db.execute(
        'ALTER TABLE transactions ADD COLUMN is_settlement INTEGER NOT NULL DEFAULT 0',
      );

      // Migrate existing settlement transactions
      await db.execute('''
        UPDATE transactions 
        SET is_settlement = 1 
        WHERE description LIKE '%ettlement%' OR description LIKE '%Settle%'
      ''');

      log('DatabaseHelper: Settlement flag added');
    }

    if (oldVersion < 6) {
      log(
        'DatabaseHelper: Upgrading to version 6 - Adding udhari_items and split status/paid',
      );

      // Create udhari_items table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS udhari_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_name TEXT NOT NULL UNIQUE,
          usage_count INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Create indexes for udhari_items
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_udhari_items_name ON udhari_items(item_name COLLATE NOCASE)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_udhari_items_usage ON udhari_items(usage_count DESC)',
      );

      // Populate from existing transactions
      await db.execute('''
        INSERT INTO udhari_items (item_name, usage_count, created_at, updated_at)
        SELECT 
          item_name,
          COUNT(*) as usage_count,
          datetime('now') as created_at,
          datetime('now') as updated_at
        FROM transactions
        WHERE transaction_category = 'udhari' 
          AND item_name IS NOT NULL 
          AND TRIM(item_name) != ''
        GROUP BY LOWER(TRIM(item_name))
      ''');

      // Add status column to split_expenses if it doesn't exist
      try {
        await db.execute(
          'ALTER TABLE split_expenses ADD COLUMN status TEXT NOT NULL DEFAULT "pending"',
        );
        log('DatabaseHelper: Added status column to split_expenses');
      } catch (e) {
        log(
          'DatabaseHelper: Status column in split_expenses may already exist: $e',
        );
      }

      // Create index for split status
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_split_expenses_status ON split_expenses(status)',
      );

      // Add paid and status columns to split_participants
      try {
        await db.execute(
          'ALTER TABLE split_participants ADD COLUMN paid REAL NOT NULL DEFAULT 0',
        );
        log('DatabaseHelper: Added paid column to split_participants');
      } catch (e) {
        log(
          'DatabaseHelper: Paid column in split_participants may already exist: $e',
        );
      }

      try {
        await db.execute(
          'ALTER TABLE split_participants ADD COLUMN status TEXT NOT NULL DEFAULT "pending"',
        );
        log('DatabaseHelper: Added status column to split_participants');
      } catch (e) {
        log(
          'DatabaseHelper: Status column in split_participants may already exist: $e',
        );
      }

      // Create index for participant status
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_split_participants_status ON split_participants(status)',
      );

      // Migrate old is_paid column to new paid and status columns
      try {
        await db.execute('''
          UPDATE split_participants 
          SET status = CASE 
            WHEN is_paid = 1 THEN 'paid' 
            ELSE 'pending' 
          END
          WHERE status = 'pending'
        ''');
        log('DatabaseHelper: Migrated is_paid to status');
      } catch (e) {
        log('DatabaseHelper: Could not migrate is_paid data: $e');
      }

      log(
        'DatabaseHelper: Udhari items table and split status/paid columns added',
      );
    }

    // Ensure all indexes exist (for any version upgrade)
    await _createIndexes(db);
    log('DatabaseHelper: Database upgrade completed');
  }

  // Generic CRUD operations with error handling
  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      final result = await db.insert(table, data);
      log('DatabaseHelper: Inserted into $table with id: $result');
      return result;
    } catch (e) {
      log('DatabaseHelper: Error inserting into $table - $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      return await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      log('DatabaseHelper: Error querying $table - $e');
      rethrow;
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      final result = await db.update(
        table,
        data,
        where: where,
        whereArgs: whereArgs,
      );
      log('DatabaseHelper: Updated $result row(s) in $table');
      return result;
    } catch (e) {
      log('DatabaseHelper: Error updating $table - $e');
      rethrow;
    }
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    try {
      final db = await database;
      final result = await db.delete(table, where: where, whereArgs: whereArgs);
      log('DatabaseHelper: Deleted $result row(s) from $table');
      return result;
    } catch (e) {
      log('DatabaseHelper: Error deleting from $table - $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String query, [
    List<Object?>? arguments,
  ]) async {
    try {
      final db = await database;
      return await db.rawQuery(query, arguments);
    } catch (e) {
      log('DatabaseHelper: Error executing raw query - $e');
      log('DatabaseHelper: Query was: $query');
      rethrow;
    }
  }

  Future<int> rawInsert(String query, [List<Object?>? arguments]) async {
    try {
      final db = await database;
      return await db.rawInsert(query, arguments);
    } catch (e) {
      log('DatabaseHelper: Error executing raw insert - $e');
      rethrow;
    }
  }

  Future<int> rawUpdate(String query, [List<Object?>? arguments]) async {
    try {
      final db = await database;
      return await db.rawUpdate(query, arguments);
    } catch (e) {
      log('DatabaseHelper: Error executing raw update - $e');
      rethrow;
    }
  }

  Future<int> rawDelete(String query, [List<Object?>? arguments]) async {
    try {
      final db = await database;
      return await db.rawDelete(query, arguments);
    } catch (e) {
      log('DatabaseHelper: Error executing raw delete - $e');
      rethrow;
    }
  }

  // Export database for backup
  Future<String> exportDatabase() async {
    final db = await database;
    String path = db.path;
    log('DatabaseHelper: Database path: $path');
    return path;
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      log('DatabaseHelper: Database closed');
    }
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    log('DatabaseHelper: Clearing all data...');
    final db = await database;
    await db.delete('split_participants');
    await db.delete('split_expenses');
    await db.delete('expenses');
    await db.delete('transactions');
    await db.delete('contacts');
    await db.delete('udhari_items');
    log('DatabaseHelper: All data cleared');
  }

  // Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final contacts = await db.rawQuery(
      'SELECT COUNT(*) as count FROM contacts',
    );
    final transactions = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions',
    );
    final expenses = await db.rawQuery(
      'SELECT COUNT(*) as count FROM expenses',
    );
    final splits = await db.rawQuery(
      'SELECT COUNT(*) as count FROM split_expenses',
    );
    final udhariItems = await db.rawQuery(
      'SELECT COUNT(*) as count FROM udhari_items',
    );

    return {
      'contacts': (contacts.first['count'] as int?) ?? 0,
      'transactions': (transactions.first['count'] as int?) ?? 0,
      'expenses': (expenses.first['count'] as int?) ?? 0,
      'splits': (splits.first['count'] as int?) ?? 0,
      'udhari_items': (udhariItems.first['count'] as int?) ?? 0,
    };
  }
}
