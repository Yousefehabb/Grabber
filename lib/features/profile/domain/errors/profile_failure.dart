/// A safe profile-operation failure that does not expose customer data.
class ProfileFailure implements Exception {
  const ProfileFailure({required this.code, required this.operation});

  final String code;
  final String operation;
}
