// bill_detail_screen.dart
// -----------------------
// The answer screen (US-004, US-009, M4, M9).
//
// Three registers read from SettingsState:
//   brief    → amount + one sentence only (Marguerite, Dana)
//   explained → sentence + spend-driver list from /analyse
//   full     → line-items table + per-number tap-to-source provenance (Wes)
//
// Design rules:
//   - Amount is ALWAYS the largest text element (Deference pillar)
//   - D2: Words carry status, never colour
//   - Provenance: every number is tappable → source-region overlay
//   - 60px touch targets (D1)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/components/primary_button.dart';
import '../../../shared/data/bill_repository.dart';
import '../../../shared/data/fake_bill_repository.dart';
import '../../../shared/models/bill.dart';
import '../../../shared/models/extraction_field.dart';
import '../../../shared/models/line_item.dart';
import '../../../shared/services/ai_service_client.dart';
import '../../../state/settings_state.dart';
import '../../../theme/tokens.dart';

class BillDetailScreen extends StatefulWidget {
  const BillDetailScreen({super.key, required this.billId});
  final String billId;

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  late Future<_DetailData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<BillRepository>();
    _dataFuture = _fetchAll(repo);
  }

  Future<_DetailData> _fetchAll(BillRepository repo) async {
    final bill = await repo.getBillById(widget.billId);
    return _DetailData(bill: bill, drivers: []);
  }

  // Fetch /analyse drivers lazily when register is explained or full
  Future<List<SpendDriver>> _fetchDrivers(BillDetail bill) async {
    if (bill.amountDue == null) return [];
    // Offline/demo mode has no AI service — never hit the network (it would
    // block on a long timeout trying to reach localhost:8000). Return empty.
    final repo = context.read<BillRepository>();
    if (repo is FakeBillRepository) return [];
    try {
      final currentMap = _billToMap(bill);
      final result = await AiServiceClient.instance.analyse(
        bill: currentMap,
        priorBill: null,
      );
      return (result['drivers'] as List? ?? [])
          .map((d) => SpendDriver.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _billToMap(BillDetail bill) => {
    'bill_id':      bill.id,
    'amount_due':   bill.amountDue,
    'period_start': bill.periodStart?.toIso8601String().split('T').first,
    'period_end':   bill.periodEnd?.toIso8601String().split('T').first,
    'line_items': bill.lineItems.map((li) => {
      'description': li.description,
      'amount':      li.amount.toString(),
      'item_type':   li.itemType,
    }).toList(),
    'fields': bill.extractionFields.map((f) => {
      'field_name':   f.fieldName,
      'raw_value':    f.rawValue,
      'parsed_value': f.parsedValue,
      'confidence':   f.confidence,
    }).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Scaffold(
      body: FutureBuilder<_DetailData>(
        future: _dataFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ));
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Could not load bill.',
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppTokens.space4),
                TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Try again')),
              ]),
            );
          }
          final bill = snap.data!.bill;
          return _BillDetailBody(
            bill:       bill,
            register:   settings.detailLevel,
            fetchDrivers: _fetchDrivers,
            onEdit:     () => context.push('/manual-bill?id=${widget.billId}'),
            onDelete:   () => _confirmAndDelete(bill),
          );
        },
      ),
    );
  }

  // ── Delete with confirmation + Undo (M15) ───────────────────────────────
  Future<void> _confirmAndDelete(BillDetail bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final text = Theme.of(ctx).textTheme;
        return AlertDialog(
          title: const Text('Delete this bill?'),
          content: Text(
            'Remove ${bill.provider}'
            '${bill.amountDue != null ? ' (${NumberFormat.currency(symbol: r'$').format(bill.amountDue)})' : ''}? '
            'You can undo right after.',
            style: text.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF5A5A),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final repo = context.read<BillRepository>();
    await repo.deleteBill(bill.id);
    if (!mounted) return;

    // Leave the detail screen, then offer Undo on the list.
    context.pop();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Text('Deleted ${bill.provider}.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (repo is FakeBillRepository) {
              FakeBillRepository.restoreBill(bill.id);
            }
          },
        ),
      ),
    );
  }
}

// ── Detail body — stateless once data is loaded ───────────────────────────

class _BillDetailBody extends StatelessWidget {
  const _BillDetailBody({
    required this.bill,
    required this.register,
    required this.fetchDrivers,
    required this.onEdit,
    required this.onDelete,
  });

  final BillDetail bill;
  final DetailLevel register;
  final Future<List<SpendDriver>> Function(BillDetail) fetchDrivers;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _fmt(double? v) => v == null
      ? '—'
      : NumberFormat.currency(symbol: r'$').format(v);

