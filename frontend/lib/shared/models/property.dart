// lib/shared/models/property.dart
// Mirrors the Supabase `properties` table.

class Property {
  const Property({
    required this.id,
    required this.userId,
    required this.name,
    this.address,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? address;
  final DateTime createdAt;

  factory Property.fromJson(Map<String, dynamic> j) => Property(
        id:        j['id'] as String,
        userId:    j['user_id'] as String,
        name:      j['name'] as String,
        address:   j['address'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
