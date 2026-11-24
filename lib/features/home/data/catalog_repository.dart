// Provides the local category and product catalog used by shopping screens.
import 'package:grabber_app/features/home/data/models/catalog_models.dart';

/// Provides lookup methods over the static catalog data in this repository.
class CatalogRepository {
  static const categories = <CategoryModel>[
    CategoryModel(
      id: 'vegetables',
      name: 'Vegetables',
      image: 'assets/category_images/vegetables.jpg',
    ),
    CategoryModel(
      id: 'fruits',
      name: 'Fruits',
      image: 'assets/category_images/fruits.jpg',
    ),
    CategoryModel(
      id: 'eggs_dairy_essentials',
      name: 'Eggs & Dairy Essentials',
      image: 'assets/category_images/eggs_dairy_essentials.jpg',
    ),
    CategoryModel(
      id: 'yogurts',
      name: 'Yogurts',
      image: 'assets/category_images/yogurts.jpg',
    ),
    CategoryModel(
      id: 'hummus_salads',
      name: 'Hummus & Salads',
      image: 'assets/category_images/hummus_salads.jpg',
    ),
    CategoryModel(
      id: 'cheese',
      name: 'Cheese',
      image: 'assets/category_images/cheese.jpg',
    ),
    CategoryModel(
      id: 'dairy_alternatives',
      name: 'Dairy Alternatives',
      image: 'assets/category_images/dairy_alternatives.jpg',
    ),
    CategoryModel(
      id: 'delis_meat_shop',
      name: "Deli's Meat Shop",
      image: 'assets/category_images/delis_meat_shop.jpg',
    ),
  ];

  static const products = <ProductModel>[
    ProductModel(
      id: 'banana',
      categoryId: 'fruits',
      name: 'Banana',
      image: 'assets/fruits/banana.png',
      price: '3.99',
      rate: '4',
      rateCount: '287',
    ),
    ProductModel(
      id: 'papper',
      categoryId: 'fruits',
      name: 'Papper',
      image: 'assets/fruits/papper.png',
      price: '2.99',
      rate: '4',
      rateCount: '287',
    ),
    ProductModel(
      id: 'orange',
      categoryId: 'fruits',
      name: 'Orange',
      image: 'assets/fruits/orange.png',
      price: '1.99',
      rate: '4',
      rateCount: '287',
    ),
    ProductModel(
      id: 'egg',
      categoryId: 'eggs_dairy_essentials',
      name: 'Egg',
      image: 'assets/category/egg.png',
      price: '1.99',
      rate: '4',
      rateCount: '287',
    ),
  ];

  /// Finds a configured category by its stable identifier.
  static CategoryModel? categoryById(String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  /// Returns local products for a known category, or an empty list otherwise.
  static List<ProductModel> productsForCategory(String categoryId) {
    if (categoryById(categoryId) == null) return const [];
    return products
        .where((product) => product.categoryId == categoryId)
        .toList(growable: false);
  }
}
