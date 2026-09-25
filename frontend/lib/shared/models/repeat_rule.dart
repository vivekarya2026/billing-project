// lib/shared/models/repeat_rule.dart
// How often a manually entered bill repeats. The rule's id is the account id
// shared by every cycle's bill ("rep-<uuid>"), so a rule is found from any
// of its bills.

enum RepeatEvery { week, month, quarter, year, custom }

/// Longest custom interval the form accepts.
const maxCustomDays = 365;

extension RepeatEveryX on RepeatEvery {
  /// Option label in the Repeats field.
  String get label {
    switch (this) {
      case RepeatEvery.week:    return 'Every week';
      case RepeatEvery.month:   return 'Every month';
      case RepeatEvery.quarter: return 'Every 3 months';
      case RepeatEvery.year:    return 'Every year';
      case RepeatEvery.custom:  return 'Custom';
    }
  }

  /// "Repeats every month" / "Repeats every 21 days" on bill detail.
  String repeatsPhrase([int days = 0]) {
    if (this != RepeatEvery.custom) return 'Repeats ${label.toLowerCase()}';
    return days == 1 ? 'Repeats every day' : 'Repeats every $days days';
  }
}

class RepeatRule {
  RepeatRule({
    required this.accountId,
    required this.every,
    required this.anchor,
    required this.lastIssued,
    this.days = 0,
  });

  final String accountId;
  RepeatEvery every;

  /// Interval in days when [every] is custom.
  int days;

  /// The first cycle's due date; every later date is counted from it.
  DateTime anchor;

  /// Latest due date issued so far, including cycles the user deleted, so a
  /// deletion skips that cycle instead of re-creating it.
  DateTime lastIssued;

  String get phrase => every.repeatsPhrase(days);
}
