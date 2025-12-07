import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartItem {
  final String productId;
  final int quantity;
  final String size; // Added size field

  const CartItem({
    required this.productId,
    required this.quantity,
    this.size = '',
  });

  CartItem copyWith({String? productId, int? quantity, String? size}) =>
      CartItem(
        productId: productId ?? this.productId,
        quantity: quantity ?? this.quantity,
        size: size ?? this.size,
      );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'size': size,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] as String,
    quantity: (json['quantity'] as num).toInt(),
    size: json['size'] as String? ?? '',
  );
}

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ValueNotifier<List<CartItem>> cartListenable =
      ValueNotifier<List<CartItem>>(<CartItem>[]);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToCart(user.uid);
      } else {
        cartListenable.value = <CartItem>[];
      }
    });

    // Load initial cart if user is signed in
    if (_auth.currentUser != null) {
      _listenToCart(_auth.currentUser!.uid);
    }
  }

  void _listenToCart(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
          final List<CartItem> items = snapshot.docs
              .map((doc) {
                try {
                  return CartItem.fromJson(doc.data());
                } catch (e) {
                  debugPrint('Error parsing cart item ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<CartItem>()
              .toList();

          cartListenable.value = items;
        });
  }

  List<CartItem> get items => List<CartItem>.unmodifiable(cartListenable.value);

  String _getDocId(String productId, String size) => '${productId}_$size';

  Future<void> add(
    String productId, {
    int quantity = 1,
    String size = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('User not signed in, cannot add to cart');
      return;
    }

    try {
      final String docId = _getDocId(productId, size);
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(docId);

      final doc = await docRef.get();
      if (doc.exists) {
        final currentQuantity = (doc.data()?['quantity'] as num?)?.toInt() ?? 0;
        await docRef.update({'quantity': currentQuantity + quantity});
      } else {
        await docRef.set({
          'productId': productId,
          'quantity': quantity,
          'size': size,
        });
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> setQuantity(
    String productId,
    int quantity, {
    String size = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final String docId = _getDocId(productId, size);
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(docId);

      if (quantity <= 0) {
        await docRef.delete();
      } else {
        await docRef.update({'quantity': quantity});
      }
    } catch (e) {
      debugPrint('Error setting cart quantity: $e');
      rethrow;
    }
  }

  Future<void> remove(String productId, {String size = ''}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final String docId = _getDocId(productId, size);
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }
}
