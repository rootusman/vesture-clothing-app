import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_preferences.dart';

class UserPreferencesService {
  static final UserPreferencesService _instance =
      UserPreferencesService._internal();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ValueNotifier<UserPreferences> preferencesListenable =
      ValueNotifier<UserPreferences>(const UserPreferences());

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadPreferences(user.uid);
      } else {
        preferencesListenable.value = const UserPreferences();
      }
    });

    // Load initial preferences if user is signed in
    if (_auth.currentUser != null) {
      await _loadPreferences(_auth.currentUser!.uid);
    }
  }

  Future<void> _loadPreferences(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('settings')
          .get();

      if (doc.exists) {
        preferencesListenable.value = UserPreferences.fromJson(doc.data()!);
      } else {
        // Create default preferences
        preferencesListenable.value = const UserPreferences();
        await savePreferences(preferencesListenable.value);
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      preferencesListenable.value = const UserPreferences();
    }
  }

  UserPreferences get preferences => preferencesListenable.value;

  Future<void> savePreferences(UserPreferences prefs) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Cannot save preferences: User not signed in');
      return;
    }

    try {
      debugPrint('Saving preferences: ${prefs.toJson()}');
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('settings')
          .set(prefs.toJson());

      preferencesListenable.value = prefs;
      debugPrint('Preferences saved and notified successfully');
    } catch (e) {
      debugPrint('Error saving preferences: $e');
      rethrow;
    }
  }

  Future<void> updateThemeMode(String themeMode) async {
    debugPrint('Updating theme mode to: $themeMode');
    final updated = preferences.copyWith(themeMode: themeMode);
    await savePreferences(updated);
    debugPrint('Theme mode updated successfully');
  }

  Future<void> updateLanguage(String language) async {
    final updated = preferences.copyWith(language: language);
    await savePreferences(updated);
  }

  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? orderUpdates,
  }) async {
    final updated = preferences.copyWith(
      notificationsEnabled: notificationsEnabled,
      emailNotifications: emailNotifications,
      pushNotifications: pushNotifications,
      orderUpdates: orderUpdates,
    );
    await savePreferences(updated);
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    debugPrint('Updating notifications enabled to: $enabled');
    await updateNotificationSettings(notificationsEnabled: enabled);
    debugPrint('Notifications enabled updated successfully');
  }
}
