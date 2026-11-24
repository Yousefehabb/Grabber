/// A safe, operation-scoped description of an Authentication failure.
class AuthFailure implements Exception {
  const AuthFailure({required this.code, required this.operation});

  final String code;
  final String operation;
}
