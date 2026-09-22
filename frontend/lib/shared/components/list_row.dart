// list_row.dart
// --------------
// Reusable settings-list row — dark tokens applied.
// Background: surfaceContainer (#0c0c0e dark), white/10 divider, zinc-400 chevron.
// D1: 60pt min touch target.

import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leadingIcon,
    this.isNavigation = false,
    this.showSeparator = true,
    this.onTap,
  });

  final String  title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? leadingIcon;
  final bool    isNavigation;
  final bool    showSeparator;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          splashColor: colours.outline,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppTokens.targetMin),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.screenEdge,
              vertical: AppTokens.space3,
            ),
            child: Row(
              children: [
                // optional leading icon
                if (leadingIcon != null) ...[
                  Icon(leadingIcon,
                      color: colours.onSurfaceVariant, size: 20),
                  const SizedBox(width: AppTokens.space3),
                ],

                // title (+ optional subtitle)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: text.bodyLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: text.bodySmall?.copyWith(
                            color: colours.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (trailing != null) ...[
                  const SizedBox(width: AppTokens.space3),
                  trailing!,
                ],
                if (isNavigation) ...[
                  const SizedBox(width: AppTokens.space2),
                  Icon(
                    Icons.chevron_right,
                    color: colours.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showSeparator)
          Divider(
            color: colours.outline,
            thickness: 0.5,
            indent: AppTokens.screenEdge,
            endIndent: 0,
          ),
      ],
    );
  }
}
