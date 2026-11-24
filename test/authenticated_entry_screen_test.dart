import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grabber_app/app/authenticated_entry_screen.dart';
import 'package:grabber_app/app/main_navigation_screen.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';
import 'package:grabber_app/features/profile/domain/entities/user_profile.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:grabber_app/features/profile/presentation/screens/complete_profile_screen.dart';
import 'package:grabber_app/features/profile/presentation/screens/delivery_address_screen.dart';

void main() {
  testWidgets('shows a loading state while checking the address', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository()
      ..pendingRead = Completer<DeliveryAddress?>();
    await tester.pumpWidget(_testApp(repository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.text('Checking your profile and delivery address...'),
      findsOneWidget,
    );
    expect(repository.readCalls, 1);

    repository.pendingRead!.complete(_validAddress);
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);
  });

  testWidgets('an existing address opens MainNavigationScreen', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository()
      ..address = _validAddress;
    final authRepository = _FakeAuthRepository();
    await tester.pumpWidget(
      _testApp(repository, authRepository: authRepository),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(repository.readUids, ['authenticated-user']);
    expect(
      tester
          .widget<MainNavigationScreen>(find.byType(MainNavigationScreen))
          .authRepository,
      same(authRepository),
    );
    expect(
      tester
          .widget<MainNavigationScreen>(find.byType(MainNavigationScreen))
          .deliveryAddressRepository,
      same(repository),
    );
  });

  testWidgets('a missing address opens DeliveryAddressScreen with its inputs', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
    final addressScreen = tester.widget<DeliveryAddressScreen>(
      find.byType(DeliveryAddressScreen),
    );
    expect(addressScreen.uid, 'authenticated-user');
    expect(addressScreen.deliveryAddressRepository, same(repository));
  });

  testWidgets('an invalid saved address remains gated and can be corrected', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository()
      ..readFailures.add(
        const ProfileFailure(code: 'invalid-address', operation: 'get-address'),
      );
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
    expect(
      find.textContaining('Your saved address is incomplete.'),
      findsOneWidget,
    );
    expect(find.text('Update Address'), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
  });

  testWidgets('a missing profile is completed before the address gate', (
    WidgetTester tester,
  ) async {
    final addressRepository = _FakeDeliveryAddressRepository();
    final profileRepository = _FakeUserProfileRepository()..profile = null;
    await tester.pumpWidget(
      _testApp(addressRepository, profileRepository: profileRepository),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CompleteProfileScreen), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), 'Taylor Shopper');
    await tester.enterText(find.byType(TextFormField).at(2), '+201234567890');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Profile and Continue'));
    await tester.pumpAndSettle();

    expect(profileRepository.savedProfile?.uid, 'authenticated-user');
    expect(profileRepository.savedProfile?.email, 'shopper@example.com');
    expect(profileRepository.savedProfile?.fullName, 'Taylor Shopper');
    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
    expect(addressRepository.readUids, ['authenticated-user']);
  });

  testWidgets('a profile read failure retries instead of showing setup', (
    WidgetTester tester,
  ) async {
    final addressRepository = _FakeDeliveryAddressRepository();
    final profileRepository = _FakeUserProfileRepository()
      ..readFailures.add(
        const ProfileFailure(code: 'unavailable', operation: 'get-profile'),
      );
    await tester.pumpWidget(
      _testApp(addressRepository, profileRepository: profileRepository),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to check your profile. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(CompleteProfileScreen), findsNothing);
    expect(find.byType(MainNavigationScreen), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
    expect(profileRepository.readUids, [
      'authenticated-user',
      'authenticated-user',
    ]);
  });

  testWidgets('successful address save proceeds without another read', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository();
    final authRepository = _FakeAuthRepository();
    await tester.pumpWidget(
      _testApp(repository, authRepository: authRepository),
    );
    await tester.pumpAndSettle();
    await _enterValidAddress(tester);
    await tester.ensureVisible(find.text('Save Address'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();

    expect(repository.readCalls, 1);
    expect(repository.saveCalls, 1);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(
      tester
          .widget<MainNavigationScreen>(find.byType(MainNavigationScreen))
          .authRepository,
      same(authRepository),
    );
    expect(
      tester
          .widget<MainNavigationScreen>(find.byType(MainNavigationScreen))
          .deliveryAddressRepository,
      same(repository),
    );
  });

  testWidgets('read failure shows an error without opening the main app', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository()
      ..readFailures.add(Exception('read failed'));
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to check your delivery address. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(find.byType(DeliveryAddressScreen), findsNothing);
  });

  testWidgets('retry after read failure repeats only the address read', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository()
      ..readFailures.add(Exception('read failed'))
      ..address = _validAddress;
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.readCalls, 2);
    expect(repository.readUids, ['authenticated-user', 'authenticated-user']);
    expect(repository.saveCalls, 0);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
  });

  testWidgets('a changed authenticated UID ignores the previous address read', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository()
      ..pendingRead = Completer<DeliveryAddress?>();
    var uid = 'first-user';
    late StateSetter update;

    Widget app() => MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return AuthenticatedEntryScreen(
            uid: uid,
            email: 'shopper@example.com',
            deliveryAddressRepository: repository,
            authRepository: _FakeAuthRepository(),
            profileRepository: _FakeUserProfileRepository(),
          );
        },
      ),
    );

    await tester.pumpWidget(app());
    repository
      ..pendingRead = null
      ..address = _validAddress;
    update(() => uid = 'second-user');
    await tester.pumpAndSettle();

    expect(repository.readUids, ['first-user', 'second-user']);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('Example Street 12A, Nasr City, Cairo'), findsOneWidget);

    repository.readCompleter!.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);
  });

  testWidgets('rebuilding while a read is pending does not duplicate it', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository()
      ..pendingRead = Completer<DeliveryAddress?>();
    late StateSetter rebuild;
    final gate = AuthenticatedEntryScreen(
      uid: 'authenticated-user',
      email: 'shopper@example.com',
      deliveryAddressRepository: repository,
      authRepository: _FakeAuthRepository(),
      profileRepository: _FakeUserProfileRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return gate;
          },
        ),
      ),
    );

    rebuild(() {});
    await tester.pump();
    rebuild(() {});
    await tester.pump();

    expect(repository.readCalls, 1);
    repository.pendingRead!.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
  });
}

