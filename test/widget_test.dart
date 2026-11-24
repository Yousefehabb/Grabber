import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grabber_app/app/authenticated_entry_screen.dart';
import 'package:grabber_app/app/app_session.dart';
import 'package:grabber_app/app/customer_registration_coordinator.dart';
import 'package:grabber_app/app/main_navigation_screen.dart';
import 'package:grabber_app/app/app.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/errors/auth_failure.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/authentication/presentation/screens/login.dart';
import 'package:grabber_app/features/authentication/presentation/screens/register.dart';
import 'package:grabber_app/features/authentication/presentation/screens/verify_email.dart';
import 'package:grabber_app/features/basket/presentation/screens/basket_screen.dart';
import 'package:grabber_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:grabber_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:grabber_app/features/home/presentation/screens/home.dart';
import 'package:grabber_app/features/home/presentation/widgets/product_item.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';
import 'package:grabber_app/features/profile/domain/entities/user_profile.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';

void main() {
  testWidgets('Home no longer presents the catalog products', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Home(onOpenBasket: _emptyCallback)),
    );

    expect(find.byType(ProductItem), findsNothing);
    expect(find.text('Banana'), findsNothing);
    expect(find.text('Papper'), findsNothing);
    expect(find.text('Orange'), findsNothing);
    expect(find.text('Egg'), findsNothing);
  });

  testWidgets('selecting a category shows only its products', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: CategoriesScreen(
          onAddProduct: (_) {},
          onDecreaseQuantity: (_) {},
          getQuantity: (_) => 0,
        ),
      ),
    );
    await tester.tap(find.text('Fruits'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductItem), findsAtLeastNWidgets(1));
    expect(
      tester.getSize(find.byType(ProductItem).first).height,
      lessThan(240),
    );
    expect(find.byTooltip('Add Banana to basket'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Papper'), findsOneWidget);
    expect(find.text('Egg'), findsNothing);

    await tester.drag(find.byType(GridView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Orange'), findsOneWidget);
    expect(find.text('Egg'), findsNothing);
  });

  testWidgets('selecting an empty category shows an empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CategoriesScreen(
          onAddProduct: (_) {},
          onDecreaseQuantity: (_) {},
          getQuantity: (_) => 0,
        ),
      ),
    );
    await tester.tap(find.text('Vegetables'));
    await tester.pumpAndSettle();

    expect(find.text('No products in this category yet.'), findsOneWidget);
    expect(find.byType(ProductItem), findsNothing);
  });

  testWidgets('category cards stay compact at a phone viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: CategoriesScreen(
          onAddProduct: (_) {},
          onDecreaseQuantity: (_) {},
          getQuantity: (_) => 0,
        ),
      ),
    );

    final firstCard = find
        .ancestor(of: find.text('Vegetables'), matching: find.byType(Container))
        .first;
    final size = tester.getSize(firstCard);

    expect(size.width, closeTo(172, 1));
    expect(size.height, closeTo(size.width, 1));
  });

  testWidgets('categories scroll without overscroll stretching', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: CategoriesScreen(
          onAddProduct: (_) {},
          onDecreaseQuantity: (_) {},
          getQuantity: (_) => 0,
        ),
      ),
    );

    final grid = find.byType(GridView);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: grid, matching: find.byType(Scrollable)),
    );

    expect(grid, findsOneWidget);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(scrollable.position.pixels, 0);

    await tester.drag(grid, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);

    await tester.drag(grid, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);

    await tester.drag(grid, const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, 0);

    await tester.drag(grid, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, 0);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
  });

  testWidgets('splash transitions to login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        authRepository: _FakeAuthRepository(),
        deliveryAddressRepository: _FakeDeliveryAddressRepository(),
        profileRepository: _FakeUserProfileRepository(),
      ),
    );

    expect(find.text('Fresh finds, delivered.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('splash opens the app for an existing authenticated user', (
    WidgetTester tester,
  ) async {
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      MyApp(
        authRepository: _FakeAuthRepository(
          sessionUser: const AuthUser(
            uid: 'existing-user',
            email: 'shopper@example.com',
            emailVerified: true,
          ),
        ),
        deliveryAddressRepository: deliveryAddressRepository,
        profileRepository: _FakeUserProfileRepository(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.byType(AuthenticatedEntryScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(deliveryAddressRepository.addressReadUids, ['existing-user']);
  });

  testWidgets('splash opens the app for an unverified authenticated user', (
    WidgetTester tester,
  ) async {
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      MyApp(
        authRepository: _FakeAuthRepository(
          sessionUser: const AuthUser(
            uid: 'unverified-user',
            email: 'shopper@example.com',
            emailVerified: false,
          ),
        ),
        deliveryAddressRepository: deliveryAddressRepository,
        profileRepository: _FakeUserProfileRepository(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.byType(AuthenticatedEntryScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsNothing);
  });

  testWidgets('splash does not refresh verification before opening the app', (
    WidgetTester tester,
  ) async {
    final repository =
        _FakeAuthRepository(
            sessionUser: const AuthUser(
              uid: 'possibly-verified-user',
              email: 'shopper@example.com',
              emailVerified: true,
            ),
          )
          ..refreshFailure = const AuthFailure(
            code: 'network-request-failed',
            operation: 'refresh-user',
          );
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      MyApp(
        authRepository: repository,
        deliveryAddressRepository: deliveryAddressRepository,
        profileRepository: _FakeUserProfileRepository(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.byType(AuthenticatedEntryScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsNothing);
    expect(repository.refreshCalls, 0);
  });

  testWidgets('login validates fields and toggles password visibility', (
    WidgetTester tester,
  ) async {
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authRepository: _FakeAuthRepository(),
          deliveryAddressRepository: deliveryAddressRepository,
          profileRepository: _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.tap(find.text('Log in'));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('login does not offer guest access', (WidgetTester tester) async {
    final repository = _FakeAuthRepository();
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authRepository: repository,
          deliveryAddressRepository: deliveryAddressRepository,
          profileRepository: _FakeUserProfileRepository(),
        ),
      ),
    );

    expect(find.text('Continue as Guest'), findsNothing);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(repository.signInCalls, 0);
  });

  testWidgets('login trims email but preserves the entered password', (
    WidgetTester tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authRepository: authRepository,
          deliveryAddressRepository: deliveryAddressRepository,
          profileRepository: _FakeUserProfileRepository(),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      ' shopper@example.com ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), ' secret ');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(authRepository.signInEmail, 'shopper@example.com');
    expect(authRepository.signInPassword, ' secret ');
    expect(find.byType(AuthenticatedEntryScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('unverified login enters the main app', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..signInUser = const AuthUser(
        uid: 'unverified',
        email: 'new@example.com',
        emailVerified: false,
      );
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      _authTestApp(
        repository,
        deliveryAddressRepository: deliveryAddressRepository,
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'new@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password-8');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthenticatedEntryScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsNothing);
    expect(deliveryAddressRepository.addressReadUids, ['unverified']);
  });

  testWidgets('verified login enters the main app', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..signInUser = const AuthUser(
        uid: 'verified',
        email: 'shopper@example.com',
        emailVerified: true,
      );
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      _authTestApp(
        repository,
        deliveryAddressRepository: deliveryAddressRepository,
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'shopper@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password-8');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthenticatedEntryScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsNothing);
    expect(repository.signInCalls, 1);
    expect(deliveryAddressRepository.addressReadUids, ['verified']);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('login error is user friendly and does not expose details', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..signInFailure = const AuthFailure(
        code: 'wrong-password',
        operation: 'sign-in',
      );
    await tester.pumpWidget(_authTestApp(repository));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'shopper@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrect');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('login and registration links navigate between screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_authTestApp(_FakeAuthRepository()));

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);

    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets(
    'registration validates gender and forwards it to the repository',
    (WidgetTester tester) async {
      final authRepository = _FakeAuthRepository();
      final profileRepository = _FakeUserProfileRepository();
      final coordinator = CustomerRegistrationCoordinator(
        authRepository: authRepository,
        profileRepository: profileRepository,
      );
      await tester.pumpWidget(
        _authTestApp(authRepository, registrationCoordinator: coordinator),
      );

      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Mobile number is required'), findsOneWidget);
      expect(find.text('Gender is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Taylor Shopper',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        ' shopper@example.com ',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '+201234567890');
      await tester.enterText(find.byType(TextFormField).at(3), 'short');
      await tester.enterText(find.byType(TextFormField).at(4), 'short');
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField).at(3), 'fresh-picks-8');
      await tester.enterText(
        find.byType(TextFormField).at(4),
        'does-not-match',
      );
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Female').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(4), 'fresh-picks-8');
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(profileRepository.createdProfile?.fullName, 'Taylor Shopper');
      expect(profileRepository.createdProfile?.email, 'shopper@example.com');
      expect(profileRepository.createdProfile?.gender, 'female');
      expect(authRepository.registrationEmail, 'shopper@example.com');
      expect(authRepository.registrationPassword, 'fresh-picks-8');
      expect(find.byType(AuthenticatedEntryScreen), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byType(VerifyEmailScreen), findsNothing);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    },
  );

  testWidgets('registration sends lowercase male gender to the repository', (
    WidgetTester tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    final profileRepository = _FakeUserProfileRepository();
    final coordinator = CustomerRegistrationCoordinator(
      authRepository: authRepository,
      profileRepository: profileRepository,
    );
    await tester.pumpWidget(
      _authTestApp(
        authRepository,
        initial: _registerScreen(
          authRepository,
          registrationCoordinator: coordinator,
          profileRepository: profileRepository,
        ),
        registrationCoordinator: coordinator,
      ),
    );

    await _fillRegistrationForm(tester, gender: 'Male');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(profileRepository.createdProfile?.gender, 'male');
  });

  testWidgets('registration retry preserves the selected gender', (
    WidgetTester tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    final profileRepository = _FakeUserProfileRepository()
      ..createFailure = const ProfileFailure(
        code: 'permission-denied',
        operation: 'create-profile',
      );
    final coordinator = CustomerRegistrationCoordinator(
      authRepository: authRepository,
      profileRepository: profileRepository,
    );
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      _authTestApp(
        authRepository,
        initial: _registerScreen(
          authRepository,
          deliveryAddressRepository: deliveryAddressRepository,
          registrationCoordinator: coordinator,
          profileRepository: profileRepository,
        ),
        deliveryAddressRepository: deliveryAddressRepository,
        registrationCoordinator: coordinator,
      ),
    );

    await _fillRegistrationForm(tester, gender: 'Male');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(profileRepository.createCalls, 1);
    expect(find.text('Retry profile setup'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);

    profileRepository.createFailure = null;
    await tester.tap(find.text('Retry profile setup'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthenticatedEntryScreen), findsOneWidget);
    expect(profileRepository.createCalls, 2);
    expect(authRepository.registrationCalls, 1);
    expect(profileRepository.createdProfile?.gender, 'male');
    expect(deliveryAddressRepository.addressReadUids, ['registered-user']);
  });

  testWidgets('verification refresh grants access only when verified', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..sessionUser = const AuthUser(
        uid: 'pending',
        email: 'shopper@example.com',
        emailVerified: false,
      )
      ..refreshedUser = const AuthUser(
        uid: 'pending',
        email: 'shopper@example.com',
        emailVerified: true,
      );
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      _authTestApp(
        repository,
        initial: _verifyScreen(
          repository,
          deliveryAddressRepository: deliveryAddressRepository,
        ),
        deliveryAddressRepository: deliveryAddressRepository,
      ),
    );

    await tester.tap(find.text("I've Verified My Email"));
    await tester.pumpAndSettle();

    expect(repository.refreshCalls, 1);
    expect(find.byType(AuthenticatedEntryScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(
      tester
          .widget<MainNavigationScreen>(find.byType(MainNavigationScreen))
          .session,
      AppSession.authenticated,
    );
    expect(deliveryAddressRepository.addressReadUids, ['pending']);
  });

  testWidgets('failed verification refresh does not grant access', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..sessionUser = const AuthUser(
        uid: 'pending',
        email: 'shopper@example.com',
        emailVerified: false,
      )
      ..refreshFailure = const AuthFailure(
        code: 'network-request-failed',
        operation: 'refresh-user',
      );
    await tester.pumpWidget(
      _authTestApp(repository, initial: _verifyScreen(repository)),
    );

    await tester.tap(find.text("I've Verified My Email"));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(
      find.text('Network error. Check your connection and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('unverified result after refresh stays on verification screen', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..sessionUser = const AuthUser(
        uid: 'pending',
        email: 'shopper@example.com',
        emailVerified: false,
      )
      ..refreshedUser = const AuthUser(
        uid: 'pending',
        email: 'shopper@example.com',
        emailVerified: false,
      );
    await tester.pumpWidget(
      _authTestApp(repository, initial: _verifyScreen(repository)),
    );

    await tester.tap(find.text("I've Verified My Email"));
    await tester.pumpAndSettle();

    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(find.textContaining('not verified yet'), findsOneWidget);
  });

  testWidgets('resend verification reports success and failure', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      _authTestApp(repository, initial: _verifyScreen(repository)),
    );

    await tester.tap(find.text('Resend Verification Email'));
    await tester.pumpAndSettle();
    expect(repository.resendCalls, 1);
    expect(
      find.text('Verification email sent. Check your inbox.'),
      findsOneWidget,
    );

    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    repository.resendFailure = const AuthFailure(
      code: 'network-request-failed',
      operation: 'send-verification-email',
    );
    await tester.tap(find.text('Resend Verification Email'));
    await tester.pumpAndSettle();
    expect(
      find.text('Network error. Check your connection and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('valid registration opens the main app', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository();
    final profileRepository = _FakeUserProfileRepository();
    final coordinator = CustomerRegistrationCoordinator(
      authRepository: repository,
      profileRepository: profileRepository,
    );
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      _authTestApp(
        repository,
        initial: _registerScreen(
          repository,
          deliveryAddressRepository: deliveryAddressRepository,
          registrationCoordinator: coordinator,
        ),
        deliveryAddressRepository: deliveryAddressRepository,
        registrationCoordinator: coordinator,
        profileRepository: profileRepository,
      ),
    );

    await _fillRegistrationForm(tester, gender: 'Female');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(profileRepository.createdProfile?.fullName, 'Taylor Shopper');
    expect(repository.registrationEmail, 'shopper@example.com');
    expect(profileRepository.createdProfile?.gender, 'female');
    expect(find.byType(AuthenticatedEntryScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(deliveryAddressRepository.addressReadUids, ['registered-user']);
    expect(find.byType(VerifyEmailScreen), findsNothing);
  });

  testWidgets('display name update failure can be retried', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository()
      ..displayNameFailure = const AuthFailure(
        code: 'network-request-failed',
        operation: 'update-display-name',
      );
    final deliveryAddressRepository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(
      _authTestApp(
        repository,
        initial: VerifyEmailScreen(
          authRepository: repository,
          deliveryAddressRepository: deliveryAddressRepository,
          profileRepository: _FakeUserProfileRepository(),
          email: 'shopper@example.com',
          fullNameForRetry: 'Taylor Shopper',
          displayNameNeedsUpdate: true,
        ),
      ),
    );

    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.text('Retry profile name update'), findsOneWidget);

    await tester.tap(find.text('Retry profile name update'));
    await tester.pumpAndSettle();
    expect(repository.updateDisplayNameCalls, 1);
    expect(
      find.text('Network error. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry profile name update'), findsOneWidget);

    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    repository.displayNameFailure = null;
    await tester.tap(find.text('Retry profile name update'));
    await tester.pumpAndSettle();
    expect(repository.updateDisplayNameCalls, 2);
    expect(find.text('Your profile name has been updated.'), findsOneWidget);
  });

  testWidgets('sign out from verification returns to Login', (
    WidgetTester tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      _authTestApp(repository, initial: _verifyScreen(repository)),
    );

    await tester.tap(find.text('Sign out and return to Login'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsNothing);
  });

  testWidgets('bottom navigation switches tabs and preserves the Home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _mainNavigationScreen()));

    expect(
      find.text('Example Street 12A, Nasr City, Cairo').hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.text('Categories'));
    await tester.pump();
    expect(find.text('Browse categories').hitTestable(), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      1,
    );

    await tester.tap(find.text('Favorites'));
    await tester.pump();
    expect(
      find.text('Sign in to view your favorites.').hitTestable(),
      findsOneWidget,
    );
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      2,
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(
      find.text('Please sign in to view your profile.').hitTestable(),
      findsOneWidget,
    );
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      3,
    );

    await tester.tap(find.text('Home'));
    await tester.pump();
    expect(
      find.text('Example Street 12A, Nasr City, Cairo').hitTestable(),
      findsOneWidget,
    );
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      0,
    );

    expect(find.byType(ProductItem), findsNothing);
  });

  testWidgets('product add button updates and removes items from the basket', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _mainNavigationScreen()));

    await tester.tap(find.text('Categories'));
    await tester.pump();
    await tester.tap(find.text('Fruits'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add Banana to basket'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.byTooltip('Increase Banana quantity'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase Banana quantity'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Papper to basket'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Increase Papper quantity'), findsOneWidget);
    expect(find.text('View Basket').hitTestable(), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Subtotal: \$ 10.97').hitTestable(), findsOneWidget);

    await tester.tap(find.text('View Basket'));
    await tester.pumpAndSettle();
    expect(find.byType(BasketScreen), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Papper'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('\$ 7.98'), findsOneWidget);
    expect(find.text('\$ 2.99'), findsAtLeastNWidgets(1));
    expect(find.text('\$ 10.97'), findsOneWidget);

    await tester.tap(find.byTooltip('Decrease Banana quantity'));
    await tester.pumpAndSettle();
    expect(find.text('\$ 6.98'), findsOneWidget);

    await tester.tap(find.byTooltip('Decrease Banana quantity'));
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsNothing);
    expect(find.text('\$ 2.99'), findsAtLeastNWidgets(1));

    await tester.tap(find.byTooltip('Increase Papper quantity'));
    await tester.pumpAndSettle();
    expect(find.text('\$ 5.98'), findsAtLeastNWidgets(1));

    await tester.tap(find.byTooltip('Remove Papper'));
    await tester.pumpAndSettle();
    expect(find.text('Your basket is empty'), findsOneWidget);
  });

  testWidgets('header basket icon opens the basket screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _mainNavigationScreen()));

    await tester.tap(find.byTooltip('Open basket'));
    await tester.pumpAndSettle();

    expect(find.byType(BasketScreen), findsOneWidget);
    expect(find.text('Your basket is empty'), findsOneWidget);
  });

  testWidgets('editing the delivery address refreshes the Home header', (
    WidgetTester tester,
  ) async {
    final addressRepository = _FakeDeliveryAddressRepository()
      ..address = _testDeliveryAddress;
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScreen(
          uid: 'authenticated-user',
          initialAddress: _testDeliveryAddress,
          authRepository: _FakeAuthRepository(),
          favoritesRepository: _FakeFavoritesRepository(),
          deliveryAddressRepository: addressRepository,
        ),
      ),
    );

    await tester.tap(find.text('Example Street 12A, Nasr City, Cairo'));
    await tester.pumpAndSettle();
    expect(find.text('Update your delivery address'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), 'Updated Street');
    await tester.tap(find.text('Update Address'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Street 12A, Nasr City, Cairo'), findsOneWidget);
    expect(addressRepository.address?.streetName, 'Updated Street');
  });
}

