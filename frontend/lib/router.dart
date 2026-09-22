// router.dart — Billing-only navigation (SplitWise hidden)
//
// 3 shell tabs: /bills, /spend (Insights), /settings-tab
//   The app reads as a focused Billing App. SplitWise routes and screens
//   remain compiled below the shell but are no longer linked from any tab,
//   so the feature can be restored by re-adding its branches/destinations.
//
// Full-screen pushes (bill domain):
//   /onboarding        — first-run hero
//   /add-bill          — add-bill chooser (scan vs manual)
//   /capture           — guided bill capture (+ ?mode=camera|files)
//   /manual-bill       — manual entry (also edit mode via ?id=)
//   /bill/:id          — bill detail / answer screen
//   /settings          — 4-item settings screen (also reachable as a tab)
//
// Full-screen pushes (split domain — kept, currently unlinked):
//   /sign-in, /sign-up
//   /create-group
//   /group-details/:id
//   /group-details/:id/add-expense
//   /group-details/:id/add-member
//   /add-friend
//   /settle/:receiverId

import 'package:go_router/go_router.dart';
import 'state/auth_state.dart' as app_auth;
import 'shared/components/app_shell.dart';

// ── Screen imports — Bill domain ───────────────────────────────────────────
import 'features/home/home_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/bill_capture/add_bill_screen.dart';
import 'features/bill_capture/bill_capture_screen.dart';
import 'features/bill_capture/manual_bill_screen.dart';
import 'features/bill_detail/bill_detail_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

// ── Screen imports — Auth ──────────────────────────────────────────────────
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';

// ── Screen imports — Split domain ─────────────────────────────────────────
import 'features/groups/groups_screen.dart';
import 'features/groups/create_group_screen.dart';
import 'features/groups/group_details_screen.dart';
import 'features/expenses/add_expense_screen.dart';
import 'features/friends/friends_screen.dart';
import 'features/friends/add_friend_screen.dart';
import 'features/friends/settlement_screen.dart';
import 'features/activity/activity_screen.dart';
import 'features/profile/profile_screen.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: '/bills',
  // Re-run redirect whenever auth state changes (e.g. after demo login).
  refreshListenable: app_auth.AuthState.instance,
  redirect: (context, state) {
    final isSignedIn = app_auth.AuthState.instance.isSignedIn;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == '/sign-in' || loc == '/sign-up';

    // Unauthenticated users go to sign-in (unless already there)
    if (!isSignedIn && !isAuthRoute) return '/sign-in';

    // Signed-in users on auth routes go to the bills tab
    if (isSignedIn && isAuthRoute) return '/bills';

    return null;
  },
  routes: [
    // ── Full-screen auth ──────────────────────────────────────────────────
    GoRoute(
      path: '/sign-in',
      builder: (_, __) => const SignInScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (_, __) => const SignUpScreen(),
    ),

    // ── Shell (3 tabs — SplitWise hidden) ─────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        // Tab 0 — Bills (unified list + type filter + add/remove)
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/bills',
            builder: (_, __) => const HomeScreen(),
          ),
        ]),
        // Tab 1 — Insights (spend tracking)
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/spend',
            builder: (_, __) => const DashboardScreen(),
          ),
        ]),
        // Tab 2 — Settings
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/settings-tab',
            builder: (_, __) => const SettingsScreen(),
          ),
        ]),
      ],
    ),

    // ── Full-screen bill domain ───────────────────────────────────────────
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/add-bill',
      builder: (_, __) => const AddBillScreen(),
    ),
    GoRoute(
      path: '/capture',
      builder: (_, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'files';
        return BillCaptureScreen(mode: mode);
      },
    ),
    GoRoute(
      path: '/manual-bill',
      builder: (_, state) => ManualBillScreen(
        billId: state.uri.queryParameters['id'],
      ),
    ),
    GoRoute(
      path: '/bill/:id',
      builder: (_, state) => BillDetailScreen(
          billId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),

    // ── Full-screen split domain (kept, currently unlinked from nav) ──────
    // These SplitWise screens remain reachable by URL so the code stays
    // compiled and the feature is trivially restorable — but no tab links
    // to them while the app is billing-only.
    GoRoute(
      path: '/groups',
      builder: (_, __) => const GroupsScreen(),
    ),
    GoRoute(
      path: '/friends',
      builder: (_, __) => const FriendsScreen(),
    ),
    GoRoute(
      path: '/activity',
      builder: (_, __) => const ActivityScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/create-group',
      builder: (_, __) => const CreateGroupScreen(),
    ),
    GoRoute(
      path: '/group-details/:id',
      builder: (_, state) => GroupDetailsScreen(
          groupId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/group-details/:id/add-expense',
      builder: (_, state) => AddExpenseScreen(
          groupId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/group-details/:id/add-member',
      builder: (_, state) => AddFriendScreen(
          groupId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/add-friend',
      builder: (_, __) => const AddFriendScreen(),
    ),
    GoRoute(
      path: '/settle/:receiverId',
      builder: (_, state) {
        final rid    = state.pathParameters['receiverId']!;
        final amount = double.tryParse(
            state.uri.queryParameters['amount'] ?? '');
        final name   = state.uri.queryParameters['name'] ?? '';
        return SettlementScreen(
          receiverId:      rid,
          receiverName:    name,
          suggestedAmount: amount,
        );
      },
    ),
  ],
);
