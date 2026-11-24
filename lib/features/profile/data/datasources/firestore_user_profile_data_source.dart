import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grabber_app/features/profile/domain/entities/user_profile.dart';

/// Persists and parses customer profile documents in Cloud Firestore.
class FirestoreUserProfileDataSource {
  /// Allows a test Firestore instance; production falls back to the default.
  FirestoreUserProfileDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Creates a profile only when the user's document is not already present.
  ///
  /// This makes registration retry-safe and preserves the original
  /// `createdAt` value rather than replacing existing customer data.
  Future<void> createProfile(UserProfile profile) async {
    final document = _db.collection('users').doc(profile.uid);
    final existingProfile = await document.get();
    if (existingProfile.exists) return;

    await document.set({
      'fullName': profile.fullName,
      'email': profile.email,
      'mobileNumber': profile.mobileNumber,
      if (profile.gender != null) 'gender': profile.gender,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reads one profile by its Auth UID, or returns `null` if it is absent.
  Future<UserProfile?> getProfile(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;

    return profileFromData(uid: snapshot.id, data: data);
  }

  /// Converts a Firestore map into a profile and rejects invalid field types.
  static UserProfile profileFromData({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    final fullName = data['fullName'];
    final email = data['email'];
    final mobileNumber = data['mobileNumber'];
    final gender = data['gender'];
    if (fullName is! String ||
        email is! String ||
        mobileNumber is! String ||
        (gender != null && gender is! String)) {
      throw const FormatException('Invalid user profile data.');
    }

    return UserProfile(
      uid: uid,
      fullName: fullName,
      email: email,
      mobileNumber: mobileNumber,
      gender: gender as String?,
    );
  }
}
