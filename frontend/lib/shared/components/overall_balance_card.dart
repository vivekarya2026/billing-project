// overall_balance_card.dart — summary card for activity screen
import 'package:flutter/material.dart';
import '../../theme/accents.dart';
import '../../shared/models/balance.dart';

class OverallBalanceCard extends StatelessWidget {
  const OverallBalanceCard({super.key, required this.balance});
  final OverallBalance balance;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final net     = balance.net;
    final isPositive = net >= 0;

    return Container(
      decoration: BoxDecoration(
        color:        colours.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: colours.outline),
        boxShadow:    const [AppAccents.glowCard],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overall Balance',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colours.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(
            children: [
              ShaderMask(
                shaderCallback: (r) =>
                    (isPositive ? AppAccents.skyToBlue : const LinearGradient(
                      colors: [AppAccents.danger, Color(0xFFFF8A65)],
                    )).createShader(r),
                blendMode: BlendMode.srcIn,
                child: Text(
                  '${isPositive ? '+' : ''}${AppAccents.currencySymbol}'
                  '${net.abs().toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            _BalancePill(
              label: 'You get back',
              amount: balance.totalOwed,
              color:  AppAccents.success,
              bg:     AppAccents.successTint,
            ),
            const SizedBox(width: 10),
            _BalancePill(
              label: 'You owe',
              amount: balance.totalOwing,
              color:  AppAccents.danger,
              bg:     AppAccents.dangerTint,
            ),
          ]),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({
    required this.label,
    required this.amount,
    required this.color,
    required this.bg,
  });
  final String label;
  final double amount;
  final Color  color;
  final Color  bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: color)),
          const SizedBox(height: 2),
          Text(
            '${AppAccents.currencySymbol}${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize:   16,
              color:      color,
            ),
          ),
        ]),
      ),
    );
  }
}
