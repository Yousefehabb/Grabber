import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/profile/domain/entities/user_profile.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';

/// Holds the outcome of creating an Auth account and its Firestore profile.
class CustomerRegistrationResult {
  const CustomerRegistrationResult({
    required this.user,
    this.profileCreationFailure,
  });

  final AuthUser user;
  final ProfileFailure? profileCreationFailure;

  bool get profileCreated => profileCreationFailure == null;
}

/// Coordinates registration across Authentication and Profile features.
///
/// Auth creates the account and returns its UID; this app-layer coordinator
/// then uses that identity to create the customer's Firestore profile.
class CustomerRegistrationCoordinator {
  const CustomerRegistrationCoordinator({
    required AuthRepository authRepository,
    required UserProfileRepository profileRepository,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository;

  final AuthRepository _authRepository;
  final UserProfileRepository _profileRepository;

  /// Creates the Auth account, then attempts to save its customer profile.
  ///
  /// Profile failures are returned with the authenticated user so the UI can
  /// offer a profile-only retry instead of creating the Auth account again.
  Future<CustomerRegistrationResult> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String gender,
    required String password,
  }) async {
    final user = await _authRepository.register(
      email: email,
      password: password,
    );
    final failure = await _createProfile(
      user: user,
      fullName: fullName,
      mobileNumber: mobileNumber,
      gender: gender,
    );
    return CustomerRegistrationResult(
      user: user,
      profileCreationFailure: failure,
    );
  }

  /// Retries only profile persistence for an account that already exists.
  Future<void> retryProfileCreation({
    required AuthUser user,
    required String fullName,
    required String mobileNumber,
    required String gender,
  }) async {
    final failure = await _createProfile(
      user: user,
      fullName: fullName,
      mobileNumber: mobileNumber,
      gender: gender,
    );
    if (failure != null) throw failure;
  }

  /// Builds the Firestore profile from registration fields and Auth identity.
  ///
  /// Returns a profile failure for a missing Auth email or a repository
  /// [ProfileFailure]; the caller can retry without repeating account creation.
  Future<ProfileFailure?> _createProfile({
    required AuthUser user,
    required String fullName,
    required String mobileNumber,
    required String gender,
  }) async {
    final email = user.email;
    if (email == null || email.isEmpty) {
      return const ProfileFailure(
        code: 'missing-email',
        operation: 'create-profile',
      );
    }

    try {
      await _profileRepository.createProfile(
        UserProfile(
          uid: user.uid,
          fullName: fullName,
          email: email,
          mobileNumber: mobileNumber,
          gender: gender,
        ),
      );
      return null;
    } on ProfileFailure catch (failure) {
      return failure;
    }
  }
}
