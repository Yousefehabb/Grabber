/// Maps safe Auth and profile error codes to customer-facing messages.
abstract final class AuthErrorMessages {
  /// Returns a sign-in message without exposing Firebase internals.
  static String signIn(String code) {
    return switch (code) {
      'invalid-email' => 'Please enter a valid email address.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email or password is incorrect.',
      'user-disabled' => 'This account has been disabled. Contact support.',
      'too-many-requests' =>
        'Too many sign-in attempts. Please try again later.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      _ => 'Unable to sign in. Please try again.',
    };
  }

  /// Returns a registration message for a Firebase Auth error code.
  static String registration(String code) {
    return switch (code) {
      'email-already-in-use' =>
        'An account already exists for this email address.',
      'weak-password' => 'Choose a stronger password and try again.',
      'invalid-email' => 'Please enter a valid email address.',
      'operation-not-allowed' =>
        'Email registration is currently unavailable. Please try later.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      _ => 'Unable to create your account. Please try again.',
    };
  }

  /// Returns a profile-setup message for a persistence error code.
  static String profile(String code) {
    return switch (code) {
      'permission-denied' =>
        'We could not save your profile. Please check your account permissions.',
      'network-request-failed' || 'unavailable' =>
        'Network error. Check your connection and try again.',
      _ => 'Your account was created, but we could not save your profile.',
    };
  }

  /// Returns a user-facing message for verification-related failures.
  static String verification(String code) {
    return switch (code) {
      'too-many-requests' =>
        'Too many requests. Wait a little before trying again.',
      'network-request-failed' =>
        'Network error. Check your connection and try again.',
      'user-not-found' => 'Your session expired. Please sign in again.',
      _ => 'Unable to complete that action. Please try again.',
    };
  }
}
