// sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart' as app_auth;
import '../../shared/components/primary_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form     = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool   _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<app_auth.AuthState>().signInWithEmail(
        email:    _email.text.trim(),
        password: _password.text,
      );
      if (mounted) context.go('/bills');
    } catch (e) {
      setState(() { _error = 'Invalid email or password.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _demo() async {
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<app_auth.AuthState>().signInDemo();
      if (mounted) context.go('/bills');
    } catch (e) {
      // fallback — just navigate (BYPASS_AUTH with fake repo)
      if (mounted) context.go('/bills');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero ──────────────────────────────────────────────
                  const SizedBox(height: 32),
                  Icon(Icons.balance, size: 48, color: colours.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome back.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colours.primary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text('Sign in to your SpendShare account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colours.onSurfaceVariant)),
                  const SizedBox(height: 32),

                  // ── Fields ────────────────────────────────────────────
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Enter your email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Enter your password' : null,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(
                            color:    colours.error,
                            fontSize: 13)),
                  ],

                  const SizedBox(height: 24),
                  AppButton.primary(
                    label:   'Sign In',
                    loading: _loading,
                    onTap:   _loading ? null : _signIn,
                  ),
                  const SizedBox(height: 12),
                  AppButton.secondary(
                    label:   'Try Demo Account',
                    onTap:   _loading ? null : _demo,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/sign-up'),
                      child: const Text("Don't have an account? Sign up"),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
