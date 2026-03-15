import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/database/app_database.dart';
import 'package:parkflow_manager/core/database/database_provider.dart';
import 'package:parkflow_manager/core/network/api_client.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/network/sync_service.dart';
import 'package:parkflow_manager/core/services/incident_service.dart';

@module
abstract class RegisterModule {
  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions:
            IOSOptions(accessibility: KeychainAccessibility.first_unlock),
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
  @preResolve
  Future<AppDatabase> database() => DatabaseProvider.getDatabase();

  @singleton
  SyncService syncService(
    AppDatabase database,
    ApiClient apiClient,
    NetworkInfo networkInfo,
  ) =>
      SyncService(
        database: database,
        apiClient: apiClient,
        networkInfo: networkInfo,
      );

  @singleton
  IncidentService incidentService(AppDatabase database) =>
      IncidentService(database: database);
}
