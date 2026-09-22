// onboarding_screen.dart
// -----------------------
// First-run hero with dark gradient aesthetic.
// Serif italic gradient headline mirrors the reference's "bg-clip-text" span.
//
// Two modes:
//   BYPASS_AUTH=true  → batch drop entry; no sign-in shown
//   BYPASS_AUTH=false → Google + Apple sign-in buttons

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/components/primary_button.dart';
import '../../../state/auth_state.dart' as app_auth;
import '../../../theme/tokens.dart';
import '../../../theme/accents.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _loading = false;
  String? _error;

  bool get _bypass => dotenv.env['BYPASS_AUTH']?.toLowerCase() == 'true';

  Future<void> _signIn(Future<void> Function() fn) async {
    setState(() { _loading = true; _error = null; });
    try {
      await fn();
      if (mounted) context.go('/bills');
    } catch (e) {
      setState(() { _error = 'Sign in failed. Please try again.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text   = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;
    final auth   = context.watch<app_auth.AuthState>();

    return Scaffold(
      backgroundColor: colours.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.screenEdge,
            vertical:   AppTokens.space6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // ── Badge chip (pulse dot + label) ───────────────────────
              const _BadgeChip(
                label: 'AI-powered bill analysis',
              ),
              const SizedBox(height: AppTokens.space5),

              // ── Gradient serif headline ──────────────────────────────
              // "Add your bills." where "your bills" is gradient italic
              RichText(
                text: TextSpan(
                  style: text.displayMedium?.copyWith(
                    color: colours.onSurface,
                  ),
                  children: [
                    const TextSpan(text: 'Add '),
                    TextSpan(
                      text: 'your bills.',
                      style: text.displayMedium?.copyWith(
                        color: colours.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTokens.space4),

              // ── Body copy ────────────────────────────────────────────
              Text(
                'Photos or PDFs. As many as you have.\nGet one sentence on every bill.',
                style: text.bodyLarge?.copyWith(
                  color: colours.onSurfaceVariant,
                ),
              ),

              const Spacer(),

              // ── Error message ─────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTokens.space3),
                  decoration: BoxDecoration(
                    color: colours.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(
                        color: colours.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!,
                      style: text.bodyMedium
                          ?.copyWith(color: colours.error)),
                ),
                const SizedBox(height: AppTokens.space3),
              ],

              // ── Sign-in buttons ───────────────────────────────────────
              if (!_bypass) ...[
                AppButton(
                  label: 'Continue with Google',
                  loading: _loading,
                  onPressed: () => _signIn(auth.signInWithGoogle),
                ),
                const SizedBox(height: AppTokens.space3),
                AppButton(
                  label: 'Continue with Apple',
                  variant: ButtonVariant.secondary,
                  loading: _loading,
                  onPressed: () => _signIn(auth.signInWithApple),
                ),
              ],

              // ── Bypass mode buttons ───────────────────────────────────
              if (_bypass) ...[
                AppButton(
                  label: 'Choose files',
                  onPressed: () => context.push('/capture?mode=files'),
                ),
                const SizedBox(height: AppTokens.space3),
                AppButton(
                  label: 'Take a photo',
                  variant: ButtonVariant.secondary,
                  onPressed: () => context.push('/capture?mode=camera'),
                ),
              ],

              const SizedBox(height: AppTokens.space8),

              // ── Footer ────────────────────────────────────────────────
              Center(
                child: Text(
                  _bypass
                      ? 'No account. No sign up.'
                      : 'Your bills never leave this device without your consent.',
                  style: text.bodySmall?.copyWith(
                    color: colours.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppTokens.space4),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Badge chip ────────────────────────────────────────────────────────────
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppAccents.skyTint10,
        borderRadius: BorderRadius.circular(AppTokens.radiusSelector),
        border: Border.all(color: AppAccents.skyBorder20, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppAccents.emeraldDot,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: AppTokens.textCaption,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
