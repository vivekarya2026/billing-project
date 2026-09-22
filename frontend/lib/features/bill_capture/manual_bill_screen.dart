// manual_bill_screen.dart
// ------------------------
// Quick manual bill entry (Decision D3: "manual entry plus photo/PDF capture").
//
// The user types just what they know:
//   • Bill name / provider  (e.g. "Ohio Edison", "Netflix")
//   • Amount
//   • Due date (optional)
//
// The category icon updates LIVE as the name is typed (CategoryIcons), so the
// user never picks a category. On save the bill is written through the same
// BillRepository path as capture and the user lands on the answer screen.
//
// Also serves EDIT mode (M15): when constructed with a [billId], the form is
// prefilled from that bill and saving applies an in-place update instead of
// creating a new bill.
//
// Offline: bills are session-only (a subtle hint states this).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/components/category_icons.dart';
import '../../../shared/data/bill_repository.dart';
import '../../../shared/data/fake_bill_repository.dart';
import '../../../shared/services/supabase_client.dart';
import '../../../theme/tokens.dart';

class ManualBillScreen extends StatefulWidget {
  const ManualBillScreen({super.key, this.billId});

  /// When set, the screen edits an existing bill instead of creating one.
  final String? billId;

  @override
  State<ManualBillScreen> createState() => _ManualBillScreenState();
}

class _ManualBillScreenState extends State<ManualBillScreen> {
  final _form   = GlobalKey<FormState>();
  final _name   = TextEditingController();
  final _amount = TextEditingController();
  DateTime? _dueDate;
  bool _saving = false;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.billId != null;

  @override
  void initState() {
    super.initState();
    // Rebuild on name change so the live icon updates.
    _name.addListener(() => setState(() {}));
    if (_isEdit) _prefill();
  }

  Future<void> _prefill() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<BillRepository>();
      final bill = await repo.getBillById(widget.billId!);
      if (!mounted) return;
      setState(() {
        _name.text = bill.provider;
        if (bill.amountDue != null) {
          _amount.text = bill.amountDue!.toStringAsFixed(2);
        }
        _dueDate = bill.dueDate;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  bool get _isOffline => context.read<BillRepository>() is FakeBillRepository;

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() { _saving = true; _error = null; });

    try {
      final repo = context.read<BillRepository>();
      const uuid = Uuid();
      final billId = uuid.v4();

      String userId = '00000000-0000-0000-0000-000000000001';
      if (!_isOffline) {
        try {
          userId = SupabaseService.instance.currentUser?.id ?? userId;
        } catch (_) {}
      }

      final name   = _name.text.trim();
      final amount = double.parse(
          _amount.text.trim().replaceAll(RegExp(r'[^0-9.]'), ''));
      // Derive a service type from the auto-detected category keyword so the
      // bill card shows a matching icon later.
      final serviceType = _serviceTypeFor(name);

      String? dueIso;
      if (_dueDate != null) {
        dueIso = '${_dueDate!.year}-'
            '${_dueDate!.month.toString().padLeft(2, '0')}-'
            '${_dueDate!.day.toString().padLeft(2, '0')}';
      }

      if (_isEdit) {
        // ── Edit mode: apply an in-place update (M15) ──────────────────
        await repo.updateBill(widget.billId!, {
          'provider':     name,
          'service_type': serviceType,
          'amount_due':   amount,
          'due_date':     dueIso,
        });
        // Return to the Bills list (never a dead-end); offer a tap-through to
        // the updated detail.
        if (mounted) {
          context.go('/bills');
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              content: Text('Updated $name.'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () => context.push('/bill/${widget.billId}'),
              ),
            ),
          );
        }
        return;
      }

      await repo.createBill({
        'id':                billId,
        'user_id':           userId,
        'account_id':        'manual',
        'provider':          name,
        'name':              name,
        'service_type':      serviceType,
        'amount_due':        amount,
        'due_date':          dueIso,
        'bill_type':         'utility',
        'extraction_status': 'done',
      });

      final narration = _isOffline
          ? 'Added manually. Nothing to compare yet.'
          : 'Added manually.';
      await repo.updateBillNarration(billId, narration);

      // UX: creating a bill returns the user to the Bills list (home), where
      // the new row is now visible — not a dead-end detail screen. A brief
      // confirmation with a tap-through keeps the answer one tap away.
      if (mounted) {
        context.go('/bills');
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            content: Text('Added $name.'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => context.push('/bill/$billId'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Could not save. Please try again.';
      });
    }
  }

  /// Best-effort service type for the icon/data, mirroring CategoryIcons.
  String _serviceTypeFor(String name) {
    final l = name.toLowerCase();
    if (l.contains('electric') || l.contains('edison') || l.contains('power')) return 'electric';
    if (l.contains('gas') || l.contains('heating')) return 'gas';
    if (l.contains('water') || l.contains('sewer')) return 'water';
    if (l.contains('internet') || l.contains('wifi') || l.contains('broadband')) return 'internet';
    if (l.contains('trash') || l.contains('waste')) return 'trash';
    if (l.contains('phone') || l.contains('mobile')) return 'phone';
    if (l.contains('netflix') || l.contains('spotify') || l.contains('stream') ||
        l.contains('hulu') || l.contains('disney') || l.contains('subscription')) {
      return 'streaming';
    }
    if (l.contains('insurance')) return 'insurance';
    if (l.contains('rent') || l.contains('mortgage')) return 'rent';
    if (l.contains('cable') || l.contains('tv')) return 'cable';
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;
    final name    = _name.text.trim();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isEdit ? 'Edit bill' : 'Enter a bill'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: colours.primary))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.screenEdge),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Live category icon + name ─────────────────────────
                Row(
                  children: [
                    CategoryIconBadge(
                      text: name.isEmpty ? 'bill' : name,
                      size: 26,
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Bill name or provider',
                          hintText: 'e.g. Ohio Edison, Netflix, Water',
                        ),
                        style: text.bodyLarge,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a name' : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTokens.space5),

                // ── Amount (largest field) ────────────────────────────
                TextFormField(
                  controller: _amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: r'$ ',
                  ),
                  style: text.displayLarge?.copyWith(
                    fontSize: AppTokens.textAmount,
                    fontWeight: FontWeight.w700,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter an amount';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),

                const SizedBox(height: AppTokens.space5),

                // ── Due date (optional) ───────────────────────────────
                InkWell(
                  onTap: _pickDueDate,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  child: Container(
                    constraints:
                        const BoxConstraints(minHeight: AppTokens.targetMin),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space4,
                        vertical: AppTokens.space3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: colours.outline, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_outlined,
                            color: colours.onSurfaceVariant, size: 20),
                        const SizedBox(width: AppTokens.space3),
                        Expanded(
                          child: Text(
                            _dueDate == null
                                ? 'Add a due date (optional)'
                                : 'Due ${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}',
                            style: text.bodyLarge?.copyWith(
                              color: _dueDate == null
                                  ? colours.onSurfaceVariant
                                  : colours.onSurface,
                            ),
                          ),
                        ),
                        if (_dueDate != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _dueDate = null),
                          ),
                      ],
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: AppTokens.space4),
                  Text(_error!,
                      style: text.bodyMedium?.copyWith(color: colours.error)),
                ],

                const SizedBox(height: AppTokens.space8),

                AppButton(
                  label: _isEdit ? 'Save changes' : 'Save bill',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),

                const SizedBox(height: AppTokens.space4),

                if (_isOffline && !_isEdit)
                  Center(
                    child: Text(
                      'Demo mode: manually added bills reset when you reload.',
                      style: text.bodySmall
                          ?.copyWith(color: colours.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
