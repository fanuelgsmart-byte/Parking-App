import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:parkflow_manager/app.dart';
import 'package:parkflow_manager/core/di/injection.dart';

Future<void> run() async {
  await configureDependencies();

  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      Logger().e(
        'Flutter error',
        error: details.exception,
        stackTrace: details.stack,
      );
    }
  };

  if (!kDebugMode) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ParkFlowApp());
}
