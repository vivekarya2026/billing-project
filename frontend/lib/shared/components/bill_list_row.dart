// bill_list_row.dart — compact bill row (daisyUI list-row).
// ------------------------------------------------------------
// Layout:
//   [ month ]   [ colored ]   Provider name              $amount
//   [  day  ]   [  tile   ]   subtitle (narration)      status label
//
// The colored category tile (CategoryTile) is shared with expense rows so
// bills and expenses read identically.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/accents.dart';
import '../../theme/tokens.dart';
import '../layout/responsive.dart';
import 'category_icons.dart';

class BillListRow extends StatelessWidget {
  const BillListRow({
    super.key,
    required this.provider,
    required this.amount,
    required this.dueDate,
    required this.interpretation,
    required this.onTap,
    this.serviceType,
    this.isOverdue = false,
    this.isPaid = false,
  });

  final String provider;
  final double? amount;
  final DateTime? dueDate;
  final String interpretation;
  final VoidCallback onTap;
  final String? serviceType;
  final bool isOverdue;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;
    final compact = Breakpoints.isCompact(context);

    // Mobile-tuned layout metrics (type sizes come from the responsive theme).
    final tileSize     = compact ? 40.0 : 46.0;
    final dateColWidth = compact ? 32.0 : 36.0;
    final gap          = compact ? AppTokens.space2 : AppTokens.space3;
    final vPad         = compact ? AppTokens.space3 : AppTokens.space4;
    final statusMax    = compact ? 96.0 : 132.0;

    final statusLabel = _statusLabel();
    final statusColor = isOverdue
        ? AppAccents.danger
        : (isPaid ? AppAccents.success : colours.onSurfaceVariant);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusBox),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTokens.space2,
            vertical: vPad,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Date (month over day) ────────────────────────────────
              SizedBox(
                width: dateColWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dueDate != null
                          ? DateFormat('MMM').format(dueDate!)
                          : '—',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: text.labelSmall?.copyWith(
                        color: colours.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      dueDate != null ? DateFormat('d').format(dueDate!) : '',
                      style: text.titleLarge?.copyWith(
                        color: colours.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: gap),

              // ── Colored category tile ────────────────────────────────
              CategoryTile(
                text: provider,
                serviceType: serviceType,
                dimension: tileSize,
              ),
              SizedBox(width: gap),

              // ── Provider + subtitle ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider,
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      interpretation,
                      style: text.bodySmall?.copyWith(
                        color: colours.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: gap),

              // ── Amount + status label (amount leads) ─────────────────
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: statusMax),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _fmtAmount(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isOverdue
                            ? AppAccents.danger
                            : colours.onSurface,
                      ),
                    ),
                    if (statusLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: text.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight:
                              isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtAmount() {
    if (amount == null) return '—';
    return NumberFormat.currency(symbol: r'$', decimalDigits: 2).format(amount);
  }

  String? _statusLabel() {
    if (isPaid) return 'Paid';
    if (dueDate == null) return null;
    final now  = DateTime.now();
    final diff = dueDate!
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff < 0)  return '${-diff}d overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }
}
