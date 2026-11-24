/// Provides form validators shared by login and registration screens.
abstract final class AuthValidators {
  /// Checks that an email is present and has a basic address structure.
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Requires a non-empty password for sign-in.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  /// Requires a non-empty customer name.
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  /// Checks for a non-empty phone number with a supported character pattern.
  static String? mobileNumber(String? value) {
    final number = value?.trim() ?? '';
    if (number.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^\+?[0-9][0-9 ()-]{6,19}$').hasMatch(number)) {
      return 'Enter a valid mobile number';
    }
    return null;
  }

  /// Requires a registration password of at least eight characters.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  /// Confirms that the repeated password matches the original value.
  static String? confirmPassword({
    required String? value,
    required String password,
  }) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
