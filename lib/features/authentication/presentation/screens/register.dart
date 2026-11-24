import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grabber_app/core/constants/app_colors.dart';
import 'package:grabber_app/core/constants/app_fonts.dart';
import 'package:grabber_app/app/customer_registration_coordinator.dart';
import 'package:grabber_app/app/authenticated_entry_screen.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/errors/auth_failure.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/authentication/presentation/auth_error_messages.dart';
import 'package:grabber_app/features/authentication/presentation/auth_validators.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';

/// Collects new-customer details and coordinates Auth and profile creation.
class RegisterScreen extends StatefulWidget {
  /// Receives the coordinator and repositories needed by the registration flow.
  const RegisterScreen({
    required this.authRepository,
    required this.deliveryAddressRepository,
    required this.registrationCoordinator,
    required this.profileRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final DeliveryAddressRepository deliveryAddressRepository;
  final CustomerRegistrationCoordinator registrationCoordinator;
  final UserProfileRepository profileRepository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final AuthRepository _authRepository = widget.authRepository;
  late final CustomerRegistrationCoordinator _registrationCoordinator =
      widget.registrationCoordinator;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _hasNavigated = false;
  AuthUser? _pendingProfileUser;
  String? _gender;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates registration input and creates the Auth account and profile.
  ///
  /// If profile creation fails after Auth succeeds, retains the identity so the
  /// customer can retry profile setup without creating another account.
  Future<void> _submit() async {
    if (_isLoading || _hasNavigated) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await _registrationCoordinator.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileNumberController.text.trim(),
        gender: _gender!,
        password: _passwordController.text,
      );
      if (!mounted || _hasNavigated) return;
      if (!result.profileCreated) {
        setState(() => _pendingProfileUser = result.user);
        _showMessage(
          AuthErrorMessages.profile(result.profileCreationFailure!.code),
        );
        return;
      }
      _openAuthenticatedEntry(result.user);
    } on AuthFailure catch (failure) {
      _logFailure(failure);
      if (mounted) {
        _showMessage(AuthErrorMessages.registration(failure.code));
      }
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('Registration failed: ${error.runtimeType}');
      }
      if (mounted) {
        _showMessage('Unable to create your account. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Retries profile persistence for the already-created Auth account.
  Future<void> _retryProfileCreation() async {
    final user = _pendingProfileUser;
    if (user == null || _isLoading || _hasNavigated) return;
    setState(() => _isLoading = true);
    try {
      await _registrationCoordinator.retryProfileCreation(
        user: user,
        fullName: _fullNameController.text.trim(),
        mobileNumber: _mobileNumberController.text.trim(),
        gender: _gender!,
      );
      if (!mounted) return;
      _openAuthenticatedEntry(user);
    } on ProfileFailure catch (failure) {
      if (mounted) _showMessage(AuthErrorMessages.profile(failure.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Replaces registration with the gate that enforces profile/address setup.
  void _openAuthenticatedEntry(AuthUser user) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => AuthenticatedEntryScreen(
          uid: user.uid,
          email: user.email ?? '',
          deliveryAddressRepository: widget.deliveryAddressRepository,
          authRepository: _authRepository,
          profileRepository: widget.profileRepository,
        ),
      ),
      (_) => false,
    );
  }

  /// Logs only safe Auth failure metadata in debug builds.
  void _logFailure(AuthFailure failure) {
    if (kDebugMode) {
      debugPrint(
        'Authentication ${failure.operation} failed: code=${failure.code}',
      );
    }
  }

  /// Builds a styled notification for registration outcomes.
  SnackBar _snackBar(String message) => SnackBar(
    content: Text(
      message,
      style: const TextStyle(fontFamily: AppFonts.bebasNeue),
    ),
  );

  /// Displays a registration outcome without exposing credentials.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(_snackBar(message));
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
                    child: Form(
                      key: _formKey,
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
                            'Create your account',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: const Color(0xFF1E2A1D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join Grabber for fresh picks and easy shopping.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _fullNameController,
                            enabled: !_isLoading,
                            style: const TextStyle(fontFamily: 'Roboto'),
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            validator: AuthValidators.fullName,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              hintText: 'Your name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            style: const TextStyle(fontFamily: 'Roboto'),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: AuthValidators.email,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          TextFormField(
                            controller: _mobileNumberController,
                            enabled: !_isLoading && _pendingProfileUser == null,
                            style: const TextStyle(fontFamily: 'Roboto'),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            validator: AuthValidators.mobileNumber,
                            decoration: const InputDecoration(
                              labelText: 'Mobile number',
                              hintText: '+20 123 456 7890',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            initialValue: _gender,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            hint: const Text('Select gender'),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                            ],
                            onChanged: _isLoading || _pendingProfileUser != null
                                ? null
                                : (value) => setState(() => _gender = value),
                            validator: (value) =>
                                value == null ? 'Gender is required' : null,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            style: const TextStyle(fontFamily: 'SourceCodePro'),
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: AuthValidators.newPassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'At least 8 characters',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _isPasswordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(
                                        () => _isPasswordVisible =
                                            !_isPasswordVisible,
                                      ),
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _confirmPasswordController,
                            enabled: !_isLoading,
                            style: const TextStyle(fontFamily: 'SourceCodePro'),
                            obscureText: !_isConfirmPasswordVisible,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (value) =>
                                AuthValidators.confirmPassword(
                                  value: value,
                                  password: _passwordController.text,
                                ),
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              hintText: 'Re-enter your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _isConfirmPasswordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(
                                        () => _isConfirmPasswordVisible =
                                            !_isConfirmPasswordVisible,
                                      ),
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: _isLoading
                                  ? null
                                  : _pendingProfileUser == null
                                  ? _submit
                                  : _retryProfileCreation,
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
                                  : Text(
                                      _pendingProfileUser == null
                                          ? 'Create account'
                                          : 'Retry profile setup',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text('Log in'),
                              ),
                            ],
                          ),
                        ],
                      ),
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