  String _fmtDate(DateTime? d) =>
      d == null ? '' : DateFormat('MMMM d, y').format(d);

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppTokens.contentMaxWidth),
        child: CustomScrollView(
          slivers: [
        // ── App bar ────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
          title: Text(bill.provider),
          actions: [
            // Edit + Delete (Jakob: actions top-right) via an overflow menu.
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Bill actions',
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline,
                        color: Color(0xFFFF5A5A)),
                    title: Text('Delete',
                        style: TextStyle(color: Color(0xFFFF5A5A))),
                  ),
                ),
              ],
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AppTokens.screenEdge),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // ── Amount — always the largest element ──────────────────
              Semantics(
                label: 'Amount due ${_fmt(bill.amountDue)}',
                child: _TappableNumber(
                  label: _fmt(bill.amountDue),
                  style: text.displayLarge!,
                  field: bill.extractionFields
                      .where((f) => f.fieldName == 'amount_due')
                      .firstOrNull,
                  bill: bill,
                ),
              ),
              Text(_fmtDate(bill.dueDate).isNotEmpty
                  ? 'Due ${_fmtDate(bill.dueDate)}' : '',
                  style: text.bodySmall),

              const SizedBox(height: AppTokens.space4),
              Divider(color: colours.outline, thickness: 0.5),
              const SizedBox(height: AppTokens.space4),

              // ── The one sentence (brief / explained / full all show it)
              Text(
                bill.narrationSentence ??
                    'Tap any number to see where it came from.',
                style: text.titleLarge, // 19pt semibold
              ),

              // ── Explained: spend drivers ──────────────────────────────
              if (register == DetailLevel.explained ||
                  register == DetailLevel.full) ...[
                const SizedBox(height: AppTokens.space6),
                _DriversSection(bill: bill, fetchDrivers: fetchDrivers),
              ],

              // ── Full: line-items table with tap-to-source ─────────────
              if (register == DetailLevel.full) ...[
                const SizedBox(height: AppTokens.space6),
                _LineItemsSection(bill: bill),
              ],

              const SizedBox(height: AppTokens.space8),

              // ── Source region prompt ──────────────────────────────────
              if (bill.rawImagePath != null) ...[
                Text(
                  'Tap any number to see where on the bill it came from.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppTokens.space8),
              ],
            ]),
          ),
        ),
          ],
          ),
        ),
    );
  }
}

// ── Spend drivers (explained + full registers) ────────────────────────────

class _DriversSection extends StatefulWidget {
  const _DriversSection({required this.bill, required this.fetchDrivers});
  final BillDetail bill;
  final Future<List<SpendDriver>> Function(BillDetail) fetchDrivers;

  @override
  State<_DriversSection> createState() => _DriversSectionState();
}

class _DriversSectionState extends State<_DriversSection> {
  late Future<List<SpendDriver>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _driversFuture = widget.fetchDrivers(widget.bill);
  }

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    return FutureBuilder<List<SpendDriver>>(
      future: _driversFuture,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        final drivers = snap.data ?? [];
        if (drivers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What changed', style: text.headlineMedium),
            const SizedBox(height: AppTokens.space3),
            ...drivers.map((d) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
              child: Row(
                children: [
                  Expanded(child: Text(d.label, style: text.bodyLarge)),
                  Text(
                    '${d.amountDelta >= 0 ? '+' : ''}'
                    '\$${d.amountDelta.abs().toStringAsFixed(2)}',
                    style: text.bodyLarge,
                  ),
                ],
              ),
            )),
            Divider(color: colours.outline, thickness: 0.5),
          ],
        );
      },
    );
  }
}

// ── Line items (full register) ────────────────────────────────────────────

class _LineItemsSection extends StatelessWidget {
  const _LineItemsSection({required this.bill});
  final BillDetail bill;

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    if (bill.lineItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Every charge', style: text.headlineMedium),
        const SizedBox(height: AppTokens.space3),
        ...bill.lineItems.map((li) => _LineItemRow(
          item: bill.lineItems.indexOf(li) < bill.extractionFields.length
              ? li : li,
          extractionField: bill.extractionFields
              .where((f) => f.fieldName.contains(li.description.toLowerCase().replaceAll(' ', '_')))
              .firstOrNull,
          bill: bill,
        )),
        Divider(color: colours.outline, thickness: 0.5),
        const SizedBox(height: AppTokens.space3),
        Row(
          children: [
            Expanded(
                child: Text('Total',
                    style: text.titleLarge)),
            Text(
              '\$${bill.lineItems.fold(0.0, (s, li) => s + li.amount).toStringAsFixed(2)}',
              style: text.titleLarge,
            ),
          ],
        ),
      ],
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.item, this.extractionField, required this.bill});
  final LineItemModel item;
  final ExtractionFieldModel? extractionField;
  final BillDetail bill;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        children: [
          Expanded(child: Text(item.description, style: text.bodyLarge)),
          _TappableNumber(
            label: '\$${item.amount.toStringAsFixed(2)}',
            style: text.bodyLarge!,
            field: extractionField,
            bill: bill,
          ),
        ],
      ),
    );
  }
}

