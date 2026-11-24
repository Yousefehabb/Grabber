import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grabber_app/app/app_session.dart';
import 'package:grabber_app/app/authenticated_entry_screen.dart';
import 'package:grabber_app/core/constants/app_colors.dart';
import 'package:grabber_app/core/constants/app_fonts.dart';
import 'package:grabber_app/features/authentication/domain/errors/auth_failure.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/authentication/presentation/auth_error_messages.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';

/// Lets a signed-in customer verify their email before entering the data gate.
class VerifyEmailScreen extends StatefulWidget {
  /// Receives Auth actions and the repositories needed after verification.
  const VerifyEmailScreen({
    required this.authRepository,
    required this.deliveryAddressRepository,
    required this.profileRepository,
    required this.email,
    this.fullNameForRetry,
    this.displayNameNeedsUpdate = false,
    this.verificationEmailNeedsResend = false,
    this.initialRefreshFailed = false,
    super.key,
  });

  final AuthRepository authRepository;
  final DeliveryAddressRepository deliveryAddressRepository;
  final UserProfileRepository profileRepository;
  final String? email;
  final String? fullNameForRetry;
  final bool displayNameNeedsUpdate;
  final bool verificationEmailNeedsResend;
  final bool initialRefreshFailed;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;
  bool _displayNameNeedsUpdate = false;
  bool _verificationEmailNeedsResend = false;

  @override
  void initState() {
    super.initState();
    _displayNameNeedsUpdate = widget.displayNameNeedsUpdate;
    _verificationEmailNeedsResend = widget.verificationEmailNeedsResend;
  }

  /// Requests another verification email through Firebase Auth.
  Future<void> _resendVerificationEmail() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.authRepository.sendVerificationEmail();
      if (!mounted) return;
      setState(() => _verificationEmailNeedsResend = false);
      _showMessage('Verification email sent. Check your inbox.');
    } on AuthFailure catch (failure) {
      _logFailure(failure);
      if (mounted) {
        _showMessage(AuthErrorMessages.verification(failure.code));
      }
    } on Object catch (error) {
      _logUnexpected(error);
      if (mounted) {
        _showMessage('Unable to send the email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Retries saving the Auth display name after an earlier partial failure.
  Future<void> _retryDisplayName() async {
    final fullName = widget.fullNameForRetry;
    if (_isLoading || fullName == null || fullName.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await widget.authRepository.updateDisplayName(fullName);
      if (!mounted) return;
      setState(() => _displayNameNeedsUpdate = false);
      _showMessage('Your profile name has been updated.');
    } on AuthFailure catch (failure) {
      _logFailure(failure);
      if (mounted) {
        _showMessage(AuthErrorMessages.verification(failure.code));
      }
    } on Object catch (error) {
      _logUnexpected(error);
      if (mounted) {
        _showMessage('Unable to update your profile name. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Refreshes Auth state and continues only after email verification succeeds.
  Future<void> _checkVerification() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = await widget.authRepository.refreshCurrentUser();
      if (!mounted) return;
      if (user == null) {
        _showMessage('Your session expired. Please sign in again.');
      } else if (user.emailVerified) {
        _navigateToMain(user);
      } else {
        _showMessage(
          'Your email is not verified yet. Open the verification link, '
          'then try again.',
        );
      }
    } on AuthFailure catch (failure) {
      _logFailure(failure);
      if (mounted) {
        _showMessage(AuthErrorMessages.verification(failure.code));
      }
    } on Object catch (error) {
      _logUnexpected(error);
      if (mounted) {
        _showMessage('Unable to check verification. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Ends the Auth session and returns to the login route.
  Future<void> _signOut() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.authRepository.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } on AuthFailure catch (failure) {
      _logFailure(failure);
      if (mounted) {
        _showMessage(AuthErrorMessages.verification(failure.code));
      }
    } on Object catch (error) {
      _logUnexpected(error);
      if (mounted) {
        _showMessage('Unable to sign out. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Routes the verified identity through the profile/address completion gate.
  void _navigateToMain(AuthUser user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => AuthenticatedEntryScreen(
          uid: user.uid,
          email: user.email ?? '',
          deliveryAddressRepository: widget.deliveryAddressRepository,
          authRepository: widget.authRepository,
          profileRepository: widget.profileRepository,
          session: AppSession.authenticated,
        ),
      ),
      (_) => false,
    );
  }

  /// Displays a user-facing result for a verification action.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppFonts.bebasNeue),
        ),
      ),
    );
  }

  /// Logs only operation and error-code metadata in debug builds.
  void _logFailure(AuthFailure failure) {
    if (kDebugMode) {
      debugPrint(
        'Authentication ${failure.operation} failed: code=${failure.code}',
      );
    }
  }

  /// Logs the unexpected error type without printing sensitive input.
  void _logUnexpected(Object error) {
    if (kDebugMode) {
      debugPrint('Verification action failed: ${error.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: AppFonts.bebasNeue),
      ),
      child: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SvgPicture.asset(
                            'assets/logo/logo.svg',
                            width: 132,
                            height: 54,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'Verify your email',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: const Color(0xFF1E2A1D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Email verification is required before you can '
                          'access Grabber shopping.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (widget.initialRefreshFailed) ...[
                          const SizedBox(height: 12),
                          Text(
                            'We could not refresh your account status. '
                            'Check your connection and try again.',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                        if (widget.email != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            widget.email!,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (_displayNameNeedsUpdate &&
                            widget.fullNameForRetry != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Your account was created, but the profile name '
                            'could not be saved.',
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _isLoading ? null : _retryDisplayName,
                            child: const Text('Retry profile name update'),
                          ),
                        ],
                        if (_verificationEmailNeedsResend) ...[
                          const SizedBox(height: 12),
                          Text(
                            'The verification email was not sent. You can '
                            'request another one below.',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: _isLoading
                                ? null
                                : _resendVerificationEmail,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Resend Verification Email'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isLoading ? null : _checkVerification,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColor.primary,
                            side: BorderSide(color: AppColor.primary),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("I've Verified My Email"),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _isLoading ? null : _signOut,
                          child: const Text('Sign out and return to Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
