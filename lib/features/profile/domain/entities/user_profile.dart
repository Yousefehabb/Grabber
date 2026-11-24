/// Customer details stored separately from Firebase Authentication credentials.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    this.gender,
  });

  final String uid;
  final String fullName;
  final String email;
  final String mobileNumber;
  final String? gender;
}
