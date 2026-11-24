import 'package:flutter/material.dart';
import 'package:grabber_app/features/home/data/home_categories_data.dart';

/// Renders the horizontally scrolling category shortcuts on Home.
class HomeCategoriesSection extends StatelessWidget {
  /// Receives the locally configured categories to display.
  const HomeCategoriesSection({
    super.key,
    required this.categories,
  });

  final List<HomeCategory> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  width: 70,
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Image.asset(
                      category.image,
                      width: 50,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
