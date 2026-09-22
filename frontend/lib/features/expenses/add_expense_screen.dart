// add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/data/split_repository.dart';
import '../../shared/models/profile.dart';
import '../../state/current_user_state.dart';
import '../../shared/components/primary_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.groupId});
  final String groupId;
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _form   = GlobalKey<FormState>();
  final _desc   = TextEditingController();
  final _amount = TextEditingController();

  List<Profile>   _members = [];
  Set<String>     _selected = {};
  String?         _paidById;
  bool            _loading  = false;
  String?         _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _desc.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final repo = context.read<SplitRepository>();
    final me   = context.read<CurrentUserState>().profile;
    final group = await repo.getGroup(widget.groupId);
    if (!mounted) return;
    setState(() {
      _members   = group.members;
      _selected  = group.members.map((m) => m.id).toSet();
      _paidById  = me?.id ?? (group.members.isNotEmpty ? group.members.first.id : null);
    });
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_selected.length < 2) {
      setState(() => _error = 'Select at least 2 members to split with');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<SplitRepository>().createExpense(
        groupId:       widget.groupId,
        description:   _desc.text.trim(),
        amount:        double.parse(_amount.text.trim()),
        paidById:      _paidById!,
        splitMemberIds: _selected.toList(),
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.receipt_outlined),
                ),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Enter a description' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Enter an amount';
                  if (double.tryParse(v!) == null || double.parse(v) <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text('Paid by', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _members.map((m) {
                  final selected = m.id == _paidById;
                  return ChoiceChip(
                    label:    Text(m.name.split(' ').first),
                    selected: selected,
                    onSelected: (_) => setState(() => _paidById = m.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Split with', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                'Select who shares this expense',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colours.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              ..._members.map((m) => CheckboxListTile(
                    title:   Text(m.name),
                    subtitle: Text('@${m.username}',
                        style: const TextStyle(fontSize: 11)),
                    value:   _selected.contains(m.id),
                    onChanged: (v) => setState(() {
                      if (v ?? false) {
                        _selected.add(m.id);
                      } else {
                        _selected.remove(m.id);
                      }
                    }),
                    dense:        true,
                    contentPadding: EdgeInsets.zero,
                  )),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: colours.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              AppButton.primary(
                label:   'Add Expense',
                loading: _loading,
                onTap:   _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
