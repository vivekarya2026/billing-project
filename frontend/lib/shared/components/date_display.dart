// date_display.dart — human-readable relative time
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateDisplay extends StatelessWidget {
  const DateDisplay({super.key, required this.date, this.style});
  final DateTime date;
  final TextStyle? style;

  static String format(DateTime d) {
    final now  = DateTime.now();
    final diff = now.difference(d);
    if (diff.inSeconds < 60)     return 'just now';
    if (diff.inMinutes < 60)     return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)       return '${diff.inHours}h ago';
    if (diff.inDays < 7)         return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(d);
  }

  @override
  Widget build(BuildContext context) => Text(
        format(date),
        style: style ??
            Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}
