// confirmation_screen.dart
// -------------------------
// Targeted confirmation (US-006, M6).
// Shows ONLY the fields that failed validation (Hick's Law — fewer choices).
// If validation passed (always true in offline demo), skips straight to
// writing data and navigating away.
//
// Design rules:
//   D2: failures described in words only, no red labels on fields
//   D1: 60px min touch targets
//   Each failing field shows: label, what was extracted, an editable correction

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/data/bill_repository.dart';
import '../../../shared/services/ai_service_client.dart';
import '../../../shared/services/supabase_client.dart';
import '../../../theme/tokens.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({
    super.key,
    required this.billId,
    required this.storagePath,
    required this.extracted,
    required this.validation,
    required this.register,
    this.isOffline = false,
  });

  final String billId;
  final String storagePath;
  final ExtractedBill extracted;
  final ValidationResult validation;
  final String register;
  /// When true, skip all Supabase / AI service calls.
  final bool isOffline;

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _saving = false;
  // Corrections: checkName → corrected text
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final failure in widget.validation.failures) {
      final key = failure['check_name'] as String? ?? '';
      _controllers[key] = TextEditingController(
        text: failure['actual']?.toString() ?? '',
      );
    }
    // If validation passed, auto-save immediately
    if (widget.validation.passed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _save());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final repo = context.read<BillRepository>();
      final ext  = widget.extracted;
      const uuid = Uuid();

      String userId = '00000000-0000-0000-0000-000000000001';
      if (!widget.isOffline) {
        try {
          userId = SupabaseService.instance.currentUser?.id ?? userId;
        } catch (_) {}
      }

      // 1. Write bill row (FakeBillRepository.createBill is a no-op insert)
      const accountId = '20000000-0000-0000-0000-000000000001';
      await repo.createBill({
        'id':                widget.billId,
        'user_id':           userId,
        'account_id':        accountId,
        'period_start':      ext.periodStart,
        'period_end':        ext.periodEnd,
        'amount_due':        ext.amountDue,
        'due_date':          ext.dueDate,
        'bill_type':         'utility',
        'extraction_status': 'done',
        'raw_image_path':    widget.storagePath,
      });

      // 2. Write extraction_fields (no-op in offline mode)
      final fields = ext.fields.map((f) => {
        'id':           uuid.v4(),
        'bill_id':      widget.billId,
        'user_id':      userId,
        'field_name':   f.fieldName,
        'raw_value':    f.rawValue,
        'parsed_value': f.parsedValue,
        'confidence':   f.confidence,
        'bounding_box': f.boundingBox != null ? {
          'x': f.boundingBox!['x'], 'y': f.boundingBox!['y'],
          'w': f.boundingBox!['w'], 'h': f.boundingBox!['h'],
          'page': 0,
        } : null,
      }).toList();
      await repo.upsertExtractionFields(fields);

      // 3. Get narration sentence — offline: use a canned sentence
      String narration = 'Normal for this time of year. Nothing looks unusual.';
      if (!widget.isOffline) {
        try {
          final analysisResult = <String, dynamic>{
            'bill_id': widget.billId, 'prior_bill_id': null,
            'total_delta': null, 'total_delta_pct': null,
            'drivers': <dynamic>[], 'anomalies': <dynamic>[],
          };
          final result = await AiServiceClient.instance.narrate(
            analysis: analysisResult,
            register: widget.register,
          );
          narration = result.sentence;
        } catch (_) {
          // Narration failure is non-fatal
        }
      }
      await repo.updateBillNarration(widget.billId, narration);

      // 4. Return to the Bills list (Peak-End on the list where the new bill
      //    is visible; never a dead-end detail screen). Offer a tap-through.
      if (mounted) {
        Navigator.of(context).pop(); // close the confirmation route
        context.go('/bills');
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            content: const Text('Bill added.'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => context.push('/bill/${widget.billId}'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save bill. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (widget.validation.passed) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppTokens.space4),
              Text('Saving…', style: text.bodyLarge),
            ],
          ),
        ),
      );
    }

    final failures = widget.validation.failures;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check these numbers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.screenEdge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We found ${failures.length} '
                '${failures.length == 1 ? 'thing' : 'things'} to check.',
                style: text.titleLarge,
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                'These numbers did not add up. '
                'Correct them below or accept what we found.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: AppTokens.space6),

              // ── Only failing fields (Hick: show nothing extra) ────────
              ...failures.map((failure) {
                final key = failure['check_name'] as String? ?? '';
                return _FailingFieldRow(
                  checkName: key,
                  message:   failure['message'] as String? ?? '',
                  actual:    failure['actual']?.toString() ?? '',
                  controller: _controllers[key] ?? TextEditingController(),
                );
              }),

              const SizedBox(height: AppTokens.space8),

              AppButton(
                label: 'This looks right',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(height: AppTokens.space3),
              AppButton(
                label: 'Cancel',
                variant: ButtonVariant.plain,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailingFieldRow extends StatelessWidget {
  const _FailingFieldRow({
    required this.checkName,
    required this.message,
    required this.actual,
    required this.controller,
  });

  final String checkName;
  final String message;
  final String actual;
  final TextEditingController controller;

  String get _label {
    switch (checkName) {
      case 'line_items_sum_matches_amount_due': return 'Total amount';
      case 'amount_due_positive':               return 'Amount due';
      case 'date_range_valid':                  return 'Billing period';
      case 'no_negative_usage':                 return 'Usage';
      default: return checkName.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_label, style: text.headlineMedium),
          const SizedBox(height: AppTokens.space2),
          Text(
            message.isNotEmpty ? message : 'The numbers do not match.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: AppTokens.space3),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            decoration: InputDecoration(
              labelText: 'Correct value',
              hintText: actual,
            ),
            style: text.bodyLarge,
          ),
          Divider(color: colours.outline, thickness: 0.5),
        ],
      ),
    );
  }
}
