// bill_list_row.dart — compact SplitWise-style row for a bill.
// ------------------------------------------------------------
// Layout mirrors the reference activity list:
//   [ month ]   [ colored ]   Provider name            status label
//   [  day  ]   [  tile   ]   subtitle (narration)          $amount
//
// The colored category tile (CategoryTile) is shared with expense rows so
// bills and expenses read identically.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/accents.dart';
import '../../theme/tokens.dart';
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
  });

  final String provider;
  final double? amount;
  final DateTime? dueDate;
  final String interpretation;
  final VoidCallback onTap;
  final String? serviceType;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    // Right-hand status label mirrors the reference ("you borrowed" etc.).
    final statusLabel = _statusLabel();
    final statusColor = isOverdue ? AppAccents.danger : colours.onSurfaceVariant;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Date (month over day) ────────────────────────────────
              SizedBox(
                width: 30,
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
                      style: text.bodySmall?.copyWith(
                        color: colours.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      dueDate != null ? DateFormat('d').format(dueDate!) : '',
                      style: text.titleMedium?.copyWith(
                        color: colours.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Colored category tile ────────────────────────────────
              CategoryTile(text: provider, serviceType: serviceType),
              const SizedBox(width: 12),

              // ── Provider + subtitle ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider,
                      style: text.titleMedium?.copyWith(
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
              const SizedBox(width: 8),

              // ── Status label + amount ────────────────────────────────
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (statusLabel != null)
                      Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: text.bodySmall?.copyWith(
                          color: statusColor,
                          fontSize: 10.5,
                        ),
                      ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _fmtAmount(),
                        maxLines: 1,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: AppTokens.textTitle3,
                          color: isOverdue
                              ? AppAccents.danger
                              : colours.onSurface,
                        ),
                      ),
                    ),
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
    if (dueDate == null) return null;
    final now  = DateTime.now();
    final diff = dueDate!
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff < 0)  return 'overdue by ${-diff} day${-diff == 1 ? '' : 's'}';
    if (diff == 0) return 'due today';
    if (diff == 1) return 'due tomorrow';
    return 'due in $diff days';
  }
}
