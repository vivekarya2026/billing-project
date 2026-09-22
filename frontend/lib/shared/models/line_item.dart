// lib/shared/models/line_item.dart
// Mirrors the Supabase `line_items` table.

class LineItemModel {
  const LineItemModel({
    required this.id,
    required this.billId,
    required this.description,
    required this.amount,
    required this.itemType,
    required this.sortOrder,
  });

  final String id;
  final String billId;
  final String description;
  final double amount;
  final String itemType;  // "charge" | "credit" | "tax" | "fee" | "other"
  final int sortOrder;

  factory LineItemModel.fromJson(Map<String, dynamic> j) => LineItemModel(
        id:          j['id'] as String,
        billId:      j['bill_id'] as String,
        description: j['description'] as String,
        amount:      (j['amount'] as num).toDouble(),
        itemType:    j['item_type'] as String? ?? 'charge',
        sortOrder:   j['sort_order'] as int? ?? 0,
      );
}
