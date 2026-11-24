import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grabber_app/features/profile/data/datasources/firestore_user_profile_data_source.dart';
import 'package:grabber_app/features/profile/domain/entities/user_profile.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';

/// Implements profile operations and translates persistence errors.
class UserProfileRepositoryImpl implements UserProfileRepository {
  /// Uses the provided source or creates one backed by default Firestore.
  UserProfileRepositoryImpl({FirestoreUserProfileDataSource? dataSource})
    : _dataSource = dataSource ?? FirestoreUserProfileDataSource();

  final FirestoreUserProfileDataSource _dataSource;

  /// Creates the user's profile if it is not already stored.
  @override
  Future<void> createProfile(UserProfile profile) =>
      _run('create-profile', () => _dataSource.createProfile(profile));

  /// Retrieves the profile belonging to the supplied Auth UID.
  @override
  Future<UserProfile?> getProfile(String uid) =>
      _run('get-profile', () => _dataSource.getProfile(uid));

  /// Converts Firebase and unexpected errors to safe domain failures.
  Future<T> _run<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on ProfileFailure {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        ProfileFailure(code: error.code, operation: operation),
        stackTrace,
      );
    } on Object catch (_, stackTrace) {
      Error.throwWithStackTrace(
        ProfileFailure(code: 'unknown', operation: operation),
        stackTrace,
      );
    }
  }
}
