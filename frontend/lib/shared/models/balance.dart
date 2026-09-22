// balance.dart
// -------------
// Client-side view-models for debt/balance computations.
// No DB table — these are computed by simplify.dart.

/// A single directed debt edge: [from] owes [to] ₹[amount].
class DebtEdge {
  const DebtEdge({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
  });

  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;

  @override
  String toString() => '$fromName owes $toName ₹${amount.toStringAsFixed(0)}';
}

/// Overall balance for the current user across all groups.
class OverallBalance {
  const OverallBalance({
    required this.totalOwed,
    required this.totalOwing,
  });

  final double totalOwed;   // others owe me
  final double totalOwing;  // I owe others

  double get net => totalOwed - totalOwing;
}

/// Pairwise raw balance between two users (before settlements).
class PairBalance {
  const PairBalance({
    required this.userCanReceive,  // amount the friend owes the user
    required this.userOwes,        // amount the user owes the friend
  });

  final double userCanReceive;
  final double userOwes;

  double get net => userCanReceive - userOwes;
}
