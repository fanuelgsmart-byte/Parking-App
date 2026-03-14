import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:parkflow_manager/core/constants/api_constants.dart';

/// Payload emitted when the camera service detects a license plate.
class PlateDetectionEvent {
  final String licensePlate;
  final String confidence;
  final DateTime timestamp;

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
}

/// Manages the WebSocket connection to the ALPR camera system.
///
/// Usage:
/// ```dart
/// final service = CameraWebSocketService();
/// service.connect('lot-01', authToken: token);
/// service.plateStream.listen((event) { ... });
/// service.dispose();
/// ```
class CameraWebSocketService {
  WebSocketChannel? _channel;
  final StreamController<PlateDetectionEvent> _plateController =
      StreamController.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController.broadcast();

  Timer? _reconnectTimer;
  bool _disposed = false;
  String? _lotId;
  String? _authToken;

  /// Stream of detected license plate events from the camera.
  Stream<PlateDetectionEvent> get plateStream => _plateController.stream;

  /// Stream of WebSocket connection status changes.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Connect to the camera WebSocket for the given [lotId].
  void connect(String lotId, {required String authToken}) {
    _lotId = lotId;
    _authToken = authToken;
    _connect();
  }

  void _connect() {
    if (_disposed) return;

    final uri = Uri.parse(
      '${ApiConstants.cameraWebSocket}/$_lotId?token=$_authToken',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _statusController.add(ConnectionStatus.connecting);

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _statusController.add(ConnectionStatus.connected);
    } catch (e) {
      _statusController.add(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final eventType = json['type'] as String?;

      if (eventType == 'plate_detected') {
        final event = PlateDetectionEvent.fromJson(
          json['payload'] as Map<String, dynamic>,
        );
        _plateController.add(event);
      }
    } catch (_) {
      // Ignore malformed messages
    }
  }

  void _onError(dynamic error) {
    _statusController.add(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _onDone() {
    _statusController.add(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _connect);
  }

  /// Send a ping to keep the connection alive.
  void ping() {
    _channel?.sink.add(jsonEncode({'type': 'ping'}));
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _plateController.close();
    _statusController.close();
  }
}

enum ConnectionStatus { connecting, connected, disconnected }
