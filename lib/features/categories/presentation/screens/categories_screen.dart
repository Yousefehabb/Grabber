// Lists grocery categories and opens their product grids.
import 'package:flutter/material.dart';
import 'package:grabber_app/core/constants/app_colors.dart';
import 'package:grabber_app/core/constants/app_fonts.dart';
import 'package:grabber_app/features/categories/presentation/screens/category_products_screen.dart';
import 'package:grabber_app/features/favorites/presentation/favorites_controller.dart';
import 'package:grabber_app/features/home/data/catalog_repository.dart';
import 'package:grabber_app/features/home/data/models/catalog_models.dart';

/// Shows the grocery departments in a consistent, mobile-friendly card grid.
class CategoriesScreen extends StatelessWidget {
  /// Receives basket callbacks so category products update shared basket state.
  const CategoriesScreen({
    super.key,
    required this.onAddProduct,
    required this.onDecreaseQuantity,
    required this.getQuantity,
    this.favoritesController,
    this.onToggleFavorite,
  });

  final ValueChanged<ProductModel> onAddProduct;
  final ValueChanged<String> onDecreaseQuantity;
  final int Function(String) getQuantity;
  final FavoritesController? favoritesController;
  final ValueChanged<ProductModel>? onToggleFavorite;

  /// Builds the page heading and responsive category cards from local assets.
  @override
  Widget build(BuildContext context) {
    final categories = CatalogRepository.categories;

    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: AppFonts.bebasNeue),
      ),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Categories')),
          body: ColoredBox(
            color: const Color(0xFFF7F9F6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browse categories',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fresh picks and everyday essentials',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(overscroll: false),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      physics: const ClampingScrollPhysics(),
                      itemCount: categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CategoryProductsScreen(
                                  category: category,
                                  onAddProduct: onAddProduct,
                                  onDecreaseQuantity: onDecreaseQuantity,
                                  getQuantity: getQuantity,
                                  favoritesController: favoritesController,
                                  onToggleFavorite: onToggleFavorite,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE7ECE5),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A1E2A1D),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox.expand(
                                      child: Image.asset(
                                        category.image,
                                        fit: BoxFit.cover,
                                        semanticLabel: category.name,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 42,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      category.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppColor.primary,
                                            fontWeight: FontWeight.w600,
                                            height: 1.15,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
