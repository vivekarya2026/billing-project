// bill_card.dart
// --------------
// Home screen card for a single bill.
// Dark aesthetic: glassy #0c0c0e surface, white/10 hairline border,
// faint sky glow on hover/press.
//
// Design rules:
//   D1: 60pt min touch target
//   D2: no colour-only status — all status expressed in words
//   Amount is always the largest element

import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../theme/accents.dart';
import 'category_icons.dart';

class BillCard extends StatefulWidget {
  const BillCard({
    super.key,
    required this.provider,
    required this.amount,
    required this.dueDate,
    required this.interpretation,
    required this.onTap,
    this.serviceType,
  });

  final String provider;
  final String amount;
  final String dueDate;
  final String interpretation;
  final VoidCallback onTap;
  final String? serviceType;

  @override
  State<BillCard> createState() => _BillCardState();
}

class _BillCardState extends State<BillCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;
    final isDark  = colours.brightness == Brightness.dark;

    final cardBg    = isDark ? const Color(0xFF0C0C0E) : colours.surfaceContainer;
    final glowColor = (_hovered || _pressed) && isDark
        ? [AppAccents.glowCard]
        : <BoxShadow>[];

    return Semantics(
      label: '${widget.provider}, ${widget.amount}, ${widget.dueDate}',
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown:   (_) => setState(() => _pressed = true),
          onTapUp:     (_) => setState(() => _pressed = false),
          onTapCancel: ()  => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: AppTokens.targetMin),
            margin: const EdgeInsets.only(bottom: AppTokens.space3),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: colours.outline, width: 0.5),
              boxShadow: glowColor,
            ),
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Provider name with category icon ─────────────────────
                Row(
                  children: [
                    CategoryIconBadge(
                      text: widget.provider,
                      serviceType: widget.serviceType,
                      size: 18,
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Text(
                        widget.provider,
                        style: text.headlineMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTokens.space2),

                // ── Amount — always the largest element ──────────────────
                Text(
                  widget.amount,
                  style: (text.displayLarge ?? text.headlineLarge)?.copyWith(
                    color: colours.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),

                const SizedBox(height: AppTokens.space1),

                // ── Due date ─────────────────────────────────────────────
                Text(widget.dueDate, style: text.bodySmall),

                const SizedBox(height: AppTokens.space3),

                // ── One-sentence interpretation ──────────────────────────
                Text(
                  widget.interpretation,
                  style: text.bodyMedium?.copyWith(
                    color: colours.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
