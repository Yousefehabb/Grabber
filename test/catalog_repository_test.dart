import 'package:flutter_test/flutter_test.dart';
import 'package:grabber_app/features/home/data/catalog_repository.dart';

void main() {
  test('every catalog product has a unique ID and a valid category', () {
    final productIds = CatalogRepository.products.map((product) => product.id);

    expect(productIds.toSet(), hasLength(CatalogRepository.products.length));
    for (final product in CatalogRepository.products) {
      expect(CatalogRepository.categoryById(product.categoryId), isNotNull);
    }
  });

  test('category filtering returns only matching products', () {
    final fruits = CatalogRepository.productsForCategory('fruits');
    final eggs = CatalogRepository.productsForCategory('eggs_dairy_essentials');

    expect(fruits.map((product) => product.name), [
      'Banana',
      'Papper',
      'Orange',
    ]);
    expect(eggs.map((product) => product.name), ['Egg']);
    expect(fruits.every((product) => product.categoryId == 'fruits'), isTrue);
    expect(
      eggs.every((product) => product.categoryId == 'eggs_dairy_essentials'),
      isTrue,
    );
  });

  test('empty and invalid categories return no products', () {
    expect(CatalogRepository.productsForCategory('vegetables'), isEmpty);
    expect(CatalogRepository.productsForCategory('missing-category'), isEmpty);
    expect(CatalogRepository.categoryById('missing-category'), isNull);
  });
}
