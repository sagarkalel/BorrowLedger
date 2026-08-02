class ContactSummary {
  final ContactModel contact;
  final int transactionCount;
  final double totalLent;
  final double totalBorrowed;
  final double netBalance;
  final DateTime? lastTransactionDate;
  final int cashCount;
  final int udhariCount;
  final int splitCount;

  ContactSummary({
    required this.contact,
    required this.transactionCount,
    required this.totalLent,
    required this.totalBorrowed,
    required this.netBalance,
    required this.lastTransactionDate,
    this.cashCount = 0,
    this.udhariCount = 0,
    this.splitCount = 0,
  });
}

class ContactModel {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactModel({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      avatar: map['avatar'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ContactModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ContactModel(id: $id, name: $name, phone: $phone, email: $email)';
  }
}
