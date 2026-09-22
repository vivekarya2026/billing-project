// groups_screen.dart — list of the user's groups in a responsive grid
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/data/split_repository.dart';
import '../../shared/models/group.dart';
import '../../state/current_user_state.dart';
import '../../theme/accents.dart';
import '../../shared/components/group_card.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late Future<List<Group>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Group>> _load() {
    final uid  = context.read<CurrentUserState>().profile?.id ?? '';
    return context.read<SplitRepository>().getMyGroups(uid);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppAccents.gradientText('Groups',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await context.push('/create-group');
              _reload();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Group>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final groups = snap.data ?? [];
          if (groups.isEmpty) {
            return _EmptyState(onCreateGroup: () async {
              await context.push('/create-group');
              _reload();
            });
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: _GroupGrid(groups: groups, onGroupDeleted: _reload),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/create-group');
          _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
    );
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.groups, required this.onGroupDeleted});
  final List<Group> groups;
  final VoidCallback onGroupDeleted;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols  = width < 500 ? 1 : width < 900 ? 2 : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing:  12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: groups.length,
      itemBuilder: (_, i) => GroupCard(
        group:  groups[i],
        onTap:  () => context.push('/group-details/${groups[i].id}'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateGroup});
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ShaderMask(
          shaderCallback: (r) => AppAccents.skyToIndigo.createShader(r),
          blendMode: BlendMode.srcIn,
          child: const Icon(Icons.group_outlined, size: 64),
        ),
        const SizedBox(height: 16),
        Text('No groups yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Create a group to start splitting expenses',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onCreateGroup,
          icon: const Icon(Icons.add),
          label: const Text('Create Group'),
        ),
      ]),
    );
  }
}