const _validAddress = DeliveryAddress(
  city: 'Cairo',
  district: 'Nasr City',
  streetName: 'Example Street',
  buildingNumber: '12A',
);

Widget _testApp(
  _FakeDeliveryAddressRepository repository, {
  AuthRepository? authRepository,
  UserProfileRepository? profileRepository,
}) {
  return MaterialApp(
    home: AuthenticatedEntryScreen(
      uid: 'authenticated-user',
      email: 'shopper@example.com',
      deliveryAddressRepository: repository,
      authRepository: authRepository ?? _FakeAuthRepository(),
      profileRepository: profileRepository ?? _FakeUserProfileRepository(),
    ),
  );
}

class _FakeUserProfileRepository implements UserProfileRepository {
  UserProfile? profile = const UserProfile(
    uid: 'authenticated-user',
    fullName: 'Taylor Shopper',
    email: 'shopper@example.com',
    mobileNumber: '+201234567890',
    gender: 'female',
  );
  UserProfile? savedProfile;
  final List<ProfileFailure> readFailures = [];
  final List<String> readUids = [];

  @override
  Future<void> createProfile(UserProfile profile) async {
    savedProfile = profile;
    this.profile = profile;
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    readUids.add(uid);
    if (readFailures.isNotEmpty) throw readFailures.removeAt(0);
    return profile;
  }
}

Future<void> _enterValidAddress(WidgetTester tester) async {
  const values = ['Cairo', 'Nasr City', 'Example Street', '12A'];
  for (var index = 0; index < values.length; index++) {
    await tester.enterText(find.byType(TextFormField).at(index), values[index]);
  }
}

class _FakeDeliveryAddressRepository implements DeliveryAddressRepository {
  DeliveryAddress? address;
  Completer<DeliveryAddress?>? pendingRead;
  Completer<DeliveryAddress?>? readCompleter;
  final List<Object> readFailures = [];
  final List<String> readUids = [];
  int readCalls = 0;
  int saveCalls = 0;

  @override
  Future<DeliveryAddress?> getAddress(String uid) async {
    readCalls++;
    readUids.add(uid);
    final pending = pendingRead;
    if (pending != null) {
      readCompleter = pending;
      return pending.future;
    }
    if (readFailures.isNotEmpty) throw readFailures.removeAt(0);
    return address;
  }

  @override
  Future<void> saveAddress({
    required String uid,
    required DeliveryAddress address,
  }) async {
    saveCalls++;
    this.address = address;
  }
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