Widget _mainNavigationScreen() => MainNavigationScreen(
  uid: 'authenticated-user',
  initialAddress: _testDeliveryAddress,
  authRepository: _FakeAuthRepository(),
  favoritesRepository: _FakeFavoritesRepository(),
  deliveryAddressRepository: _FakeDeliveryAddressRepository(),
);

void _emptyCallback() {}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.sessionUser});

  AuthUser? sessionUser;
  AuthUser? signInUser = const AuthUser(
    uid: 'signed-in-user',
    email: 'shopper@example.com',
    emailVerified: true,
  );
  AuthUser? refreshedUser;
  AuthFailure? signInFailure;
  AuthFailure? refreshFailure;
  AuthFailure? resendFailure;
  AuthFailure? displayNameFailure;
  int signInCalls = 0;
  int registrationCalls = 0;
  int refreshCalls = 0;
  int resendCalls = 0;
  int updateDisplayNameCalls = 0;
  int signOutCalls = 0;
  String? signInEmail;
  String? signInPassword;
  String? registrationEmail;
  String? registrationPassword;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(sessionUser);

  @override
  Future<AuthUser?> refreshCurrentUser() async {
    refreshCalls++;
    final failure = refreshFailure;
    if (failure != null) throw failure;
    return refreshedUser ?? sessionUser;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    signInEmail = email;
    signInPassword = password;
    final failure = signInFailure;
    if (failure != null) throw failure;
    final user = signInUser!;
    sessionUser = user;
    return user;
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    registrationCalls++;
    registrationEmail = email;
    registrationPassword = password;
    final user = AuthUser(
      uid: 'registered-user',
      email: email,
      emailVerified: false,
    );
    sessionUser = user;
    return user;
  }

  @override
  Future<void> updateDisplayName(String fullName) async {
    updateDisplayNameCalls++;
    final failure = displayNameFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> sendVerificationEmail() async {
    resendCalls++;
    final failure = resendFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    sessionUser = null;
  }
}

