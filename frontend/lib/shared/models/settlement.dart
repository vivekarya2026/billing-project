// settlement.dart
// ----------------
// A recorded cash/manual settlement between two users.

import 'profile.dart';

class Settlement {
  const Settlement({
    required this.id,
    this.groupId,
    required this.payer,
    required this.receiver,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String? groupId;  // nullable — cross-group settlements allowed
  final Profile payer;
  final Profile receiver;
  final double amount;
  final DateTime createdAt;

  factory Settlement.fromJson(Map<String, dynamic> j) => Settlement(
        id:       j['id'] as String,
        groupId:  j['group_id'] as String?,
        payer:    Profile.fromJson(j['payer'] as Map<String, dynamic>),
        receiver: Profile.fromJson(j['receiver'] as Map<String, dynamic>),
        amount:   (j['amount'] as num).toDouble(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
