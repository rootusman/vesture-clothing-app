import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_repository.dart';
import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  ImageProvider _providerFrom(String src) {
    if (src.startsWith('http')) return NetworkImage(src);
    return FileImage(File(src));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: CartService().cartListenable,
            builder: (context, items, _) {
              if (items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear Cart',
                onPressed: () => _showClearCartDialog(context),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartService().cartListenable,
        builder: (BuildContext context, List<CartItem> items, Widget? _) {
          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }
          final Map<String, ProductModel> idToProduct = {
            for (final ProductModel p in ProductRepository().products) p.id: p,
          };
          double total = 0;
          for (final CartItem ci in items) {
            final ProductModel? p = idToProduct[ci.productId];
            if (p != null) total += p.price * ci.quantity;
          }
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int i) {
                    final CartItem ci = items[i];
                    final ProductModel? p = idToProduct[ci.productId];
                    if (p == null) return const SizedBox.shrink();
                    final String sizeText = ci.size.isNotEmpty
                        ? ' • Size: ${ci.size}'
                        : '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: _providerFrom(p.primaryImage),
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                        '\$${p.price.toStringAsFixed(2)} x ${ci.quantity}$sizeText',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Remove item button
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            tooltip: 'Remove item',
                            onPressed: () =>
                                _showRemoveItemDialog(context, p, ci.size),
                          ),
                          const SizedBox(width: 8),
                          // Decrease quantity
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => CartService().setQuantity(
                              p.id,
                              ci.quantity - 1,
                              size: ci.size,
                            ),
                          ),
                          Text(ci.quantity.toString()),
                          // Increase quantity
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => CartService().setQuantity(
                              p.id,
                              ci.quantity + 1,
                              size: ci.size,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Total: \$${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    FilledButton(
                      onPressed: items.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => CheckoutPage(
                                    cartItems: items,
                                    total: total,
                                  ),
                                ),
                              );
                            },
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRemoveItemDialog(
    BuildContext context,
    ProductModel product,
    String size,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text(
            'Remove ${product.name}${size.isNotEmpty ? " (Size: $size)" : ""} from cart?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                CartService().remove(product.id, size: size);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} removed from cart')),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text(
            'Are you sure you want to remove all items from your cart?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await CartService().clearCart();
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cart cleared')));
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
