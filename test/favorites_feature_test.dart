import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grabber_app/app/main_navigation_screen.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/errors/auth_failure.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/favorites/domain/errors/favorites_failure.dart';
import 'package:grabber_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:grabber_app/features/favorites/presentation/widgets/favorite_button.dart';
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';

void main() {
  testWidgets(
    'Favorites uses catalog data, hides missing products, and shares removals',
    (tester) async {
      final authRepository = _FakeAuthRepository();
      addTearDown(authRepository.dispose);
      final favoritesRepository = _FakeFavoritesRepository()
        ..favoritesByUid['shopper'] = {'banana', 'removed-product'}
        ..removeGate = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: _mainNavigation(
            authRepository: authRepository,
            favoritesRepository: favoritesRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _selectTab(tester, 'Favorites');
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('\$ 3.99'), findsOneWidget);
      expect(find.text('removed-product'), findsNothing);
      expect(find.byType(FavoriteButton), findsOneWidget);
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(
        (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        2,
      );

      await tester.tap(find.byTooltip('Remove Banana from favorites'));
      await tester.pump();
      expect(find.text('Your favorites will appear here'), findsOneWidget);
      expect(favoritesRepository.removeCalls, 1);

      favoritesRepository.removeGate!.complete();
      await tester.pumpAndSettle();
      await _selectTab(tester, 'Categories');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fruits'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Add Banana to favorites'), findsOneWidget);
    },
  );

  testWidgets(
    'failed optimistic writes roll back and repeated taps are blocked',
    (tester) async {
      final authRepository = _FakeAuthRepository();
      addTearDown(authRepository.dispose);
      final favoritesRepository = _FakeFavoritesRepository()
        ..addGate = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: _mainNavigation(
            authRepository: authRepository,
            favoritesRepository: favoritesRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _selectTab(tester, 'Categories');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fruits'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add Orange to favorites'));
      await tester.pump();
      expect(find.byTooltip('Remove Orange from favorites'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove Orange from favorites'));
      expect(favoritesRepository.addCalls, 1);

      favoritesRepository.addGate!.completeError(
        const FavoritesFailure(code: 'unavailable', operation: 'add-favorite'),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Add Orange to favorites'), findsOneWidget);
      expect(
        find.text('Favorites need an internet connection. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'switching accounts clears the previous Favorites while loading',
    (tester) async {
      final authRepository = _FakeAuthRepository();
      addTearDown(authRepository.dispose);
      final favoritesRepository = _FakeFavoritesRepository()
        ..favoritesByUid['shopper'] = {'banana'}
        ..pendingReads['another-shopper'] = Completer<Set<String>>();
      await tester.pumpWidget(
        MaterialApp(
          home: _mainNavigation(
            authRepository: authRepository,
            favoritesRepository: favoritesRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _selectTab(tester, 'Favorites');
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsOneWidget);

      authRepository.emit(
        const AuthUser(
          uid: 'another-shopper',
          email: 'another@example.com',
          emailVerified: true,
        ),
      );
      await tester.pump();
      expect(favoritesRepository.readUids, ['shopper', 'another-shopper']);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Banana'), findsNothing);

      favoritesRepository.pendingReads['another-shopper']!.complete({'orange'});
      await tester.pumpAndSettle();
      expect(find.text('Orange'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
    },
  );

  testWidgets('a failed list read shows an error and retry reloads Favorites', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    addTearDown(authRepository.dispose);
    final favoritesRepository = _FakeFavoritesRepository()
      ..readFailures['shopper'] = const FavoritesFailure(
        code: 'network-request-failed',
        operation: 'get-favorites',
      );
    await tester.pumpWidget(
      MaterialApp(
        home: _mainNavigation(
          authRepository: authRepository,
          favoritesRepository: favoritesRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _selectTab(tester, 'Favorites');
    expect(
      find.text(
        'Favorites need an internet connection. Check your connection and retry.',
      ),
      findsOneWidget,
    );

    favoritesRepository
      ..readFailures.remove('shopper')
      ..favoritesByUid['shopper'] = {'banana'};
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsOneWidget);
  });
}

Widget _mainNavigation({
  required _FakeAuthRepository authRepository,
  required _FakeFavoritesRepository favoritesRepository,
}) => MainNavigationScreen(
  uid: 'shopper',
  initialAddress: const DeliveryAddress(
    city: 'Cairo',
    district: 'Nasr City',
    streetName: 'Example Street',
    buildingNumber: '12A',
  ),
  authRepository: authRepository,
  favoritesRepository: favoritesRepository,
  deliveryAddressRepository: _FakeDeliveryAddressRepository(),
);

Future<void> _selectTab(WidgetTester tester, String label) async {
  final navigationBar = find.byType(BottomNavigationBar);
  await tester.tap(
    find.descendant(of: navigationBar, matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

class _FakeFavoritesRepository implements FavoritesRepository {
  final Map<String, Set<String>> favoritesByUid = {};
  final Map<String, Completer<Set<String>>> pendingReads = {};
  final Map<String, Object> readFailures = {};
  final List<String> readUids = [];
  Completer<void>? addGate;
  Completer<void>? removeGate;
  int addCalls = 0;
  int removeCalls = 0;

  @override
  Future<Set<String>> getFavoriteProductIds(String uid) async {
    readUids.add(uid);
    final failure = readFailures[uid];
    if (failure != null) throw failure;
    final pendingRead = pendingReads[uid];
    if (pendingRead != null) return pendingRead.future;
    return Set<String>.of(favoritesByUid[uid] ?? const {});
  }

  @override
  Future<void> addFavorite({
    required String uid,
    required String productId,
  }) async {
    addCalls++;
    final gate = addGate;
    if (gate != null) await gate.future;
    favoritesByUid.putIfAbsent(uid, () => <String>{}).add(productId);
  }

  @override
  Future<void> removeFavorite({
    required String uid,
    required String productId,
  }) async {
    removeCalls++;
    final gate = removeGate;
    if (gate != null) await gate.future;
    favoritesByUid[uid]?.remove(productId);
  }
}

class _FakeAuthRepository implements AuthRepository {
  AuthUser? _currentUser = const AuthUser(
    uid: 'shopper',
    email: 'shopper@example.com',
    emailVerified: true,
  );
  final StreamController<AuthUser?> _changes =
      StreamController<AuthUser?>.broadcast();

  void emit(AuthUser? user) {
    _currentUser = user;
    _changes.add(user);
  }

  Future<void> dispose() => _changes.close();

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _changes.stream;
  }

  @override
  Future<AuthUser?> refreshCurrentUser() async => null;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async => throw const AuthFailure(code: 'unknown', operation: 'sign-in');

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async =>
      throw const AuthFailure(code: 'unknown', operation: 'create-account');

  @override
  Future<void> updateDisplayName(String fullName) async {}

  @override
  Future<void> sendVerificationEmail() async {}

  @override
  Future<void> signOut() async {
    emit(null);
  }
}

class _FakeDeliveryAddressRepository implements DeliveryAddressRepository {
  @override
  Future<DeliveryAddress?> getAddress(String uid) async => null;

  @override
  Future<void> saveAddress({
    required String uid,
    required DeliveryAddress address,
  }) async {}
}
