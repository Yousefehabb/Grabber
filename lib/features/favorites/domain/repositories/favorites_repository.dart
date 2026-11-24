import 'package:grabber_app/features/favorites/domain/errors/favorites_failure.dart';

/// Contract for reading and changing the signed-in user's favorite product IDs.
abstract interface class FavoritesRepository {
  /// Loads the owner's saved product IDs from the server.
  ///
  /// Throws [FavoritesFailure] when the request or saved data is invalid.
  Future<Set<String>> getFavoriteProductIds(String uid);

  /// Saves a product ID as a favorite for [uid].
  Future<void> addFavorite({required String uid, required String productId});

  /// Removes a product ID from [uid]'s favorites without affecting the catalog.
  Future<void> removeFavorite({required String uid, required String productId});
}
