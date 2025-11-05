import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ValueNotifier<String?> currentUserIdListenable = ValueNotifier<String?>(null);
  
  String? _currentUserId;
  String? _currentUserRole;

  String? get currentUserId => _currentUserId;
  bool get isSignedIn => _currentUserId != null;
  bool get isOwner => _currentUserRole == 'store_owner';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    _currentUserRole = prefs.getString('userRole');
    currentUserIdListenable.value = _currentUserId;
  }

  Future<void> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUserId = email.split('@')[0];
    _currentUserRole = email.toLowerCase().contains('owner') ? 'store_owner' : 'regular_user';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _currentUserId!);
    await prefs.setString('userRole', _currentUserRole!);
    
    currentUserIdListenable.value = _currentUserId;
  }

  Future<void> signUpRegularUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUserId = email.split('@')[0];
    _currentUserRole = 'regular_user';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _currentUserId!);
    await prefs.setString('userRole', _currentUserRole!);
    await prefs.setString('firstName', firstName);
    await prefs.setString('lastName', lastName);
    
    currentUserIdListenable.value = _currentUserId;
  }

  Future<void> signUpStoreOwner({
    required String email,
    required String password,
    required String ownerName,
    required String storeName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUserId = email.split('@')[0];
    _currentUserRole = 'store_owner';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', _currentUserId!);
    await prefs.setString('userRole', _currentUserRole!);
    await prefs.setString('ownerName', ownerName);
    await prefs.setString('storeName', storeName);
    
    currentUserIdListenable.value = _currentUserId;
  }

  Future<void> signOut() async {
    _currentUserId = null;
    _currentUserRole = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userRole');
    
    currentUserIdListenable.value = null;
  }

  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId') ?? '',
      'userRole': prefs.getString('userRole') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'ownerName': prefs.getString('ownerName') ?? '',
      'storeName': prefs.getString('storeName') ?? '',
    };
  }
}