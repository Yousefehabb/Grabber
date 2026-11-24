// Reads and changes favorite IDs in each user's private Firestore subcollection.
import 'package:cloud_firestore/cloud_firestore.dart';

/// Encapsulates the Firestore paths and document format for Favorites.
class FirestoreFavoritesDataSource {
  /// Accepts a Firestore instance for tests; otherwise uses the default app.
  FirestoreFavoritesDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Reads only from the server so cached/offline Favorites are not treated as
  /// a supported result.
  Future<Set<String>> getFavoriteProductIds(String uid) async {
    final snapshot = await _favoritesCollection(
      uid,
    ).get(const GetOptions(source: Source.server));
    final productIds = <String>{};
    for (final document in snapshot.docs) {
      final data = document.data();
      final productId = data['productId'];
      if (productId is! String ||
          productId.trim().isEmpty ||
          productId != document.id ||
          data.keys.toSet().difference({'productId', 'addedAt'}).isNotEmpty ||
          data['addedAt'] is! Timestamp) {
        throw const FormatException('Invalid favorite document.');
      }
      productIds.add(productId);
    }
    return productIds;
  }

  /// Creates a minimal favorite document if it does not already exist.
  ///
  /// A transaction requires a server connection and avoids overwriting an
  /// existing document or its original server timestamp.
  Future<void> addFavorite({
    required String uid,
    required String productId,
  }) async {
    _validateProductId(productId);
    final document = _favoriteDocument(uid, productId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (!snapshot.exists) {
        transaction.set(document, {
          'productId': productId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Deletes only the favorite document, leaving product and basket data alone.
  Future<void> removeFavorite({
    required String uid,
    required String productId,
  }) async {
    _validateProductId(productId);
    final document = _favoriteDocument(uid, productId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      if (snapshot.exists) transaction.delete(document);
    });
  }

  CollectionReference<Map<String, dynamic>> _favoritesCollection(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  DocumentReference<Map<String, dynamic>> _favoriteDocument(
    String uid,
    String productId,
  ) => _favoritesCollection(uid).doc(productId);

  void _validateProductId(String productId) {
    if (productId.trim().isEmpty || productId.contains('/')) {
      throw ArgumentError.value(productId, 'productId', 'is invalid');
    }
  }
}
