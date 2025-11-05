import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';

import 'models/product.dart';
import 'services/product_repository.dart';
import 'services/auth_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/favorites_service.dart';
import 'services/cart_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/signup_selection_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase - Note: You need to add firebase_options.dart file
  // Run: flutterfire configure
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // If Firebase is not configured, the app will still work with local auth
    debugPrint('Firebase not initialized: $e');
  }
  // Initialize services
  await FirebaseAuthService().init();
  await AuthService().init(); // Keep old service for backward compatibility
  await FavoritesService().init();
  await CartService().init();
  // Seed with initial demo products on first launch
  final List<ProductModel> seed = <ProductModel>[
    ProductModel(
      id: _genId(),
      name: 'Casual Tee',
      brand: 'Vesture',
      price: 24.99,
      imageUrl: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=800',
      imageUrls: const <String>[],
      category: 'Men',
      stock: 50,
    ),
    ProductModel(
      id: _genId(),
      name: 'Denim Jacket',
      brand: 'Vesture',
      price: 79.99,
      imageUrl: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=801',
      imageUrls: const <String>[],
      category: 'Women',
      stock: 30,
    ),
    ProductModel(
      id: _genId(),
      name: 'Running Shoes',
      brand: 'Stride',
      price: 59.99,
      imageUrl: 'https://images.unsplash.com/photo-1519741491517-9d7eea80e7b4?w=800',
      imageUrls: const <String>[],
      category: 'Shoes',
      stock: 100,
    ),
    ProductModel(
      id: _genId(),
      name: 'Summer Dress',
      brand: 'Bloom',
      price: 49.99,
      imageUrl: 'https://images.unsplash.com/photo-1520975914400-05a0f4c5d0a1?w=800',
      imageUrls: const <String>[],
      category: 'Women',
      stock: 40,
    ),
    ProductModel(
      id: _genId(),
      name: 'Classic Cap',
      brand: 'Headway',
      price: 14.99,
      imageUrl: 'https://images.unsplash.com/photo-1520975914400-05a0f4c5d0a1?w=801',
      imageUrls: const <String>[],
      category: 'Accessories',
      stock: 70,
    ),
    ProductModel(
      id: _genId(),
      name: 'Leather Bag',
      brand: 'Urban',
      price: 129.99,
      imageUrl: 'https://images.unsplash.com/photo-1519741491517-9d7eea80e7b4?w=801',
      imageUrls: const <String>[],
      category: 'Accessories',
      stock: 25,
    ),
  ];
  await ProductRepository().init(seed: seed);
  runApp(const VestureApp());
}

String _genId() {
  final Random r = Random();
  return '${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(1 << 32)}';
}

ImageProvider _providerFrom(String src) {
  if (src.startsWith('http')) return NetworkImage(src);
  return FileImage(File(src));
}

