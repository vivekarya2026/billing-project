// group_card.dart — dark glassy card for a group in the grid
import 'package:flutter/material.dart';
import '../../theme/accents.dart';
import '../../shared/models/group.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  final Group group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final total   = group.totalExpenses;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:        colours.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: colours.outline),
          boxShadow:    const [AppAccents.glowCard],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient:     AppAccents.skyToIndigo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.group, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        AppAccents.skyTint10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${group.members.length} members',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colours.primary,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              group.groupName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color:      colours.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'by ${group.creator.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colours.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colours.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${AppAccents.currencySymbol}${total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color:      colours.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
