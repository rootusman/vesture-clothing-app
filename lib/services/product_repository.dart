import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductRepository {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ValueNotifier<List<ProductModel>> productsListenable =
      ValueNotifier<List<ProductModel>>(<ProductModel>[]);

  bool _initialized = false;

  Future<void> init({List<ProductModel>? seed}) async {
    if (_initialized) return;
    _initialized = true;

    // Listen to products collection in real-time
    _firestore.collection('products').snapshots().listen((snapshot) {
      final List<ProductModel> products = snapshot.docs
          .map((doc) {
            try {
              return ProductModel.fromJson({'id': doc.id, ...doc.data()});
            } catch (e) {
              debugPrint('Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ProductModel>()
          .toList();

      productsListenable.value = products;
    });

    // If seed data provided and collection is empty, add it
    if (seed != null && seed.isNotEmpty) {
      final snapshot = await _firestore.collection('products').limit(1).get();
      if (snapshot.docs.isEmpty) {
        for (final product in seed) {
          await addProduct(product);
        }
      }
    }
  }

  List<ProductModel> get products =>
      List<ProductModel>.unmodifiable(productsListenable.value);

  Future<void> addProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toJson());
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String id, ProductModel updated) async {
    try {
      await _firestore.collection('products').doc(id).update(updated.toJson());
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  Future<ProductModel?> getProduct(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (doc.exists) {
        return ProductModel.fromJson({'id': doc.id, ...doc.data()!});
      }
    } catch (e) {
      debugPrint('Error getting product: $e');
    }
    return null;
  }
}
