import 'package:flutter/material.dart';
import 'package:grabber_app/core/constants/app_colors.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/authentication/presentation/screens/login.dart';
import 'package:grabber_app/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:grabber_app/features/profile/domain/entities/user_profile.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';

/// Shows the signed-in user's Firestore profile and provides Auth sign-out.
class ProfileScreen extends StatefulWidget {
  /// Accepts repositories so the screen can be tested without Firebase.
  const ProfileScreen({
    this.authRepository,
    this.deliveryAddressRepository,
    this.profileRepository,
    super.key,
  });

  final AuthRepository? authRepository;
  final DeliveryAddressRepository? deliveryAddressRepository;
  final UserProfileRepository? profileRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserProfileRepository _profileRepository =
      widget.profileRepository ?? UserProfileRepositoryImpl();
  bool _isSigningOut = false;

  /// Ends the Auth session and replaces the authenticated navigation stack.
  Future<void> _signOut() async {
    if (_isSigningOut) return;
    final authRepository = widget.authRepository;
    final deliveryAddressRepository = widget.deliveryAddressRepository;
    if (authRepository == null || deliveryAddressRepository == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out. Please try again.')),
      );
      return;
    }
    setState(() => _isSigningOut = true);
    try {
      await authRepository.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(
            authRepository: authRepository,
            deliveryAddressRepository: deliveryAddressRepository,
            profileRepository: _profileRepository,
          ),
        ),
        (_) => false,
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: widget.authRepository == null
          ? const _ProfileMessage(
              message: 'Please sign in to view your profile.',
            )
          : StreamBuilder<AuthUser?>(
              stream: widget.authRepository!.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user = authSnapshot.data;
                if (user == null) {
                  return const Center(
                    child: Text('Please sign in to view your profile.'),
                  );
                }
                return FutureBuilder<UserProfile?>(
                  future: _profileRepository.getProfile(user.uid),
                  builder: (context, profileSnapshot) {
                    if (profileSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (profileSnapshot.hasError) {
                      final error = profileSnapshot.error;
                      final message =
                          error is ProfileFailure &&
                              error.code == 'permission-denied'
                          ? 'You do not have permission to view this profile.'
                          : 'Unable to load your profile. Please try again.';
                      return _ProfileMessage(message: message);
                    }
                    final profile = profileSnapshot.data;
                    if (profile == null) {
                      return const _ProfileMessage(
                        message:
                            'Your profile is not available yet. Please try again later.',
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 48,
                          color: AppColor.primary,
                        ),
                        const SizedBox(height: 20),
                        _ProfileField(
                          label: 'Full name',
                          value: profile.fullName,
                        ),
                        _ProfileField(label: 'Email', value: profile.email),
                        _ProfileField(
                          label: 'Mobile number',
                          value: profile.mobileNumber,
                        ),
                        if (profile.gender != null)
                          _ProfileField(
                            label: 'Gender',
                            value: profile.gender!,
                          ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: _isSigningOut ? null : _signOut,
                          child: _isSigningOut
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Log out'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
