class SplitExpenseModel {
  final int? id;
  final String title;
  final double totalAmount;
  final double paidByUser;
  final String? description;
  final DateTime date;
  final String status; // pending, settled
  final String settlementRouteMode;
  final int? settlementMediatorContactId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // For joined queries
  final List<SplitParticipantModel>? participants;

  SplitExpenseModel({
    this.id,
    required this.title,
    required this.totalAmount,
    required this.paidByUser,
    this.description,
    required this.date,
    required this.status,
    this.settlementRouteMode = 'optimized',
    this.settlementMediatorContactId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.participants,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'total_amount': totalAmount,
      'paid_by_user': paidByUser,
      'description': description,
      'date': date.toIso8601String(),
      'status': status,
      'settlement_route_mode': settlementRouteMode,
      'settlement_mediator_contact_id': settlementMediatorContactId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SplitExpenseModel.fromMap(Map<String, dynamic> map) {
    return SplitExpenseModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidByUser: (map['paid_by_user'] as num).toDouble(),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      status: map['status'] as String,
      settlementRouteMode:
          map['settlement_route_mode'] as String? ?? 'optimized',
      settlementMediatorContactId:
          map['settlement_mediator_contact_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SplitExpenseModel copyWith({
    int? id,
    String? title,
    double? totalAmount,
    double? paidByUser,
    String? description,
    DateTime? date,
    String? status,
    String? settlementRouteMode,
    int? settlementMediatorContactId,
    bool clearSettlementMediatorContactId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SplitParticipantModel>? participants,
  }) {
    return SplitExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      paidByUser: paidByUser ?? this.paidByUser,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      settlementRouteMode: settlementRouteMode ?? this.settlementRouteMode,
      settlementMediatorContactId: clearSettlementMediatorContactId
          ? null
          : (settlementMediatorContactId ?? this.settlementMediatorContactId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
    );
  }
}

class SplitParticipantModel {
  final int? id;
  final int splitId;
  final int contactId;
  final double shareAmount;
  final double expensePaid;
  final double paid;
  final String status; // pending, paid

  // For joined queries
  final String? contactName;

  SplitParticipantModel({
    this.id,
    required this.splitId,
    required this.contactId,
    required this.shareAmount,
    this.expensePaid = 0,
    this.paid = 0,
    required this.status,
    this.contactName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'split_id': splitId,
      'contact_id': contactId,
      'share_amount': shareAmount,
      'expense_paid': expensePaid,
      'paid': paid,
      'status': status,
    };
  }

  double get remainingShareAmount {
    final remaining = shareAmount - expensePaid - paid;
    return remaining <= 0 ? 0 : remaining;
  }

  factory SplitParticipantModel.fromMap(Map<String, dynamic> map) {
    return SplitParticipantModel(
      id: map['id'] as int?,
      splitId: map['split_id'] as int,
      contactId: map['contact_id'] as int,
      shareAmount: (map['share_amount'] as num).toDouble(),
      expensePaid: (map['expense_paid'] as num?)?.toDouble() ?? 0,
      paid: (map['paid'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String,
      contactName: map['contact_name'] as String?,
    );
  }

  SplitParticipantModel copyWith({
    int? id,
    int? splitId,
    int? contactId,
    double? shareAmount,
    double? expensePaid,
    double? paid,
    String? status,
    String? contactName,
  }) {
    return SplitParticipantModel(
      id: id ?? this.id,
      splitId: splitId ?? this.splitId,
      contactId: contactId ?? this.contactId,
      shareAmount: shareAmount ?? this.shareAmount,
      expensePaid: expensePaid ?? this.expensePaid,
      paid: paid ?? this.paid,
      status: status ?? this.status,
      contactName: contactName ?? this.contactName,
    );
  }
}
