import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/logger.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppLogger.init();

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }

      FlutterError.onError = (details) {
        AppLogger.error('Flutter error', details.exception, details.stack);
      };

      try {
        await Firebase.initializeApp();
      } catch (e) {
        AppLogger.error('Firebase initialization failed', e);
      }

      runApp(const ProviderScope(child: FactoryWorkforceApp()));
    },
    (error, stackTrace) {
      AppLogger.error('Uncaught zone error', error, stackTrace);
    },
  );
}
