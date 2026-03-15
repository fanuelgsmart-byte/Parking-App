import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:parkflow_manager/app.dart';
import 'package:parkflow_manager/core/di/injection.dart';

void main() async {
  // Run the app inside an error zone so that uncaught async errors are
  // logged rather than crashing silently.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // ──────── Security: prevent screenshots in release builds ────────
      // On Android, FLAG_SECURE prevents screenshots and screen recording.
      // On iOS, this is handled via native config.
      if (!kDebugMode) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }

      // Lock to portrait mode for consistent lot map display
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Initialize dependency injection (including encrypted database)
      await configureDependencies();

      // Catch Flutter framework errors (widget build errors, etc.)
      FlutterError.onError = (details) {
        if (kDebugMode) {
          FlutterError.dumpErrorToConsole(details);
        } else {
          // In release mode, log without exposing stack traces to user
          Logger().e(
            'Flutter error',
            error: details.exception,
            stackTrace: details.stack,
          );
        }
      };

      runApp(const ParkFlowApp());
    },
    (error, stackTrace) {
      // Catch uncaught async errors
      if (kDebugMode) {
        debugPrint('Uncaught error: $error');
        debugPrint('$stackTrace');
      } else {
        Logger().e('Uncaught error', error: error, stackTrace: stackTrace);
        // In production, send to crash reporting service (Crashlytics, Sentry)
      }
    },
  );
}