Widget _authTestApp(
  _FakeAuthRepository repository, {
  Widget? initial,
  DeliveryAddressRepository? deliveryAddressRepository,
  CustomerRegistrationCoordinator? registrationCoordinator,
  UserProfileRepository? profileRepository,
}) {
  final addressRepository =
      deliveryAddressRepository ?? _FakeDeliveryAddressRepository();
  final customerProfileRepository =
      profileRepository ?? _FakeUserProfileRepository();
  final coordinator =
      registrationCoordinator ??
      CustomerRegistrationCoordinator(
        authRepository: repository,
        profileRepository: customerProfileRepository,
      );
  return MaterialApp(
    home:
        initial ??
        LoginScreen(
          authRepository: repository,
          deliveryAddressRepository: addressRepository,
          profileRepository: customerProfileRepository,
        ),
    routes: {
      '/login': (_) => LoginScreen(
        authRepository: repository,
        deliveryAddressRepository: addressRepository,
        profileRepository: customerProfileRepository,
      ),
      '/register': (_) => RegisterScreen(
        authRepository: repository,
        deliveryAddressRepository: addressRepository,
        registrationCoordinator: coordinator,
        profileRepository: customerProfileRepository,
      ),
    },
  );
}

Widget _verifyScreen(
  _FakeAuthRepository repository, {
  DeliveryAddressRepository? deliveryAddressRepository,
  UserProfileRepository? profileRepository,
}) => VerifyEmailScreen(
  authRepository: repository,
  deliveryAddressRepository:
      deliveryAddressRepository ?? _FakeDeliveryAddressRepository(),
  profileRepository: profileRepository ?? _FakeUserProfileRepository(),
  email: 'shopper@example.com',
);

