// ambient_background.dart
// -----------------------
// daisyUI uses flat base-100 surfaces (no ambient glow/grid). This widget is
// now a no-op so the scaffold's base-100 background shows through cleanly.
// Kept as a widget (rather than deleted) so existing call sites compile.

import 'package:flutter/material.dart';

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
