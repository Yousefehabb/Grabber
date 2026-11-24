import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grabber_app/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:grabber_app/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/profile/data/datasources/firestore_delivery_address_data_source.dart';
import 'package:grabber_app/features/profile/data/datasources/firestore_user_profile_data_source.dart';
import 'package:grabber_app/features/profile/data/repositories/delivery_address_repository_impl.dart';
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';
import 'package:grabber_app/features/profile/domain/entities/user_profile.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';

void main() {
  test('registration creates only the Firebase Auth account', () async {
    final dataSource = _FakeFirebaseAuthDataSource();
    final repository = AuthRepositoryImpl(dataSource: dataSource);

    final user = await repository.register(
      email: 'shopper@example.com',
      password: 'fresh-picks-8',
    );

    expect(user.uid, 'registered-user');
    expect(dataSource.createdEmail, 'shopper@example.com');
    expect(dataSource.createdPassword, 'fresh-picks-8');
  });

  test('legacy profile data without gender parses with a null gender', () {
    final profile = FirestoreUserProfileDataSource.profileFromData(
      uid: 'legacy-user',
      data: {
        'fullName': 'Taylor Shopper',
        'email': 'shopper@example.com',
        'mobileNumber': '+201234567890',
      },
    );

    expect(profile.gender, isNull);
  });

  test('Firestore datasource writes gender to the user document', () async {
    final firestore = _FakeFirebaseFirestore();
    final dataSource = FirestoreUserProfileDataSource(firestore: firestore);

    await dataSource.createProfile(
      const UserProfile(
        uid: 'registered-user',
        fullName: 'Taylor Shopper',
        email: 'shopper@example.com',
        mobileNumber: '+201234567890',
        gender: 'female',
      ),
    );

    expect(firestore.collectionPath, 'users');
    expect(firestore.documentId, 'registered-user');
    expect(firestore.writtenData?['gender'], 'female');
  });

  test('profile creation retry preserves an existing profile', () async {
    final firestore = _FakeFirebaseFirestore()..documentExists = true;
    final dataSource = FirestoreUserProfileDataSource(firestore: firestore);

    await dataSource.createProfile(
      const UserProfile(
        uid: 'existing-user',
        fullName: 'Updated Name',
        email: 'updated@example.com',
        mobileNumber: '+201234567890',
        gender: 'male',
      ),
    );

    expect(firestore.documentPath, 'users/existing-user');
    expect(firestore.writeCount, 0);
  });

  test('Firestore datasource omits null gender from legacy profiles', () async {
    final firestore = _FakeFirebaseFirestore();
    final dataSource = FirestoreUserProfileDataSource(firestore: firestore);

    await dataSource.createProfile(
      const UserProfile(
        uid: 'legacy-user',
        fullName: 'Taylor Shopper',
        email: 'shopper@example.com',
        mobileNumber: '+201234567890',
      ),
    );

    expect(firestore.collectionPath, 'users');
    expect(firestore.documentId, 'legacy-user');
    expect(firestore.writtenData, isNot(contains('gender')));
  });

  test('profile data with a non-string gender is invalid', () {
    expect(
      () => FirestoreUserProfileDataSource.profileFromData(
        uid: 'invalid-user',
        data: {
          'fullName': 'Taylor Shopper',
          'email': 'shopper@example.com',
          'mobileNumber': '+201234567890',
          'gender': 1,
        },
      ),
      throwsFormatException,
    );
  });

  test('delivery address save uses the UID and primary document', () async {
    final firestore = _FakeFirebaseFirestore();
    final dataSource = FirestoreDeliveryAddressDataSource(firestore: firestore);

    await dataSource.saveAddress(uid: 'user-123', address: _deliveryAddress());

    expect(firestore.documentPath, 'users/user-123/addresses/primary');
  });

  test(
    'delivery address save serializes only the four address fields',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final dataSource = FirestoreDeliveryAddressDataSource(
        firestore: firestore,
      );
      const address = DeliveryAddress(
        city: 'Cairo',
        district: 'Nasr City',
        streetName: 'Example Street',
        buildingNumber: '12A',
      );

      await dataSource.saveAddress(uid: 'user-123', address: address);

      expect(firestore.writtenData, {
        'city': 'Cairo',
        'district': 'Nasr City',
        'streetName': 'Example Street',
        'buildingNumber': '12A',
        'updatedAt': isA<FieldValue>(),
      });
    },
  );

  test(
    'delivery address save preserves entered values without trimming',
    () async {
      final firestore = _FakeFirebaseFirestore();
      final dataSource = FirestoreDeliveryAddressDataSource(
        firestore: firestore,
      );
      const address = DeliveryAddress(
        city: ' Cairo ',
        district: ' Nasr City ',
        streetName: ' Example Street ',
        buildingNumber: ' 12A ',
      );

      await dataSource.saveAddress(uid: 'user-123', address: address);

      expect(firestore.writtenData?['city'], 'Cairo');
      expect(firestore.writtenData?['district'], 'Nasr City');
      expect(firestore.writtenData?['streetName'], 'Example Street');
      expect(firestore.writtenData?['buildingNumber'], '12A');
    },
  );

  test('delivery address read parses an existing document', () async {
    final firestore = _FakeFirebaseFirestore()
      ..documentExists = true
      ..readData = {
        'city': 'Cairo',
        'district': 'Nasr City',
        'streetName': 'Example Street',
        'buildingNumber': '12A',
      };
    final dataSource = FirestoreDeliveryAddressDataSource(firestore: firestore);

    final address = await dataSource.getAddress('user-123');

    expect(address?.city, 'Cairo');
    expect(address?.district, 'Nasr City');
    expect(address?.streetName, 'Example Street');
    expect(address?.buildingNumber, '12A');
    expect(firestore.documentPath, 'users/user-123/addresses/primary');
  });

  test('delivery address read returns null for a missing document', () async {
    final dataSource = FirestoreDeliveryAddressDataSource(
      firestore: _FakeFirebaseFirestore(),
    );

    expect(await dataSource.getAddress('user-123'), isNull);
  });

  test('delivery address read rejects malformed documents', () async {
    final malformedDocuments = <Map<String, dynamic>>[
      {
        'district': 'Nasr City',
        'streetName': 'Example Street',
        'buildingNumber': '12A',
      },
      {
        'city': 1,
        'district': 'Nasr City',
        'streetName': 'Example Street',
        'buildingNumber': '12A',
      },
      {
        'city': 'Cairo',
        'district': 'Nasr City',
        'streetName': 'Example Street',
        'buildingNumber': '12A',
        'extra': 'not allowed',
      },
      {
        'city': 'Cairo',
        'district': 'Nasr City',
        'streetName': 'Example Street',
        'buildingNumber': '12A',
        'updatedAt': 'not a timestamp',
      },
      {
        'city': 'Cairo',
        'district': 'Nasr City',
        'streetName': ' ',
        'buildingNumber': '12A',
      },
    ];

    for (final document in malformedDocuments) {
      final firestore = _FakeFirebaseFirestore()
        ..documentExists = true
        ..readData = document;
      final dataSource = FirestoreDeliveryAddressDataSource(
        firestore: firestore,
      );

      await expectLater(
        dataSource.getAddress('user-123'),
        throwsFormatException,
      );
    }
  });

  test('delivery address rejects empty values before writing', () async {
    final firestore = _FakeFirebaseFirestore();
    final dataSource = FirestoreDeliveryAddressDataSource(firestore: firestore);
    final invalidAddresses = <DeliveryAddress Function(String)>[
      (value) => _deliveryAddress(city: value),
      (value) => _deliveryAddress(district: value),
      (value) => _deliveryAddress(streetName: value),
      (value) => _deliveryAddress(buildingNumber: value),
    ];

    for (final createAddress in invalidAddresses) {
      for (final value in ['', ' \t ']) {
        expect(
          () => dataSource.saveAddress(
            uid: 'user-123',
            address: createAddress(value),
          ),
          throwsArgumentError,
        );
      }
    }

    expect(firestore.writeCount, 0);
  });

  test('delivery address repository preserves Firestore failures', () async {
    final firestore = _FakeFirebaseFirestore();
    final repository = DeliveryAddressRepositoryImpl(
      dataSource: FirestoreDeliveryAddressDataSource(firestore: firestore),
    );
    firestore.readFailure = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );

    await expectLater(
      repository.getAddress('user-123'),
      throwsA(
        isA<ProfileFailure>()
            .having((failure) => failure.code, 'code', 'unavailable')
            .having((failure) => failure.operation, 'operation', 'get-address'),
      ),
    );

    firestore
      ..readFailure = null
      ..writeFailure = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );

    await expectLater(
      repository.saveAddress(uid: 'user-123', address: _deliveryAddress()),
      throwsA(
        isA<ProfileFailure>()
            .having((failure) => failure.code, 'code', 'permission-denied')
            .having(
              (failure) => failure.operation,
              'operation',
              'save-address',
            ),
      ),
    );
  });
}

