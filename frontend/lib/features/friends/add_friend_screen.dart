// add_friend_screen.dart — also used for "Add Member to Group"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/data/split_repository.dart';
import '../../shared/models/profile.dart';
import '../../state/current_user_state.dart';
import '../../shared/components/user_search_row.dart';

class AddFriendScreen extends StatefulWidget {
  /// If [groupId] is non-null, adds the found user as a group member.
  const AddFriendScreen({super.key, this.groupId});
  final String? groupId;
  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _ctrl = TextEditingController();
  List<Profile> _results  = [];
  final Set<String> _added = {};
  bool          _searching = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onSearch);
  }

  @override
  void dispose() { _ctrl.removeListener(_onSearch); _ctrl.dispose(); super.dispose(); }

  void _onSearch() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final results = await context.read<SplitRepository>().searchUsersByUsername(q);
    if (mounted) setState(() { _results = results; _searching = false; });
  }

  Future<void> _add(Profile p) async {
    final uid  = context.read<CurrentUserState>().profile?.id ?? '';
    final repo = context.read<SplitRepository>();
    if (widget.groupId != null) {
      await repo.addMember(widget.groupId!, p.id);
    } else {
      await repo.addFriend(uid, p.id);
    }
    if (mounted) setState(() => _added.add(p.id));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.groupId != null ? 'Add Member' : 'Add Friend';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller:  _ctrl,
              autofocus:   true,
              decoration:  InputDecoration(
                hintText:   'Search by username',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child:   CircularProgressIndicator(strokeWidth: 2))
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final p = _results[i];
                final me = context.read<CurrentUserState>().profile;
                if (p.id == me?.id) return const SizedBox.shrink();
                return UserSearchRow(
                  profile: p,
                  isAdded: _added.contains(p.id),
                  onAction: () => _add(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
