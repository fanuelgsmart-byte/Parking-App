import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parkflow_manager/bootstrap/bootstrap.dart' as bootstrap;

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await bootstrap.run();
    },
    (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
      debugPrint('Uncaught error: $error');
      debugPrint('$stackTrace');
    },
  );
}
