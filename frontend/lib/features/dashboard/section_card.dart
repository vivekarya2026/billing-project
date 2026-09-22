// lib/features/dashboard/section_card.dart
// -----------------------------------------
// daisyUI Card: base-200 fill, base-300 hairline border, radius-box corners.
// Leads with a heading, optional plain-language takeaway, then the visual.

import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.takeaway,
    required this.child,
    this.semanticSummary,
  });

  final String  title;
  final String? takeaway;
  final Widget  child;
  final String? semanticSummary;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final text    = Theme.of(context).textTheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: text.titleLarge?.copyWith(
              color: colours.onSurface,
              fontWeight: FontWeight.w600,
            )),
        if (takeaway != null) ...[
          const SizedBox(height: AppTokens.space1),
          Text(
            takeaway!,
            style: text.bodyMedium?.copyWith(color: colours.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppTokens.space5),
        child,
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppTokens.space5),
      decoration: BoxDecoration(
        color: colours.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusBox),
        border: Border.all(color: colours.outline, width: 1),
      ),
      child: semanticSummary != null
          ? Semantics(
              container: true,
              label: semanticSummary,
              child: ExcludeSemantics(child: content),
            )
          : content,
    );
  }
}
