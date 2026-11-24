/// Static category shortcuts shown in the Home screen's horizontal row.
class HomeCategory {
  const HomeCategory({
    required this.name,
    required this.image,
  });

  final String name;
  final String image;
}

const homeCategories = <HomeCategory>[
  HomeCategory(
    name: 'Fruits',
    image: 'assets/category/fruits.png',
  ),
  HomeCategory(
    name: 'Milk & Egg',
    image: 'assets/category/egg.png',
  ),
  HomeCategory(
    name: 'Bavergas',
    image: 'assets/category/bavergas.png',
  ),
  HomeCategory(
    name: 'luandry',
    image: 'assets/category/luandry.png',
  ),
  HomeCategory(
    name: 'luandry',
    image: 'assets/category/luandry.png',
  ),

];
