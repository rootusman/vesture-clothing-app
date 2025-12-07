import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ValueNotifier<List<OrderModel>> ordersListenable =
      ValueNotifier<List<OrderModel>>(<OrderModel>[]);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToOrders(user.uid);
      } else {
        ordersListenable.value = <OrderModel>[];
      }
    });

    // Load initial orders if user is signed in
    if (_auth.currentUser != null) {
      _listenToOrders(_auth.currentUser!.uid);
    }
  }

  void _listenToOrders(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final List<OrderModel> orders = snapshot.docs
              .map((doc) {
                try {
                  return OrderModel.fromJson(doc.data());
                } catch (e) {
                  debugPrint('Error parsing order ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<OrderModel>()
              .toList();

          ordersListenable.value = orders;
        });
  }

  List<OrderModel> get orders =>
      List<OrderModel>.unmodifiable(ordersListenable.value);

  Future<String> createOrder({
    required List<OrderItem> items,
    required double totalAmount,
    required double shippingCost,
    required String shippingAddress,
    String? paymentMethod,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'User not signed in';
    }

    try {
      final String orderId =
          '${DateTime.now().millisecondsSinceEpoch}_${user.uid}';
      final order = OrderModel(
        id: orderId,
        userId: user.uid,
        items: items,
        totalAmount: totalAmount,
        shippingCost: shippingCost,
        status: 'pending',
        createdAt: DateTime.now(),
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .set(order.toJson());

      return orderId;
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .update({'status': status});
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        return OrderModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }
}