DeliveryAddress _deliveryAddress({
  String city = 'Cairo',
  String district = 'Nasr City',
  String streetName = 'Example Street',
  String buildingNumber = '12A',
}) => DeliveryAddress(
  city: city,
  district: district,
  streetName: streetName,
  buildingNumber: buildingNumber,
);

class _FakeFirebaseAuthDataSource implements FirebaseAuthDataSource {
  FirebaseException? verificationError;
  FirebaseException? displayNameError;
  String? createdEmail;
  String? createdPassword;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(null);

  @override
  Future<AuthUser?> refreshCurrentUser() async => createdEmail == null
      ? null
      : const AuthUser(
          uid: 'registered-user',
          email: 'shopper@example.com',
          emailVerified: false,
        );

  @override
  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async =>
      AuthUser(uid: 'signed-in-user', email: email, emailVerified: false);

  @override
  Future<AuthUser?> createAccount({
    required String email,
    required String password,
  }) async {
    createdEmail = email;
    createdPassword = password;
    return AuthUser(uid: 'registered-user', email: email, emailVerified: false);
  }

  @override
  Future<void> updateDisplayName(String fullName) async {
    final error = displayNameError;
    if (error != null) throw error;
  }

  @override
  Future<void> sendEmailVerification() async {
    final error = verificationError;
    if (error != null) throw error;
  }

