// simplify_sheet.dart — bottom sheet showing simplified debt edges
import 'package:flutter/material.dart';
import '../../theme/accents.dart';
import '../../shared/models/balance.dart';

class SimplifySheet extends StatelessWidget {
  const SimplifySheet({super.key, required this.edges});
  final List<DebtEdge> edges;

  static Future<void> show(BuildContext context, List<DebtEdge> edges) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SimplifySheet(edges: edges),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: colours.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Simplified Debts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Minimum transfers to settle all balances',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colours.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          if (edges.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.check_circle_outline,
                      size: 48, color: AppAccents.success),
                  SizedBox(height: 8),
                  Text('All settled up!',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            )
          else
            ...edges.map((e) => _DebtEdgeTile(edge: e)),
        ],
      ),
    );
  }
}

class _DebtEdgeTile extends StatelessWidget {
  const _DebtEdgeTile({required this.edge});
  final DebtEdge edge;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Container(
      margin:   const EdgeInsets.symmetric(vertical: 4),
      padding:  const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        colours.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: colours.outline),
      ),
      child: Row(children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text:  edge.fromName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' owes '),
                TextSpan(
                  text:  edge.toName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${AppAccents.currencySymbol}${edge.amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color:      AppAccents.danger,
            fontSize:   16,
          ),
        ),
      ]),
    );
  }
}
