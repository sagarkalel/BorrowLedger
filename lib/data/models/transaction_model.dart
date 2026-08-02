class TransactionModel {
  final int? id;
  final String type; // 'lend' or 'borrow'
  final String category; // 'cash', 'udhari', or 'split'
  final int contactId;
  final double amount;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Udhari-specific fields
  final String? itemName;
  final String? quantity;
  final DateTime? expectedDate;
  final double? paidAmount;

  // Settlement flag (RECOMMENDED APPROACH)
  final bool isSettlement;

  // Source linkage for generated transactions
  final String? sourceType;
  final int? sourceId;

  // Optional, for joined queries
  final String? contactName;
  final String? contactPhone;
  final String? contactAvatar;

  TransactionModel({
    this.id,
    required this.type,
    this.category = 'cash', // Default to cash
    required this.contactId,
    required this.amount,
    this.description,
    required this.date,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.itemName,
    this.quantity,
    this.expectedDate,
    this.paidAmount,
    this.isSettlement = false, // Default false
    this.sourceType,
    this.sourceId,
    this.contactName,
    this.contactPhone,
    this.contactAvatar,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Helper getter for cash transactions
  bool get isCash => category == 'cash';

  // Helper getter for udhari transactions
  bool get isUdhari => category == 'udhari';

  // Helper getter for split-linked transactions
  bool get isSplit => category == 'split';

  // Helper getter to check if transaction is overdue
  bool get isOverdue {
    if (expectedDate == null) return false;
    return DateTime.now().isAfter(expectedDate!);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'transaction_category': category,
      'contact_id': contactId,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'item_name': itemName,
      'quantity': quantity,
      'expected_date': expectedDate?.toIso8601String(),
      'paid_amount': paidAmount,
      'is_settlement': isSettlement ? 1 : 0, // Store as integer
      'source_type': sourceType,
      'source_id': sourceId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      category: map['transaction_category'] as String? ?? 'cash',
      contactId: map['contact_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      itemName: map['item_name'] as String?,
      quantity: map['quantity'] as String?,
      expectedDate: map['expected_date'] != null
          ? DateTime.parse(map['expected_date'] as String)
          : null,
      paidAmount: map['paid_amount'] != null
          ? (map['paid_amount'] as num).toDouble()
          : null,
      isSettlement: (map['is_settlement'] as int?) == 1,
      sourceType: map['source_type'] as String?,
      sourceId: map['source_id'] as int?,
      contactName: map['contact_name'] as String?,
      contactPhone: map['contact_phone'] as String?,
      contactAvatar: map['contact_avatar'] as String?,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? type,
    String? category,
    int? contactId,
    double? amount,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? itemName,
    String? quantity,
    DateTime? expectedDate,
    String? status,
    double? paidAmount,
    bool? isSettlement,
    String? sourceType,
    int? sourceId,
    String? contactName,
    String? contactPhone,
    String? contactAvatar,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      contactId: contactId ?? this.contactId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      expectedDate: expectedDate ?? this.expectedDate,
      paidAmount: paidAmount ?? this.paidAmount,
      isSettlement: isSettlement ?? this.isSettlement,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactAvatar: contactAvatar ?? this.contactAvatar,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, category: $category, amount: $amount, isSettlement: $isSettlement)';
  }
}
