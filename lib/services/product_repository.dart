import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class ProductRepository {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal();

  static const String _storageKey = 'products_v1';

  final ValueNotifier<List<ProductModel>> productsListenable = ValueNotifier<List<ProductModel>>(<ProductModel>[]);

  SharedPreferences? _prefs;

  Future<void> init({List<ProductModel>? seed}) async {
    _prefs ??= await SharedPreferences.getInstance();
    final String? raw = _prefs!.getString(_storageKey);
    if (raw == null) {
      final List<ProductModel> initial = seed ?? <ProductModel>[];
      productsListenable.value = initial;
      await _persist();
    } else {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final List<ProductModel> loaded = decoded.map((dynamic item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
      productsListenable.value = loaded;
    }
  }

  List<ProductModel> get products => List<ProductModel>.unmodifiable(productsListenable.value);

  Future<void> addProduct(ProductModel product) async {
    final List<ProductModel> next = List<ProductModel>.from(productsListenable.value)..add(product);
    productsListenable.value = next;
    await _persist();
  }

  Future<void> updateProduct(String id, ProductModel updated) async {
    final List<ProductModel> next = productsListenable.value.map((ProductModel p) => p.id == id ? updated : p).toList();
    productsListenable.value = next;
    await _persist();
  }

  Future<void> deleteProduct(String id) async {
    final List<ProductModel> next = productsListenable.value.where((ProductModel p) => p.id != id).toList();
    productsListenable.value = next;
    await _persist();
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    final String raw = jsonEncode(productsListenable.value.map((ProductModel p) => p.toJson()).toList());
    await _prefs!.setString(_storageKey, raw);
  }
}
