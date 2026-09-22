// settlement_screen.dart — record a cash payment between two users
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/data/split_repository.dart';
import '../../state/current_user_state.dart';
import '../../shared/models/settlement.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/components/settlement_row.dart';
import '../../theme/accents.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.suggestedAmount,
  });
  final String  receiverId;
  final String  receiverName;
  final double? suggestedAmount;
  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final _ctrl    = TextEditingController();
  bool  _loading = false;
  String? _error;
  List<Settlement> _history = [];

  @override
  void initState() {
    super.initState();
    if (widget.suggestedAmount != null) {
      _ctrl.text = widget.suggestedAmount!.toStringAsFixed(0);
    }
    _loadHistory();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadHistory() async {
    final uid  = context.read<CurrentUserState>().profile?.id ?? '';
    final repo = context.read<SplitRepository>();
    final h    = await repo.getSettlementsForPair(uid, widget.receiverId);
    if (mounted) setState(() => _history = h);
  }

  Future<void> _settle() async {
    final amount = double.tryParse(_ctrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    final uid = context.read<CurrentUserState>().profile?.id ?? '';
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<SplitRepository>().makeSettlement(
        payerId:    uid,
        receiverId: widget.receiverId,
        amount:     amount,
      );
      if (mounted) {
        await _loadHistory();
        _ctrl.clear();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final uid = context.watch<CurrentUserState>().profile?.id ?? '';
    return Scaffold(
      appBar: AppBar(title: Text('Settle with ${widget.receiverName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Amount input ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:        colours.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(color: colours.outline),
                boxShadow:    const [AppAccents.glowCard],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount to settle',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller:  _ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus:    true,
                    decoration: InputDecoration(
                      prefixText: '${AppAccents.currencySymbol} ',
                      hintText:   '0',
                      errorText:  _error,
                    ),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  AppButton.primary(
                    label:   'Record Payment',
                    loading: _loading,
                    onTap:   _loading ? null : _settle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Settlement history ──────────────────────────────────────
            Text('Settlement History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              Text('No settlements yet',
                  style: TextStyle(color: colours.onSurfaceVariant))
            else
              ..._history.map((s) => SettlementRow(
                    settlement: s,
                    currentUserId: uid,
                  )),
          ],
        ),
      ),
    );
  }
}
