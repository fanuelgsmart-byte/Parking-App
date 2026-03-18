import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:parkflow_manager/core/network/network_info.dart';
import 'package:parkflow_manager/core/network/sync_service.dart';

@singleton
class SyncCoordinator {
  SyncCoordinator({
    required this.networkInfo,
    required this.syncService,
  });

  final NetworkInfo networkInfo;
  final SyncService syncService;
  StreamSubscription<bool>? _subscription;

  void start() {
    _subscription ??= networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        unawaited(syncService.syncAll());
      }
    });
  }

  void triggerSync() {
    unawaited(syncService.syncAll());
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
