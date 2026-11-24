// Displays a product card and delegates quantity changes to its parent.
import 'package:flutter/material.dart';
import 'package:grabber_app/features/favorites/presentation/widgets/favorite_button.dart';

class ProductItem extends StatelessWidget {
  /// Receives display data and callbacks; basket state remains owned upstream.
  const ProductItem({
    super.key,
    required this.image,
    required this.name,
    required this.rate,
    required this.rateCount,
    required this.price,
    required this.quantity,
    required this.isFavorite,
    required this.isFavoritePending,
    required this.onToggleFavorite,
    required this.onAdd,
    required this.onDecrease,
  });
  final String image;
  final String name;
  final String rate;
  final String rateCount;
  final String price;
  final int quantity;
  final bool isFavorite;
  final bool isFavoritePending;
  final VoidCallback? onToggleFavorite;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.4,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(image, fit: BoxFit.contain),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: FavoriteButton(
                      productName: name,
                      isFavorite: isFavorite,
                      isPending: isFavoritePending,
                      onPressed: onToggleFavorite,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: quantity == 0
                        ? IconButton(
                            tooltip: 'Add $name to basket',
                            onPressed: onAdd,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 40,
                              height: 40,
                            ),
                            icon: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.add),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Decrease $name quantity',
                                  onPressed: onDecrease,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 36,
                                    height: 36,
                                  ),
                                  icon: const CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.remove, size: 18),
                                  ),
                                ),
                                Text(
                                  quantity.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Increase $name quantity',
                                  onPressed: onAdd,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 36,
                                    height: 36,
                                  ),
                                  icon: const CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.add, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              '\$ $price',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icons/star.png', width: 16),
                const SizedBox(width: 4),
                Text(
                  '$rate ($rateCount)',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
