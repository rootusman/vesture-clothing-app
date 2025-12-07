import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';
import '../services/favorites_service.dart';
import '../services/cart_service.dart';
import '../pages/cart_page.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});

  ImageProvider _providerFrom(String src) {
    if (src.startsWith('http')) return NetworkImage(src);
    return FileImage(File(src));
  }

  Future<void> _addToCart(BuildContext context, ProductModel p) async {
    // If product has sizes, show size selection dialog
    if (p.sizes.isNotEmpty) {
      final String? selectedSize = await showDialog<String>(
        context: context,
        builder: (BuildContext ctx) {
          String? tempSize;
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: const Text('Select Size'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Please select a size for ${p.name}'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: p.sizes.map((String s) {
                        final bool isSelected = tempSize == s;
                        return FilterChip(
                          label: Text(s),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              tempSize = selected ? s : null;
                            });
                          },
                          selectedColor: const Color.fromARGB(
                            255,
                            116,
                            226,
                            25,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(null),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (tempSize != null) {
                        Navigator.of(ctx).pop(tempSize);
                      }
                    },
                    child: const Text('Add to Cart'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selectedSize == null) return; // User cancelled

      await CartService().add(p.id, quantity: 1, size: selectedSize);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} (Size: $selectedSize) added to cart'),
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
    } else {
      // No sizes, add directly
      await CartService().add(p.id, quantity: 1);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} added to cart'),
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
  }

  @override
  Widget build(BuildContext context) {
    final String priceText = '\$${product.price.toStringAsFixed(2)}';
    final String img = product.primaryImage;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image(image: _providerFrom(img), fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ValueListenableBuilder<Set<String>>(
                        valueListenable: FavoritesService().favoritesListenable,
                        builder:
                            (
                              BuildContext context,
                              Set<String> favIds,
                              Widget? _,
                            ) {
                              final bool fav = favIds.contains(product.id);
                              return CircleAvatar(
                                backgroundColor: Colors.white70,
                                child: IconButton(
                                  onPressed: () =>
                                      FavoritesService().toggle(product.id),
                                  icon: Icon(
                                    fav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 18,
                                    color: fav ? Colors.red : null,
                                  ),
                                ),
                              );
                            },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        priceText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => _addToCart(context, product),
                        icon: const Icon(Icons.add_shopping_cart_outlined),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
