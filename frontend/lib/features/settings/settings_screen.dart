// settings_screen.dart
// ---------------------
// Exactly 4 items — no more (Miller's Law).
// Detail level change takes effect immediately across the app via SettingsState.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/components/list_row.dart';
import '../../../shared/layout/responsive.dart';
import '../../../state/settings_state.dart';
import '../../../theme/tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colours  = Theme.of(context).colorScheme;
    final text     = Theme.of(context).textTheme;
    final settings = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      backgroundColor: colours.surface,
      body: SafeArea(
        child: CenteredContent(
          maxWidth: 560,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.screenEdge),
            child: Column(
            children: [
              const SizedBox(height: AppTokens.space4),
              Container(
                decoration: BoxDecoration(
                  color: colours.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTokens.radiusBox),
                  border: Border.all(color: colours.outline, width: 1),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(children: [
                  // 1. Backup & restore (deferred SEC-PM-006/007)
                  ListRow(
                    title: 'Backup & restore',
                    isNavigation: true,
                    onTap: () => _showComingSoon(context, 'Backup & restore'),
                  ),

                  // 2. Language
                  ListRow(
                    title: 'Language',
                    trailing: Text(
                      _languageLabel(settings.language),
                      style: text.bodyMedium,
                    ),
                    isNavigation: true,
                    onTap: () => _showLanguagePicker(context, settings),
                  ),

                  // 3. Reminders
                  ListRow(
                    title: 'Reminders',
                    trailing: Text(
                      _remindersLabel(settings.reminders),
                      style: text.bodyMedium,
                    ),
                    isNavigation: true,
                    onTap: () => _showRemindersPicker(context, settings),
                  ),

                  // 4. Detail level — the register setting (brief/explained/full)
                  ListRow(
                    title: 'Detail level',
                    trailing: Text(
                      settings.detailLevel.label,
                      style: text.bodyMedium,
                    ),
                    isNavigation: true,
                    showSeparator: false,
                    onTap: () => _showDetailLevelPicker(context, settings),
                  ),
                ]),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  void _showDetailLevelPicker(BuildContext context, SettingsState settings) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _PickerSheet(
        title: 'Detail level',
        subtitle: 'How much detail do you want on bill screens?',
        options: const [
          _Option('brief',     'Brief',     'Amount and one sentence.'),
          _Option('explained', 'Explained', 'Sentence plus what changed.'),
          _Option('full',      'Full',      'Every charge, every number, sources.'),
        ],
        selected: settings.detailLevel.name,
        onSelect: (val) {
          settings.setDetailLevel(DetailLevelX.fromString(val));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsState settings) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _PickerSheet(
        title: 'Language',
        subtitle: 'Language for the app interface. Bills always stay in their original language.',
        options: const [
          _Option('en', 'English', ''),
          _Option('es', 'Español', ''),
        ],
        selected: settings.language,
        onSelect: (val) {
          settings.setLanguage(val);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showRemindersPicker(BuildContext context, SettingsState settings) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _PickerSheet(
        title: 'Reminders',
        subtitle: 'When to remind you about upcoming bills.',
        options: const [
          _Option('off',        'Off',         'No reminders.'),
          _Option('day_before', 'Day before',  'Notify the day before each due date.'),
          _Option('day_of',     'Day of',      'Notify on the due date.'),
        ],
        selected: settings.reminders,
        onSelect: (val) {
          settings.setReminders(val);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final text = Theme.of(ctx).textTheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppTokens.screenEdge, AppTokens.space6,
            AppTokens.screenEdge,
            MediaQuery.of(ctx).padding.bottom + AppTokens.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(feature, style: text.headlineLarge),
              const SizedBox(height: AppTokens.space3),
              Text('Coming in a future update.', style: text.bodyLarge),
            ],
          ),
        );
      },
    );
  }

  String _languageLabel(String code) =>
      code == 'es' ? 'Español' : 'English';

  String _remindersLabel(String code) {
    switch (code) {
      case 'day_before': return 'Day before';
      case 'day_of':     return 'Day of';
      default:           return 'Off';
    }
  }
}

// ── Generic picker sheet ──────────────────────────────────────────────────

class _Option {
  const _Option(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelect,
  });
  final String title;
  final String subtitle;
  final List<_Option> options;
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.screenEdge, AppTokens.space6,
          AppTokens.screenEdge, AppTokens.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.headlineLarge),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: AppTokens.space2),
              Text(subtitle, style: text.bodyMedium),
            ],
            const SizedBox(height: AppTokens.space4),
            ...options.map((opt) => Semantics(
              checked: opt.value == selected,
              child: InkWell(
                onTap: () => onSelect(opt.value),
                child: Container(
                  constraints: const BoxConstraints(minHeight: AppTokens.targetMin),
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt.label, style: text.bodyLarge),
                            if (opt.description.isNotEmpty)
                              Text(opt.description, style: text.bodySmall),
                          ],
                        ),
                      ),
                      if (opt.value == selected)
                        Icon(Icons.check, color: colours.primary),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
