// Starts the app only after Flutter bindings and Firebase are ready.
import 'package:flutter/material.dart';
import 'package:grabber_app/app/app.dart';
import 'package:grabber_app/core/config/firebase_initializer.dart';

/// Initializes Firebase before mounting the root application widget.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.initialize();
  runApp(MyApp());
}
