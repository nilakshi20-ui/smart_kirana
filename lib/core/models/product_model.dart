// lib/core/models/product_model.dart
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Product extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String category;
  final double price;
  final double costPrice;
  final int quantity;
  final int lowStockThreshold;
  final String? supplier;
  final String? barcode;
  final String unit; // kg, piece, litre, pack, dozen
  final bool isActive;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.price,
    required this.costPrice,
    required this.quantity,
    required this.lowStockThreshold,
    this.supplier,
    this.barcode,
    this.unit = 'piece',
    this.isActive = true,
    this.syncStatus = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get isOutOfStock => quantity == 0;
  double get profitMargin => price > 0 ? ((price - costPrice) / price) * 100 : 0;

  factory Product.create({
    required String userId,
    required String name,
    required String category,
    required double price,
    required double costPrice,
    required int quantity,
    int lowStockThreshold = 10,
    String? supplier,
    String? barcode,
    String unit = 'piece',
  }) {
    final now = DateTime.now();
    return Product(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      category: category,
      price: price,
      costPrice: costPrice,
      quantity: quantity,
      lowStockThreshold: lowStockThreshold,
      supplier: supplier,
      barcode: barcode,
      unit: unit,
      createdAt: now,
      updatedAt: now,
    );
  }

  Product copyWith({
    String? name,
    String? category,
    double? price,
    double? costPrice,
    int? quantity,
    int? lowStockThreshold,
    String? supplier,
    String? barcode,
    String? unit,
    bool? isActive,
    String? syncStatus,
  }) {
    return Product(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      supplier: supplier ?? this.supplier,
      barcode: barcode ?? this.barcode,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'category': category,
    'price': price,
    'cost_price': costPrice,
    'quantity': quantity,
    'low_stock_threshold': lowStockThreshold,
    'supplier': supplier,
    'barcode': barcode,
    'unit': unit,
    'is_active': isActive ? 1 : 0,
    'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'],
    userId: map['user_id'],
    name: map['name'],
    category: map['category'],
    price: (map['price'] as num).toDouble(),
    costPrice: (map['cost_price'] as num).toDouble(),
    quantity: map['quantity'],
    lowStockThreshold: map['low_stock_threshold'] ?? 10,
    supplier: map['supplier'],
    barcode: map['barcode'],
    unit: map['unit'] ?? 'piece',
    isActive: map['is_active'] == 1 || map['is_active'] == true,
    syncStatus: map['sync_status'] ?? 'pending',
    createdAt: DateTime.parse(map['created_at']),
    updatedAt: DateTime.parse(map['updated_at']),
  );

  @override
  List<Object?> get props => [id, name, quantity, price, syncStatus];
}
