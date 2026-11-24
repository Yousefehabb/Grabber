import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grabber_app/features/profile/data/datasources/firestore_delivery_address_data_source.dart';
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';

/// Adapts the address data source to the domain repository contract.
class DeliveryAddressRepositoryImpl implements DeliveryAddressRepository {
  /// Uses the supplied data source or creates one backed by default Firestore.
  DeliveryAddressRepositoryImpl({
    FirestoreDeliveryAddressDataSource? dataSource,
  }) : _dataSource = dataSource ?? FirestoreDeliveryAddressDataSource();

  final FirestoreDeliveryAddressDataSource _dataSource;

  /// Returns a parsed primary address and maps read or data errors.
  @override
  Future<DeliveryAddress?> getAddress(String uid) =>
      _run('get-address', () => _dataSource.getAddress(uid));

  /// Saves the user's primary address and maps validation or Firebase errors.
  @override
  Future<void> saveAddress({
    required String uid,
    required DeliveryAddress address,
  }) => _run(
    'save-address',
    () => _dataSource.saveAddress(uid: uid, address: address),
  );

  /// Preserves stack traces while exposing Firebase failures as domain errors.
  Future<T> _run<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on ProfileFailure {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ProfileFailure(code: error.code, operation: operation),
        stackTrace,
      );
    } on ArgumentError catch (_, stackTrace) {
      Error.throwWithStackTrace(
        ProfileFailure(code: 'invalid-address', operation: operation),
        stackTrace,
      );
    } on FormatException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        ProfileFailure(code: 'invalid-address', operation: operation),
        stackTrace,
      );
    } on Object catch (_, stackTrace) {
      Error.throwWithStackTrace(
        ProfileFailure(code: 'unknown', operation: operation),
        stackTrace,
      );
    }
  }
}
