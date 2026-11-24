// Displays the active user's saved products using the current local catalog.
import 'package:flutter/material.dart';
import 'package:grabber_app/core/constants/app_colors.dart';
import 'package:grabber_app/features/favorites/domain/errors/favorites_failure.dart';
import 'package:grabber_app/features/favorites/presentation/favorites_controller.dart';
import 'package:grabber_app/features/home/data/catalog_repository.dart';
import 'package:grabber_app/features/home/data/models/catalog_models.dart';
import 'package:grabber_app/features/home/presentation/widgets/product_item.dart';

/// Shows loading, retryable errors, an empty state, or a two-column product grid.
class FavoritesScreen extends StatelessWidget {
  /// Receives shared Favorites and basket state from the navigation owner.
  const FavoritesScreen({
    required this.favoritesController,
    required this.onToggleFavorite,
    required this.onAddProduct,
    required this.onDecreaseQuantity,
    required this.getQuantity,
    super.key,
  });

  final FavoritesController favoritesController;
  final ValueChanged<ProductModel> onToggleFavorite;
  final ValueChanged<ProductModel> onAddProduct;
  final ValueChanged<String> onDecreaseQuantity;
  final int Function(String) getQuantity;

  @override
  Widget build(BuildContext context) {
    final controller = favoritesController;
    final Widget body;
    if (controller.activeUid == null &&
        controller.loadFailure?.code == 'auth-state-unavailable') {
      body = const _FavoritesMessage(
        icon: Icons.error_outline,
        message: 'Unable to verify your account. Please sign in again.',
      );
    } else if (controller.activeUid == null) {
      body = const _FavoritesMessage(
        icon: Icons.favorite_border,
        message: 'Sign in to view your favorites.',
      );
    } else if (controller.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (controller.loadFailure case final failure?) {
      body = _FavoritesError(
        message: _loadErrorMessage(failure),
        onRetry: controller.retry,
      );
    } else {
      final favoriteIds = controller.favoriteProductIds;
      final products = CatalogRepository.products
          .where((product) => favoriteIds.contains(product.id))
          .toList(growable: false);
      body = products.isEmpty
          ? const _FavoritesMessage(
              icon: Icons.favorite_border,
              message: 'Your favorites will appear here',
            )
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
                  quantity: getQuantity(product.id),
                  isFavorite: controller.isFavorite(product.id),
                  isFavoritePending:
                      !controller.canToggle || controller.isPending(product.id),
                  onToggleFavorite: () => onToggleFavorite(product),
                  onAdd: () => onAddProduct(product),
                  onDecrease: () => onDecreaseQuantity(product.id),
                );
              },
            );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: body,
    );
  }

  String _loadErrorMessage(FavoritesFailure failure) => switch (failure.code) {
    'permission-denied' =>
      'Unable to access your favorites. Check your account permissions.',
    'network-request-failed' || 'unavailable' || 'deadline-exceeded' =>
      'Favorites need an internet connection. Check your connection and retry.',
    'auth-state-unavailable' =>
      'Unable to verify your account. Please sign in again.',
    _ => 'Unable to load your favorites. Please try again.',
  };
}

class _FavoritesMessage extends StatelessWidget {
  const _FavoritesMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: AppColor.primary),
        const SizedBox(height: 12),
        Text(message, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _FavoritesError extends StatelessWidget {
  const _FavoritesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
