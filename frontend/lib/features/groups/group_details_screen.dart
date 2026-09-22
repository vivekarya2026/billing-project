// group_details_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/data/split_repository.dart';
import '../../shared/models/group.dart';
import '../../state/current_user_state.dart';
import '../../shared/logic/simplify.dart';
import '../../shared/components/expense_row.dart';
import '../../shared/components/member_row.dart';
import '../../shared/components/simplify_sheet.dart';
import '../../theme/accents.dart';

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({super.key, required this.groupId});
  final String groupId;
  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Future<Group> _future;

  @override
  void initState() {
    super.initState();
    _tab    = TabController(length: 2, vsync: this);
    _future = _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<Group> _load() =>
      context.read<SplitRepository>().getGroup(widget.groupId);

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<CurrentUserState>().profile?.id ?? '';
    return FutureBuilder<Group>(
      future: _future,
      builder: (context, snap) {
        final group = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(group?.groupName ?? '…'),
            actions: [
              if (group != null) ...[
                IconButton(
                  icon: const Icon(Icons.auto_fix_high),
                  tooltip: 'Simplify debts',
                  onPressed: () {
                    final edges = simplifyDebts([group]);
                    SimplifySheet.show(context, edges);
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'add_expense') {
                      await context.push('/group-details/${widget.groupId}/add-expense');
                      _reload();
                    } else if (v == 'add_member') {
                      await context.push('/group-details/${widget.groupId}/add-member');
                      _reload();
                    } else if (v == 'delete') {
                      _confirmDelete(context, group);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'add_expense', child: Text('Add Expense')),
                    PopupMenuItem(value: 'add_member',  child: Text('Add Member')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Group',
                          style: TextStyle(color: AppAccents.danger)),
                    ),
                  ],
                ),
              ],
            ],
            bottom: TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Members'),
              ],
            ),
          ),
          body: snap.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : snap.hasError
                  ? Center(child: Text('Error: ${snap.error}'))
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _ExpensesTab(
                            group: group!,
                            currentUserId: uid,
                            onDelete: _reload),
                        _MembersTab(group: group),
                      ],
                    ),
          floatingActionButton: group == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () async {
                    await context.push('/group-details/${widget.groupId}/add-expense');
                    _reload();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Expense'),
                ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete group?'),
        content: Text('Delete "${group.groupName}"? All expenses will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final nav  = Navigator.of(context);
              final root = GoRouter.of(context);
              nav.pop(); // close dialog
              final repo = context.read<SplitRepository>();
              await repo.deleteGroup(group.id);
              root.pop(); // pop group details screen
            },
            child: const Text('Delete',
                style: TextStyle(color: AppAccents.danger)),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({
    required this.group,
    required this.currentUserId,
    required this.onDelete,
  });
  final Group group;
  final String currentUserId;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (group.expenses.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined, size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          const Text('No expenses yet'),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: group.expenses.length,
      itemBuilder: (_, i) => ExpenseRow(
        expense:       group.expenses[i],
        currentUserId: currentUserId,
        onDelete: () async {
          await context.read<SplitRepository>()
              .deleteExpense(group.expenses[i].id);
          onDelete();
        },
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: group.members
          .map((m) => MemberRow(profile: m, subtitle: '@${m.username}'))
          .toList(),
    );
  }
}
