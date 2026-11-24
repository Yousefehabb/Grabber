// Shows products for one category and delegates basket changes to its parent.
import 'package:flutter/material.dart';
import 'package:grabber_app/features/favorites/presentation/favorites_controller.dart';
import 'package:grabber_app/features/home/data/catalog_repository.dart';
import 'package:grabber_app/features/home/data/models/catalog_models.dart';
import 'package:grabber_app/features/home/presentation/widgets/product_item.dart';

class CategoryProductsScreen extends StatefulWidget {
  /// Uses the selected category and shared basket callbacks from navigation.
  const CategoryProductsScreen({
    super.key,
    required this.category,
    required this.onAddProduct,
    required this.onDecreaseQuantity,
    required this.getQuantity,
    this.favoritesController,
    this.onToggleFavorite,
  });

  final CategoryModel category;
  final ValueChanged<ProductModel> onAddProduct;
  final ValueChanged<String> onDecreaseQuantity;
  final int Function(String) getQuantity;
  final FavoritesController? favoritesController;
  final ValueChanged<ProductModel>? onToggleFavorite;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  @override
  void initState() {
    super.initState();
    widget.favoritesController?.addListener(_onFavoritesChanged);
  }

  @override
  void didUpdateWidget(covariant CategoryProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.favoritesController != widget.favoritesController) {
      oldWidget.favoritesController?.removeListener(_onFavoritesChanged);
      widget.favoritesController?.addListener(_onFavoritesChanged);
    }
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.favoritesController?.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = CatalogRepository.productsForCategory(widget.category.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: products.isEmpty
          ? const Center(child: Text('No products in this category yet.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductItem(
                  image: product.image,
                  name: product.name,
                  rate: product.rate,
                  rateCount: product.rateCount,
                  price: product.price,
                  quantity: widget.getQuantity(product.id),
                  isFavorite:
                      widget.favoritesController?.isFavorite(product.id) ??
                      false,
                  isFavoritePending:
                      widget.favoritesController == null ||
                      !widget.favoritesController!.canToggle ||
                      widget.favoritesController!.isPending(product.id),
                  onToggleFavorite: widget.favoritesController == null
                      ? null
                      : () => widget.onToggleFavorite?.call(product),
                  onAdd: () {
                    widget.onAddProduct(product);
                    setState(() {});
                  },
                  onDecrease: () {
                    widget.onDecreaseQuantity(product.id);
                    setState(() {});
                  },
                );
              },
            ),
    );
  }
}
