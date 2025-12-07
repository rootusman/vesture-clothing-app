import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CategoryService extends ChangeNotifier {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal() {
    _loadCategories();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'categories';

  List<String> _categories = ['All'];

  List<String> get categories => List.unmodifiable(_categories);
  ValueListenable<List<String>> get categoriesListenable =>
      _CategoriesNotifier(this);

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();

      if (snapshot.docs.isEmpty) {
        // Initialize with default categories
        await _initializeDefaultCategories();
      } else {
        final List<String> loadedCategories = ['All'];
        for (var doc in snapshot.docs) {
          final name = doc.data()['name'] as String?;
          if (name != null && name != 'All') {
            loadedCategories.add(name);
          }
        }
        _categories = loadedCategories;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // Use default categories on error
      _categories = ['All', 'Men', 'Women', 'Shoes', 'Accessories', 'Sale'];
      notifyListeners();
    }
  }

  Future<void> _initializeDefaultCategories() async {
    final defaultCategories = ['Men', 'Women', 'Shoes', 'Accessories', 'Sale'];
    for (final category in defaultCategories) {
      await _addCategoryToFirestore(category);
    }
    _categories = ['All', ...defaultCategories];
    notifyListeners();
  }

  Future<void> addCategory(String categoryName) async {
    final trimmedName = categoryName.trim();
    if (trimmedName.isEmpty || trimmedName == 'All') {
      throw 'Invalid category name';
    }

    if (_categories.contains(trimmedName)) {
      throw 'Category already exists';
    }

    try {
      await _addCategoryToFirestore(trimmedName);
      _categories = [..._categories, trimmedName];
      notifyListeners();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw 'Permission denied. Please update Firestore security rules to allow category creation. See Firebase Console → Firestore Database → Rules';
      }
      throw 'Failed to add category: ${e.message}';
    }
  }

  Future<void> _addCategoryToFirestore(String categoryName) async {
    try {
      await _firestore.collection(_collectionName).add({
        'name': categoryName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint(
        'Error adding category to Firestore: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryName) async {
    if (categoryName == 'All') {
      throw 'Cannot delete "All" category';
    }

    try {
      // Find and delete the document
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('name', isEqualTo: categoryName)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      _categories = _categories.where((c) => c != categoryName).toList();
      notifyListeners();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw 'Permission denied. Please update Firestore security rules to allow category deletion.';
      }
      throw 'Failed to delete category: ${e.message}';
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }
}

class _CategoriesNotifier extends ValueNotifier<List<String>> {
  _CategoriesNotifier(CategoryService service) : super(service.categories) {
    service.addListener(_update);
    _service = service;
  }

  late final CategoryService _service;

  void _update() {
    value = _service.categories;
  }

  @override
  void dispose() {
    _service.removeListener(_update);
    super.dispose();
  }
}
