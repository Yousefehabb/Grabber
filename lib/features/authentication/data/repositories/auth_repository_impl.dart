import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:grabber_app/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:grabber_app/features/authentication/domain/entities/auth_user.dart';
import 'package:grabber_app/features/authentication/domain/errors/auth_failure.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';

/// Implements the Auth contract and translates Firebase errors for callers.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({FirebaseAuthDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseAuthDataSource();

  final FirebaseAuthDataSource _dataSource;

  /// Converts Firebase session stream errors into [AuthFailure] values.
  @override
  Stream<AuthUser?> authStateChanges() =>
      _dataSource.authStateChanges().transform(
        StreamTransformer<AuthUser?, AuthUser?>.fromHandlers(
          handleError: (Object error, StackTrace stackTrace, sink) {
            final failure = _toFailure(error, 'session');
            _logFailure(failure, error);
            sink.addError(failure, stackTrace);
          },
        ),
      );

  /// Reloads the current user through the data source and maps failures.
  @override
  Future<AuthUser?> refreshCurrentUser() =>
      _run('refresh-user', _dataSource.refreshCurrentUser);

  /// Signs in through Firebase Auth and rejects an unexpected empty result.
  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _run(
      'sign-in',
      () => _dataSource.signIn(email: email, password: password),
    );
    if (user == null) {
      throw const AuthFailure(code: 'unknown', operation: 'sign-in');
    }
    return user;
  }

  /// Creates only the Firebase Auth account; profile setup is a separate step.
  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    final user = await _run(
      'create-account',
      () => _dataSource.createAccount(email: email, password: password),
    );
    if (user == null) {
      throw const AuthFailure(code: 'unknown', operation: 'create-account');
    }
    return user;
  }

  @override
  Future<void> updateDisplayName(String fullName) => _run(
    'update-display-name',
    () => _dataSource.updateDisplayName(fullName),
  );

  @override
  Future<void> sendVerificationEmail() =>
      _run('send-verification-email', _dataSource.sendEmailVerification);

  @override
  Future<void> signOut() => _run('sign-out', _dataSource.signOut);

  /// Runs one Auth SDK operation and preserves its stack when mapping errors.
  Future<T> _run<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on Object catch (error, stackTrace) {
      final failure = _toFailure(error, operation);
      _logFailure(failure, error);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  /// Keeps Firebase error details out of the domain failure contract.
  AuthFailure _toFailure(Object error, String operation) {
    if (error is AuthFailure) return error;
    return AuthFailure(
      code: error is FirebaseException ? error.code : 'unknown',
      operation: operation,
    );
  }

  /// Logs only safe failure metadata in debug builds.
  void _logFailure(AuthFailure failure, Object error) {
    if (kDebugMode) {
      debugPrint(
        'Authentication ${failure.operation} failed: '
        'code=${failure.code}, type=${error.runtimeType}',
      );
    }
  }
}
