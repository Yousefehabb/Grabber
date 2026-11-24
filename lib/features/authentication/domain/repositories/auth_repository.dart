import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';

/// Contract for authentication and session operations, independent of Firebase.
abstract interface class AuthRepository {
  /// Emits the current signed-in identity or `null` when signed out.
  Stream<AuthUser?> authStateChanges();

  /// Refreshes the current Firebase Auth user and returns its latest identity.
  Future<AuthUser?> refreshCurrentUser();

  /// Signs in with credentials and returns the authenticated identity.
  Future<AuthUser> signIn({required String email, required String password});

  /// Creates an Auth account; customer profile persistence is coordinated above
  /// this repository by the app layer.
  Future<AuthUser> register({required String email, required String password});

  // Retained for the inactive legacy verification screen.
  Future<void> updateDisplayName(String fullName);

  // Retained for the inactive legacy verification screen.
  Future<void> sendVerificationEmail();

  Future<void> signOut();
}
