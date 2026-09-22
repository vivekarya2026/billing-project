// test/screens_smoke_test.dart
// ─────────────────────────────
// Smoke-tests every screen renders without throwing, using the fake repo.
// Catches null-safety crashes, missing providers, and layout exceptions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:bill_intelligence/theme/theme.dart';
import 'package:bill_intelligence/state/auth_state.dart' as app_auth;
import 'package:bill_intelligence/state/current_user_state.dart';
import 'package:bill_intelligence/shared/data/split_repository.dart';
import 'package:bill_intelligence/shared/data/fake_split_repository.dart';
import 'package:bill_intelligence/shared/models/profile.dart';

import 'package:bill_intelligence/features/groups/groups_screen.dart';
import 'package:bill_intelligence/features/groups/create_group_screen.dart';
import 'package:bill_intelligence/features/groups/group_details_screen.dart';
import 'package:bill_intelligence/features/expenses/add_expense_screen.dart';
import 'package:bill_intelligence/features/friends/friends_screen.dart';
import 'package:bill_intelligence/features/friends/add_friend_screen.dart';
import 'package:bill_intelligence/features/friends/settlement_screen.dart';
import 'package:bill_intelligence/features/activity/activity_screen.dart';
import 'package:bill_intelligence/features/profile/profile_screen.dart';

Widget _host(Widget child) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => child),
    GoRoute(path: '/settle/:id', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/create-group', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/add-friend', builder: (_, __) => const Scaffold()),
  ]);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<app_auth.AuthState>.value(value: app_auth.AuthState.instance),
      ChangeNotifierProvider<CurrentUserState>.value(value: CurrentUserState.instance),
      Provider<SplitRepository>.value(value: FakeSplitRepository()),
    ],
    child: MaterialApp.router(
      theme: buildTheme(brightness: Brightness.dark),
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() {
    CurrentUserState.instance.setFakeProfile(const Profile(
      id: '00000000-0000-0000-0000-000000000101',
      username: 'alice', name: 'Alice Kumar', email: 'alice@split.local',
    ));
  });

  Future<void> smoke(WidgetTester t, Widget screen, String label) async {
    await t.pumpWidget(_host(screen));
    await t.pumpAndSettle();
    // pumpAndSettle rethrows if the screen threw during build/async.
  }

  testWidgets('Groups screen', (t) async {
    await smoke(t, const GroupsScreen(), 'Groups');
    expect(find.text('Goa Trip 🏖️'), findsWidgets);
  });

  testWidgets('Create Group screen', (t) async {
    await smoke(t, const CreateGroupScreen(), 'CreateGroup');
  });

  testWidgets('Group Details screen', (t) async {
    await smoke(t, const GroupDetailsScreen(groupId: 'grp-001'), 'GroupDetails');
    expect(find.text('Dinner at shack'), findsWidgets);
  });

  testWidgets('Add Expense screen', (t) async {
    await smoke(t, const AddExpenseScreen(groupId: 'grp-001'), 'AddExpense');
  });

  testWidgets('Friends screen', (t) async {
    await smoke(t, const FriendsScreen(), 'Friends');
  });

  testWidgets('Add Friend screen', (t) async {
    await smoke(t, const AddFriendScreen(), 'AddFriend');
  });

  testWidgets('Settlement screen', (t) async {
    await smoke(t, const SettlementScreen(
      receiverId: '00000000-0000-0000-0000-000000000102',
      receiverName: 'Bob Sharma',
      suggestedAmount: 100,
    ), 'Settlement');
  });

  testWidgets('Activity screen', (t) async {
    await smoke(t, const ActivityScreen(), 'Activity');
    expect(find.text('Overall Balance'), findsWidgets);
  });

  testWidgets('Profile screen', (t) async {
    await smoke(t, const ProfileScreen(), 'Profile');
    expect(find.text('Alice Kumar'), findsWidgets);
  });
}
