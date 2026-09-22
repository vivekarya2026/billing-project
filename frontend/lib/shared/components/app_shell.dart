// app_shell.dart — adaptive navigation shell
// ─────────────────────────────────────────────────────────────────────────
// Mobile  (width < 640)  → NavigationBar (daisyUI Dock)
// Desktop (width ≥ 640)  → NavigationRail (daisyUI Menu, left side)
//
// Tabs: Bills / Insights / Settings  (billing-only; SplitWise hidden)
// Theme: daisyUI base-300 nav surfaces, primary indicator tint.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colours.dart';
import '../../theme/accents.dart';
import '../../theme/tokens.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  void _onTap(int index) => shell.goBranch(
        index,
        initialLocation: index == shell.currentIndex,
      );

  static const _destinations = [
    _Dest(icon: Icons.receipt_long_outlined,  activeIcon: Icons.receipt_long,     label: 'Bills'),
    _Dest(icon: Icons.insights_outlined,      activeIcon: Icons.insights,         label: 'Insights'),
    _Dest(icon: Icons.settings_outlined,      activeIcon: Icons.settings,         label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppTokens.desktopBreakpoint) {
      return _MobileShell(shell: shell, onTap: _onTap);
    } else {
      return _DesktopShell(shell: shell, onTap: _onTap);
    }
  }
}

// ── Mobile shell ────────────────────────────────────────────────────────────
class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.shell, required this.onTap});
  final StatefulNavigationShell shell;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final colours = AppColours.resolveColours(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: onTap,
        backgroundColor:    colours.surfaceContainerHighest,
        indicatorColor:     AppAccents.skyTint10,
        labelBehavior:      NavigationDestinationLabelBehavior.alwaysShow,
        destinations: AppShell._destinations.map((d) => NavigationDestination(
          icon:         Icon(d.icon),
          selectedIcon: Icon(d.activeIcon),
          label:        d.label,
        )).toList(),
      ),
    );
  }
}

// ── Desktop shell ────────────────────────────────────────────────────────────
class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.shell, required this.onTap});
  final StatefulNavigationShell shell;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final colours = AppColours.resolveColours(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex:  shell.currentIndex,
            onDestinationSelected: onTap,
            backgroundColor:    colours.surfaceContainerHighest,
            indicatorColor:     AppAccents.skyTint10,
            labelType:          NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _AppLogo(),
            ),
            destinations: AppShell._destinations.map((d) => NavigationRailDestination(
              icon:         Icon(d.icon),
              selectedIcon: Icon(d.activeIcon),
              label:        Text(d.label),
            )).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.balance,
      size: 32,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class _Dest {
  const _Dest({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String  label;
}
