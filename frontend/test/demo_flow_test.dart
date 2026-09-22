// test/demo_flow_test.dart
// ─────────────────────────
// Reproduces the "Try Demo Account" → Groups navigation flow end-to-end
// using the fake repository and offline bypass, to catch routing/auth bugs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bill_intelligence/router.dart';
import 'package:bill_intelligence/theme/theme.dart';
import 'package:bill_intelligence/state/auth_state.dart' as app_auth;
import 'package:bill_intelligence/state/current_user_state.dart';
import 'package:bill_intelligence/shared/data/split_repository.dart';
import 'package:bill_intelligence/shared/data/fake_split_repository.dart';
import 'package:bill_intelligence/shared/models/profile.dart';

Widget _buildApp(SplitRepository repo) {
  final router = buildRouter();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<app_auth.AuthState>.value(
          value: app_auth.AuthState.instance),
      ChangeNotifierProvider<CurrentUserState>.value(
          value: CurrentUserState.instance),
      Provider<SplitRepository>.value(value: repo),
    ],
    child: MaterialApp.router(
      theme:     buildTheme(brightness: Brightness.light),
      darkTheme: buildTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('unauthenticated user lands on Sign In', (tester) async {
    // Ensure clean auth
    await app_auth.AuthState.instance.signOut();
    CurrentUserState.instance.clear();

    await tester.pumpWidget(_buildApp(FakeSplitRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Try Demo Account'), findsOneWidget);
  });

  testWidgets('Try Demo Account navigates to Groups', (tester) async {
    await app_auth.AuthState.instance.signOut();
    // Seed the offline profile like main.dart does
    CurrentUserState.instance.setFakeProfile(const Profile(
      id:       '00000000-0000-0000-0000-000000000101',
      username: 'alice',
      name:     'Alice Kumar',
      email:    'alice@split.local',
    ));

    await tester.pumpWidget(_buildApp(FakeSplitRepository()));
    await tester.pumpAndSettle();

    // Tap the demo button
    await tester.tap(find.text('Try Demo Account'));
    await tester.pumpAndSettle();

    // We should now be on the Groups screen (title + the seeded group)
    expect(find.text('Groups'), findsWidgets);
    expect(find.text('Goa Trip 🏖️'), findsWidgets);
  });
}
