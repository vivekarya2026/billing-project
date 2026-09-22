// add_bill_screen.dart
// ---------------------
// The Add Bill entry point. Hick's Law: exactly two choices.
//   • Scan or upload  → BillCaptureScreen (photo / PDF, existing flow)
//   • Enter manually   → ManualBillScreen (quick amount entry)
//
// Both honour Decision D3: "manual entry plus photo/PDF capture".

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/tokens.dart';

class AddBillScreen extends StatelessWidget {
  const AddBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Add a bill'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.screenEdge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTokens.space4),
              Text(
                'How would you like\nto add it?',
                style: text.headlineLarge,
              ),
              const SizedBox(height: AppTokens.space3),
              Text(
                'Snap a photo and we read it, or just type the amount.',
                style: text.bodyLarge
                    ?.copyWith(color: colours.onSurfaceVariant),
              ),
              const SizedBox(height: AppTokens.space7),

              _ChoiceCard(
                icon: Icons.add_a_photo_outlined,
                title: 'Scan or upload',
                subtitle: 'Take a photo or pick a file. We read the numbers.',
                onTap: () => context.push('/capture?mode=files'),
              ),
              const SizedBox(height: AppTokens.space4),
              _ChoiceCard(
                icon: Icons.edit_outlined,
                title: 'Enter manually',
                subtitle: 'Just have the amount? Type it in a few seconds.',
                onTap: () => context.push('/manual-bill'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusBox),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppTokens.targetMin),
            padding: const EdgeInsets.all(AppTokens.space5),
            decoration: BoxDecoration(
              color: colours.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTokens.radiusBox),
              border: Border.all(color: colours.outline, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colours.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSelector),
                  ),
                  child: Icon(icon, color: colours.primary),
                ),
                const SizedBox(width: AppTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleLarge),
                      const SizedBox(height: AppTokens.space1),
                      Text(
                        subtitle,
                        style: text.bodyMedium
                            ?.copyWith(color: colours.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colours.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
