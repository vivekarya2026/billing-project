// lib/shared/models/account.dart
// Mirrors the Supabase `accounts` table.

class Account {
  const Account({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.provider,
    this.accountNumber,
    required this.serviceType,
    required this.isActive,
  });

  final String id;
  final String userId;
  final String propertyId;
  final String provider;     // "Ohio Edison"
  final String? accountNumber; // masked "****-4892"
  final String serviceType;  // "electric" | "gas" | "water" | ...
  final bool isActive;

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id:            j['id'] as String,
        userId:        j['user_id'] as String,
        propertyId:    j['property_id'] as String,
        provider:      j['provider'] as String,
        accountNumber: j['account_number'] as String?,
        serviceType:   j['service_type'] as String,
        isActive:      j['is_active'] as bool? ?? true,
      );
}
