import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/profile/domain/entities/user_profile.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:grabber_app/features/profile/presentation/screens/profile_screen.dart';

void main() {
  testWidgets('profile displays data read for the authenticated UID', (
    WidgetTester tester,
  ) async {
    final authRepository = _FakeAuthRepository();
    final profileRepository = _FakeUserProfileRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          authRepository: authRepository,
          profileRepository: profileRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(profileRepository.requestedUid, 'signed-in-user');
    expect(find.text('Taylor Shopper'), findsOneWidget);
    expect(find.text('shopper@example.com'), findsOneWidget);
    expect(find.text('+201234567890'), findsOneWidget);
    expect(find.text('female'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(
    const AuthUser(
      uid: 'signed-in-user',
      email: 'shopper@example.com',
      emailVerified: true,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserProfileRepository implements UserProfileRepository {
  String? requestedUid;

  @override
  Future<UserProfile?> getProfile(String uid) async {
    requestedUid = uid;
    return const UserProfile(
      uid: 'signed-in-user',
      fullName: 'Taylor Shopper',
      email: 'shopper@example.com',
      mobileNumber: '+201234567890',
      gender: 'female',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
