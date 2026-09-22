// simplify.dart
// --------------
// Client-side debt computation — a faithful Dart port of the reference
// Splitwise clone's Simplify.tsx logic.
//
// Three public functions:
//
//   processTransactions(userId, expenses, friendId)
//     → PairBalance (userCanReceive, userOwes)
//     Equal-split arithmetic for a pair of users.
//
//   simplifyDebts(groups)
//     → List<DebtEdge>
//     Greedy cash-flow-minimization ("A owes B ₹X").
//
//   overallBalance(expenses, settlements, userId)
//     → OverallBalance (totalOwed, totalOwing)
//     Overall balance for the current user, net of recorded settlements.

import '../models/group.dart';
import '../models/expense.dart';
import '../models/settlement.dart';
import '../models/balance.dart';

// ── processTransactions ───────────────────────────────────────────────────
/// Compute the raw pairwise balance between [userId] and [friendId]
/// across [expenses], using equal-split arithmetic.
///
/// Returns [PairBalance]:
///   userCanReceive — the amount [friendId] owes [userId]
///   userOwes       — the amount [userId] owes [friendId]
PairBalance processTransactions(
  String userId,
  List<Expense> expenses,
  String friendId,
) {
  double userCanReceive = 0;
  double userOwes       = 0;

  for (final e in expenses) {
    if (e.splitMembers.isEmpty) continue;
    final share = e.amount / e.splitMembers.length;

    final userInSplit   = e.splitMembers.any((m) => m.id == userId);
    final friendInSplit = e.splitMembers.any((m) => m.id == friendId);

    if (e.paidBy.id == userId && friendInSplit) {
      // I paid and friend shares → friend owes me their share
      userCanReceive += share;
    } else if (e.paidBy.id == friendId && userInSplit) {
      // Friend paid and I share → I owe friend my share
      userOwes += share;
    }
  }

  return PairBalance(
    userCanReceive: userCanReceive,
    userOwes:       userOwes,
  );
}

// ── simplifyDebts ─────────────────────────────────────────────────────────
/// Greedy cash-flow-minimization ("Splitwise simplify") over [groups].
///
/// Algorithm (mirrors reference Simplify.tsx):
///   1. Collect unique members across all groups.
///   2. For every unordered pair (A, B), compute pairwise balances via
///      processTransactions, then produce directed edges A→B and B→A.
///   3. Fold all edges into a net-balance map (negative = creditor).
///   4. Greedy settle-up: pair the largest creditor with the largest debtor,
///      transfer min(|creditor|, debtor), repeat.
///
/// Returns a minimal list of [DebtEdge] ("A owes B ₹X").
List<DebtEdge> simplifyDebts(List<Group> groups) {
  // Step 1 — unique members
  final memberMap = <String, String>{}; // id → name
  for (final g in groups) {
    for (final m in g.members) {
      memberMap[m.id] = m.name;
    }
  }
  final memberIds = memberMap.keys.toList();
  if (memberIds.length < 2) return [];

  // Step 2 — flatten expenses
  final allExpenses = groups.expand((g) => g.expenses).toList();

  // Step 3 — directed edges from pairwise balances
  final processedPairs = <String>{};
  final netBalance = <String, double>{
    for (final id in memberIds) id: 0.0,
  };

  for (var i = 0; i < memberIds.length; i++) {
    for (var j = i + 1; j < memberIds.length; j++) {
      final a = memberIds[i];
      final b = memberIds[j];
      final pairKey = [a, b]..sort();
      final key = pairKey.join('-');
      if (processedPairs.contains(key)) continue;
      processedPairs.add(key);

      final pb = processTransactions(a, allExpenses, b);
      // a owes b pb.userOwes
      // b owes a pb.userCanReceive
      netBalance[a] = (netBalance[a] ?? 0) - pb.userCanReceive;
      netBalance[a] = (netBalance[a] ?? 0) + pb.userOwes;
      netBalance[b] = (netBalance[b] ?? 0) + pb.userCanReceive;
      netBalance[b] = (netBalance[b] ?? 0) - pb.userOwes;
    }
  }

  // Step 4 — greedy settle-up
  // positive balance = debtor (owes money)
  // negative balance = creditor (is owed money)
  final result = <DebtEdge>[];

  // Work on mutable copy
  final bal = Map<String, double>.from(netBalance);

  bool progress = true;
  while (progress) {
    progress = false;

    // Find max debtor and max creditor
    String? debtorId;
    String? creditorId;
    double maxDebt    = 0.01; // threshold to avoid floating-point noise
    double maxCredit  = 0.01;

    for (final entry in bal.entries) {
      if (entry.value > maxDebt) {
        maxDebt   = entry.value;
        debtorId  = entry.key;
      }
      if (entry.value < -maxCredit) {
        maxCredit  = -entry.value;
        creditorId = entry.key;
      }
    }

    if (debtorId == null || creditorId == null) break;

    final transfer = maxDebt < maxCredit ? maxDebt : maxCredit;
    bal[debtorId]  = (bal[debtorId]  ?? 0) - transfer;
    bal[creditorId] = (bal[creditorId] ?? 0) + transfer;

    result.add(DebtEdge(
      fromId:   debtorId,
      fromName: memberMap[debtorId]  ?? debtorId,
      toId:     creditorId,
      toName:   memberMap[creditorId] ?? creditorId,
      amount:   double.parse(transfer.toStringAsFixed(2)),
    ));
    progress = true;
  }

  return result;
}

// ── overallBalance ────────────────────────────────────────────────────────
/// Compute the current user's overall balance across all [expenses],
/// reconciled against already-recorded [settlements].
///
/// Mirrors the reference's `calculateOverallBalance` in SimplifyCard.tsx.
OverallBalance overallBalance(
  List<Expense> expenses,
  List<Settlement> settlements,
  String userId,
) {
  double rawOwed  = 0; // others owe me
  double rawOwing = 0; // I owe others

  for (final e in expenses) {
    final splitCount = e.splitMembers.length;
    final userInSplit = e.splitMembers.any((m) => m.id == userId);

    if (e.paidBy.id == userId) {
      // I paid
      if (userInSplit && splitCount > 0) {
        // Others owe me the rest; my share is excluded
        rawOwed += e.amount - (e.amount / splitCount);
      } else {
        // I paid for others who split; I get back the whole amount
        rawOwed += e.amount;
      }
    } else if (userInSplit && splitCount > 0) {
      // Someone else paid and I owe my share
      rawOwing += e.amount / splitCount;
    }
  }

  // Subtract recorded settlements from raw balances
  double settledAsPayer    = 0;
  double settledAsReceiver = 0;
  for (final s in settlements) {
    if (s.payer.id == userId)    settledAsPayer    += s.amount;
    if (s.receiver.id == userId) settledAsReceiver += s.amount;
  }

    final netOwed  = (rawOwed  - settledAsPayer).clamp(0.0, double.infinity);
    final netOwing = (rawOwing - settledAsReceiver).clamp(0.0, double.infinity);

  return OverallBalance(
    totalOwed:  netOwed,
    totalOwing: netOwing,
  );
}
