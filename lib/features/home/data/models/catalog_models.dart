/// Lightweight local models for catalog categories and products.
class CategoryModel {
  final String id;
  final String name;
  final String image;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
  });
}

/// Catalog product details used by category grids and the in-memory basket.
class ProductModel {
  final String id;
  final String categoryId;
  final String name;
  final String image;
  final String price;
  final String rate;
  final String rateCount;

  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.image,
    required this.price,
    required this.rate,
    required this.rateCount,
  });
}
