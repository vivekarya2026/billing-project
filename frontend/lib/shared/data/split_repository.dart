// split_repository.dart
// ----------------------
// Abstract interface + Supabase-backed implementation for all
// SplitWise data operations.

import '../models/profile.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/settlement.dart';
import '../services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

// ── Abstract interface ────────────────────────────────────────────────────
abstract class SplitRepository {
  // ── Profiles ─────────────────────────────────────────────────────────
  Future<Profile?> getProfileById(String id);
  Future<List<Profile>> searchUsersByUsername(String query);

  // ── Groups ────────────────────────────────────────────────────────────
  Future<List<Group>> getMyGroups(String userId);
  Future<Group> getGroup(String groupId);
  Future<Group> createGroup(String groupName, String creatorId);
  Future<void> deleteGroup(String groupId);
  Future<void> addMember(String groupId, String memberId);
  Future<void> removeMember(String groupId, String memberId);

  // ── Friends ───────────────────────────────────────────────────────────
  Future<List<Profile>> getFriends(String userId);
  Future<void> addFriend(String ownerId, String friendId);

  // ── Expenses ──────────────────────────────────────────────────────────
  Future<List<Expense>> getGroupExpenses(String groupId);
  Future<List<Expense>> getAllMyExpenses(String userId);
  Future<Expense> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidById,
    required List<String> splitMemberIds,
  });
  Future<void> deleteExpense(String expenseId);

  // ── Settlements ───────────────────────────────────────────────────────
  Future<List<Settlement>> getSettlementsForPair(
      String userId, String friendId);
  Future<Settlement> makeSettlement({
    required String payerId,
    required String receiverId,
    required double amount,
    String? groupId,
  });
}

// ── Supabase implementation ───────────────────────────────────────────────
class SupabaseSplitRepository implements SplitRepository {
  SupabaseSplitRepository();

  SupabaseClient get _client => SupabaseService.instance.client;

  // ── Profiles ─────────────────────────────────────────────────────────