Widget _registerScreen(
  _FakeAuthRepository repository, {
  DeliveryAddressRepository? deliveryAddressRepository,
  CustomerRegistrationCoordinator? registrationCoordinator,
  UserProfileRepository? profileRepository,
}) {
  final customerProfileRepository =
      profileRepository ?? _FakeUserProfileRepository();
  return RegisterScreen(
    authRepository: repository,
    deliveryAddressRepository:
        deliveryAddressRepository ?? _FakeDeliveryAddressRepository(),
    registrationCoordinator:
        registrationCoordinator ??
        CustomerRegistrationCoordinator(
          authRepository: repository,
          profileRepository: customerProfileRepository,
        ),
    profileRepository: customerProfileRepository,
  );
}

class _FakeUserProfileRepository implements UserProfileRepository {
  ProfileFailure? createFailure;
  UserProfile? createdProfile;
  UserProfile? existingProfile = const UserProfile(
    uid: 'signed-in-user',
    fullName: 'Taylor Shopper',
    email: 'shopper@example.com',
    mobileNumber: '+201234567890',
    gender: 'female',
  );
  int createCalls = 0;

  @override
  Future<void> createProfile(UserProfile profile) async {
    createCalls++;
    final failure = createFailure;
    if (failure != null) throw failure;
    createdProfile = profile;
  }

