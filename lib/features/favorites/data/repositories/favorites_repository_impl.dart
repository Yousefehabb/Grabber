// Maps Favorites domain operations to the Firestore data source.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grabber_app/features/favorites/data/datasources/firestore_favorites_data_source.dart';
import 'package:grabber_app/features/favorites/domain/errors/favorites_failure.dart';
import 'package:grabber_app/features/favorites/domain/repositories/favorites_repository.dart';

/// Implements the Favorites contract and reports persistence failures safely.
class FavoritesRepositoryImpl implements FavoritesRepository {
  /// Uses the supplied data source or creates one backed by default Firestore.
  FavoritesRepositoryImpl({FirestoreFavoritesDataSource? dataSource})
    : _dataSource = dataSource ?? FirestoreFavoritesDataSource();

  final FirestoreFavoritesDataSource _dataSource;

  /// Loads saved product IDs and maps Firestore or document-format failures.
  @override
  Future<Set<String>> getFavoriteProductIds(String uid) =>
      _run('get-favorites', () => _dataSource.getFavoriteProductIds(uid));

  /// Adds a favorite document for this user's UID and product ID.
  @override
  Future<void> addFavorite({required String uid, required String productId}) =>
      _run(
        'add-favorite',
        () => _dataSource.addFavorite(uid: uid, productId: productId),
      );

  /// Removes a favorite document without deleting catalog or basket data.
  @override
  Future<void> removeFavorite({
    required String uid,
    required String productId,
  }) => _run(
    'remove-favorite',
    () => _dataSource.removeFavorite(uid: uid, productId: productId),
  );

  /// Converts persistence errors to domain failures while preserving stacks.
  Future<T> _run<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on FavoritesFailure {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        FavoritesFailure(code: error.code, operation: operation),
        stackTrace,
      );
    } on ArgumentError catch (_, stackTrace) {
      Error.throwWithStackTrace(
        FavoritesFailure(code: 'invalid-product-id', operation: operation),
        stackTrace,
      );
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        FavoritesFailure(code: 'invalid-data', operation: operation),
        stackTrace,
      );
    } on Object catch (_, stackTrace) {
      Error.throwWithStackTrace(
        FavoritesFailure(code: 'unknown', operation: operation),
        stackTrace,
      );
    }
  }
}
