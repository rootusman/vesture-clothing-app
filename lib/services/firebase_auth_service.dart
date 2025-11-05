import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ValueNotifier<User?> currentUserListenable = ValueNotifier<User?>(null);

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> init() async {
    currentUserListenable.value = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      currentUserListenable.value = user;
    });
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool get isOwner {
    final User? user = currentUser;
    if (user == null) return false;
    // Check role from Firestore (async, but for synchronous check we'll use a cached value)
    // In production, you'd want to cache this or make it async
    return false; // Will be updated based on user role
  }

  Future<void> signIn(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      currentUserListenable.value = result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  Future<void> signUpRegularUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'role': 'regular_user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        currentUserListenable.value = user;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  Future<void> signUpStoreOwner({
    required String email,
    required String password,
    required String ownerName,
    required String storeName,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'ownerName': ownerName,
          'storeName': storeName,
          'email': email,
          'role': 'store_owner',
          'createdAt': FieldValue.serverTimestamp(),
        });
        currentUserListenable.value = user;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    currentUserListenable.value = null;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

