class UserPreferences {
  final String themeMode; // 'light', 'dark', 'system'
  final String language; // 'en', 'es', 'fr', etc.
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool orderUpdates;

  const UserPreferences({
    this.themeMode = 'system',
    this.language = 'en',
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.orderUpdates = true,
  });

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode,
    'language': language,
    'notificationsEnabled': notificationsEnabled,
    'emailNotifications': emailNotifications,
    'pushNotifications': pushNotifications,
    'orderUpdates': orderUpdates,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      themeMode: json['themeMode'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      orderUpdates: json['orderUpdates'] as bool? ?? true,
    );
  }

  UserPreferences copyWith({
    String? themeMode,
    String? language,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? orderUpdates,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      orderUpdates: orderUpdates ?? this.orderUpdates,
    );
  }
}