class VestureApp extends StatelessWidget {
  const VestureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vesture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 116, 226, 25)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

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

    return ValueListenableBuilder<dynamic>(
      valueListenable: FirebaseAuthService().currentUserListenable,
      builder: (BuildContext context, dynamic firebaseUser, Widget? _) {
        return ValueListenableBuilder<String?>(
          valueListenable: AuthService().currentUserIdListenable,
          builder: (BuildContext context, String? uid, Widget? _) {
            final bool isOwner = AuthService().isOwner || 
              (firebaseUser != null && firebaseUser.email?.contains('owner') == true);
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
                    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CartPage()));
                    setState(() {});
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  tooltip: 'Cart',
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FavoritesPage()));
                    setState(() {});
                  },
                  icon: const Icon(Icons.favorite_border),
                  tooltip: 'Favorites',
                ),
                if (isOwner)
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminPage()));
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
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Orders'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
            selectedItemColor: scheme.primary,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
            );
          },
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
  final List<String> categories = <String>['All', 'Men', 'Women', 'Shoes', 'Accessories', 'Sale'];
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<List<ProductModel>>(
      valueListenable: ProductRepository().productsListenable,
      builder: (BuildContext context, List<ProductModel> allProducts, Widget? _) {
        final List<ProductModel> searched = _applySearch(allProducts, _searchCtrl.text);
        final List<ProductModel> filtered = (selectedCategory == 'All')
            ? searched
            : searched.where((ProductModel p) => _productMatchesCategory(p, selectedCategory)).toList();

        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      color: scheme.secondary.withOpacity(0.1),
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
            SizedBox(
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
                    onSelected: (_) => setState(() => selectedCategory = cat),
                    selectedColor: scheme.primary,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: active ? Colors.white : Colors.black87,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    return products.where((ProductModel p) => ('${p.name} ${p.brand}').toLowerCase().contains(q)).toList();
  }

  bool _productMatchesCategory(ProductModel p, String category) {
    if (category == 'All') return true;
    return p.category.toLowerCase() == category.toLowerCase() || ('${p.name} ${p.brand}').toLowerCase().contains(category.toLowerCase());
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ProductModel>>(
      valueListenable: ProductRepository().productsListenable,
      builder: (BuildContext context, List<ProductModel> all, Widget? _) {
        final String q = _searchCtrl.text.trim().toLowerCase();
        final List<ProductModel> results = q.isEmpty
            ? all
            : all.where((ProductModel p) => ('${p.name} ${p.brand} ${p.category}').toLowerCase().contains(q)).toList();
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
                    subtitle: Text('${p.brand} • ${p.category} • \$${p.price.toStringAsFixed(2)}'),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No orders yet. When users place orders, they will appear here.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<dynamic>(
      valueListenable: FirebaseAuthService().currentUserListenable,
      builder: (BuildContext context, dynamic firebaseUser, Widget? _) {
        // Fallback to old auth service if Firebase not available
        final bool hasFirebaseUser = firebaseUser != null;
        final String? uid = hasFirebaseUser ? firebaseUser.uid : null;
        
        return ValueListenableBuilder<String?>(
          valueListenable: AuthService().currentUserIdListenable,
          builder: (BuildContext context, String? oldUid, Widget? _) {
            final bool isLoggedIn = hasFirebaseUser || oldUid != null;
            final bool isOwner = AuthService().isOwner || (hasFirebaseUser && firebaseUser.email?.contains('owner') == true);
            
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          !isLoggedIn 
                            ? 'Guest' 
                            : hasFirebaseUser 
                              ? 'User: ${firebaseUser.email ?? uid}' 
                              : 'User: $oldUid',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!isLoggedIn) ...<Widget>[
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                      ),
                      icon: const Icon(Icons.login),
                      label: const Text('Login'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const SignupSelectionScreen()),
                      ),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Sign Up'),
                    ),
                  ] else ...<Widget>[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(isOwner ? 'Store Owner' : 'Regular User'),
                      subtitle: Text(isOwner ? 'Admin tools are visible in the app bar.' : 'Admin tools hidden.'),
                      leading: Icon(isOwner ? Icons.verified : Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (hasFirebaseUser) {
                          await FirebaseAuthService().signOut();
                        } else {
                          await AuthService().signOut();
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

void _showProductDetail(BuildContext context, ProductModel p) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (BuildContext ctx) {
      final List<String> images = p.imageUrls.isNotEmpty ? p.imageUrls : <String>[p.imageUrl];
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
                  Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(p.brand, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 12),
                  Text('\$${p.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'High quality, comfortable fit. Perfect for everyday wear. Machine washable. Replace this description with real product details.'),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _addToCart(context, p);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Add to Cart'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ValueListenableBuilder<Set<String>>(
                        valueListenable: FavoritesService().favoritesListenable,
                        builder: (BuildContext context, Set<String> favs, Widget? _) {
                          final bool fav = favs.contains(p.id);
                          return OutlinedButton.icon(
                            onPressed: () => FavoritesService().toggle(p.id),
                            icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? Colors.red : null),
                            label: Text(fav ? 'Favorited' : 'Favorite'),
                          );
                        },
                      )
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
}

Future<void> _addToCart(BuildContext context, ProductModel p) async {

  await CartService().add(p.id, quantity: 1);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${p.name} added to cart'),
      action: SnackBarAction(
        label: 'View cart',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CartPage()),
          );
        },
      ),
    ),
  );
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});

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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image(
                      image: _providerFrom(img),
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ValueListenableBuilder<Set<String>>(
                        valueListenable: FavoritesService().favoritesListenable,
                        builder: (BuildContext context, Set<String> favIds, Widget? _) {
                          final bool fav = favIds.contains(product.id);
                          return CircleAvatar(
                            backgroundColor: Colors.white70,
                            child: IconButton(
                              onPressed: () => FavoritesService().toggle(product.id),
                              icon: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 18, color: fav ? Colors.red : null),
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
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(product.brand, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(priceText, style: const TextStyle(fontWeight: FontWeight.bold)),
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

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    // Gate admin access here as a second line of defense
    final dynamic firebaseUser = FirebaseAuthService().currentUser;
    final bool isOwner = AuthService().isOwner || 
      (firebaseUser != null && firebaseUser.email?.contains('owner') == true);
    
    if (!isOwner) {
      return const Scaffold(
        body: Center(child: Text('Access denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Products'),
        actions: <Widget>[
          IconButton(
            onPressed: () => _openCreateOrEdit(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add product',
          )
        ],
      ),
      body: ValueListenableBuilder<List<ProductModel>>(
        valueListenable: ProductRepository().productsListenable,
        builder: (BuildContext context, List<ProductModel> products, Widget? _) {
          if (products.isEmpty) {
            return const Center(child: Text('No products. Tap + to add.'));
          }
          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final ProductModel p = products[index];
              final String img = p.primaryImage;
              return ListTile(
                leading: CircleAvatar(backgroundImage: _providerFrom(img)),
                title: Text(p.name),
                subtitle: Text('${p.brand}  •  ${p.category}  •  ${p.price.toStringAsFixed(2)}  •  stock ${p.stock}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openCreateOrEdit(context, product: p),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Delete product?'),
                              content: Text('Are you sure you want to delete ${p.name}?'),
                              actions: <Widget>[
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            );
                          },
                        );
                        if (confirm == true) {
                          await ProductRepository().deleteProduct(p.id);
                        }
                      },
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openCreateOrEdit(BuildContext context, {ProductModel? product}) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController(text: product?.name ?? '');
    final TextEditingController brandCtrl = TextEditingController(text: product?.brand ?? '');
    final TextEditingController priceCtrl = TextEditingController(text: product != null ? product.price.toString() : '');
    final TextEditingController imageCtrl = TextEditingController(text: product?.imageUrl ?? '');
    final TextEditingController categoryCtrl = TextEditingController(text: product?.category ?? 'All');
    final TextEditingController stockCtrl = TextEditingController(text: product != null ? product.stock.toString() : '0');

    final List<String> pickedImages = List<String>.from(product?.imageUrls ?? <String>[]);

    final ProductModel? result = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (BuildContext ctx, void Function(void Function()) setSheetState) {
              Future<void> pickFromGallery() async {
                final ImagePicker picker = ImagePicker();
                final List<XFile> files = await picker.pickMultiImage(imageQuality: 85);
                if (files.isNotEmpty) {
                  setSheetState(() {
                    pickedImages.addAll(files.map((XFile f) => f.path));
                  });
                }
              }

              void removeAt(int idx) {
                setSheetState(() {
                  pickedImages.removeAt(idx);
                });
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(product == null ? 'Add Product' : 'Edit Product', style: Theme.of(ctx).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: brandCtrl,
                          decoration: const InputDecoration(labelText: 'Brand'),
                          validator: (String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: priceCtrl,
                          decoration: const InputDecoration(labelText: 'Price'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (String? v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final double? parsed = double.tryParse(v);
                            if (parsed == null) return 'Invalid number';
                            if (parsed < 0) return 'Must be >= 0';
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: imageCtrl,
                          decoration: const InputDecoration(labelText: 'Primary Image URL (optional)'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: pickFromGallery,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Add images from gallery'),
                            ),
                            const SizedBox(width: 12),
                            if (pickedImages.isNotEmpty) Text('${pickedImages.length} selected'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (pickedImages.isNotEmpty)
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: pickedImages.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (BuildContext _, int i) {
                                final String src = pickedImages[i];
                                return Stack(
                                  children: <Widget>[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image(
                                        image: _providerFrom(src),
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: InkWell(
                                        onTap: () => removeAt(i),
                                        child: Container(
                                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: categoryCtrl,
                          decoration: const InputDecoration(labelText: 'Category'),
                        ),
                        TextFormField(
                          controller: stockCtrl,
                          decoration: const InputDecoration(labelText: 'Stock'),
                          keyboardType: TextInputType.number,
                          validator: (String? v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final int? parsed = int.tryParse(v);
                            if (parsed == null) return 'Invalid number';
                            if (parsed < 0) return 'Must be >= 0';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop<ProductModel>(null),
                              child: const Text('Cancel'),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) return;
                                final List<String> images = pickedImages;
                                final String primaryUrl = imageCtrl.text.trim();
                                final List<String> finalImages = <String>[...images];
                                if (finalImages.isEmpty && primaryUrl.isNotEmpty) {
                                  finalImages.add(primaryUrl);
                                }
                                final ProductModel built = ProductModel(
                                  id: product?.id ?? _genId(),
                                  name: nameCtrl.text.trim(),
                                  brand: brandCtrl.text.trim(),
                                  price: double.parse(priceCtrl.text.trim()),
                                  imageUrl: primaryUrl.isNotEmpty ? primaryUrl : (finalImages.isNotEmpty ? finalImages.first : ''),
                                  imageUrls: finalImages,
                                  category: categoryCtrl.text.trim().isEmpty ? 'All' : categoryCtrl.text.trim(),
                                  stock: int.parse(stockCtrl.text.trim()),
                                  isFavorite: product?.isFavorite ?? false,
                                );
                                Navigator.of(ctx).pop<ProductModel>(built);
                              },
                              child: Text(product == null ? 'Add' : 'Save'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (result != null) {
      if (product == null) {
        await ProductRepository().addProduct(result);
      } else {
        await ProductRepository().updateProduct(product.id, result);
      }
    }
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: FavoritesService().favoritesListenable,
        builder: (BuildContext context, Set<String> favIds, Widget? _) {
          final List<ProductModel> products = ProductRepository()
              .products
              .where((ProductModel p) => favIds.contains(p.id))
              .toList();
          if (products.isEmpty) return const Center(child: Text('No favorites yet'));
          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) {
              final ProductModel p = products[i];
              return ListTile(
                leading: CircleAvatar(backgroundImage: _providerFrom(p.primaryImage)),
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

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartService().cartListenable,
        builder: (BuildContext context, List<CartItem> items, Widget? _) {
          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }
          final Map<String, ProductModel> idToProduct = {
            for (final ProductModel p in ProductRepository().products) p.id: p
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
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: _providerFrom(p.primaryImage)),
                      title: Text(p.name),
                      subtitle: Text('\$${p.price.toStringAsFixed(2)} x ${ci.quantity}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => CartService().setQuantity(p.id, ci.quantity - 1),
                          ),
                          Text(ci.quantity.toString()),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => CartService().setQuantity(p.id, ci.quantity + 1),
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
                    Expanded(child: Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout is not implemented')));
                      },
                      child: const Text('Checkout'),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