  @override
  Future<Profile?> getProfileById(String id) async {
    final rows = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .limit(1) as List;
    if (rows.isEmpty) return null;
    return Profile.fromJson(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<Profile>> searchUsersByUsername(String query) async {
    if (query.trim().isEmpty) return [];
    final rows = await _client
        .from('profiles')
        .select()
        .ilike('username', '%${query.trim()}%')
        .limit(10) as List;
    return rows
        .map((r) => Profile.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ── Groups ─────────────────────────────────────────────────────────────

  @override
  Future<List<Group>> getMyGroups(String userId) async {
    // Fetch groups where user is a member via group_members join
    final rows = await _client
        .from('group_members')
        .select('''
          group_id,
          groups!inner(
            id,
            group_name,
            creator_id,
            created_at,
            creator:profiles!groups_creator_id_fkey(id, username, name, email)
          )
        ''')
        .eq('member_id', userId) as List;

    final groupIds =
        rows.map((r) => r['group_id'] as String).toList();
    if (groupIds.isEmpty) return [];

    // Fetch all groups in one go with members
    return Future.wait(groupIds.map((id) => getGroup(id)));
  }

  @override
  Future<Group> getGroup(String groupId) async {
    // Group + creator
    final gRows = await _client
        .from('groups')
        .select('''
          id,
          group_name,
          created_at,
          creator:profiles!groups_creator_id_fkey(id, username, name, email)
        ''')
        .eq('id', groupId)
        .single();

    // Members
    final mRows = await _client
        .from('group_members')
        .select('member:profiles!group_members_member_id_fkey(id, username, name, email)')
        .eq('group_id', groupId) as List;

    final members = mRows
        .map((r) => Profile.fromJson(r['member'] as Map<String, dynamic>))
        .toList();

    // Expenses
    final expenses = await getGroupExpenses(groupId);

    return Group(
      id:        gRows['id'] as String,
      groupName: gRows['group_name'] as String,
      creator:   Profile.fromJson(gRows['creator'] as Map<String, dynamic>),
      members:   members,
      expenses:  expenses,
    );
  }

  @override
  Future<Group> createGroup(String groupName, String creatorId) async {
    final row = await _client.from('groups').insert({
      'group_name': groupName,
      'creator_id': creatorId,
    }).select().single();

    // Add creator as first member
    await _client.from('group_members').insert({
      'group_id':  row['id'],
      'member_id': creatorId,
    });

    return getGroup(row['id'] as String);
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _client.from('groups').delete().eq('id', groupId);
  }

  @override
  Future<void> addMember(String groupId, String memberId) async {
    await _client.from('group_members').upsert({
      'group_id':  groupId,
      'member_id': memberId,
    });
  }

  @override
  Future<void> removeMember(String groupId, String memberId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('member_id', memberId);
  }

  // ── Friends ─────────────────────────────────────────────────────────────

  @override
  Future<List<Profile>> getFriends(String userId) async {
    final rows = await _client
        .from('friends')
        .select('friend:profiles!friends_friend_id_fkey(id, username, name, email)')
        .eq('owner_id', userId) as List;
    return rows
        .map((r) => Profile.fromJson(r['friend'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addFriend(String ownerId, String friendId) async {
    // Insert both directions
    await _client.from('friends').upsert([
      {'owner_id': ownerId, 'friend_id': friendId},
      {'owner_id': friendId, 'friend_id': ownerId},
    ]);
  }

  // ── Expenses ─────────────────────────────────────────────────────────────

  @override
  Future<List<Expense>> getGroupExpenses(String groupId) async {
    final rows = await _client
        .from('expenses')
        .select('''
          id,
          group_id,
          description,
          amount,
          created_at,
          paid_by:profiles!expenses_paid_by_fkey(id, username, name, email)
        ''')
        .eq('group_id', groupId)
        .order('created_at', ascending: false) as List;

    if (rows.isEmpty) return [];

    final ids = rows.map((r) => r['id'] as String).toList();
    final splitRows = await _client
        .from('expense_members')
        .select('expense_id, member:profiles!expense_members_member_id_fkey(id, username, name, email)')
        .inFilter('expense_id', ids) as List;

    final splitMap = <String, List<Profile>>{};
    for (final s in splitRows) {
      final eid = s['expense_id'] as String;
      (splitMap[eid] ??= []).add(
          Profile.fromJson(s['member'] as Map<String, dynamic>));
    }

    return rows.map((r) {
      final id = r['id'] as String;
      return Expense(
        id:          id,
        groupId:     r['group_id'] as String,
        description: r['description'] as String,
        amount:      (r['amount'] as num).toDouble(),
        paidBy:      Profile.fromJson(r['paid_by'] as Map<String, dynamic>),
        splitMembers: splitMap[id] ?? [],
        createdAt:   DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  @override
  Future<List<Expense>> getAllMyExpenses(String userId) async {
    // Get all group IDs the user belongs to
    final gmRows = await _client
        .from('group_members')
        .select('group_id')
        .eq('member_id', userId) as List;
    final groupIds = gmRows.map((r) => r['group_id'] as String).toList();
    if (groupIds.isEmpty) return [];

    // Fetch all expenses across those groups in one call
    final rows = await _client
        .from('expenses')
        .select('''
          id,
          group_id,
          description,
          amount,
          created_at,
          paid_by:profiles!expenses_paid_by_fkey(id, username, name, email)
        ''')
        .inFilter('group_id', groupIds)
        .order('created_at', ascending: false) as List;

    if (rows.isEmpty) return [];

    final ids = rows.map((r) => r['id'] as String).toList();
    final splitRows = await _client
        .from('expense_members')
        .select('expense_id, member:profiles!expense_members_member_id_fkey(id, username, name, email)')
        .inFilter('expense_id', ids) as List;

    final splitMap = <String, List<Profile>>{};
    for (final s in splitRows) {
      final eid = s['expense_id'] as String;
      (splitMap[eid] ??= []).add(
          Profile.fromJson(s['member'] as Map<String, dynamic>));
    }

    return rows.map((r) {
      final id = r['id'] as String;
      return Expense(
        id:          id,
        groupId:     r['group_id'] as String,
        description: r['description'] as String,
        amount:      (r['amount'] as num).toDouble(),
        paidBy:      Profile.fromJson(r['paid_by'] as Map<String, dynamic>),
        splitMembers: splitMap[id] ?? [],
        createdAt:   DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  @override
  Future<Expense> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidById,
    required List<String> splitMemberIds,
  }) async {
    // Insert expense
    final row = await _client.from('expenses').insert({
      'group_id':    groupId,
      'description': description,
      'amount':      amount,
      'paid_by':     paidById,
    }).select().single();

    final expenseId = row['id'] as String;

    // Insert split members
    await _client.from('expense_members').insert(
      splitMemberIds
          .map((mid) => {'expense_id': expenseId, 'member_id': mid})
          .toList(),
    );

    // Fetch full expense with profiles
    final expenses = await getGroupExpenses(groupId);
    return expenses.firstWhere((e) => e.id == expenseId);
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }

  // ── Settlements ───────────────────────────────────────────────────────

  @override
  Future<List<Settlement>> getSettlementsForPair(
      String userId, String friendId) async {
    final rows = await _client
        .from('settlements')
        .select('''
          id,
          group_id,
          amount,
          created_at,
          payer:profiles!settlements_payer_id_fkey(id, username, name, email),
          receiver:profiles!settlements_receiver_id_fkey(id, username, name, email)
        ''')
        .or('and(payer_id.eq.$userId,receiver_id.eq.$friendId),'
            'and(payer_id.eq.$friendId,receiver_id.eq.$userId)')
        .order('created_at', ascending: false) as List;

    return rows.map((r) => Settlement(
          id:        r['id'] as String,
          groupId:   r['group_id'] as String?,
          payer:     Profile.fromJson(r['payer'] as Map<String, dynamic>),
          receiver:  Profile.fromJson(r['receiver'] as Map<String, dynamic>),
          amount:    (r['amount'] as num).toDouble(),
          createdAt: DateTime.parse(r['created_at'] as String),
        )).toList();
  }

  @override
  Future<Settlement> makeSettlement({
    required String payerId,
    required String receiverId,
    required double amount,
    String? groupId,
  }) async {
    final row = await _client.from('settlements').insert({
      'payer_id':    payerId,
      'receiver_id': receiverId,
      'amount':      amount,
      if (groupId != null) 'group_id': groupId,
    }).select('''
      id,
      group_id,
      amount,
      created_at,
      payer:profiles!settlements_payer_id_fkey(id, username, name, email),
      receiver:profiles!settlements_receiver_id_fkey(id, username, name, email)
    ''').single();

    return Settlement(
      id:        row['id'] as String,
      groupId:   row['group_id'] as String?,
      payer:     Profile.fromJson(row['payer'] as Map<String, dynamic>),
      receiver:  Profile.fromJson(row['receiver'] as Map<String, dynamic>),
      amount:    (row['amount'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
