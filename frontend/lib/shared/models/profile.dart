// profile.dart
// -------------
// Public user profile (mirrors public.profiles Supabase table).

class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
  });

  final String id;
  final String username;  // @handle
  final String name;      // display name
  final String email;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id:       j['id'] as String,
        username: j['username'] as String,
        name:     j['name'] as String,
        email:    j['email'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id':       id,
        'username': username,
        'name':     name,
        'email':    email,
      };

  @override
  bool operator ==(Object other) =>
      other is Profile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