// ── Tappable number → source-region overlay ───────────────────────────────

class _TappableNumber extends StatelessWidget {
  const _TappableNumber({
    required this.label,
    required this.style,
    this.field,
    required this.bill,
  });

  final String label;
  final TextStyle style;
  final ExtractionFieldModel? field;
  final BillDetail bill;

  @override
  Widget build(BuildContext context) {
    if (field == null || field!.boundingBox == null) {
      return Text(label, style: style);
    }
    return GestureDetector(
      onTap: () => _showSourceOverlay(context),
      child: Semantics(
        label: '$label — tap to see source',
        button: true,
        child: Text(
          label,
          style: style.copyWith(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
          ),
        ),
      ),
    );
  }

  void _showSourceOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SourceRegionSheet(
        bill:  bill,
        field: field!,
        label: label,
      ),
    );
  }
}

// ── Source-region sheet (provenance, M9) ──────────────────────────────────

class _SourceRegionSheet extends StatefulWidget {
  const _SourceRegionSheet({
    required this.bill,
    required this.field,
    required this.label,
  });
  final BillDetail bill;
  final ExtractionFieldModel field;
  final String label;

  @override
  State<_SourceRegionSheet> createState() => _SourceRegionSheetState();
}

class _SourceRegionSheetState extends State<_SourceRegionSheet> {
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadImageUrl();
  }

  Future<void> _loadImageUrl() async {
    if (widget.bill.rawImagePath == null) return;
    try {
      final repo = context.read<BillRepository>();
      final url  = await repo.getSignedImageUrl(widget.bill.rawImagePath!);
      if (mounted) setState(() => _imageUrl = url);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;
    final bb      = widget.field.boundingBox!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colours.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusXl)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppTokens.space3),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colours.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.screenEdge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Source on the bill', style: text.headlineMedium),
                const SizedBox(height: AppTokens.space2),
                Row(children: [
                  Text('Field: ', style: text.bodyMedium),
                  Text(widget.field.fieldName.replaceAll('_', ' '),
                      style: text.bodyLarge),
                ]),
                Row(children: [
                  Text('Extracted: ', style: text.bodyMedium),
                  Text(widget.field.rawValue, style: text.bodyLarge),
                ]),
                Row(children: [
                  Text('Confidence: ', style: text.bodyMedium),
                  Text('${(widget.field.confidence * 100).toStringAsFixed(0)}%',
                      style: text.bodyLarge),
                ]),
              ],
            ),
          ),
          // Image with bounding box highlight
          Expanded(
            child: _imageUrl == null
                ? Center(child: Text('Loading image…', style: text.bodyMedium))
                : _BillImageWithHighlight(
                    imageUrl: _imageUrl!,
                    boundingBox: bb,
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.screenEdge),
              child: AppButton(
                label: 'Close',
                variant: ButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillImageWithHighlight extends StatelessWidget {
  const _BillImageWithHighlight({
    required this.imageUrl,
    required this.boundingBox,
  });
  final String imageUrl;
  final BoundingBox boundingBox;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __, ___) => Center(
        child: Text('Image not available',
            style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

// ── Data classes ─────────────────────────────────────────────────────────

class _DetailData {
  const _DetailData({required this.bill, required this.drivers});
  final BillDetail bill;
  final List<SpendDriver> drivers;
}

class SpendDriver {
  const SpendDriver({
    required this.label,
    required this.amountDelta,
    required this.pctOfDelta,
    required this.source,
  });
  final String label;
  final double amountDelta;
  final double pctOfDelta;
  final String source;

  factory SpendDriver.fromJson(Map<String, dynamic> j) => SpendDriver(
    label:       j['label'] as String,
    amountDelta: (j['amount_delta'] as num).toDouble(),
    pctOfDelta:  (j['pct_of_delta'] as num).toDouble(),
    source:      j['source'] as String,
  );
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iter = iterator;
    return iter.moveNext() ? iter.current : null;
  }
}
