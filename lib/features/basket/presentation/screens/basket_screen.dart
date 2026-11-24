import 'package:flutter/material.dart';
import 'package:grabber_app/features/basket/domain/entities/basket_item.dart';
import 'package:grabber_app/features/home/data/models/catalog_models.dart';

/// Displays the live in-memory basket and forwards product changes to its owner.
class BasketScreen extends StatefulWidget {
  /// Uses the parent's basket and callbacks instead of maintaining a duplicate.
  const BasketScreen({
    super.key,
    required this.basketItems,
    required this.totalItemQuantity,
    required this.subtotalCents,
    required this.onAddProduct,
    required this.onDecreaseQuantity,
    required this.onRemoveProduct,
  });

  /// This is the owner's live list; the screen does not keep a second basket.
  final List<BasketItem> basketItems;
  final int Function() totalItemQuantity;
  final int? Function() subtotalCents;
  final ValueChanged<ProductModel> onAddProduct;
  final ValueChanged<String> onDecreaseQuantity;
  final ValueChanged<String> onRemoveProduct;

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  /// Delegates an increment to the basket owner, then refreshes this view.
  void _addProduct(ProductModel product) {
    widget.onAddProduct(product);
    setState(() {});
  }

  /// Delegates a decrement to the basket owner, then refreshes this view.
  void _decreaseQuantity(String productId) {
    widget.onDecreaseQuantity(productId);
    setState(() {});
  }

  /// Delegates removal to the basket owner, then refreshes this view.
  void _removeProduct(String productId) {
    widget.onRemoveProduct(productId);
    setState(() {});
  }

  /// Formats an integer-cent amount for display with two decimal places.
  String _formatCents(int cents) {
    final wholeUnits = cents ~/ 100;
    final fractionalUnits = (cents % 100).toString().padLeft(2, '0');
    return '$wholeUnits.$fractionalUnits';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final basketSubtotal = widget.subtotalCents();

    return Scaffold(
      appBar: AppBar(title: const Text('Basket')),
      body: widget.basketItems.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your basket is empty',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add products to see them here.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.basketItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = widget.basketItems[index];
                      final unitPriceCents = item.unitPriceCents;
                      final lineSubtotalCents = item.lineSubtotalCents;

                      return Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey.shade50,
                                  padding: const EdgeInsets.all(6),
                                  child: Image.asset(
                                    item.product.image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip:
                                              'Remove ${item.product.name}',
                                          onPressed: () =>
                                              _removeProduct(item.product.id),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      unitPriceCents == null
                                          ? 'Unit price unavailable'
                                          : 'Unit price: \$ ${item.product.price}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip:
                                              'Decrease ${item.product.name} quantity',
                                          onPressed: () => _decreaseQuantity(
                                            item.product.id,
                                          ),
                                          icon: const Icon(Icons.remove),
                                        ),
                                        Text(
                                          item.quantity.toString(),
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        IconButton(
                                          tooltip:
                                              'Increase ${item.product.name} quantity',
                                          onPressed: () =>
                                              _addProduct(item.product),
                                          icon: const Icon(Icons.add),
                                        ),
                                        const Spacer(),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Line subtotal',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                            Text(
                                              lineSubtotalCents == null
                                                  ? 'Unavailable'
                                                  : '\$ ${_formatCents(lineSubtotalCents)}',
                                              style: theme.textTheme.titleSmall,
                                            ),
                                          ],
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
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Items'),
                            Text(widget.totalItemQuantity().toString()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              basketSubtotal == null
                                  ? 'Unavailable'
                                  : '\$ ${_formatCents(basketSubtotal)}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
