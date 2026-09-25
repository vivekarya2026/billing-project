// main.dart — Hybrid Bill Intelligence + SplitWise entry point
//
// Offline-first boot:
//   • No .env file required. If present, Supabase is used. If absent, the
//     app starts in demo/offline mode automatically.
//   • "Try Demo Account" on the sign-in screen always works, even with no DB.
//   • Both BillRepository (bill intelligence) and SplitRepository
//     (expense splitting) are provided side by side.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/theme.dart';
import 'router.dart';
import 'state/auth_state.dart' as app_auth;
import 'state/current_user_state.dart';
import 'state/settings_state.dart';
import 'state/recurring_bills.dart';
import 'shared/data/split_repository.dart';
import 'shared/data/fake_split_repository.dart';
import 'shared/data/bill_repository.dart';
import 'shared/data/fake_bill_repository.dart';
import 'shared/models/profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Try to load .env — silently skip if file doesn't exist
  String supabaseUrl     = '';
  String supabaseAnonKey = '';
  bool   bypassAuth      = false;

  try {
    await dotenv.load(fileName: '.env');
    supabaseUrl     = dotenv.env['SUPABASE_URL']      ?? '';
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    bypassAuth      = dotenv.env['BYPASS_AUTH']?.toLowerCase() == 'true';
  } catch (_) {
    // No .env file — run fully offline
  }

  final useRealDb = supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // 2. Initialise Supabase if credentials are available
  if (useRealDb) {
    try {
      await Supabase.initialize( // ignore: deprecated_member_use
          url: supabaseUrl, anonKey: supabaseAnonKey);

      // Auto-login in bypass mode
      if (bypassAuth) {
        try {
          final existing = Supabase.instance.client.auth.currentSession;
          if (existing == null) {
            final email    = dotenv.env['BYPASS_EMAIL']    ?? 'alice@split.local';
            final password = dotenv.env['BYPASS_PASSWORD'] ?? 'demo1234';
            await Supabase.instance.client.auth.signInWithPassword(
              email: email, password: password,
            );
          }
        } catch (_) { /* proceed offline */ }
      }
    } catch (_) {
      // Supabase init failed — fall back to offline
    }
  }

  // 3. Initialise auth listener (safe even if Supabase not initialised)
  app_auth.AuthState.instance.initialize();

  // 4. Load persisted settings
  await SettingsState.instance.load();

  // 5. Decide repositories
  bool isSignedIn = false;
  try {
    isSignedIn = useRealDb &&
        Supabase.instance.client.auth.currentSession != null;
  } catch (_) {}

  // In bypass mode without a real session, auto-enter offline so the app
  // lands on the app shell (no sign-in screen needed for dev/demo).
  if (bypassAuth && !isSignedIn) {
    app_auth.AuthState.instance.activateBypass();
  }

  final SplitRepository splitRepo = isSignedIn
      ? SupabaseSplitRepository()
      : FakeSplitRepository();

  // Bill repository — always offline for now (Supabase bill tables deferred).
  // Swap to SupabaseBillRepository() once the live DB is connected.
  final BillRepository billRepo = FakeBillRepository();
  await RecurringBills.instance.init(billRepo);

  // 6. Seed current user for offline/bypass mode
  final currentUserState = CurrentUserState.instance;
  if (isSignedIn) {
    try {
      final uid = Supabase.instance.client.auth.currentSession!.user.id;
      await currentUserState.load(uid);
    } catch (_) {}
  } else {
    // Always seed the Alice profile in offline mode so the app has a user
    currentUserState.setFakeProfile(const Profile(
      id:       '00000000-0000-0000-0000-000000000101',
      username: 'alice',
      name:     'Alice Kumar',
      email:    'alice@split.local',
    ));
  }

  runApp(BillApp(splitRepo: splitRepo, billRepo: billRepo));
}

class BillApp extends StatelessWidget {
  const BillApp({
    super.key,
    required this.splitRepo,
    required this.billRepo,
  });
  final SplitRepository splitRepo;
  final BillRepository billRepo;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<app_auth.AuthState>.value(
            value: app_auth.AuthState.instance),
        ChangeNotifierProvider<CurrentUserState>.value(
            value: CurrentUserState.instance),
        ChangeNotifierProvider<SettingsState>.value(
            value: SettingsState.instance),
        ChangeNotifierProvider<RecurringBills>.value(
            value: RecurringBills.instance),
        Provider<SplitRepository>.value(value: splitRepo),
        Provider<BillRepository>.value(value: billRepo),
      ],
      child: const _BillMaterialApp(),
    );
  }
}

class _BillMaterialApp extends StatelessWidget {
  const _BillMaterialApp();

  @override
  Widget build(BuildContext context) {
    final router = buildRouter();
    RecurringBills.instance.onOpenBill = (id) => router.push('/bill/$id');
    // Phones (< 400pt wide) get the tighter compact type scale; larger
    // screens keep the comfortable default. LayoutBuilder makes this
    // reactive to window resizes on web/desktop.
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 400;
        return MaterialApp.router(
          title: 'BillSense',
          debugShowCheckedModeBanner: false,
          theme:     buildTheme(brightness: Brightness.light, compact: compact),
          darkTheme: buildTheme(brightness: Brightness.dark,  compact: compact),
          themeMode: ThemeMode.dark,
          routerConfig: router,
          builder: (context, child) => ColoredBox(
            // daisyUI base-100 behind any transparent scaffolds.
            color: Theme.of(context).colorScheme.surface,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
