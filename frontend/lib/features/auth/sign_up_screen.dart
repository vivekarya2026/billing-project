// sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart' as app_auth;
import '../../shared/components/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form     = GlobalKey<FormState>();
  final _name     = TextEditingController();
  final _username = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool   _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<app_auth.AuthState>().signUpWithEmail(
        name:     _name.text.trim(),
        username: _username.text.trim().toLowerCase(),
        email:    _email.text.trim(),
        password: _password.text,
      );
      if (mounted) context.go('/bills');
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
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
                  const SizedBox(height: 32),
                  Icon(Icons.balance, size: 48, color: colours.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Create account.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colours.primary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text('Split expenses with friends, simplified.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colours.onSurfaceVariant)),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.alternate_email),
                      hintText: 'lowercase letters, numbers, _',
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Choose a username';
                      if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(v!)) {
                        return '3–20 chars, lowercase letters/numbers/_';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
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
                      hintText: 'At least 8 characters',
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Enter a password';
                      if ((v?.length ?? 0) < 8) return 'Minimum 8 characters';
                      return null;
                    },
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
                    label:   'Create Account',
                    loading: _loading,
                    onTap:   _loading ? null : _signUp,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Already have an account? Sign in'),
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
