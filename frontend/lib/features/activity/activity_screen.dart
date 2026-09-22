// activity_screen.dart — global activity feed + overall balance
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/data/split_repository.dart';
import '../../shared/logic/simplify.dart';
import '../../state/current_user_state.dart';
import '../../shared/components/expense_row.dart';
import '../../shared/components/overall_balance_card.dart';
import '../../shared/models/balance.dart';
import '../../theme/accents.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late Future<_ActivityData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ActivityData> _load() async {
    final uid     = context.read<CurrentUserState>().profile?.id ?? '';
    final repo    = context.read<SplitRepository>();
    final expenses = await repo.getAllMyExpenses(uid);

    // Gather all settlements for the user
    final groups  = await repo.getMyGroups(uid);
    final friendIds = <String>{};
    for (final g in groups) {
      for (final m in g.members) {
        if (m.id != uid) friendIds.add(m.id);
      }
    }
    final allSettlements = await Future.wait(
      friendIds.map((fid) => repo.getSettlementsForPair(uid, fid)),
    );
    final settlements = allSettlements.expand((s) => s).toList();

    final balance = overallBalance(expenses, settlements, uid);
    return _ActivityData(expenses: expenses, balance: balance);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<CurrentUserState>().profile?.id ?? '';
    return Scaffold(
      appBar: AppBar(
        title: AppAccents.gradientText('Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<_ActivityData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          if (data == null) {
            return const Center(child: Text('No data'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OverallBalanceCard(balance: data.balance),
                const SizedBox(height: 24),
                Text('Recent Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (data.expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No expenses yet',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ),
                  )
                else
                  ...data.expenses.map((e) => ExpenseRow(
                        expense:       e,
                        currentUserId: uid,
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivityData {
  const _ActivityData({required this.expenses, required this.balance});
  final List expenses;
  final OverallBalance balance;
}
