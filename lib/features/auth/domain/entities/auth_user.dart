class AuthUser {
  const AuthUser({
    required this.name,
    required this.email,
    this.phone = '',
  });

  final String name;
  final String email;
  final String phone;

  AuthUser copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return AuthUser(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
