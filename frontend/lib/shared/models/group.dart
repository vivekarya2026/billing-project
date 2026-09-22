// group.dart
// -----------
// A named expense group (mirrors public.groups + member list).

import 'profile.dart';
import 'expense.dart';

class Group {
  const Group({
    required this.id,
    required this.groupName,
    required this.creator,
    required this.members,
    this.expenses = const [],
  });

  final String id;
  final String groupName;
  final Profile creator;
  final List<Profile> members;
  final List<Expense> expenses;

  double get totalExpenses =>
      expenses.fold(0, (sum, e) => sum + e.amount);

  factory Group.fromJson(Map<String, dynamic> j) => Group(
        id:        j['id'] as String,
        groupName: j['group_name'] as String,
        creator:   Profile.fromJson(j['creator'] as Map<String, dynamic>),
        members: (j['members'] as List? ?? [])
            .map((m) => Profile.fromJson(m as Map<String, dynamic>))
            .toList(),
        expenses: (j['expenses'] as List? ?? [])
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Group copyWith({List<Expense>? expenses}) => Group(
        id:        id,
        groupName: groupName,
        creator:   creator,
        members:   members,
        expenses:  expenses ?? this.expenses,
      );
}
