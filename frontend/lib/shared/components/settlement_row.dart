// settlement_row.dart — a recorded settlement in history list
import 'package:flutter/material.dart';
import '../../theme/accents.dart';
import '../../shared/models/settlement.dart';
import 'date_display.dart';

class SettlementRow extends StatelessWidget {
  const SettlementRow({
    super.key,
    required this.settlement,
    required this.currentUserId,
  });

  final Settlement settlement;
  final String     currentUserId;

  @override
  Widget build(BuildContext context) {
    final colours  = Theme.of(context).colorScheme;
    final iPaid    = settlement.payer.id == currentUserId;
    final otherName = iPaid
        ? settlement.receiver.name
        : settlement.payer.name;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color:        colours.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: colours.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:        iPaid ? AppAccents.dangerTint : AppAccents.successTint,
            shape: BoxShape.circle,
          ),
          child: Icon(
            iPaid ? Icons.arrow_upward : Icons.arrow_downward,
            size:  16,
            color: iPaid ? AppAccents.danger : AppAccents.success,
          ),
        ),
        title: Text(
          iPaid ? 'You paid $otherName' : '$otherName paid you',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: DateDisplay(date: settlement.createdAt,
            style: TextStyle(fontSize: 10, color: colours.onSurfaceVariant)),
        trailing: Text(
          '${AppAccents.currencySymbol}${settlement.amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: iPaid ? AppAccents.danger : AppAccents.success,
          ),
        ),
        ),
      ),
    );
  }
}
