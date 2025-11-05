import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String id;
  final String email;
  final String password; // demo only
  final String firstName;
  final String lastName;
  final bool isOwner;

  const AuthUser({
    required this.id,
    required this.email,
    required this.password,
    this.firstName = '',
    this.lastName = '',
    this.isOwner = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'isOwner': isOwner,
      };
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        isOwner: json['isOwner'] as bool? ?? false,
      );
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _keyUserId = 'auth_current_user_id_v1';
  static const String _keyUsers = 'auth_users_v1';

  // Demo owner id constant; in real app, get this from backend/auth provider
  static const String storeOwnerId = 'OWNER_12345';

  final ValueNotifier<String?> currentUserIdListenable = ValueNotifier<String?>(null);

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final String? uid = _prefs!.getString(_keyUserId);
    currentUserIdListenable.value = uid;
    // Ensure demo owner exists
    final Map<String, AuthUser> users = await _loadUsers();
    if (!users.values.any((AuthUser u) => u.isOwner)) {
      final AuthUser owner = AuthUser(
        id: storeOwnerId,
        email: 'owner@store.com',
        password: 'owner123',
        firstName: 'Store',
        lastName: 'Owner',
        isOwner: true,
      );
      users[owner.email.toLowerCase()] = owner;
      await _saveUsers(users);
    }
  }

  String? get currentUserId => currentUserIdListenable.value;

  bool get isSignedIn => currentUserId != null;

  bool get isOwner {
    final String? id = currentUserId;
    if (id == null) return false;
    if (id == storeOwnerId) return true;
    final Map<String, AuthUser> users = _cachedUsers;
    return users.values.any((AuthUser u) => u.id == id && u.isOwner);
  }

  Future<void> signInAsOwner() async {
    await _ensurePrefs();
    currentUserIdListenable.value = storeOwnerId;
    await _prefs!.setString(_keyUserId, storeOwnerId);
  }

  Future<void> signIn(String userId) async {
    await _ensurePrefs();
    currentUserIdListenable.value = userId;
    await _prefs!.setString(_keyUserId, userId);
  }

  Future<void> signOut() async {
    await _ensurePrefs();
    currentUserIdListenable.value = null;
    await _prefs!.remove(_keyUserId);
  }

  // Email/password demo APIs
  Map<String, AuthUser> _cachedUsers = <String, AuthUser>{};

  Future<Map<String, AuthUser>> _loadUsers() async {
    await _ensurePrefs();
    final String? raw = _prefs!.getString(_keyUsers);
    if (raw == null) {
      _cachedUsers = <String, AuthUser>{};
      return _cachedUsers;
    }
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    _cachedUsers = map.map((String k, dynamic v) => MapEntry(k, AuthUser.fromJson(v as Map<String, dynamic>)));
    return _cachedUsers;
  }

  Future<void> _saveUsers(Map<String, AuthUser> users) async {
    await _ensurePrefs();
    _cachedUsers = users;
    final String raw = jsonEncode(users.map((String k, AuthUser v) => MapEntry(k, v.toJson())));
    await _prefs!.setString(_keyUsers, raw);
  }

  Future<String> signUp(String email, String password, {String firstName = '', String lastName = '', bool asOwner = false}) async {
    final Map<String, AuthUser> users = await _loadUsers();
    final String key = email.toLowerCase();
    if (users.containsKey(key)) {
      throw Exception('Email already registered');
    }
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final AuthUser user = AuthUser(id: id, email: email, password: password, firstName: firstName, lastName: lastName, isOwner: asOwner);
    users[key] = user;
    await _saveUsers(users);
    await signIn(id);
    return id;
  }

  Future<String> login(String email, String password) async {
    final Map<String, AuthUser> users = await _loadUsers();
    final AuthUser? user = users[email.toLowerCase()];
    if (user == null || user.password != password) {
      throw Exception('Invalid credentials');
    }
    await signIn(user.id);
    return user.id;
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final Map<String, AuthUser> users = await _loadUsers();
    final String key = email.toLowerCase();
    final AuthUser? user = users[key];
    if (user == null) {
      throw Exception('Email not found');
    }
    users[key] = AuthUser(id: user.id, email: user.email, password: newPassword, firstName: user.firstName, lastName: user.lastName, isOwner: user.isOwner);
    await _saveUsers(users);
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
}
