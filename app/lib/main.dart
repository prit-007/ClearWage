import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  FlutterError.onError = (details) {
    AppLogger.error('Flutter error', details.exception, details.stack);
  };

  try {
    await Firebase.initializeApp();
  } catch (e) {
    AppLogger.error('Firebase initialization failed', e);
  }

  runZonedGuarded(
    () {
      runApp(const ProviderScope(child: FactoryWorkforceApp()));
    },
    (error, stackTrace) {
      AppLogger.error('Uncaught zone error', error, stackTrace);
    },
  );
}
