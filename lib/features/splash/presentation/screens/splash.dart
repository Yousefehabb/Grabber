import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grabber_app/app/authenticated_entry_screen.dart';
import 'package:grabber_app/core/constants/app_colors.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/errors/auth_failure.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/authentication/presentation/screens/login.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';

/// Displays the launch animation and routes according to the Auth session.
class Splash extends StatefulWidget {
  /// Receives the shared repositories needed for the next authentication route.
  const Splash({
    required this.authRepository,
    required this.deliveryAddressRepository,
    required this.profileRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final DeliveryAddressRepository deliveryAddressRepository;
  final UserProfileRepository profileRepository;

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final AuthRepository _authRepository = widget.authRepository;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _resolveSession();
  }

  /// Resolves the persisted Auth session before opening login or the data gate.
  ///
  /// Session lookup failures are treated as signed out, and navigation occurs
  /// only once after the splash delay.
  Future<void> _resolveSession() async {
    AuthUser? user;
    try {
      user = await _authRepository.authStateChanges().first;
    } on AuthFailure catch (failure) {
      if (kDebugMode) {
        debugPrint(
          'Authentication session check failed: '
          'code=${failure.code}, operation=${failure.operation}',
        );
      }
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('Authentication session check failed: ${error.runtimeType}');
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    final Widget destination;
    if (user == null) {
      destination = LoginScreen(
        authRepository: _authRepository,
        deliveryAddressRepository: widget.deliveryAddressRepository,
        profileRepository: widget.profileRepository,
      );
    } else {
      destination = AuthenticatedEntryScreen(
        uid: user.uid,
        email: user.email ?? '',
        deliveryAddressRepository: widget.deliveryAddressRepository,
        authRepository: _authRepository,
        profileRepository: widget.profileRepository,
      );
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/logo/logo.svg',
                    width: 190,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Fresh finds, delivered.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColor.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
