// create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/data/split_repository.dart';
import '../../state/current_user_state.dart';
import '../../shared/components/primary_button.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _ctrl    = TextEditingController();
  bool  _loading = false;
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _create() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a group name');
      return;
    }
    final uid = context.read<CurrentUserState>().profile?.id ?? '';
    setState(() { _loading = true; _error = null; });
    try {
      final group = await context.read<SplitRepository>().createGroup(name, uid);
      if (mounted) context.pop(group);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Group')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group Name',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller:  _ctrl,
              autofocus:   true,
              decoration:  InputDecoration(
                hintText: 'e.g. Goa Trip, Office Lunch',
                prefixIcon: const Icon(Icons.group_outlined),
                errorText:  _error,
              ),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label:   'Create Group',
              loading: _loading,
              onTap:   _loading ? null : _create,
            ),
          ],
        ),
      ),
    );
  }
}
