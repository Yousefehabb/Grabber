import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';

/// Domain contract for reading and saving a user's primary delivery address.
abstract interface class DeliveryAddressRepository {
  /// Looks up the address owned by [uid], or returns `null` when absent.
  Future<DeliveryAddress?> getAddress(String uid);

  /// Stores [address] as the primary address belonging to [uid].
  Future<void> saveAddress({
    required String uid,
    required DeliveryAddress address,
  });
}
