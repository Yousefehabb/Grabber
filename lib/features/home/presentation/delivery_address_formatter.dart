// Formats a saved delivery address for the compact Home header.
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';

/// Keeps Home-specific address presentation separate from navigation state.
abstract final class DeliveryAddressFormatter {
  /// Joins the saved street, building, district, and city into one label.
  static String format(DeliveryAddress address) =>
      '${address.streetName} ${address.buildingNumber}, '
      '${address.district}, ${address.city}';
}
