import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ValueNotifier<Set<String>> favoritesListenable =
      ValueNotifier<Set<String>>(<String>{});

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToFavorites(user.uid);
      } else {
        favoritesListenable.value = <String>{};
      }
    });

    // Load initial favorites if user is signed in
    if (_auth.currentUser != null) {
      _listenToFavorites(_auth.currentUser!.uid);
    }
  }

  void _listenToFavorites(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
          final Set<String> ids = snapshot.docs.map((doc) => doc.id).toSet();
          favoritesListenable.value = ids;
        });
  }

  Set<String> get ids => Set<String>.from(favoritesListenable.value);

  bool isFavorite(String productId) =>
      favoritesListenable.value.contains(productId);

  Future<void> toggle(String productId) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('User not signed in, cannot toggle favorite');
      return;
    }

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId);

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'productId': productId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }
}