  @override
  Future<UserProfile?> getProfile(String uid) async =>
      createdProfile ?? existingProfile;
}

const _testDeliveryAddress = DeliveryAddress(
  city: 'Cairo',
  district: 'Nasr City',
  streetName: 'Example Street',
  buildingNumber: '12A',
);

class _FakeDeliveryAddressRepository implements DeliveryAddressRepository {
  DeliveryAddress? address = _testDeliveryAddress;
  Object? readFailure;
  int readCalls = 0;
  int saveCalls = 0;
  final List<String> addressReadUids = [];

  @override
  Future<DeliveryAddress?> getAddress(String uid) async {
    readCalls++;
    addressReadUids.add(uid);
    final failure = readFailure;
    if (failure != null) throw failure;
    return address;
  }

  @override
  Future<void> saveAddress({
    required String uid,
    required DeliveryAddress address,
  }) async {
    saveCalls++;
    this.address = address;
  }
}

class _FakeFavoritesRepository implements FavoritesRepository {
  @override
  Future<Set<String>> getFavoriteProductIds(String uid) async => {};

  @override
  Future<void> addFavorite({
    required String uid,
    required String productId,
  }) async {}

  @override
  Future<void> removeFavorite({
    required String uid,
    required String productId,
  }) async {}
}

Future<void> _fillRegistrationForm(
  WidgetTester tester, {
  required String gender,
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Taylor Shopper');
  await tester.enterText(
    find.byType(TextFormField).at(1),
    'shopper@example.com',
  );
  await tester.enterText(find.byType(TextFormField).at(2), '+201234567890');
  await tester.enterText(find.byType(TextFormField).at(3), 'fresh-picks-8');
  await tester.enterText(find.byType(TextFormField).at(4), 'fresh-picks-8');
  final genderDropdown = find.byType(DropdownButtonFormField<String>);
  await tester.ensureVisible(genderDropdown);
  await tester.pumpAndSettle();
  await tester.tap(genderDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(gender).last);
  await tester.pumpAndSettle();
}
