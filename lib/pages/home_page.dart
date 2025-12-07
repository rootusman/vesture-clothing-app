import 'package:flutter/material.dart';
import 'dart:io';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/product_repository.dart';
import '../services/cart_service.dart';
import '../services/category_service.dart';
import '../services/favorites_service.dart';
import '../widgets/product_card.dart';
import 'cart_page.dart';
import 'favorites_page.dart';
import 'admin_page.dart';
import 'auth/login_page.dart';
import 'auth/regular_user_signup_page.dart';

import '../models/user_preferences.dart';
import '../services/order_service.dart';
import '../services/user_preferences_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final List<Widget> tabs = <Widget>[
      const HomeTab(),
      const SearchTab(),
      const OrdersTab(),
      const ProfileTab(),
    ];

    return ListenableBuilder(
      listenable: AuthService(),
      builder: (BuildContext context, Widget? _) {
        final bool isOwner = AuthService().isOwner;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: <Widget>[
                const FlutterLogo(size: 30),
                const SizedBox(width: 10),
                const Text('Vesture'),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CartPage()),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    setState(() {});
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  tooltip: 'Cart',
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FavoritesPage(),
                      ),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    setState(() {});
                  },
                  icon: const Icon(Icons.favorite_border),
                  tooltip: 'Favorites',
                ),
                if (isOwner)
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminPage(),
                        ),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      setState(() {});
                    },
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    tooltip: 'Admin',
                  ),
              ],
            ),
            backgroundColor: scheme.primary,
            elevation: 0,
          ),
          body: SafeArea(
            child: IndexedStack(index: selectedIndex, children: tabs),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (int i) => setState(() => selectedIndex = i),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
            selectedItemColor: scheme.primary,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String selectedCategory = 'All';

  ImageProvider _providerFrom(String src) {
    if (src.startsWith('http')) return NetworkImage(src);
    return FileImage(File(src));
  }

  void _showProductDetail(BuildContext context, ProductModel p) {
    String selectedSize = ''; // Move outside StatefulBuilder

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
                                      : null, // Use theme color instead of hardcoded black
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
                                    // Show dialog instead of SnackBar so it appears on top
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text('Size Required'),
                                          content: const Text(
                                            'Please select a size before adding to cart.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                dialogContext,
                                              ).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
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
            // Navigate to cart page
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
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<List<ProductModel>>(
      valueListenable: ProductRepository().productsListenable,
      builder:
          (BuildContext context, List<ProductModel> allProducts, Widget? _) {
            final List<ProductModel> searched = _applySearch(
              allProducts,
              _searchCtrl.text,
            );
            final List<ProductModel> filtered = (selectedCategory == 'All')
                ? searched
                : searched
                      .where(
                        (ProductModel p) =>
                            _productMatchesCategory(p, selectedCategory),
                      )
                      .toList();

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search clothing, brands, styles...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: scheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list),
                        ),
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: CategoryService().categoriesListenable,
                  builder: (context, categories, _) {
                    return SizedBox(
                      height: 56,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (BuildContext context, int idx) {
                          final String cat = categories[idx];
                          final bool active = cat == selectedCategory;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: active,
                            onSelected: (_) =>
                                setState(() => selectedCategory = cat),
                            selectedColor: scheme.primary,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: active ? Colors.white : Colors.black87,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      itemCount: filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.64,
                          ),
                      itemBuilder: (BuildContext context, int index) {
                        final ProductModel p = filtered[index];
                        return ProductCard(
                          product: p,
                          onTap: () => _showProductDetail(context, p),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }

  List<ProductModel> _applySearch(List<ProductModel> products, String query) {
    if (query.trim().isEmpty) return products;
    final String q = query.toLowerCase();
    return products
        .where(
          (ProductModel p) =>
              ('${p.name} ${p.brand}').toLowerCase().contains(q),
        )
        .toList();
  }

  bool _productMatchesCategory(ProductModel p, String category) {
    if (category == 'All') return true;
    return p.category.toLowerCase() == category.toLowerCase() ||
        ('${p.name} ${p.brand}').toLowerCase().contains(category.toLowerCase());
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchCtrl = TextEditingController();

  ImageProvider _providerFrom(String src) {
    if (src.startsWith('http')) return NetworkImage(src);
    return FileImage(File(src));
  }

  void _showProductDetail(BuildContext context, ProductModel p) {
    String selectedSize = ''; // Move outside StatefulBuilder

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
                                      : null, // Use theme color instead of hardcoded black
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
                                    // Show dialog instead of SnackBar so it appears on top
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text('Size Required'),
                                          content: const Text(
                                            'Please select a size before adding to cart.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                dialogContext,
                                              ).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
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
            // Navigate to cart page
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
    return ValueListenableBuilder<List<ProductModel>>(
      valueListenable: ProductRepository().productsListenable,
      builder: (BuildContext context, List<ProductModel> all, Widget? _) {
        final String q = _searchCtrl.text.trim().toLowerCase();
        final List<ProductModel> results = q.isEmpty
            ? all
            : all
                  .where(
                    (ProductModel p) => ('${p.name} ${p.brand} ${p.category}')
                        .toLowerCase()
                        .contains(q),
                  )
                  .toList();
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int i) {
                  final ProductModel p = results[i];
                  final String img = p.primaryImage;
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: _providerFrom(img)),
                    title: Text(p.name),
                    subtitle: Text(
                      '${p.brand} • ${p.category} • \$${p.price.toStringAsFixed(2)}',
                    ),
                    onTap: () => _showProductDetail(context, p),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OrderService().ordersListenable,
      builder: (context, _) {
        final orders = OrderService().orders;
        if (orders.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No orders yet. When you place orders, they will appear here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              child: ExpansionTile(
                title: Text('Order #${order.id.split('_')[0]}'),
                subtitle: Text(
                  '${order.items.length} items • \$${order.totalAmount.toStringAsFixed(2)} • ${order.status}',
                ),
                children: [
                  ...order.items.map(
                    (item) => ListTile(
                      title: Text(item.productName),
                      subtitle: Text(
                        'Size: ${item.size} • Qty: ${item.quantity}',
                      ),
                      trailing: Text('\$${item.price.toStringAsFixed(2)}'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(order.createdAt.toString().split('.')[0]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  final UserPreferencesService _prefsService = UserPreferencesService();
  Map<String, String> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!_authService.isSignedIn) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final data = await _authService.getUserData();
    if (mounted) {
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authService,
      builder: (context, _) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!_authService.isSignedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Sign in to view your profile'),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SignupScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Sign Up'),
                ),
              ],
            ),
          );
        }

        return ValueListenableBuilder<UserPreferences>(
          valueListenable: _prefsService.preferencesListenable,
          builder: (context, prefs, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // User Info
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getUserName(),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        _userData['email'] ??
                            _authService.currentUser?.email ??
                            '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          (_userData['role'] ?? 'User').toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Settings
                _buildSectionHeader(context, 'Appearance'),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Theme'),
                  subtitle: Text(_getThemeLabel(prefs.themeMode)),
                  trailing: DropdownButton<String>(
                    value: prefs.themeMode,
                    underline: const SizedBox(),
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        await _prefsService.updateThemeMode(newValue);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                  ),
                ),

                const Divider(),
                _buildSectionHeader(context, 'Preferences'),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: Switch(
                    value: prefs.notificationsEnabled,
                    onChanged: (bool value) async {
                      await _prefsService.updateNotificationsEnabled(value);
                    },
                  ),
                ),

                const Divider(),
                _buildSectionHeader(context, 'Support'),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Help & Support'),
                        content: const Text(
                          'For assistance, please contact us at:\n\nsupport@vesture.com\n\nOr visit our website for FAQs and guides.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About Us'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About Vesture'),
                        content: const Text(
                          'Vesture - Your Premium Clothing Store\n\nVersion 1.0.0\n\nWe provide high-quality fashion for everyone. Shop the latest trends and timeless classics.\n\n© 2024 Vesture. All rights reserved.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Divider(),
                _buildSectionHeader(context, 'Account'),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () async {
                    await _authService.signOut();
                    if (mounted) {
                      setState(() {
                        _userData = {};
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getUserName() {
    if (_userData['role'] == 'store_owner') {
      return _userData['ownerName'] ?? 'Store Owner';
    }
    final firstName = _userData['firstName'] ?? '';
    final lastName = _userData['lastName'] ?? '';
    if (firstName.isEmpty && lastName.isEmpty) return 'User';
    return '$firstName $lastName'.trim();
  }

  String _getThemeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System';
      default:
        return mode;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
