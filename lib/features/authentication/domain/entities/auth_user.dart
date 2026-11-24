/// The authentication identity returned by Firebase Auth.
///
/// Profile and address records use [uid] as their Firestore owner key.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    this.displayName,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;
}
