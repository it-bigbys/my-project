class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatarInitials;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'Team Member',
  }) : avatarInitials = _getInitials(name);

  static String _getInitials(String name) {
    if (name.trim().isEmpty) return '??';
    try {
      return name
          .trim()
          .split(' ')
          .where((e) => e.isNotEmpty)
          .map((e) => e[0])
          .take(2)
          .join()
          .toUpperCase();
    } catch (_) {
      return '??';
    }
  }

  User copyWith({
    String? name,
    String? email,
    String? role,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}
