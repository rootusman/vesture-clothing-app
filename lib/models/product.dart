class ProductModel {
  final String id;
  final String name;
  final String brand;
  final double price;
  // Backward-compat single image
  final String imageUrl;
  // New: multiple images (file paths or URLs)
  final List<String> sizes;
  final String category;
  final int stock;
  final List<String> imageUrls;
  final bool isFavorite;

  const ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    this.imageUrls = const <String>[],
    this.sizes = const <String>[],
    this.isFavorite = false,
  });

  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : imageUrl;

  ProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    double? price,
    String? imageUrl,
    List<String>? imageUrls,
    String? category,
    int? stock,
    List<String>? sizes,
    bool? isFavorite,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      sizes: sizes ?? this.sizes,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? imgs = json['imageUrls'] as List<dynamic>?;
    final List<String> parsedImages = imgs != null
        ? imgs.map((dynamic e) => e as String).toList()
        : <String>[];

    final List<dynamic>? sz = json['sizes'] as List<dynamic>?;
    final List<String> parsedSizes = sz != null
        ? sz.map((dynamic e) => e as String).toList()
        : <String>[];

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl:
          json['imageUrl'] as String? ??
          (parsedImages.isNotEmpty ? parsedImages.first : ''),
      imageUrls: parsedImages,
      category: json['category'] as String? ?? 'All',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      sizes: parsedSizes,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'category': category,
      'stock': stock,
      'sizes': sizes,
      'isFavorite': isFavorite,
    };
  }
}
