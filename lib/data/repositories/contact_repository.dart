import 'package:flutter_contacts/flutter_contacts.dart';

import '../database/database_helper.dart';
import '../models/contact_model.dart';

class ContactRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /* =======================
     PERMISSIONS
  ======================== */

  Future<bool> requestContactsPermission() async {
    return FlutterContacts.requestPermission();
  }

  Future<List<Contact>> getPhoneContacts() async {
    if (!await FlutterContacts.requestPermission()) {
      throw Exception('Contacts permission denied');
    }

    return FlutterContacts.getContacts(withProperties: true, withPhoto: true);
  }

  /* =======================
     WRITE OPERATIONS
  ======================== */

  Future<int> createContact(ContactModel contact) async {
    return _dbHelper.insert('contacts', contact.toMap());
  }

  Future<int> updateContact(ContactModel contact) async {
    return _dbHelper.update(
      'contacts',
      contact.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    return _dbHelper.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  /* =======================
     READ OPERATIONS (ALL → ContactSummary)
  ======================== */

  /// All contacts with summary and pagination
  Future<List<ContactSummary>> getAllContacts({int? limit, int? offset}) async {
    final sql = StringBuffer(_contactSummaryBaseQuery);

    sql.write(' ORDER BY c.name ASC');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final rows = await _dbHelper.rawQuery(sql.toString());
    return rows.map(_mapToContactSummary).toList();
  }

  /// Dashboard / recent contacts (only contacts with transactions)
  Future<List<ContactSummary>> getAllContactsWithSummary({
    int? limit,
    int? offset,
  }) async {
    final sql = StringBuffer(_contactSummaryBaseQuery);

    sql.write(' HAVING transaction_count > 0');
    sql.write(' ORDER BY last_transaction_date DESC');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final rows = await _dbHelper.rawQuery(sql.toString());
    return rows.map(_mapToContactSummary).toList();
  }

  /// Single contact summary
  Future<ContactSummary?> getContactById(int contactId) async {
    final rows = await _dbHelper.rawQuery(
      '''
      $_contactSummaryBaseQuery
      WHERE c.id = ?
      ''',
      [contactId],
    );

    if (rows.isEmpty) return null;
    return _mapToContactSummary(rows.first);
  }

  /// Search contacts with pagination
  Future<List<ContactSummary>> searchContacts(
    String query, {
    int? limit,
    int? offset,
  }) async {
    if (query.trim().isEmpty) return [];

    final sql = StringBuffer('''
      $_contactSummaryBaseQuery
      WHERE LOWER(c.name) LIKE LOWER(?)
      ORDER BY c.name ASC
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
      if (offset != null) {
        sql.write(' OFFSET $offset');
      }
    }

    final rows = await _dbHelper.rawQuery(sql.toString(), ['%$query%']);

    return rows.map(_mapToContactSummary).toList();
  }

  /// Get contact count (for pagination)
  Future<int> getContactCount({bool onlyWithTransactions = false}) async {
    final result = await _dbHelper.rawQuery('''
      SELECT COUNT(DISTINCT c.id) as count
      FROM contacts c
      ${onlyWithTransactions ? 'INNER JOIN transactions t ON c.id = t.contact_id' : ''}
    ''');

    return (result.first['count'] as int?) ?? 0;
  }

  /* =======================
     SQL BASE + MAPPER
  ======================== */

  static const String _contactSummaryBaseQuery = '''
    SELECT
      c.*,
      COUNT(t.id) AS transaction_count,
      COALESCE(SUM(CASE WHEN t.type = 'lend' THEN t.amount ELSE 0 END), 0) AS total_lent,
      COALESCE(SUM(CASE WHEN t.type = 'borrow' THEN t.amount ELSE 0 END), 0) AS total_borrowed,
      MAX(t.date) AS last_transaction_date
    FROM contacts c
    LEFT JOIN transactions t ON c.id = t.contact_id
    GROUP BY c.id
  ''';

  ContactSummary _mapToContactSummary(Map<String, dynamic> row) {
    final contact = ContactModel.fromMap(row);

    final totalLent = (row['total_lent'] as num?)?.toDouble() ?? 0.0;
    final totalBorrowed = (row['total_borrowed'] as num?)?.toDouble() ?? 0.0;

    return ContactSummary(
      contact: contact,
      transactionCount: row['transaction_count'] as int,
      totalLent: totalLent,
      totalBorrowed: totalBorrowed,
      netBalance: totalLent - totalBorrowed,
      lastTransactionDate: row['last_transaction_date'] != null
          ? DateTime.parse(row['last_transaction_date'] as String)
          : null,
    );
  }

  Future<ContactModel?> getContactByPhone(String phone) async {
    final cleanPhone = phone.trim();
    if (cleanPhone.isEmpty) return null;

    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'contacts',
      where: 'phone = ?',
      whereArgs: [cleanPhone],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ContactModel.fromMap(maps.first);
  }
}
