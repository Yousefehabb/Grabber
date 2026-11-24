import 'package:grabber_app/features/profile/domain/entities/user_profile.dart';

/// Domain contract for creating and retrieving customer profile records.
abstract interface class UserProfileRepository {
  /// Creates a profile for its UID without replacing an existing profile.
  Future<void> createProfile(UserProfile profile);

  /// Retrieves the profile belonging to [uid], or returns `null` if absent.
  Future<UserProfile?> getProfile(String uid);
}
