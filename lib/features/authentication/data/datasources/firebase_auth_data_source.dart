import 'package:firebase_auth/firebase_auth.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';

/// Adapts Firebase Auth SDK operations to the app's authentication entity.
class FirebaseAuthDataSource {
  FirebaseAuthDataSource({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth;

  final FirebaseAuth? _firebaseAuth;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  /// Maps Firebase Auth session changes to app-level [AuthUser] values.
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_mapUser);

  /// Reloads the current Firebase user and returns its refreshed identity.
  Future<AuthUser?> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _mapUser(_auth.currentUser);
  }

  /// Authenticates with Firebase using the supplied email and password.
  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapUser(credential.user);
  }

  /// Creates a Firebase Auth account and returns the newly assigned UID.
  Future<AuthUser?> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapUser(credential.user);
  }

  /// Updates the current Auth user's display name; throws if signed out.
  Future<void> updateDisplayName(String fullName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await user.updateDisplayName(fullName);
  }

  /// Sends a verification email to the current Auth user.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await user.sendEmailVerification();
  }

  /// Converts a Firebase SDK user to the domain identity without credentials.
  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }

  /// Ends the current Firebase Auth session.
  Future<void> signOut() => _auth.signOut();
}
