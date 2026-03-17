import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';

/// Payload emitted when the camera service detects a license plate.
class PlateDetectionEvent {

  const PlateDetectionEvent({
    required this.licensePlate,
    required this.confidence,
    required this.timestamp,
  });

  factory PlateDetectionEvent.fromJson(Map<String, dynamic> json) {
    return PlateDetectionEvent(
      licensePlate: json['license_plate'] as String,
      confidence: json['confidence'] as String? ?? 'high',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
  final String licensePlate;
  final String confidence;
  final DateTime timestamp;
}

/// Manages the WebSocket connection to the ALPR camera system.
///
/// Security improvements over naive implementation:
/// - Token is sent via an `auth` protocol message after connection,
///   not as a query parameter (which gets logged in server access logs).
/// - Exponential backoff on reconnect (2s → 4s → 8s → 16s → 30s cap).
/// - Heartbeat ping every 30s to detect dead connections.
/// - Validates message structure before processing.
class CameraWebSocketService {
  WebSocketChannel? _channel;
  final StreamController<PlateDetectionEvent> _plateController =
      StreamController.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController.broadcast();

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _disposed = false;
  bool _authenticated = false;
  String? _lotId;
  String? _authToken;
  int _reconnectAttempts = 0;

  static const _maxReconnectDelay = Duration(seconds: 30);
  static const _heartbeatInterval = Duration(seconds: 30);

  /// Stream of detected license plate events from the camera.
  Stream<PlateDetectionEvent> get plateStream => _plateController.stream;

  /// Stream of WebSocket connection status changes.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Whether the WebSocket is authenticated and receiving events.
  bool get isAuthenticated => _authenticated;

  /// Connect to the camera WebSocket for the given [lotId].
  void connect(String lotId, {required String authToken}) {
    _lotId = lotId;
    _authToken = authToken;
    _reconnectAttempts = 0;
    _connect();
  }

  void _connect() {
    if (_disposed) return;

    // Connect WITHOUT the token in the URL — token goes via protocol message
    final uri = Uri.parse('${ApiConstants.cameraWebSocket}/$_lotId');

    try {
      _channel = WebSocketChannel.connect(uri);
      _statusController.add(ConnectionStatus.connecting);
      _authenticated = false;

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Send auth message immediately after connection
      _sendAuthMessage();
      _startHeartbeat();
    } catch (e) {
      _statusController.add(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  /// Authenticates via a protocol-level message instead of query params.
  void _sendAuthMessage() {
    if (_authToken == null) return;
    _channel?.sink.add(jsonEncode({
      'type': 'auth',
      'payload': {'token': _authToken},
    }));
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final eventType = json['type'] as String?;

      switch (eventType) {
        case 'auth_success':
          _authenticated = true;
          _reconnectAttempts = 0; // Reset backoff on successful auth
          _statusController.add(ConnectionStatus.connected);

        case 'auth_failed':
          _authenticated = false;
          _statusController.add(ConnectionStatus.authFailed);
          // Do NOT reconnect on auth failure — token is invalid
          _stopHeartbeat();

        case 'plate_detected':
          if (!_authenticated) return; // Ignore events before auth
          final payload = json['payload'];
          if (payload is! Map<String, dynamic>) return;
          if (!payload.containsKey('license_plate')) return;
          final event = PlateDetectionEvent.fromJson(payload);
          _plateController.add(event);

        case 'pong':
          // Heartbeat response — connection is alive
          break;

        default:
          if (kDebugMode) {
            debugPrint('CameraWS: Unknown event type: $eventType');
          }
      }
    } catch (_) {
      // Silently ignore malformed messages — do not crash on bad data
    }
  }

  void _onError(dynamic error) {
    _authenticated = false;
    _statusController.add(ConnectionStatus.disconnected);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _onDone() {
    _authenticated = false;
    _statusController.add(ConnectionStatus.disconnected);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  /// Exponential backoff: 2s, 4s, 8s, 16s, capped at 30s.
  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    final delay = Duration(
      milliseconds: min(
        _maxReconnectDelay.inMilliseconds,
        (2000 * pow(2, _reconnectAttempts)).toInt(),
      ),
    );
    _reconnectAttempts++;

    _reconnectTimer = Timer(delay, _connect);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _channel?.sink.add(jsonEncode({'type': 'ping'}));
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Disconnect and release all resources.
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _channel?.sink.close();
    _plateController.close();
    _statusController.close();
  }
}

enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
  /// Token was rejected by the server.
  authFailed,
}
