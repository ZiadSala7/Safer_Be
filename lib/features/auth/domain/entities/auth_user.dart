class AuthUser {
  const AuthUser({
    required this.name,
    required this.email,
    this.phone = '',
    this.pushNotificationConsent = false,
    this.pushNotificationConsentAt,
    this.marketingConsent = false,
    this.marketingConsentAt,
  });

  final String name;
  final String email;
  final String phone;
  final bool pushNotificationConsent;
  final String? pushNotificationConsentAt;
  final bool marketingConsent;
  final String? marketingConsentAt;

  AuthUser copyWith({
    String? name,
    String? email,
    String? phone,
    bool? pushNotificationConsent,
    String? pushNotificationConsentAt,
    bool? marketingConsent,
    String? marketingConsentAt,
  }) {
    return AuthUser(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      pushNotificationConsent:
          pushNotificationConsent ?? this.pushNotificationConsent,
      pushNotificationConsentAt:
          pushNotificationConsentAt ?? this.pushNotificationConsentAt,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      marketingConsentAt: marketingConsentAt ?? this.marketingConsentAt,
    );
  }
}
