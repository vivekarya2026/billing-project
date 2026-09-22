// category_icons.dart — single source of truth for keyword → category → icon.
// ---------------------------------------------------------------------------
// Shared across the bill domain (bill cards, manual entry, the Bills list) and
// the SplitWise domain (expense rows). Given free text (a provider name, a bill
// name, or an expense description) it resolves a CategoryKind, from which both
// the glyph (icon) and a pastel tile colour are derived — matching the
// SplitWise-style colored category tiles.
//
// Kept deliberately keyword-based (no model) so it is deterministic and works
// fully offline.

import 'package:flutter/material.dart';

/// The set of categories the app can recognise. One enum keeps the icon and
/// the tile colour in lockstep across bills and expenses.
enum CategoryKind {
  electric,
  gas,
  water,
  internet,
  trash,
  phone,
  streaming,
  insurance,
  rent,
  cable,
  food,
  coffee,
  transport,
  fuel,
  groceries,
  hotel,
  flight,
  entertainment,
  health,
  personalCare,
  fitness,
  payment,
  other,
}

class CategoryIcons {
  CategoryIcons._();

  /// Resolve a category for a piece of free text, optionally biased by a
  /// structured [serviceType] from the data model (which wins when set).
  static CategoryKind kindFor(String text, {String? serviceType}) {
    if (serviceType != null && serviceType.trim().isNotEmpty) {
      final byType = _byServiceType(serviceType.toLowerCase().trim());
      if (byType != null) return byType;
    }

    final lower = text.toLowerCase();

    // ── Utilities ────────────────────────────────────────────────────────
    if (_has(lower, ['electric', 'electricity', 'power', 'edison', 'energy'])) {
      return CategoryKind.electric;
    }
    if (_has(lower, ['gas', 'propane', 'columbia gas', 'heating'])) {
      return CategoryKind.gas;
    }
    if (_has(lower, ['water', 'sewer', 'aqua', 'utilities water'])) {
      return CategoryKind.water;
    }
    if (_has(lower, ['internet', 'wifi', 'broadband', 'fiber', 'comcast', 'xfinity', 'spectrum'])) {
      return CategoryKind.internet;
    }
    if (_has(lower, ['trash', 'garbage', 'waste', 'recycl'])) {
      return CategoryKind.trash;
    }
    if (_has(lower, ['phone', 'mobile', 'cellular', 'verizon', 'at&t', 'tmobile', 't-mobile'])) {
      return CategoryKind.phone;
    }
    if (_has(lower, ['stream', 'netflix', 'spotify', 'hulu', 'disney', 'subscription', 'prime video', 'youtube'])) {
      return CategoryKind.streaming;
    }
    if (_has(lower, ['insurance', 'premium', 'geico', 'allstate', 'policy'])) {
      return CategoryKind.insurance;
    }
    if (_has(lower, ['rent', 'lease', 'mortgage', 'landlord'])) {
      return CategoryKind.rent;
    }
    if (_has(lower, ['cable', 'tv', 'directv', 'dish'])) {
      return CategoryKind.cable;
    }

    // ── General / SplitWise categories ──────────────────────────────────
    if (_has(lower, ['food', 'dinner', 'lunch', 'restaurant', 'shack', 'meal', 'eat', 'pizza', 'burger'])) {
      return CategoryKind.food;
    }
    if (_has(lower, ['coffee', 'cafe', 'tea', 'starbucks'])) {
      return CategoryKind.coffee;
    }
    if (_has(lower, ['taxi', 'uber', 'lyft', 'cab', 'transport', 'airport', 'ride'])) {
      return CategoryKind.transport;
    }
    if (_has(lower, ['fuel', 'petrol', 'gasoline', 'diesel', 'uhaul', 'u-haul'])) {
      return CategoryKind.fuel;
    }
    if (_has(lower, ['grocery', 'groceries', 'supermarket', 'shop', 'market', 'costco', 'walmart', 'target', 'macy'])) {
      return CategoryKind.groceries;
    }
    if (_has(lower, ['hotel', 'hostel', 'stay', 'airbnb', 'lodging', 'resort'])) {
      return CategoryKind.hotel;
    }
    if (_has(lower, ['flight', 'air ', 'airline', 'airfare', 'plane'])) {
      return CategoryKind.flight;
    }
    if (_has(lower, ['movie', 'cinema', 'film', 'concert', 'ticket', 'entertain'])) {
      return CategoryKind.entertainment;
    }
    if (_has(lower, ['medicine', 'pharma', 'health', 'doctor', 'hospital', 'clinic', 'medical'])) {
      return CategoryKind.health;
    }
    if (_has(lower, ['haircut', 'salon', 'barber', 'spa'])) {
      return CategoryKind.personalCare;
    }
    if (_has(lower, ['gym', 'fitness', 'workout', 'yoga'])) {
      return CategoryKind.fitness;
    }
    if (_has(lower, ['bill', 'invoice', 'payment'])) {
      return CategoryKind.payment;
    }

    return CategoryKind.other;
  }

