import 'package:borrow_ledger/core/constants/app_constants.dart';

enum ContactSettlementEffectType {
  directCash('direct_cash'),
  directOffset('direct_offset'),
  splitParticipant('split_participant');

  final String value;
  const ContactSettlementEffectType(this.value);

  static ContactSettlementEffectType fromValue(String value) {
    return ContactSettlementEffectType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ContactSettlementEffectType.directCash,
    );
  }
}

class ContactSettlementModel {
  final int? id;
  final int contactId;
  final double netAmount;
  final String direction;
  final double directCleared;
  final double splitCleared;
  final double offsetAmount;
  final bool isPartial;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? contactName;
  final String? contactPhone;
  final String? contactAvatar;

  ContactSettlementModel({
    this.id,
    required this.contactId,
    required this.netAmount,
    required this.direction,
    this.directCleared = 0,
    this.splitCleared = 0,
    this.offsetAmount = 0,
    this.isPartial = false,
    this.note,
    required this.date,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.contactName,
    this.contactPhone,
    this.contactAvatar,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isReceive => direction == AppConstants.typeLend;
  bool get isPay => direction == AppConstants.typeBorrow;
  bool get isNoCash => netAmount.abs() <= 0.01;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contact_id': contactId,
      'net_amount': netAmount,
      'direction': direction,
      'direct_cleared': directCleared,
      'split_cleared': splitCleared,
      'offset_amount': offsetAmount,
      'is_partial': isPartial ? 1 : 0,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ContactSettlementModel.fromMap(Map<String, dynamic> map) {
    return ContactSettlementModel(
      id: map['id'] as int?,
      contactId: map['contact_id'] as int,
      netAmount: (map['net_amount'] as num).toDouble(),
      direction: map['direction'] as String,
      directCleared: (map['direct_cleared'] as num?)?.toDouble() ?? 0,
      splitCleared: (map['split_cleared'] as num?)?.toDouble() ?? 0,
      offsetAmount: (map['offset_amount'] as num?)?.toDouble() ?? 0,
      isPartial: (map['is_partial'] as int?) == 1,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      contactName: map['contact_name'] as String?,
      contactPhone: map['contact_phone'] as String?,
      contactAvatar: map['contact_avatar'] as String?,
    );
  }
}

class ContactSettlementEffectModel {
  final int? id;
  final int settlementId;
  final ContactSettlementEffectType effectType;
  final double amount;
  final String direction;
  final int? transactionId;
  final int? splitId;
  final int? splitParticipantId;
  final DateTime createdAt;

  ContactSettlementEffectModel({
    this.id,
    required this.settlementId,
    required this.effectType,
    required this.amount,
    required this.direction,
    this.transactionId,
    this.splitId,
    this.splitParticipantId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'settlement_id': settlementId,
      'effect_type': effectType.value,
      'amount': amount,
      'direction': direction,
      'transaction_id': transactionId,
      'split_id': splitId,
      'split_participant_id': splitParticipantId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ContactSettlementEffectModel.fromMap(Map<String, dynamic> map) {
    return ContactSettlementEffectModel(
      id: map['id'] as int?,
      settlementId: map['settlement_id'] as int,
      effectType: ContactSettlementEffectType.fromValue(
        map['effect_type'] as String,
      ),
      amount: (map['amount'] as num).toDouble(),
      direction: map['direction'] as String,
      transactionId: map['transaction_id'] as int?,
      splitId: map['split_id'] as int?,
      splitParticipantId: map['split_participant_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
