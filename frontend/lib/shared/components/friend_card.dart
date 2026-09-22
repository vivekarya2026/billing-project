// friend_card.dart — card for a friend with balance and settle-up action
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/accents.dart';
import '../../shared/models/profile.dart';
import 'avatar_initial.dart';

class FriendCard extends StatelessWidget {
  const FriendCard({
    super.key,
    required this.friend,
    required this.net,   // positive = friend owes me, negative = I owe friend
  });

  final Profile friend;
  final double  net;

  @override
  Widget build(BuildContext context) {
    final colours  = Theme.of(context).colorScheme;
    final isOwed   = net > 0.009;
    final isOwing  = net < -0.009;
    final label    = isOwed
        ? '${friend.name.split(' ').first} owes you ${AppAccents.currencySymbol}${net.abs().toStringAsFixed(0)}'
        : isOwing
            ? 'You owe ${friend.name.split(' ').first} ${AppAccents.currencySymbol}${net.abs().toStringAsFixed(0)}'
            : 'Settled up';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color:        colours.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: colours.outline),
        boxShadow:    const [AppAccents.glowCard],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AvatarInitial(name: friend.name, radius: 22),
        title: Text(friend.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isOwed  ? AppAccents.success
                 : isOwing ? AppAccents.danger
                 :           colours.onSurfaceVariant,
          ),
        ),
        trailing: isOwed || isOwing
            ? TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colours.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colours.outline),
                  ),
                ),
                onPressed: () => context.push(
                  '/settle/${friend.id}?amount=${net.abs().toStringAsFixed(2)}'
                  '&name=${Uri.encodeComponent(friend.name)}',
                ),
                child: const Text('Settle', style: TextStyle(fontSize: 12)),
              )
            : null,
        ),
      ),
    );
  }
}