  /// Icon (glyph) for a piece of free text.
  static IconData iconFor(String text, {String? serviceType}) =>
      iconForKind(kindFor(text, serviceType: serviceType));

  /// Pastel tile colour for a piece of free text — matches the SplitWise
  /// colored category tiles.
  static Color colorFor(String text, {String? serviceType}) =>
      colorForKind(kindFor(text, serviceType: serviceType));

  /// Glyph for a resolved [CategoryKind].
  static IconData iconForKind(CategoryKind kind) {
    switch (kind) {
      case CategoryKind.electric:      return Icons.electric_bolt;
      case CategoryKind.gas:           return Icons.local_fire_department;
      case CategoryKind.water:         return Icons.water_drop;
      case CategoryKind.internet:      return Icons.wifi;
      case CategoryKind.trash:         return Icons.delete_outline;
      case CategoryKind.phone:         return Icons.smartphone;
      case CategoryKind.streaming:     return Icons.subscriptions;
      case CategoryKind.insurance:     return Icons.shield_outlined;
      case CategoryKind.rent:          return Icons.home_outlined;
      case CategoryKind.cable:         return Icons.tv;
      case CategoryKind.food:          return Icons.restaurant;
      case CategoryKind.coffee:        return Icons.coffee;
      case CategoryKind.transport:     return Icons.directions_car;
      case CategoryKind.fuel:          return Icons.local_gas_station;
      case CategoryKind.groceries:     return Icons.shopping_cart;
      case CategoryKind.hotel:         return Icons.hotel;
      case CategoryKind.flight:        return Icons.flight;
      case CategoryKind.entertainment: return Icons.movie;
      case CategoryKind.health:        return Icons.medical_services;
      case CategoryKind.personalCare:  return Icons.content_cut;
      case CategoryKind.fitness:       return Icons.fitness_center;
      case CategoryKind.payment:       return Icons.receipt_long;
      case CategoryKind.other:         return Icons.receipt_long;
    }
  }

  /// Pastel tile colour for a resolved [CategoryKind]. Soft, saturated-but-airy
  /// hues in the spirit of the SplitWise reference (pink transport, green food,
  /// yellow shopping, etc.), tuned to read on a dark surface.
  static Color colorForKind(CategoryKind kind) {
    switch (kind) {
      case CategoryKind.electric:      return const Color(0xFFF5D06F); // amber
      case CategoryKind.gas:           return const Color(0xFFF2A65A); // orange
      case CategoryKind.water:         return const Color(0xFF7FC8F0); // sky
      case CategoryKind.internet:      return const Color(0xFF9AA7F0); // periwinkle
      case CategoryKind.trash:         return const Color(0xFFA9B4BC); // slate
      case CategoryKind.phone:         return const Color(0xFF8FD4C4); // teal
      case CategoryKind.streaming:     return const Color(0xFFE79CC4); // magenta-pink
      case CategoryKind.insurance:     return const Color(0xFF9FD08F); // green
      case CategoryKind.rent:          return const Color(0xFFC7A8E8); // lavender
      case CategoryKind.cable:         return const Color(0xFF9AA7F0); // periwinkle
      case CategoryKind.food:          return const Color(0xFF9FD08F); // green (reference)
      case CategoryKind.coffee:        return const Color(0xFFD8B48A); // tan
      case CategoryKind.transport:     return const Color(0xFFF0A6C0); // pink (reference)
      case CategoryKind.fuel:          return const Color(0xFFF0A6C0); // pink (reference)
      case CategoryKind.groceries:     return const Color(0xFFEDE08C); // yellow (reference)
      case CategoryKind.hotel:         return const Color(0xFF7FC8F0); // sky
      case CategoryKind.flight:        return const Color(0xFF9AA7F0); // periwinkle
      case CategoryKind.entertainment: return const Color(0xFFC7A8E8); // lavender
      case CategoryKind.health:        return const Color(0xFFEF9A9A); // soft red
      case CategoryKind.personalCare:  return const Color(0xFFE79CC4); // magenta-pink
      case CategoryKind.fitness:       return const Color(0xFF8FD4C4); // teal
      case CategoryKind.payment:       return const Color(0xFFB8C0C8); // neutral
      case CategoryKind.other:         return const Color(0xFFB8C0C8); // neutral
    }
  }

