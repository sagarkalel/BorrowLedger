class UdhariQuantityModel {
  final int? id;
  final String quantity;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UdhariQuantityModel({
    this.id,
    required this.quantity,
    this.usageCount = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quantity': quantity,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UdhariQuantityModel.fromMap(Map<String, dynamic> map) {
    return UdhariQuantityModel(
      id: map['id'] as int?,
      quantity: map['quantity'] as String,
      usageCount: map['usage_count'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  UdhariQuantityModel copyWith({
    int? id,
    String? quantity,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UdhariQuantityModel(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UdhariQuantityModel(id: $id, quantity: $quantity, usageCount: $usageCount)';
  }
}
