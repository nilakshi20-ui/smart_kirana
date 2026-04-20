// lib/core/database/local_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class LocalDatabase {
  static Database? _database;

  static Future<void> initialize() async {
    // sqflite package does not natively support web out of the box
    if (kIsWeb) return;

    _database = await openDatabase(
      join(await getDatabasesPath(), AppConstants.localDbName),
      version: AppConstants.localDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Database get db {
    if (_database == null) throw Exception('Database not initialized');
    return _database!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        cost_price REAL NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 0,
        low_stock_threshold INTEGER NOT NULL DEFAULT 10,
        supplier TEXT,
        barcode TEXT,
        unit TEXT NOT NULL DEFAULT 'piece',
        is_active INTEGER NOT NULL DEFAULT 1,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        total_credit REAL NOT NULL DEFAULT 0,
        notes TEXT,
        profile_url TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        customer_id TEXT,
        customer_name TEXT,
        subtotal REAL NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        total_amount REAL NOT NULL,
        payment_mode TEXT NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        credit_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'completed',
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bill_items (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES bills(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE credit_transactions (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        bill_id TEXT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_products_user ON products(user_id)');
    await db.execute('CREATE INDEX idx_products_category ON products(category)');
    await db.execute('CREATE INDEX idx_customers_user ON customers(user_id)');
    await db.execute('CREATE INDEX idx_bills_user ON bills(user_id)');
    await db.execute('CREATE INDEX idx_bills_created ON bills(created_at)');
    await db.execute('CREATE INDEX idx_bill_items_bill ON bill_items(bill_id)');
    await db.execute('CREATE INDEX idx_credit_customer ON credit_transactions(customer_id)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here for future versions
  }

  // Generic helpers
  static Future<int> insert(String table, Map<String, dynamic> data) async {
    if (kIsWeb) {
      try {
        await Supabase.instance.client.from(table).insert(data);
        return 1;
      } catch (e) {
        return 0;
      }
    }
    return await db.insert(table, data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> update(
      String table, Map<String, dynamic> data, String whereId) async {
    if (kIsWeb) {
      try {
        await Supabase.instance.client.from(table).update(data).eq('id', whereId);
        return 1;
      } catch (e) {
        return 0;
      }
    }
    return await db.update(table, data,
        where: 'id = ?', whereArgs: [whereId]);
  }

  static Future<int> delete(String table, String id) async {
    if (kIsWeb) {
      try {
        await Supabase.instance.client.from(table).delete().eq('id', id);
        return 1;
      } catch (e) {
        return 0;
      }
    }
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (kIsWeb) {
      var builder = Supabase.instance.client.from(table).select();
      if (where != null && whereArgs != null) {
        int argIndex = 0;
        final conditions = where.split(' AND ');
        for (var cond in conditions) {
          final c = cond.trim();
          if (c == 'user_id = ?') {
            builder = builder.eq('user_id', whereArgs[argIndex++]);
          } else if (c == 'customer_id = ?') {
            builder = builder.eq('customer_id', whereArgs[argIndex++]);
          } else if (c == 'bill_id = ?') {
            builder = builder.eq('bill_id', whereArgs[argIndex++]);
          } else if (c == 'is_active = 1') {
            builder = builder.eq('is_active', 1);
          } else if (c == 'quantity > 0') {
            builder = builder.gt('quantity', 0);
          }
        }
      }
      if (orderBy != null) {
        final parts = orderBy.split(' ');
        final col = parts[0];
        final asc = parts.length > 1 ? parts[1].toUpperCase() == 'ASC' : true;
        final data = await builder.order(col, ascending: asc);
        return List<Map<String, dynamic>>.from(data);
      } else {
        final data = await builder;
        return List<Map<String, dynamic>>.from(data);
      }
    }
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  static Future<Map<String, dynamic>?> queryById(
      String table, String id) async {
    if (kIsWeb) {
      try {
        final data = await Supabase.instance.client.from(table).select().eq('id', id).single();
        return data;
      } catch (e) {
        return null;
      }
    }
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  // Dashboard stats
  static Future<Map<String, dynamic>> getDashboardStats(
      String userId, DateTime date) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (kIsWeb) {
      final client = Supabase.instance.client;
      final products = await client.from('products').select('quantity, low_stock_threshold').eq('user_id', userId).eq('is_active', 1);
      int lowStock = 0;
      for (var p in products) {
        if ((p['quantity'] as num) <= (p['low_stock_threshold'] as num)) lowStock++;
      }
      final bills = await client.from('bills').select('total_amount, amount_paid').eq('user_id', userId).gte('created_at', '${dateStr}T00:00:00').lte('created_at', '${dateStr}T23:59:59').eq('status', 'completed');
      double tSales = 0;
      double tCollected = 0;
      for (var b in bills) {
        tSales += (b['total_amount'] as num).toDouble();
        tCollected += (b['amount_paid'] as num).toDouble();
      }
      final customers = await client.from('customers').select('total_credit').eq('user_id', userId);
      double tCredit = 0;
      for (var c in customers) {
        tCredit += (c['total_credit'] as num).toDouble();
      }
      
      return {
        'bill_count': bills.length,
        'total_sales': tSales,
        'total_collected': tCollected,
        'product_count': products.length,
        'low_stock_count': lowStock,
        'total_credit': tCredit,
      };
    }

    final salesResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as bill_count,
        SUM(total_amount) as total_sales,
        SUM(amount_paid) as total_collected
      FROM bills 
      WHERE user_id = ? AND date(created_at) = ? AND status = 'completed'
    ''', [userId, dateStr]);

    final productCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM products WHERE user_id = ? AND is_active = 1',
            [userId])) ?? 0;

    final lowStockCount = Sqflite.firstIntValue(
        await db.rawQuery('''
          SELECT COUNT(*) FROM products 
          WHERE user_id = ? AND is_active = 1 AND quantity <= low_stock_threshold
        ''', [userId])) ?? 0;

    final totalCredit = (await db.rawQuery('''
      SELECT SUM(total_credit) as total FROM customers WHERE user_id = ?
    ''', [userId])).first['total'];

    return {
      'bill_count': Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM bills WHERE user_id = ? AND date(created_at) = ?',
              [userId, dateStr])) ?? 0,
      'total_sales': (salesResult.first['total_sales'] as num?)?.toDouble() ?? 0.0,
      'total_collected': (salesResult.first['total_collected'] as num?)?.toDouble() ?? 0.0,
      'product_count': productCount,
      'low_stock_count': lowStockCount,
      'total_credit': (totalCredit as num?)?.toDouble() ?? 0.0,
    };
  }

  // Sales report
  static Future<List<Map<String, dynamic>>> getSalesReport(
      String userId, DateTime from, DateTime to) async {
    if (kIsWeb) return [];
    return await db.rawQuery('''
      SELECT 
        date(created_at) as sale_date,
        COUNT(*) as bill_count,
        SUM(total_amount) as total_sales,
        SUM(amount_paid) as total_collected
      FROM bills
      WHERE user_id = ? 
        AND date(created_at) BETWEEN ? AND ?
        AND status = 'completed'
      GROUP BY date(created_at)
      ORDER BY sale_date ASC
    ''', [
      userId,
      from.toIso8601String().substring(0, 10),
      to.toIso8601String().substring(0, 10),
    ]);
  }

  // Top products
  static Future<List<Map<String, dynamic>>> getTopProducts(
      String userId, DateTime from, DateTime to, {int limit = 10}) async {
    if (kIsWeb) return [];
    return await db.rawQuery('''
      SELECT 
        bi.product_id,
        bi.product_name,
        SUM(bi.quantity) as total_quantity,
        SUM(bi.total_price) as total_revenue
      FROM bill_items bi
      JOIN bills b ON bi.bill_id = b.id
      WHERE b.user_id = ? 
        AND date(b.created_at) BETWEEN ? AND ?
        AND b.status = 'completed'
      GROUP BY bi.product_id, bi.product_name
      ORDER BY total_quantity DESC
      LIMIT ?
    ''', [
      userId,
      from.toIso8601String().substring(0, 10),
      to.toIso8601String().substring(0, 10),
      limit,
    ]);
  }
}
