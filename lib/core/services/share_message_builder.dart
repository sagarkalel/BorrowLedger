import 'package:borrow_ledger/l10n/app_localizations.dart';

/// Builds the recipient-facing text shared from HisaabMate.
///
/// Keeping these messages in one place ensures UPI links, statements, and
/// split invoices use the same friendly format and sign-off.
class ShareMessageBuilder {
  const ShareMessageBuilder._();

  static String upiRequest({
    required AppLocalizations tr,
    required String contactName,
    required String amount,
    required String ownerName,
    required String upiUri,
  }) {
    return tr.upiRequestShareMessage(
      contactName,
      amount,
      ownerName,
      tr.appName,
      upiUri,
    );
  }

  static String upiPaymentDetails({
    required AppLocalizations tr,
    required String contactName,
    required String amount,
    required String ownerName,
    required String upiUri,
  }) {
    return tr.upiPaymentDetailsShareMessage(
      contactName,
      amount,
      tr.appName,
      upiUri,
      ownerName,
    );
  }

  static String contactStatement({
    required AppLocalizations tr,
    required String contactName,
    required String dateRange,
    required String ownerName,
  }) {
    return tr.contactStatementShareMessage(
      contactName,
      tr.appName,
      dateRange,
      ownerName,
    );
  }

  static String ledgerStatement({
    required AppLocalizations tr,
    required String dateRange,
    required String ownerName,
  }) {
    return tr.ledgerStatementShareMessage(tr.appName, dateRange, ownerName);
  }

  static String splitInvoice({
    required AppLocalizations tr,
    required String splitTitle,
    required String ownerName,
  }) {
    return tr.splitInvoiceShareMessage(tr.appName, splitTitle, ownerName);
  }
}
