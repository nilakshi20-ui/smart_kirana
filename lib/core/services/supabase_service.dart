// lib/core/services/supabase_service.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String? get userId => currentUser?.id;
  static Session? get session => client.auth.currentSession;

  static Future<String> uploadProfilePicture(String path, Uint8List bytes, String ext) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final fullPath = '$path/$fileName';
    
    await client.storage.from('avatars').uploadBinary(
      fullPath,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    
    return client.storage.from('avatars').getPublicUrl(fullPath);
  }

  static Future<void> updateOwnerProfile(String profileUrl) async {
    await client.auth.updateUser(
      UserAttributes(data: {'profile_url': profileUrl}),
    );
  }

  // ─── AUTH ────────────────────────────────────────────────────
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String shopName,
    required String ownerName,
    required String phone,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'shop_name': shopName,
        'owner_name': ownerName,
        'phone': phone,
      },
    );
    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // ─── PRODUCTS ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    final data = await client
        .from('products')
        .select()
        .eq('user_id', userId!)
        .eq('is_active', 1)
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> upsertProduct(Map<String, dynamic> product) async {
    await client.from('products').upsert(product);
  }

  static Future<void> deleteProduct(String id) async {
    await client
        .from('products')
        .update({'is_active': 0})
        .eq('id', id);
  }

  // ─── CUSTOMERS ───────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchCustomers() async {
    final data = await client
        .from('customers')
        .select()
        .eq('user_id', userId!)
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> upsertCustomer(Map<String, dynamic> customer) async {
    await client.from('customers').upsert(customer);
  }

  static Future<void> deleteCustomer(String id) async {
    await client.from('customers').delete().eq('id', id);
  }

  // ─── BILLS ───────────────────────────────────────────────────
  static Future<void> insertBill(
    Map<String, dynamic> bill,
    List<Map<String, dynamic>> items,
  ) async {
    await client.from('bills').insert(bill);
    if (items.isNotEmpty) {
      await client.from('bill_items').insert(items);
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBills({
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query = client
        .from('bills')
        .select('*, bill_items(*)')
        .eq('user_id', userId!);

    if (from != null) {
      query = query.gte('created_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('created_at', to.toIso8601String());
    }

    final data = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(data as List);
  }

  // ─── CREDIT TRANSACTIONS ─────────────────────────────────────
  static Future<void> recordCreditTransaction(
      Map<String, dynamic> transaction) async {
    await client.from('credit_transactions').insert(transaction);
  }

  static Future<List<Map<String, dynamic>>> fetchCreditTransactions(
      String customerId) async {
    final data = await client
        .from('credit_transactions')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
