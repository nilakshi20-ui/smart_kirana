// lib/core/models/bill_model.dart
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'product_model.dart';

class BillItem extends Equatable {
  final String id;
  final String billId;
  final String productId;
  final String productName; // snapshot
  final double unitPrice;   // snapshot
  final int quantity;
  final double totalPrice;

  const BillItem({
    required this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory BillItem.fromProduct({
    required String billId,
    required Product product,
    required int quantity,
  }) {
    return BillItem(
      id: const Uuid().v4(),
      billId: billId,
      productId: product.id,
      productName: product.name,
      unitPrice: product.price,
      quantity: quantity,
      totalPrice: product.price * quantity,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'bill_id': billId,
    'product_id': productId,
    'product_name': productName,
    'unit_price': unitPrice,
    'quantity': quantity,
    'total_price': totalPrice,
  };

  factory BillItem.fromMap(Map<String, dynamic> map) => BillItem(
    id: map['id'],
    billId: map['bill_id'],
    productId: map['product_id'],
    productName: map['product_name'],
    unitPrice: (map['unit_price'] as num).toDouble(),
    quantity: map['quantity'],
    totalPrice: (map['total_price'] as num).toDouble(),
  );

  @override
  List<Object?> get props => [id, productId, quantity];
}

class Bill extends Equatable {
  final String id;
  final String userId;
  final String? customerId;
  final String? customerName;
  final List<BillItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String paymentMode; // cash, upi, credit
  final double amountPaid;
  final double creditAmount;
  final String status; // completed, pending, cancelled
  final String syncStatus;
  final DateTime createdAt;

  const Bill({
    required this.id,
    required this.userId,
    this.customerId,
    this.customerName,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMode,
    required this.amountPaid,
    required this.creditAmount,
    this.status = 'completed',
    this.syncStatus = 'pending',
    required this.createdAt,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  factory Bill.create({
    required String userId,
    String? customerId,
    String? customerName,
    required List<BillItem> items,
    required double subtotal,
    double discountAmount = 0,
    double taxAmount = 0,
    required String paymentMode,
    required double amountPaid,
  }) {
    final total = subtotal - discountAmount + taxAmount;
    final credit = paymentMode == 'credit' ? total : 0.0;
    return Bill(
      id: const Uuid().v4(),
      userId: userId,
      customerId: customerId,
      customerName: customerName,
      items: items,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: total,
      paymentMode: paymentMode,
      amountPaid: amountPaid,
      creditAmount: credit,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'customer_id': customerId,
    'customer_name': customerName,
    'subtotal': subtotal,
    'discount_amount': discountAmount,
    'tax_amount': taxAmount,
    'total_amount': totalAmount,
    'payment_mode': paymentMode,
    'amount_paid': amountPaid,
    'credit_amount': creditAmount,
    'status': status,
    'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(),
  };

  factory Bill.fromMap(Map<String, dynamic> map, List<BillItem> items) => Bill(
    id: map['id'],
    userId: map['user_id'],
    customerId: map['customer_id'],
    customerName: map['customer_name'],
    items: items,
    subtotal: (map['subtotal'] as num).toDouble(),
    discountAmount: (map['discount_amount'] as num).toDouble(),
    taxAmount: (map['tax_amount'] as num).toDouble(),
    totalAmount: (map['total_amount'] as num).toDouble(),
    paymentMode: map['payment_mode'],
    amountPaid: (map['amount_paid'] as num).toDouble(),
    creditAmount: (map['credit_amount'] as num).toDouble(),
    status: map['status'],
    syncStatus: map['sync_status'] ?? 'pending',
    createdAt: DateTime.parse(map['created_at']),
  );

  @override
  List<Object?> get props => [id, totalAmount, paymentMode, createdAt];
}

// Cart item (UI-only, not persisted)
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}
