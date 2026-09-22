// fake_split_repository.dart
// ---------------------------
// In-memory repository for BYPASS_AUTH=true / offline development.
// Pre-loaded with three users, one group, expenses, and a settlement
// anchored to DateTime.now() for realistic dates.

import '../models/profile.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/settlement.dart';
import 'split_repository.dart';

// ── Seed identities ──────────────────────────────────────────────────────
const _alice = Profile(
  id:       '00000000-0000-0000-0000-000000000101',
  username: 'alice',
  name:     'Alice Kumar',
  email:    'alice@split.local',
);

const _bob = Profile(
  id:       '00000000-0000-0000-0000-000000000102',
  username: 'bob',
  name:     'Bob Sharma',
  email:    'bob@split.local',
);

const _carol = Profile(
  id:       '00000000-0000-0000-0000-000000000103',
  username: 'carol',
  name:     'Carol Patel',
  email:    'carol@split.local',
);

// ── Fake repo ─────────────────────────────────────────────────────────────
class FakeSplitRepository implements SplitRepository {
  FakeSplitRepository({String? currentUserId})
      : _me = currentUserId == _bob.id
            ? _bob
            : currentUserId == _carol.id
                ? _carol
                : _alice;

  final Profile _me;

  late final List<Expense> _expenses = [
    Expense(
      id:          'exp-001',
      groupId:     'grp-001',
      description: 'Dinner at shack',
      amount:      1500,
      paidBy:      _alice,
      splitMembers: [_alice, _bob, _carol],
      createdAt:   DateTime.now().subtract(const Duration(days: 2)),
    ),
    Expense(
      id:          'exp-002',
      groupId:     'grp-001',
      description: 'Taxi to airport',
      amount:      900,
      paidBy:      _bob,
      splitMembers: [_alice, _bob, _carol],
      createdAt:   DateTime.now().subtract(const Duration(days: 1)),
    ),
    Expense(
      id:          'exp-003',
      groupId:     'grp-001',
      description: 'Grocery shopping',
      amount:      600,
      paidBy:      _carol,
      splitMembers: [_alice, _carol],
      createdAt:   DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  late final List<Settlement> _settlements = [
    Settlement(
      id:         'stl-001',
      groupId:    'grp-001',
      payer:      _bob,
      receiver:   _alice,
      amount:     400,
      createdAt:  DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  Group get _group => Group(
        id:        'grp-001',
        groupName: 'Goa Trip 🏖️',
        creator:   _alice,
        members:   [_alice, _bob, _carol],
        expenses:  _expenses,
      );

  // ── Profiles ──────────────────────────────────────────────────────────

  @override
  Future<Profile?> getProfileById(String id) async {
    for (final p in [_alice, _bob, _carol]) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<List<Profile>> searchUsersByUsername(String query) async {
    final q = query.toLowerCase();
    return [_alice, _bob, _carol]
        .where((p) => p.username.contains(q) || p.name.toLowerCase().contains(q))
        .toList();
  }

  // ── Groups ────────────────────────────────────────────────────────────

  @override
  Future<List<Group>> getMyGroups(String userId) async => [_group];

  @override
  Future<Group> getGroup(String groupId) async => _group;

  @override
  Future<Group> createGroup(String groupName, String creatorId) async {
    // In fake mode just return the existing group with a new name
    return Group(
      id:        'grp-new-${DateTime.now().millisecondsSinceEpoch}',
      groupName: groupName,
      creator:   _me,
      members:   [_me],
      expenses:  const [],
    );
  }

  @override
  Future<void> deleteGroup(String groupId) async {}

  @override
  Future<void> addMember(String groupId, String memberId) async {}

  @override
  Future<void> removeMember(String groupId, String memberId) async {}

  // ── Friends ───────────────────────────────────────────────────────────

  @override
  Future<List<Profile>> getFriends(String userId) async {
    return [_alice, _bob, _carol].where((p) => p.id != userId).toList();
  }

  @override
  Future<void> addFriend(String ownerId, String friendId) async {}

  // ── Expenses ──────────────────────────────────────────────────────────

  @override
  Future<List<Expense>> getGroupExpenses(String groupId) async => _expenses;

  @override
  Future<List<Expense>> getAllMyExpenses(String userId) async => _expenses;

  @override
  Future<Expense> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidById,
    required List<String> splitMemberIds,
  }) async {
    final profiles = [_alice, _bob, _carol];
    final paidBy = profiles.firstWhere((p) => p.id == paidById,
        orElse: () => _me);
    final splits =
        profiles.where((p) => splitMemberIds.contains(p.id)).toList();
    final exp = Expense(
      id:          'exp-new-${DateTime.now().millisecondsSinceEpoch}',
      groupId:     groupId,
      description: description,
      amount:      amount,
      paidBy:      paidBy,
      splitMembers: splits,
      createdAt:   DateTime.now(),
    );
    _expenses.insert(0, exp);
    return exp;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    _expenses.removeWhere((e) => e.id == expenseId);
  }

  // ── Settlements ───────────────────────────────────────────────────────

  @override
  Future<List<Settlement>> getSettlementsForPair(
      String userId, String friendId) async {
    return _settlements.where((s) =>
        (s.payer.id == userId && s.receiver.id == friendId) ||
        (s.payer.id == friendId && s.receiver.id == userId)).toList();
  }

  @override
  Future<Settlement> makeSettlement({
    required String payerId,
    required String receiverId,
    required double amount,
    String? groupId,
  }) async {
    final profiles = [_alice, _bob, _carol];
    final payer    = profiles.firstWhere((p) => p.id == payerId,
        orElse: () => _me);
    final receiver = profiles.firstWhere((p) => p.id == receiverId,
        orElse: () => _bob);
    final stl = Settlement(
      id:         'stl-new-${DateTime.now().millisecondsSinceEpoch}',
      groupId:    groupId,
      payer:      payer,
      receiver:   receiver,
      amount:     amount,
      createdAt:  DateTime.now(),
    );
    _settlements.insert(0, stl);
    return stl;
  }
}
