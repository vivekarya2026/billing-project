// member_row.dart — a single member in a group/expense list
import 'package:flutter/material.dart';
import '../../shared/models/profile.dart';
import 'avatar_initial.dart';

class MemberRow extends StatelessWidget {
  const MemberRow({
    super.key,
    required this.profile,
    this.trailing,
    this.subtitle,
  });

  final Profile profile;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AvatarInitial(name: profile.name, radius: 18),
      title:   Text(profile.name,
                   style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(
              '@${profile.username}',
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            )
          : null,
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      dense: true,
    );
  }
}
