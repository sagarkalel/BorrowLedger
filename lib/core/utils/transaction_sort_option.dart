enum TransactionSortOption {
  transactionDateDesc,
  transactionDateAsc,
  createdDateDesc,
  createdDateAsc,
}

extension TransactionSortOptionSql on TransactionSortOption {
  String orderBy({String alias = 't'}) {
    final prefix = alias.isEmpty ? '' : '$alias.';
    return switch (this) {
      TransactionSortOption.transactionDateDesc =>
        'datetime(${prefix}date) DESC, datetime(COALESCE(${prefix}created_at, ${prefix}date)) DESC, ${prefix}id DESC',
      TransactionSortOption.transactionDateAsc =>
        'datetime(${prefix}date) ASC, datetime(COALESCE(${prefix}created_at, ${prefix}date)) ASC, ${prefix}id ASC',
      TransactionSortOption.createdDateDesc =>
        'datetime(COALESCE(${prefix}created_at, ${prefix}date)) DESC, ${prefix}id DESC',
      TransactionSortOption.createdDateAsc =>
        'datetime(COALESCE(${prefix}created_at, ${prefix}date)) ASC, ${prefix}id ASC',
    };
  }
}
