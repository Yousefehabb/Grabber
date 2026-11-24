// Shares a user's favorite IDs across product cards and the Favorites screen.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/favorites/domain/errors/favorites_failure.dart';
import 'package:grabber_app/features/favorites/domain/repositories/favorites_repository.dart';

/// Owns loading, account changes, and optimistic Favorites updates.
class FavoritesController extends ChangeNotifier {
  /// Starts loading [initialUid]'s list and follows later Auth identity changes.
  FavoritesController({
    required FavoritesRepository repository,
    AuthRepository? authRepository,
    required String initialUid,
  }) : _repository = repository,
       _activeUid = initialUid {
    unawaited(_loadFavorites(initialUid));
    _authSubscription = authRepository?.authStateChanges().listen(
      _handleAuthUser,
      onError: (Object _) => _handleAuthFailure(),
    );
  }

  final FavoritesRepository _repository;
  StreamSubscription<AuthUser?>? _authSubscription;
  final Set<String> _favoriteProductIds = {};
  final Map<String, Set<String>> _pendingByUid = {};
  String? _activeUid;
  FavoritesFailure? _loadFailure;
  bool _isLoading = true;
  bool _isDisposed = false;
  int _identityGeneration = 0;
  int _loadGeneration = 0;

  /// Returns a read-only snapshot of the active user's product IDs.
  Set<String> get favoriteProductIds => Set.unmodifiable(_favoriteProductIds);

  /// The current UID, or `null` when the Auth session is signed out.
  String? get activeUid => _activeUid;

  /// True while the first server-backed Favorites read is in progress.
  bool get isLoading => _isLoading;

  /// A safe failure from the latest list read, if one occurred.
  FavoritesFailure? get loadFailure => _loadFailure;

  /// Whether a favorite action can safely be started for the current account.
  bool get canToggle =>
      _activeUid != null && !_isLoading && _loadFailure == null;

  /// Checks the active user's shared favorite state for a product.
  bool isFavorite(String productId) => _favoriteProductIds.contains(productId);

  /// Checks whether a write for this product and active user is pending.
  bool isPending(String productId) =>
      _activeUid != null &&
      (_pendingByUid[_activeUid]?.contains(productId) ?? false);

  /// Re-reads the active user's Favorites from the Firestore server.
  Future<void> retry() async {
    final uid = _activeUid;
    if (uid != null) await _loadFavorites(uid);
  }

  /// Optimistically changes one favorite and restores its prior value on error.
  Future<void> toggleFavorite(String productId) async {
    final uid = _activeUid;
    if (!canToggle || uid == null) return;

    final pendingProductIds = _pendingByUid.putIfAbsent(uid, () => <String>{});
    if (!pendingProductIds.add(productId)) return;

    final generation = _identityGeneration;
    final wasFavorite = _favoriteProductIds.contains(productId);
    if (wasFavorite) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _repository.removeFavorite(uid: uid, productId: productId);
      } else {
        await _repository.addFavorite(uid: uid, productId: productId);
      }
      if (!_isDisposed &&
          _activeUid == uid &&
          generation != _identityGeneration) {
        unawaited(_loadFavorites(uid));
      }
    } on FavoritesFailure {
      final stillActive =
          !_isDisposed &&
          _activeUid == uid &&
          generation == _identityGeneration;
      _restoreFavorite(uid, productId, wasFavorite, generation);
      if (stillActive) rethrow;
    } on Object catch (_, stackTrace) {
      final stillActive =
          !_isDisposed &&
          _activeUid == uid &&
          generation == _identityGeneration;
      _restoreFavorite(uid, productId, wasFavorite, generation);
      if (stillActive) {
        Error.throwWithStackTrace(
          const FavoritesFailure(code: 'unknown', operation: 'update-favorite'),
          stackTrace,
        );
      }
    } finally {
      pendingProductIds.remove(productId);
      if (pendingProductIds.isEmpty) _pendingByUid.remove(uid);
      if (!_isDisposed && _activeUid == uid) notifyListeners();
    }
  }

  void _restoreFavorite(
    String uid,
    String productId,
    bool wasFavorite,
    int generation,
  ) {
    if (_isDisposed || _activeUid != uid || generation != _identityGeneration) {
      return;
    }
    if (wasFavorite) {
      _favoriteProductIds.add(productId);
    } else {
      _favoriteProductIds.remove(productId);
    }
    notifyListeners();
  }

  void _handleAuthUser(AuthUser? user) {
    if (_isDisposed) return;
    final uid = user?.uid;
    if (uid == _activeUid) return;
    _identityGeneration++;
    _activeUid = uid;
    _favoriteProductIds.clear();
    _loadFailure = null;
    _isLoading = uid != null;
    notifyListeners();
    if (uid != null) unawaited(_loadFavorites(uid));
  }

  void _handleAuthFailure() {
    if (_isDisposed) return;
    _identityGeneration++;
    _activeUid = null;
    _favoriteProductIds.clear();
    _isLoading = false;
    _loadFailure = const FavoritesFailure(
      code: 'auth-state-unavailable',
      operation: 'get-favorites',
    );
    notifyListeners();
  }

  Future<void> _loadFavorites(String uid) async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _loadFailure = null;
    notifyListeners();
    try {
      final productIds = await _repository.getFavoriteProductIds(uid);
      if (_isDisposed || generation != _loadGeneration || uid != _activeUid) {
        return;
      }
      _favoriteProductIds
        ..clear()
        ..addAll(productIds);
      _loadFailure = null;
    } on FavoritesFailure catch (failure) {
      if (_isDisposed || generation != _loadGeneration || uid != _activeUid) {
        return;
      }
      _favoriteProductIds.clear();
      _loadFailure = failure;
    } on Object {
      if (_isDisposed || generation != _loadGeneration || uid != _activeUid) {
        return;
      }
      _favoriteProductIds.clear();
      _loadFailure = const FavoritesFailure(
        code: 'unknown',
        operation: 'get-favorites',
      );
    } finally {
      if (!_isDisposed && generation == _loadGeneration && uid == _activeUid) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
