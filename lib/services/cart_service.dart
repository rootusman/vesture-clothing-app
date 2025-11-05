import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String productId;
  final int quantity;

  const CartItem({required this.productId, required this.quantity});

  CartItem copyWith({String? productId, int? quantity}) => CartItem(
        productId: productId ?? this.productId,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        quantity: (json['quantity'] as num).toInt(),
      );
}

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  static const String _key = 'cart_v1';

  final ValueNotifier<List<CartItem>> cartListenable = ValueNotifier<List<CartItem>>(<CartItem>[]);

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final String? raw = _prefs!.getString(_key);
    if (raw != null) {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      cartListenable.value = decoded.map((dynamic e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  List<CartItem> get items => List<CartItem>.unmodifiable(cartListenable.value);

  Future<void> add(String productId, {int quantity = 1}) async {
    final List<CartItem> current = List<CartItem>.from(cartListenable.value);
    final int idx = current.indexWhere((CartItem i) => i.productId == productId);
    if (idx >= 0) {
      final CartItem updated = current[idx].copyWith(quantity: current[idx].quantity + quantity);
      current[idx] = updated;
    } else {
      current.add(CartItem(productId: productId, quantity: quantity));
    }
    cartListenable.value = current;
    await _persist();
  }

  Future<void> setQuantity(String productId, int quantity) async {
    final List<CartItem> current = List<CartItem>.from(cartListenable.value);
    final int idx = current.indexWhere((CartItem i) => i.productId == productId);
    if (idx >= 0) {
      if (quantity <= 0) {
        current.removeAt(idx);
      } else {
        current[idx] = current[idx].copyWith(quantity: quantity);
      }
      cartListenable.value = current;
      await _persist();
    }
  }

  Future<void> remove(String productId) async {
    final List<CartItem> current = cartListenable.value.where((CartItem i) => i.productId != productId).toList();
    cartListenable.value = current;
    await _persist();
  }

  Future<void> clear() async {
    cartListenable.value = <CartItem>[];
    await _persist();
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    final String raw = jsonEncode(cartListenable.value.map((CartItem i) => i.toJson()).toList());
    await _prefs!.setString(_key, raw);
  }
}
