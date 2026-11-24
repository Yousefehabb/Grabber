// Represents one product line and quantity in the in-memory basket.
import 'package:grabber_app/features/home/data/models/catalog_models.dart';

/// A product line in the in-memory basket, with price parsing kept centralized.
class BasketItem {
  const BasketItem({required this.product, required this.quantity})
    : assert(quantity > 0);

  final ProductModel product;
  final int quantity;

  int? get unitPriceCents => parsePriceToCents(product.price);

  int? get lineSubtotalCents {
    final unitPrice = unitPriceCents;
    return unitPrice == null ? null : unitPrice * quantity;
  }

  BasketItem withQuantity(int value) =>
      BasketItem(product: product, quantity: value);

  /// Supports plain non-negative decimal prices with up to two fractional digits.
  static int? parsePriceToCents(String price) {
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(price)) return null;

    final parts = price.split('.');
    final wholeUnits = int.tryParse(parts.first);
    final fractionalUnits = parts.length == 1
        ? 0
        : int.tryParse(parts[1].padRight(2, '0'));
    if (wholeUnits == null || fractionalUnits == null) return null;

    return wholeUnits * 100 + fractionalUnits;
  }
}
