import 'package:firebase_core/firebase_core.dart';
import 'package:grabber_app/firebase_options.dart';

/// Provides the single Firebase initialization entry point used by `main`.
class FirebaseInitializer {
  FirebaseInitializer._();

  static Future<FirebaseApp>? _initialization;

  /// Returns the existing default app or initializes it with this platform's
  /// generated options. Concurrent calls share the same initialization future.
  static Future<FirebaseApp> initialize() {
    if (Firebase.apps.isNotEmpty) {
      return Future<FirebaseApp>.value(Firebase.app());
    }

    return _initialization ??= Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
