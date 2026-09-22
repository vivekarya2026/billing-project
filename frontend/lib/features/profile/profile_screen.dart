// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart' as app_auth;
import '../../state/current_user_state.dart';
import '../../shared/components/avatar_initial.dart';
import '../../theme/accents.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CurrentUserState>().profile;
    final colours = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: AppAccents.gradientText('Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700)),
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // ── Avatar ──────────────────────────────────────────
                  AvatarInitial(name: profile.name, radius: 48),
                  const SizedBox(height: 16),
                  Text(profile.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('@${profile.username}',
                      style: TextStyle(
                          color:    colours.primary,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(profile.email,
                      style: TextStyle(
                          color:    colours.onSurfaceVariant,
                          fontSize: 13)),
                  const SizedBox(height: 32),

                  // ── Settings section ─────────────────────────────────
                  const _SectionCard(children: [
                    _SettingRow(
                      icon:  Icons.currency_rupee,
                      label: 'Currency',
                      value: AppAccents.currencySymbol,
                    ),
                    Divider(height: 1),
                    _SettingRow(
                      icon:    Icons.info_outline,
                      label:   'Version',
                      value:   '1.0.0',
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // ── Sign out ─────────────────────────────────────────
                  _SectionCard(children: [
                    ListTile(
                      leading: const Icon(Icons.logout,
                          color: AppAccents.danger),
                      title: const Text('Sign out',
                          style: TextStyle(
                              color:      AppAccents.danger,
                              fontWeight: FontWeight.w600)),
                      onTap: () async {
                        await context
                            .read<app_auth.AuthState>()
                            .signOut();
                        if (context.mounted) context.go('/sign-in');
                      },
                    ),
                  ]),
                ],
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:        colours.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: colours.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title:   Text(label),
      trailing: Text(value,
          style: TextStyle(color: colours.onSurfaceVariant)),
    );
  }
}
