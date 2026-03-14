class ApiConstants {
  ApiConstants._();

  // Base URL - configure per environment
  static const String baseUrl = 'https://api.parkflow.example.com/v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Parking Session Endpoints
  static const String sessions = '/sessions';
  static const String activeSessions = '/sessions/active';
  static const String sessionCheckout = '/sessions/{id}/checkout';

  // Lot Endpoints
  static const String lots = '/lots';
  static const String lotSpots = '/lots/{id}/spots';

  // Payment Endpoints
  static const String payments = '/payments';
  static const String paymentQr = '/payments/qr';

  // Report Endpoints
  static const String reportsRevenue = '/reports/revenue';
  static const String reportsOccupancy = '/reports/occupancy';
  static const String reportsEmployeePerformance = '/reports/employees';

  // Employee Endpoints
  static const String employees = '/employees';

  // Rate Endpoints
  static const String rates = '/rates';

  // Camera WebSocket
  static const String cameraWebSocket = 'wss://api.parkflow.example.com/ws/camera';
}
