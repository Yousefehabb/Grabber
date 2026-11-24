import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';

/// Reads and writes each user's primary delivery address in Cloud Firestore.
class FirestoreDeliveryAddressDataSource {
  /// Allows a test Firestore instance; production falls back to the default.
  FirestoreDeliveryAddressDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore;

  static const _addressFields = {
    'city',
    'district',
    'streetName',
    'buildingNumber',
  };
  static const _allowedAddressFields = {..._addressFields, 'updatedAt'};

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Validates and stores the address under the supplied user's UID.
  ///
  /// The server timestamp lets Firestore rules verify when the write occurred.
  Future<void> saveAddress({
    required String uid,
    required DeliveryAddress address,
  }) {
    _validateAddress(address);
    return _addressDocument(uid).set({
      'city': address.city.trim(),
      'district': address.district.trim(),
      'streetName': address.streetName.trim(),
      'buildingNumber': address.buildingNumber.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reads the user's primary address, returning `null` when it does not exist.
  Future<DeliveryAddress?> getAddress(String uid) async {
    final snapshot = await _addressDocument(uid).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) {
      throw const FormatException('Invalid delivery address data.');
    }

    return addressFromData(data);
  }

  DocumentReference<Map<String, dynamic>> _addressDocument(String uid) =>
      _db.collection('users').doc(uid).collection('addresses').doc('primary');

  /// Parses persisted fields and rejects missing, extra, or invalid values.
  static DeliveryAddress addressFromData(Map<String, dynamic> data) {
    final keys = data.keys.toSet();
    if (!keys.containsAll(_addressFields) ||
        keys.difference(_allowedAddressFields).isNotEmpty) {
      throw const FormatException('Invalid delivery address fields.');
    }
    if (data.containsKey('updatedAt') && data['updatedAt'] is! Timestamp) {
      throw const FormatException('Invalid delivery address timestamp.');
    }

    final city = data['city'];
    final district = data['district'];
    final streetName = data['streetName'];
    final buildingNumber = data['buildingNumber'];
    if (city is! String ||
        district is! String ||
        streetName is! String ||
        buildingNumber is! String ||
        city.trim().isEmpty ||
        district.trim().isEmpty ||
        streetName.trim().isEmpty ||
        buildingNumber.trim().isEmpty) {
      throw const FormatException('Invalid delivery address values.');
    }

    return DeliveryAddress(
      city: city,
      district: district,
      streetName: streetName,
      buildingNumber: buildingNumber,
    );
  }

  /// Prevents empty address fields from being sent to Firestore.
  void _validateAddress(DeliveryAddress address) {
    if (address.city.trim().isEmpty) {
      throw ArgumentError.value(address.city, 'city', 'must not be empty');
    }
    if (address.district.trim().isEmpty) {
      throw ArgumentError.value(
        address.district,
        'district',
        'must not be empty',
      );
    }
    if (address.streetName.trim().isEmpty) {
      throw ArgumentError.value(
        address.streetName,
        'streetName',
        'must not be empty',
      );
    }
    if (address.buildingNumber.trim().isEmpty) {
      throw ArgumentError.value(
        address.buildingNumber,
        'buildingNumber',
        'must not be empty',
      );
    }
  }
}
