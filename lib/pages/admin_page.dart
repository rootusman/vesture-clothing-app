import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../models/shipping_settings.dart';
import '../services/auth_service.dart';
import '../services/product_repository.dart';
import '../services/shipping_service.dart';
import '../services/category_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  ImageProvider _providerFrom(String src) {
    if (src.isEmpty) {
      return const AssetImage(
        'assets/placeholder.png',
      ); // Or any valid placeholder
    }
    if (src.startsWith('http')) return NetworkImage(src);
    return FileImage(File(src));
  }

  String _genId() {
    final Random r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}_${r.nextInt(1 << 32)}';
  }

  void _openCategoryManagement(BuildContext context) async {
    final categoryController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Manage Categories'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add category section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'New Category',
                          border: OutlineInputBorder(),
                          hintText: 'Enter category name',
                        ),
                        onSubmitted: (value) async {
                          final name = value.trim();
                          if (name.isEmpty) return;

                          try {
                            await CategoryService().addCategory(name);
                            categoryController.clear();
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Added "$name"')),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        final name = categoryController.text.trim();
                        if (name.isEmpty) return;

                        try {
                          await CategoryService().addCategory(name);
                          categoryController.clear();
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Added "$name"')),
                            );
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Categories list
                Flexible(
                  child: ValueListenableBuilder<List<String>>(
                    valueListenable: CategoryService().categoriesListenable,
                    builder: (context, categories, _) {
                      final editableCategories = categories
                          .where((c) => c != 'All')
                          .toList();

                      if (editableCategories.isEmpty) {
                        return const Center(child: Text('No categories yet'));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: editableCategories.length,
                        itemBuilder: (context, index) {
                          final category = editableCategories[index];
                          return ListTile(
                            leading: const Icon(Icons.category),
                            title: Text(category),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Category?'),
                                    content: Text(
                                      'Are you sure you want to delete "$category"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await CategoryService().deleteCategory(
                                      category,
                                    );
                                  } catch (e) {
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(
                                        dialogContext,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openShippingSettings(BuildContext context) async {
    final currentSettings = ShippingService().settings;
    bool isFreeShipping = currentSettings.isFreeShipping;
    double shippingCost = currentSettings.shippingCost;
    final costController = TextEditingController(
      text: shippingCost.toStringAsFixed(2),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Shipping Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Free Shipping'),
                    subtitle: const Text('Enable free shipping for all orders'),
                    value: isFreeShipping,
                    onChanged: (value) {
                      setDialogState(() {
                        isFreeShipping = value;
                      });
                    },
                  ),
                  if (!isFreeShipping) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: costController,
                      decoration: const InputDecoration(
                        labelText: 'Shipping Cost (\$)',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final cost = double.tryParse(costController.text) ?? 0.0;
                    final newSettings = ShippingSettings(
                      isFreeShipping: isFreeShipping,
                      shippingCost: cost,
                    );
                    await ShippingService().updateSettings(newSettings);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shipping settings updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI-only gating using local AuthService
    if (!AuthService().isOwner) {
      return const Scaffold(body: Center(child: Text('Access denied')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Products'),
        actions: <Widget>[
          IconButton(
            onPressed: () => _openCategoryManagement(context),
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
          ),
          IconButton(
            onPressed: () => _openShippingSettings(context),
            icon: const Icon(Icons.local_shipping_outlined),
            tooltip: 'Shipping Settings',
          ),
          IconButton(
            onPressed: () => _openCreateOrEdit(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add product',
          ),
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
                subtitle: Text(
                  '${p.brand}  •  ${p.category}  •  ${p.price.toStringAsFixed(2)}  •  stock ${p.stock}',
                ),
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
                              content: Text(
                                'Are you sure you want to delete ${p.name}?',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
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

  Future<void> _openCreateOrEdit(
    BuildContext context, {
    ProductModel? product,
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController(
      text: product?.name ?? '',
    );
    final TextEditingController brandCtrl = TextEditingController(
      text: product?.brand ?? '',
    );
    final TextEditingController priceCtrl = TextEditingController(
      text: product != null ? product.price.toString() : '',
    );
    final TextEditingController imageCtrl = TextEditingController(
      text: product?.imageUrl ?? '',
    );
    final TextEditingController categoryCtrl = TextEditingController(
      text: product?.category ?? 'All',
    );
    final TextEditingController stockCtrl = TextEditingController(
      text: product != null ? product.stock.toString() : '0',
    );

    final List<String> pickedImages = List<String>.from(
      product?.imageUrls ?? <String>[],
    );
    final List<String> selectedSizes = List<String>.from(
      product?.sizes ?? <String>[],
    );
    final List<String> allSizes = <String>['S', 'M', 'L', 'XL', 'XXL'];

    final ProductModel? result = await showModalBottomSheet<ProductModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder:
                (
                  BuildContext ctx,
                  void Function(void Function()) setSheetState,
                ) {
                  Future<void> pickFromGallery() async {
                    final ImagePicker picker = ImagePicker();
                    final List<XFile> files = await picker.pickMultiImage(
                      imageQuality: 85,
                    );
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
                            Text(
                              product == null ? 'Add Product' : 'Edit Product',
                              style: Theme.of(ctx).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                              ),
                              validator: (String? v) =>
                                  (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            TextFormField(
                              controller: brandCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Brand',
                              ),
                              validator: (String? v) =>
                                  (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                            TextFormField(
                              controller: priceCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (String? v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                final double? parsed = double.tryParse(v);
                                if (parsed == null) return 'Invalid number';
                                if (parsed < 0) return 'Must be >= 0';
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: imageCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Primary Image URL (optional)',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                FilledButton.icon(
                                  onPressed: pickFromGallery,
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
                                  label: const Text('Add images from gallery'),
                                ),
                                const SizedBox(width: 12),
                                if (pickedImages.isNotEmpty)
                                  Text('${pickedImages.length} selected'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (pickedImages.isNotEmpty)
                              SizedBox(
                                height: 90,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: pickedImages.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (BuildContext _, int i) {
                                    final String src = pickedImages[i];
                                    return Stack(
                                      children: <Widget>[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
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
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                            ),
                            TextFormField(
                              controller: stockCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Stock',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (String? v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                final int? parsed = int.tryParse(v);
                                if (parsed == null) return 'Invalid number';
                                if (parsed < 0) return 'Must be >= 0';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Sizes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Wrap(
                              spacing: 8,
                              children: allSizes.map((String s) {
                                final bool isSelected = selectedSizes.contains(
                                  s,
                                );
                                return FilterChip(
                                  label: Text(s),
                                  selected: isSelected,
                                  onSelected: (bool v) {
                                    setSheetState(() {
                                      if (v) {
                                        selectedSizes.add(s);
                                      } else {
                                        selectedSizes.remove(s);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop<ProductModel>(null),
                                  child: const Text('Cancel'),
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed: () {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    final List<String> images = pickedImages;
                                    final String primaryUrl = imageCtrl.text
                                        .trim();
                                    final List<String> finalImages = <String>[
                                      ...images,
                                    ];
                                    if (finalImages.isEmpty &&
                                        primaryUrl.isNotEmpty) {
                                      finalImages.add(primaryUrl);
                                    }
                                    final ProductModel built = ProductModel(
                                      id: product?.id ?? _genId(),
                                      name: nameCtrl.text.trim(),
                                      brand: brandCtrl.text.trim(),
                                      price: double.parse(
                                        priceCtrl.text.trim(),
                                      ),
                                      imageUrl: primaryUrl.isNotEmpty
                                          ? primaryUrl
                                          : (finalImages.isNotEmpty
                                                ? finalImages.first
                                                : ''),
                                      imageUrls: finalImages,
                                      category: categoryCtrl.text.trim().isEmpty
                                          ? 'All'
                                          : categoryCtrl.text.trim(),
                                      stock: int.parse(stockCtrl.text.trim()),
                                      sizes: selectedSizes,
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
