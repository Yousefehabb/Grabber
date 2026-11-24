/// A safe description of a Favorites operation failure.
class FavoritesFailure implements Exception {
  const FavoritesFailure({required this.code, required this.operation});

  final String code;
  final String operation;
}
