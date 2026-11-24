import 'package:flutter/material.dart';
import 'package:grabber_app/app/customer_registration_coordinator.dart';
import 'package:grabber_app/core/theme/app_theme.dart';
import 'package:grabber_app/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/authentication/presentation/screens/login.dart';
import 'package:grabber_app/features/authentication/presentation/screens/register.dart';
import 'package:grabber_app/features/profile/data/repositories/delivery_address_repository_impl.dart';
import 'package:grabber_app/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:grabber_app/features/splash/presentation/screens/splash.dart';

/// Builds the app-wide repositories and shares them with routed screens.
class MyApp extends StatelessWidget {
  /// Accepts optional dependencies for tests; production defaults use Firebase.
  MyApp({
    super.key,
    AuthRepository? authRepository,
    DeliveryAddressRepository? deliveryAddressRepository,
    UserProfileRepository? profileRepository,
    this.registrationCoordinator,
  }) : authRepository = authRepository ?? AuthRepositoryImpl(),
       deliveryAddressRepository =
           deliveryAddressRepository ?? DeliveryAddressRepositoryImpl(),
       profileRepository = profileRepository ?? UserProfileRepositoryImpl();

  final AuthRepository authRepository;
  final DeliveryAddressRepository deliveryAddressRepository;
  final UserProfileRepository profileRepository;
  final CustomerRegistrationCoordinator? registrationCoordinator;

  /// Creates the root MaterialApp, startup screen, and authentication routes.
  @override
  Widget build(BuildContext context) {
    final customerRegistrationCoordinator =
        registrationCoordinator ??
        CustomerRegistrationCoordinator(
          authRepository: authRepository,
          profileRepository: profileRepository,
        );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Splash(
        authRepository: authRepository,
        deliveryAddressRepository: deliveryAddressRepository,
        profileRepository: profileRepository,
      ),
      routes: {
        '/login': (_) => LoginScreen(
          authRepository: authRepository,
          deliveryAddressRepository: deliveryAddressRepository,
          profileRepository: profileRepository,
        ),
        '/register': (_) => RegisterScreen(
          authRepository: authRepository,
          deliveryAddressRepository: deliveryAddressRepository,
          registrationCoordinator: customerRegistrationCoordinator,
          profileRepository: profileRepository,
        ),
      },
    );
  }
}
