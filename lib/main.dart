import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkflow_manager/app.dart';
import 'package:parkflow_manager/core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for consistent lot map display
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependency injection
  await configureDependencies();

  runApp(ParkFlowApp());
}
