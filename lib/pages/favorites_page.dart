import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';
import '../services/favorites_service.dart';
import '../services/product_repository.dart';
import '../services/cart_service.dart';
import 'cart_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  ImageProvider _providerFrom(String src) {
    if (src.startsWith('http')) return NetworkImage(src);
    return FileImage(File(src));
  }

  void _showProductDetail(BuildContext context, ProductModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        final List<String> images = p.imageUrls.isNotEmpty
            ? p.imageUrls
            : <String>[p.imageUrl];
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            String selectedSize = '';

            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              expand: false,
              builder: (_, ScrollController controller) {
                return SingleChildScrollView(
                  controller: controller,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: 240,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: PageView.builder(
                              itemCount: images.length,
                              itemBuilder: (BuildContext context, int i) {
                                final String src = images[i];
                                return Image(
                                  image: _providerFrom(src),
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          p.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.brand,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '\$${p.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'High quality, comfortable fit. Perfect for everyday wear. Machine washable. Replace this description with real product details.',
                        ),
                        const SizedBox(height: 20),
                        if (p.sizes.isNotEmpty) ...<Widget>[
                          const Text(
                            'Select Size',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: p.sizes.map((String s) {
                              final bool isSelected = selectedSize == s;
                              return FilterChip(
                                label: Text(s),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setModalState(() {
                                    selectedSize = selected ? s : '';
                                  });
                                },
                                selectedColor: const Color.fromARGB(
                                  255,
                                  116,
                                  226,
                                  25,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Check if size is required and selected
                                  if (p.sizes.isNotEmpty &&
                                      selectedSize.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please select a size'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  await _addToCart(
                                    context,
                                    p,
                                    size: selectedSize,
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.shopping_cart),
                                label: const Text('Add to Cart'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ValueListenableBuilder<Set<String>>(
                              valueListenable:
                                  FavoritesService().favoritesListenable,
                              builder:
                                  (
                                    BuildContext context,
                                    Set<String> favs,
                                    Widget? _,
                                  ) {
                                    final bool fav = favs.contains(p.id);
                                    return OutlinedButton.icon(
                                      onPressed: () =>
                                          FavoritesService().toggle(p.id),
                                      icon: Icon(
                                        fav
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: fav ? Colors.red : null,
                                      ),
                                      label: Text(
                                        fav ? 'Favorited' : 'Favorite',
                                      ),
                                    );
                                  },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _addToCart(
    BuildContext context,
    ProductModel p, {
    String size = '',
  }) async {
    await CartService().add(p.id, quantity: 1, size: size);
    if (!context.mounted) {
      return;
    }
    final String sizeText = size.isNotEmpty ? ' (Size: $size)' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${p.name}$sizeText added to cart'),
        action: SnackBarAction(
          label: 'View cart',
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const CartPage()));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: FavoritesService().favoritesListenable,
        builder: (BuildContext context, Set<String> favIds, Widget? _) {
          final List<ProductModel> products = ProductRepository().products
              .where((ProductModel p) => favIds.contains(p.id))
              .toList();
          if (products.isEmpty) {
            return const Center(child: Text('No favorites yet'));
          }
          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) {
              final ProductModel p = products[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: _providerFrom(p.primaryImage),
                ),
                title: Text(p.name),
                subtitle: Text(p.brand),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => FavoritesService().toggle(p.id),
                ),
                onTap: () => _showProductDetail(context, p),
              );
            },
          );
        },
      ),
    );
  }
}
