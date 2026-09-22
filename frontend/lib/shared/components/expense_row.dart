// expense_row.dart — single expense in a group/activity list.
// Compact SplitWise-style layout, unified with BillListRow:
//   [ month ]   [ colored ]   Description              status label
//   [  day  ]   [  tile   ]   Paid by X · $amount           $share
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/accents.dart';
import '../../shared/models/expense.dart';
import 'category_icons.dart';

class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    super.key,
    required this.expense,
    required this.currentUserId,
    this.onDelete,
  });

  final Expense  expense;
  final String   currentUserId;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final text     = Theme.of(context).textTheme;
    final colours  = Theme.of(context).colorScheme;
    final share    = expense.sharePerPerson;
    final iPaid    = expense.paidBy.id == currentUserId;
    final iInSplit = expense.splitMembers.any((m) => m.id == currentUserId);

    // What does this expense mean to the current user?
    String? statusLabel;
    String? statusAmount;
    Color?  statusColor;
    if (iPaid && expense.splitMembers.length > 1) {
      final othersShare = expense.amount - share;
      statusLabel  = 'you get back';
      statusAmount = '${AppAccents.currencySymbol}${othersShare.toStringAsFixed(2)}';
      statusColor  = AppAccents.success;
    } else if (!iPaid && iInSplit) {
      statusLabel  = 'you owe';
      statusAmount = '${AppAccents.currencySymbol}${share.toStringAsFixed(2)}';
      statusColor  = AppAccents.danger;
    } else {
      statusLabel  = 'not involved';
      statusColor  = colours.onSurfaceVariant;
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onLongPress: onDelete != null ? () => _confirmDelete(context) : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Date (month over day) ────────────────────────────────
              SizedBox(
                width: 34,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMM').format(expense.createdAt),
                      style: text.bodySmall?.copyWith(
                        color: colours.onSurfaceVariant, fontSize: 12,
                      ),
                    ),
                    Text(
                      DateFormat('d').format(expense.createdAt),
                      style: text.titleMedium?.copyWith(
                        color: colours.onSurface,
                        fontWeight: FontWeight.w600, height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ── Colored category tile ────────────────────────────────
              CategoryTile(text: expense.description),
              const SizedBox(width: 14),

              // ── Description + subtitle ───────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expense.description,
                      style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Paid by ${expense.paidBy.name} · '
                      '${AppAccents.currencySymbol}${expense.amount.toStringAsFixed(2)}',
                      style: text.bodySmall?.copyWith(
                          color: colours.onSurfaceVariant),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Status label + share amount ──────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusLabel,
                    style: text.bodySmall?.copyWith(
                        color: statusColor, fontSize: 11),
                  ),
                  if (statusAmount != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      statusAmount,
                      style: text.titleMedium?.copyWith(
                          color: statusColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${expense.description}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); onDelete?.call(); },
            child: const Text('Delete', style: TextStyle(color: AppAccents.danger)),
          ),
        ],
      ),
    );
  }
}
