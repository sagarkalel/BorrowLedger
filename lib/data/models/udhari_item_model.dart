class UdhariItemModel {
  final int? id;
  final String itemName;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UdhariItemModel({
    this.id,
    required this.itemName,
    this.usageCount = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_name': itemName,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UdhariItemModel.fromMap(Map<String, dynamic> map) {
    return UdhariItemModel(
      id: map['id'] as int?,
      itemName: map['item_name'] as String,
      usageCount: map['usage_count'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  UdhariItemModel copyWith({
    int? id,
    String? itemName,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UdhariItemModel(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UdhariItemModel(id: $id, itemName: $itemName, usageCount: $usageCount)';
  }
}
