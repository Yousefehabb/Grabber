import 'package:flutter_test/flutter_test.dart';
import 'package:grabber_app/features/basket/domain/entities/basket_item.dart';
import 'package:grabber_app/features/home/data/catalog_repository.dart';

void main() {
  test('catalog prices convert to exact cents and scale by quantity', () {
    final banana = CatalogRepository.products.first;
    final basketItem = BasketItem(product: banana, quantity: 2);

    expect(basketItem.unitPriceCents, 399);
    expect(basketItem.lineSubtotalCents, 798);
  });

  test('unsupported price formats are rejected safely', () {
    expect(BasketItem.parsePriceToCents('3.99'), 399);
    expect(BasketItem.parsePriceToCents('3'), 300);
    expect(BasketItem.parsePriceToCents(r'$3.99'), isNull);
    expect(BasketItem.parsePriceToCents('3,99'), isNull);
    expect(BasketItem.parsePriceToCents('1.999'), isNull);
    expect(BasketItem.parsePriceToCents('-1.00'), isNull);
    expect(BasketItem.parsePriceToCents('unknown'), isNull);
  });
}
