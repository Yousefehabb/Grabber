// Provides the reusable heart control used on product cards.
import 'package:flutter/material.dart';

/// Shows and toggles one product's shared favorite state.
class FavoriteButton extends StatelessWidget {
  /// Receives the current state and parent-owned action for this product.
  const FavoriteButton({
    required this.productName,
    required this.isFavorite,
    required this.isPending,
    required this.onPressed,
    super.key,
  });

  final String productName;
  final bool isFavorite;
  final bool isPending;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: isFavorite
        ? 'Remove $productName from favorites'
        : 'Add $productName to favorites',
    onPressed: isPending ? null : onPressed,
    icon: Icon(
      isFavorite ? Icons.favorite : Icons.favorite_border,
      color: isFavorite ? Colors.red : Colors.grey.shade700,
    ),
  );
}