  @override
  Future<void> signOut() async {}
}

class _FakeFirebaseFirestore implements FirebaseFirestore {
  String? collectionPath;
  String? documentId;
  String? documentPath;
  Map<String, dynamic>? writtenData;
  Map<String, dynamic>? readData;
  bool documentExists = false;
  Object? readFailure;
  Object? writeFailure;
  int writeCount = 0;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    this.collectionPath = collectionPath;
    return _FakeCollectionReference(this, collectionPath);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _FakeCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  _FakeCollectionReference(this.firestore, this.collectionPath);

  @override
  final _FakeFirebaseFirestore firestore;
  final String collectionPath;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    firestore.documentId = path;
    final documentPath = '$collectionPath/${path ?? 'generated-id'}';
    firestore.documentPath = documentPath;
    return _FakeDocumentReference(firestore, documentPath);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _FakeDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.firestore, this.path);

  @override
  final _FakeFirebaseFirestore firestore;

  @override
  final String path;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    final failure = firestore.writeFailure;
    if (failure != null) throw failure;
    firestore.writtenData = data;
    firestore.writeCount++;
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    firestore.documentPath = path;
    final failure = firestore.readFailure;
    if (failure != null) throw failure;
    return _FakeDocumentSnapshot(firestore, path);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    final nestedPath = '${this.path}/$path';
    firestore.collectionPath = nestedPath;
    return _FakeCollectionReference(firestore, nestedPath);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this.firestore, this.path);

  final _FakeFirebaseFirestore firestore;
  final String path;

  @override
  String get id => path.split('/').last;

  @override
  bool get exists => firestore.documentExists;

  @override
  Map<String, dynamic>? data() => firestore.readData;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
