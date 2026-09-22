// activity_icon.dart — SplitWise expense-row icon.
// Now delegates to the shared CategoryIcons resolver so bills and expenses
// share one keyword->icon source of truth.
import 'package:flutter/material.dart';
import 'category_icons.dart';

class ActivityIcon extends StatelessWidget {
  const ActivityIcon({super.key, required this.description, this.size = 22});
  final String description;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CategoryIconBadge(text: description, size: size);
  }
}
