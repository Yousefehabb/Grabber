/// The required address fields used by the delivery-address feature.
class DeliveryAddress {
  const DeliveryAddress({
    required this.city,
    required this.district,
    required this.streetName,
    required this.buildingNumber,
  });

  final String city;
  final String district;
  final String streetName;
  final String buildingNumber;
}
