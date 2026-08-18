class SharedSpendPurposeModel {
  final int? id;
  final String purpose;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  SharedSpendPurposeModel({
    this.id,
    required this.purpose,
    this.usageCount = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purpose': purpose,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SharedSpendPurposeModel.fromMap(Map<String, dynamic> map) {
    return SharedSpendPurposeModel(
      id: map['id'] as int?,
      purpose: map['purpose'] as String,
      usageCount: map['usage_count'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SharedSpendPurposeModel copyWith({
    int? id,
    String? purpose,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SharedSpendPurposeModel(
      id: id ?? this.id,
      purpose: purpose ?? this.purpose,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
