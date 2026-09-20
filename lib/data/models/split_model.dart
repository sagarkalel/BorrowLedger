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
  final List<SplitBillModel>? bills;

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
    this.bills,
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
    List<SplitBillModel>? bills,
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
      bills: bills ?? this.bills,
    );
  }
}

class SplitBillModel {
  final int? id;
  final int splitId;
  final String title;
  final double amount;
  final bool paidByUser;
  final int? paidByContactId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  // For joined queries
  final String? paidByContactName;
  final String? paidByContactAvatar;

  SplitBillModel({
    this.id,
    required this.splitId,
    required this.title,
    required this.amount,
    required this.paidByUser,
    this.paidByContactId,
    required this.date,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.paidByContactName,
    this.paidByContactAvatar,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'split_id': splitId,
      'title': title,
      'amount': amount,
      'paid_by_user': paidByUser ? 1 : 0,
      'paid_by_contact_id': paidByContactId,
      'date': date.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SplitBillModel.fromMap(Map<String, dynamic> map) {
    return SplitBillModel(
      id: map['id'] as int?,
      splitId: map['split_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidByUser: ((map['paid_by_user'] as num?)?.toInt() ?? 0) == 1,
      paidByContactId: map['paid_by_contact_id'] as int?,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      paidByContactName: map['paid_by_contact_name'] as String?,
      paidByContactAvatar: map['paid_by_contact_avatar'] as String?,
    );
  }

  SplitBillModel copyWith({
    int? id,
    int? splitId,
    String? title,
    double? amount,
    bool? paidByUser,
    int? paidByContactId,
    bool clearPaidByContactId = false,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paidByContactName,
    String? paidByContactAvatar,
  }) {
    return SplitBillModel(
      id: id ?? this.id,
      splitId: splitId ?? this.splitId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidByUser: paidByUser ?? this.paidByUser,
      paidByContactId: clearPaidByContactId
          ? null
          : (paidByContactId ?? this.paidByContactId),
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidByContactName: paidByContactName ?? this.paidByContactName,
      paidByContactAvatar: paidByContactAvatar ?? this.paidByContactAvatar,
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
  final String? contactAvatar;

  SplitParticipantModel({
    this.id,
    required this.splitId,
    required this.contactId,
    required this.shareAmount,
    this.expensePaid = 0,
    this.paid = 0,
    required this.status,
    this.contactName,
    this.contactAvatar,
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
      contactAvatar: map['contact_avatar'] as String?,
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
    String? contactAvatar,
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
      contactAvatar: contactAvatar ?? this.contactAvatar,
    );
  }
}
