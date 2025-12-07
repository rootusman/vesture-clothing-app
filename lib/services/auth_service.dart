import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Deprecated: Use AuthService() as a Listenable instead
  final ValueNotifier<String?> currentUserIdListenable = ValueNotifier<String?>(
    null,
  );

  String? _currentUserRole;

  String? get currentUserId => _auth.currentUser?.uid;
  bool get isSignedIn => _auth.currentUser != null;
  bool get isOwner => _currentUserRole == 'store_owner';
  User? get currentUser => _auth.currentUser;

  Future<void> init() async {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      currentUserIdListenable.value = user?.uid;
      if (user != null) {
        // Load user role from Firestore
        await _loadUserRole(user.uid);
      } else {
        _currentUserRole = null;
      }
      notifyListeners();
    });

    // Load initial user if already signed in
    if (_auth.currentUser != null) {
      await _loadUserRole(_auth.currentUser!.uid);
      currentUserIdListenable.value = _auth.currentUser!.uid;
      notifyListeners();
    }
  }

  Future<void> _loadUserRole(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        _currentUserRole = doc.data()?['role'] as String?;
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      if (userCredential.user != null) {
        await _loadUserRole(userCredential.user!.uid);
        currentUserIdListenable.value = userCredential.user!.uid;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on TimeoutException {
      throw 'Connection timed out. Please check your internet.';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? ownerName,
    String? storeName,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;

        // Check if user is authorized admin
        bool isAdmin = await isAuthorizedAdmin(email);
        _currentUserRole = isAdmin ? 'store_owner' : 'regular_user';

        final Map<String, dynamic> userData = {
          'email': email,
          'role': _currentUserRole,
          'firstName': firstName,
          'lastName': lastName,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (ownerName != null) userData['ownerName'] = ownerName;
        if (storeName != null) userData['storeName'] = storeName;

        // Store user data in Firestore
        await _firestore
            .collection('users')
            .doc(uid)
            .set(userData)
            .timeout(const Duration(seconds: 10));

        currentUserIdListenable.value = uid;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on TimeoutException {
      throw 'Connection timed out. Please check your internet.';
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUserRole = null;
    currentUserIdListenable.value = null;
    notifyListeners();
  }

  Future<Map<String, String>> getUserData() async {
    if (_auth.currentUser == null) {
      return {};
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return {
          'userId': _auth.currentUser!.uid,
          'email': data['email'] as String? ?? '',
          'role': data['role'] as String? ?? '',
          'firstName': data['firstName'] as String? ?? '',
          'lastName': data['lastName'] as String? ?? '',
          'ownerName': data['ownerName'] as String? ?? '',
          'storeName': data['storeName'] as String? ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error getting user data: $e');
    }

    return {};
  }

  // Forgot Password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email Verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      }
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
    notifyListeners();
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      // Sign out first to force account picker every time
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // User canceled - don't throw error
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 15));

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;

        // Check if user document exists
        final doc = await _firestore
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 10));
        if (!doc.exists) {
          // Check if user is authorized admin
          bool isAdmin = await isAuthorizedAdmin(
            userCredential.user!.email ?? '',
          );
          String role = isAdmin ? 'store_owner' : 'regular_user';

          // Create user document for first-time Google sign-in
          final displayNameParts =
              userCredential.user!.displayName?.split(' ') ?? ['', ''];
          await _firestore.collection('users').doc(uid).set({
            'email': userCredential.user!.email,
            'role': role,
            'firstName': displayNameParts.isNotEmpty ? displayNameParts[0] : '',
            'lastName': displayNameParts.length > 1
                ? displayNameParts.sublist(1).join(' ')
                : '',
            'createdAt': FieldValue.serverTimestamp(),
            'signInMethod': 'google',
          });
        }

        await _loadUserRole(uid);
        currentUserIdListenable.value = uid;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      // Sign out from Google on Firebase auth errors
      await _googleSignIn.signOut();
      throw _handleAuthException(e);
    } on TimeoutException {
      await _googleSignIn.signOut();
      throw 'Connection timed out. Please check your internet.';
    } catch (e) {
      await _googleSignIn.signOut();
      throw 'Google sign-in failed: $e';
    }
  }

  // Sign up with Google (same as sign in, but explicit for clarity)
  Future<void> signUpWithGoogle() async {
    await signInWithGoogle();
  }

  // Check if email is authorized admin
  Future<bool> isAuthorizedAdmin(String email) async {
    try {
      debugPrint('Checking admin authorization for email: $email');
      final doc = await _firestore
          .collection('admin_config')
          .doc('authorized_admins')
          .get()
          .timeout(const Duration(seconds: 10));

      debugPrint('Admin config document exists: ${doc.exists}');

      if (doc.exists) {
        final data = doc.data();
        debugPrint('Admin config data: $data');

        final List<dynamic>? emails = data?['emails'] as List<dynamic>?;
        debugPrint('Authorized emails list: $emails');

        if (emails != null) {
          final normalizedEmail = email.toLowerCase().trim();
          debugPrint('Normalized email to check: $normalizedEmail');

          final isAuthorized = emails.any(
            (e) => e.toString().toLowerCase().trim() == normalizedEmail,
          );
          debugPrint('Is authorized: $isAuthorized');

          return isAuthorized;
        } else {
          debugPrint('No emails array found in admin config');
        }
      } else {
        debugPrint('Admin config document does not exist');
      }
      return false;
    } catch (e) {
      debugPrint('Error checking admin authorization: $e');
      return false;
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Login method not enabled. Please enable Email/Password and Google Sign-In in Firebase Console → Authentication → Sign-in method.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
