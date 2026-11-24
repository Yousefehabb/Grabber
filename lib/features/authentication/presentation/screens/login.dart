import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grabber_app/app/authenticated_entry_screen.dart';
import 'package:grabber_app/core/constants/app_colors.dart';
import 'package:grabber_app/core/constants/app_fonts.dart';
import 'package:grabber_app/features/authentication/domain/errors/auth_failure.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/authentication/presentation/auth_error_messages.dart';
import 'package:grabber_app/features/authentication/presentation/auth_validators.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';

/// Collects sign-in credentials and routes authenticated users to the data gate.
class LoginScreen extends StatefulWidget {
  /// Receives the shared Auth and customer-data repositories for navigation.
  const LoginScreen({
    required this.authRepository,
    required this.deliveryAddressRepository,
    required this.profileRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final DeliveryAddressRepository deliveryAddressRepository;
  final UserProfileRepository profileRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthRepository _authRepository = widget.authRepository;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _hasNavigated = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates credentials, signs in through Auth, and reports safe errors.
  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await _authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      _routeUser(user);
    } on AuthFailure catch (failure) {
      if (kDebugMode) {
        debugPrint(
          'Authentication ${failure.operation} failed: '
          'code=${failure.code}',
        );
      }
      if (mounted) _showMessage(AuthErrorMessages.signIn(failure.code));
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('Sign-in failed: ${error.runtimeType}');
      }
      if (mounted) _showMessage('Unable to sign in. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Sends the signed-in UID to the gate that checks profile and address data.
  void _routeUser(AuthUser user) {
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

  /// Shows the current placeholder response for the recovery action.
  void _showRecoveryUnavailable() {
    _showMessage('Password recovery is not available yet.');
  }

  /// Opens registration unless a sign-in request is in progress.
  void _openRegistration() {
    if (_isLoading) return;
    Navigator.of(context).pushNamed('/register');
  }

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
                            'Welcome back',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: const Color(0xFF1E2A1D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue to your fresh picks.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading,
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
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            validator: AuthValidators.password,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              filled: true,
                              fillColor: colorScheme.primary.withAlpha(13),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _isPasswordVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'Remember: Passwords are case-sensitive (A is different from a).',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : _showRecoveryUnavailable,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
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
                                  : const Text(
                                      'Log in',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text("Don't have an account?"),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : _openRegistration,
                                child: const Text('Create account'),
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
