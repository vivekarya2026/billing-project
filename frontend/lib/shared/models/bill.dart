// lib/shared/models/bill.dart
// Bill — the summary row returned by getBillsDue() for the Home screen.
// BillDetail — the full row with joins for the Detail screen.

import 'extraction_field.dart';
import 'line_item.dart';
import 'account.dart';

class Bill {
  const Bill({
    required this.id,
    required this.accountId,
    required this.provider,
    required this.serviceType,
    this.amountDue,
    this.dueDate,
    this.periodStart,
    this.periodEnd,
    required this.extractionStatus,
    // The one sentence produced by /narrate (or anomaly description).
    // Stored in bills.narration_sentence after extraction completes.
    this.narrationSentence,
  });

  final String id;
  final String accountId;
  final String provider;
  final String serviceType;
  final double? amountDue;
  final DateTime? dueDate;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String extractionStatus;
  final String? narrationSentence;

  factory Bill.fromJson(Map<String, dynamic> j) {
    // accounts is an embedded join object
    final account = j['accounts'] as Map<String, dynamic>?;
    return Bill(
      id:              j['id'] as String,
      accountId:       j['account_id'] as String,
      provider:        account?['provider'] as String? ?? '',
      serviceType:     account?['service_type'] as String? ?? '',
      amountDue:       (j['amount_due'] as num?)?.toDouble(),
      dueDate:         j['due_date'] != null
          ? DateTime.tryParse(j['due_date'] as String)
          : null,
      periodStart:     j['period_start'] != null
          ? DateTime.tryParse(j['period_start'] as String)
          : null,
      periodEnd:       j['period_end'] != null
          ? DateTime.tryParse(j['period_end'] as String)
          : null,
      extractionStatus: j['extraction_status'] as String? ?? 'pending',
      narrationSentence: j['narration_sentence'] as String?,
    );
  }
}

class BillDetail extends Bill {
  const BillDetail({
    required super.id,
    required super.accountId,
    required super.provider,
    required super.serviceType,
    super.amountDue,
    super.dueDate,
    super.periodStart,
    super.periodEnd,
    required super.extractionStatus,
    super.narrationSentence,
    this.rawImagePath,
    required this.extractionFields,
    required this.lineItems,
    required this.anomalies,
    this.account,
  });

  final String? rawImagePath;
  final List<ExtractionFieldModel> extractionFields;
  final List<LineItemModel> lineItems;
  final List<Map<String, dynamic>> anomalies;
  final Account? account;

  factory BillDetail.fromJson(Map<String, dynamic> j) {
    final account = j['accounts'] != null
        ? Account.fromJson(j['accounts'] as Map<String, dynamic>)
        : null;

    return BillDetail(
      id:              j['id'] as String,
      accountId:       j['account_id'] as String,
      provider:        account?.provider ?? '',
      serviceType:     account?.serviceType ?? '',
      amountDue:       (j['amount_due'] as num?)?.toDouble(),
      dueDate:         j['due_date'] != null
          ? DateTime.tryParse(j['due_date'] as String)
          : null,
      periodStart:     j['period_start'] != null
          ? DateTime.tryParse(j['period_start'] as String)
          : null,
      periodEnd:       j['period_end'] != null
          ? DateTime.tryParse(j['period_end'] as String)
          : null,
      extractionStatus: j['extraction_status'] as String? ?? 'pending',
      narrationSentence: j['narration_sentence'] as String?,
      rawImagePath:    j['raw_image_path'] as String?,
      extractionFields: (j['extraction_fields'] as List? ?? [])
          .map((e) => ExtractionFieldModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      lineItems: (j['line_items'] as List? ?? [])
          .map((e) => LineItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      anomalies: List<Map<String, dynamic>>.from(j['anomalies'] as List? ?? []),
      account: account,
    );
  }
}
