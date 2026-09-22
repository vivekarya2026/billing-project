// primary_button.dart
// --------------------
// daisyUI button variants:
//   primary   — solid `btn-primary` fill, radius-field corners
//   secondary — `btn-outline` (surface fill + base-300 border)
//   plain     — `btn-ghost` (text only, primary label)
//
// D1: 60pt min-height always.
// D2: label is always words — never an icon alone.

import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

enum ButtonVariant { primary, secondary, plain }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant   = ButtonVariant.primary,
    this.loading   = false,
    this.fullWidth = true,
    this.icon,
  });

  final String        label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool          loading;
  final bool          fullWidth;
  final Widget?       icon;

  // ── Convenience factories ─────────────────────────────────────────────

  factory AppButton.primary({
    Key?            key,
    required String label,
    VoidCallback?   onTap,
    bool            loading   = false,
    bool            fullWidth = true,
    Widget?         icon,
  }) =>
      AppButton(
        key:       key,
        label:     label,
        onPressed: onTap,
        variant:   ButtonVariant.primary,
        loading:   loading,
        fullWidth: fullWidth,
        icon:      icon,
      );

  factory AppButton.secondary({
    Key?            key,
    required String label,
    VoidCallback?   onTap,
    bool            loading   = false,
    bool            fullWidth = true,
    Widget?         icon,
  }) =>
      AppButton(
        key:       key,
        label:     label,
        onPressed: onTap,
        variant:   ButtonVariant.secondary,
        loading:   loading,
        fullWidth: fullWidth,
        icon:      icon,
      );

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;

    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        Text(label),
      ],
    );

    final loadingWidget = SizedBox(
      width: 20, height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: variant == ButtonVariant.primary
            ? colours.onPrimary
            : colours.primary,
      ),
    );

    final content = loading ? loadingWidget : labelWidget;

    switch (variant) {
      // ── Primary: solid daisyUI btn-primary ──────────────────────────
      case ButtonVariant.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: AppTokens.targetMin,
          child: FilledButton(
            onPressed: loading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: colours.primary,
              foregroundColor: colours.onPrimary,
              disabledBackgroundColor: colours.onSurface.withValues(alpha: 0.12),
              disabledForegroundColor: colours.onSurfaceVariant,
              minimumSize:
                  Size(fullWidth ? double.infinity : 0, AppTokens.targetMin),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusField),
              ),
              textStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppTokens.textBody,
              ),
              elevation: 0,
            ),
            child: content,
          ),
        );

      // ── Secondary: btn-outline (surface + base-300 border) ──────────
      case ButtonVariant.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: AppTokens.targetMin,
          child: OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: colours.surfaceContainer,
              foregroundColor: colours.onSurface,
              minimumSize: Size(fullWidth ? double.infinity : 0, AppTokens.targetMin),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusField)),
              side: BorderSide(color: colours.outline),
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
            child: content,
          ),
        );

      // ── Plain: btn-ghost (text only) ─────────────────────────────────
      case ButtonVariant.plain:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          child: TextButton(
            onPressed: loading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: colours.primary,
              minimumSize: Size(fullWidth ? double.infinity : 0, AppTokens.targetMin),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusField)),
            ),
            child: content,
          ),
        );
    }
  }
}
