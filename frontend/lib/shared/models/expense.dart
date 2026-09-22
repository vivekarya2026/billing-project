// expense.dart
// -------------
// A single expense in a group (mirrors public.expenses + split members).

import 'profile.dart';

class Expense {
  const Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitMembers,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String description;
  final double amount;       // always numeric
  final Profile paidBy;
  final List<Profile> splitMembers;
  final DateTime createdAt;

  /// Per-person share (equal split).
  double get sharePerPerson =>
      splitMembers.isEmpty ? amount : amount / splitMembers.length;

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id:          j['id'] as String,
        groupId:     j['group_id'] as String,
        description: j['description'] as String,
        amount:      (j['amount'] as num).toDouble(),
        paidBy:      Profile.fromJson(j['paid_by'] as Map<String, dynamic>),
        splitMembers: (j['split_members'] as List? ?? [])
            .map((m) => Profile.fromJson(m as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
