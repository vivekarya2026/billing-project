// avatar_initial.dart — coloured circle with the user's initial letter
import 'package:flutter/material.dart';

class AvatarInitial extends StatelessWidget {
  const AvatarInitial({
    super.key,
    required this.name,
    this.radius = 20,
  });

  final String name;
  final double radius;

  static Color _colorFor(String name) {
    // Deterministic hue from char code
    final code  = name.isEmpty ? 65 : name.codeUnitAt(0);
    final hue   = (code * 37) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.45).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty ? '?' : name[0].toUpperCase();
    final bg     = _colorFor(name);
    return CircleAvatar(
      radius:          radius,
      backgroundColor: bg,
      child: Text(
        letter,
        style: TextStyle(
          color:      Colors.white,
          fontWeight: FontWeight.w700,
          fontSize:   radius * 0.9,
        ),
      ),
    );
  }
}
