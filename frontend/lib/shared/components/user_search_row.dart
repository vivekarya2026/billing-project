// user_search_row.dart — search result row with an "Add" action
import 'package:flutter/material.dart';
import '../../shared/models/profile.dart';
import 'avatar_initial.dart';

class UserSearchRow extends StatelessWidget {
  const UserSearchRow({
    super.key,
    required this.profile,
    this.actionLabel = 'Add',
    this.onAction,
    this.isAdded = false,
  });

  final Profile  profile;
  final String   actionLabel;
  final VoidCallback? onAction;
  final bool     isAdded;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return ListTile(
      leading:  AvatarInitial(name: profile.name, radius: 18),
      title:    Text(profile.name),
      subtitle: Text('@${profile.username}',
          style: TextStyle(fontSize: 11, color: colours.onSurfaceVariant)),
      trailing: isAdded
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
    );
  }
}
