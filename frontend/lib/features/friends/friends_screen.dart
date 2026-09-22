// friends_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/data/split_repository.dart';
import '../../shared/logic/simplify.dart';
import '../../shared/models/profile.dart';
import '../../state/current_user_state.dart';
import '../../shared/components/friend_card.dart';
import '../../theme/accents.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late Future<List<_FriendWithBalance>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_FriendWithBalance>> _load() async {
    final uid     = context.read<CurrentUserState>().profile?.id ?? '';
    final repo    = context.read<SplitRepository>();
    final friends = await repo.getFriends(uid);
    final groups  = await repo.getMyGroups(uid);
    final allExpenses = groups.expand((g) => g.expenses).toList();

    return Future.wait(friends.map((friend) async {
      final settlements = await repo.getSettlementsForPair(uid, friend.id);
      final pb  = processTransactions(uid, allExpenses, friend.id);
      // net after settlements
      double settledByMe = 0, settledByFriend = 0;
      for (final s in settlements) {
        if (s.payer.id == uid)     settledByMe     += s.amount;
        if (s.payer.id == friend.id) settledByFriend += s.amount;
      }
      final net = (pb.userCanReceive - settledByFriend) -
                  (pb.userOwes       - settledByMe);
      return _FriendWithBalance(friend: friend, net: net);
    }));
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppAccents.gradientText('Friends',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () async {
              await context.push('/add-friend');
              _reload();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<_FriendWithBalance>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline, size: 56,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                const Text('No friends yet'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await context.push('/add-friend');
                    _reload();
                  },
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Add Friend'),
                ),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) => FriendCard(
                friend: list[i].friend,
                net:    list[i].net,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/add-friend');
          _reload();
        },
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }
}

class _FriendWithBalance {
  const _FriendWithBalance({required this.friend, required this.net});
  final Profile friend;
  final double  net;
}
