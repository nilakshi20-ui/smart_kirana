// lib/core/models/customer_model.dart
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Customer extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final double totalCredit; // Udhar balance (amount owed to shop)
  final String? notes;
  final String? profileUrl;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Customer({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.totalCredit,
    this.notes,
    this.profileUrl,
    this.syncStatus = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasCredit => totalCredit > 0;

  factory Customer.create({
    required String userId,
    required String name,
    required String phone,
    String? notes,
    String? profileUrl,
    double totalCredit = 0,
  }) {
    final now = DateTime.now();
    return Customer(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      phone: phone,
      totalCredit: totalCredit,
      notes: notes,
      profileUrl: profileUrl,
      createdAt: now,
      updatedAt: now,
    );
  }

  Customer copyWith({
    String? name,
    String? phone,
    double? totalCredit,
    String? notes,
    String? profileUrl,
    String? syncStatus,
  }) {
    return Customer(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalCredit: totalCredit ?? this.totalCredit,
      notes: notes ?? this.notes,
      profileUrl: profileUrl ?? this.profileUrl,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'phone': phone,
    'total_credit': totalCredit,
    'notes': notes,
    'profile_url': profileUrl,
    'sync_status': syncStatus,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
    id: map['id'],
    userId: map['user_id'],
    name: map['name'],
    phone: map['phone'],
    totalCredit: (map['total_credit'] as num).toDouble(),
    notes: map['notes'],
    profileUrl: map['profile_url'],
    syncStatus: map['sync_status'] ?? 'pending',
    createdAt: DateTime.parse(map['created_at']),
    updatedAt: DateTime.parse(map['updated_at']),
  );

  @override
  List<Object?> get props => [id, name, phone, totalCredit];
}
