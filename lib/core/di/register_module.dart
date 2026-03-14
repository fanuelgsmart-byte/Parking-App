import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/database/database_provider.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/core/network/network_info.dart';

@module
abstract class RegisterModule {
  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  @singleton
  Connectivity get connectivity => Connectivity();

  @singleton
  NetworkInfo networkInfo(Connectivity connectivity) =>
      NetworkInfoImpl(connectivity: connectivity);

  @singleton
  ApiClient apiClient(FlutterSecureStorage secureStorage) =>
      ApiClient(secureStorage: secureStorage);

  @singleton
  AppDatabase get database => DatabaseProvider.database;
}