  /// A short, human label for a service type (used by the bill-type filter).
  static String labelForServiceType(String serviceType) {
    switch (serviceType.toLowerCase().trim()) {
      case 'electric':
      case 'electricity':
        return 'Electric';
      case 'gas':
        return 'Gas';
      case 'water':
      case 'sewer':
        return 'Water';
      case 'internet':
      case 'wifi':
      case 'broadband':
        return 'Internet';
      case 'trash':
      case 'waste':
        return 'Trash';
      case 'phone':
      case 'mobile':
        return 'Phone';
      case 'streaming':
      case 'subscription':
        return 'Streaming';
      case 'insurance':
        return 'Insurance';
      case 'rent':
        return 'Rent';
      case 'cable':
      case 'tv':
        return 'Cable';
      case 'other':
      case '':
        return 'Other';
      default:
        return serviceType[0].toUpperCase() + serviceType.substring(1);
    }
  }

  static CategoryKind? _byServiceType(String serviceType) {
    switch (serviceType) {
      case 'electric':
      case 'electricity':
        return CategoryKind.electric;
      case 'gas':
        return CategoryKind.gas;
      case 'water':
      case 'sewer':
        return CategoryKind.water;
      case 'internet':
      case 'wifi':
      case 'broadband':
        return CategoryKind.internet;
      case 'trash':
      case 'waste':
        return CategoryKind.trash;
      case 'phone':
      case 'mobile':
        return CategoryKind.phone;
      case 'streaming':
      case 'subscription':
        return CategoryKind.streaming;
      case 'insurance':
        return CategoryKind.insurance;
      case 'rent':
        return CategoryKind.rent;
      case 'cable':
      case 'tv':
        return CategoryKind.cable;
      default:
        return null;
    }
  }

  static bool _has(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }
}

/// SplitWise-style colored category tile: a rounded square with a pastel fill
/// and a dark line-art glyph. Used across bills and expenses.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.text,
    this.serviceType,
    this.dimension = 46,
  });

  final String text;
  final String? serviceType;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final kind  = CategoryIcons.kindFor(text, serviceType: serviceType);
    final color = CategoryIcons.colorForKind(kind);
    final icon  = CategoryIcons.iconForKind(kind);

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(dimension * 0.22),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: dimension * 0.52,
        // Dark glyph on the pastel tile, like the reference line-art.
        color: const Color(0xFF1A1A20),
      ),
    );
  }
}

/// Reusable sky-tinted rounded icon badge (compact, on-theme). Retained for
/// places that want the subtle dark-theme badge rather than a pastel tile.
class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    super.key,
    required this.text,
    this.serviceType,
    this.size = 22,
  });

  final String text;
  final String? serviceType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colour = Theme.of(context).colorScheme.primary;
    return Container(
      width: size * 1.8,
      height: size * 1.8,
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.6),
      ),
      child: Icon(
        CategoryIcons.iconFor(text, serviceType: serviceType),
        size: size,
        color: colour,
      ),
    );
  }
}
