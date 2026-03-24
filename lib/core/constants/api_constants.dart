class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.parkflow.example.com/v1',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://api.parkflow.example.com/ws',
  );

  static const String pinnedHostsCsv = String.fromEnvironment(
    'PINNED_HOSTS',
    defaultValue: 'api.parkflow.example.com',
  );

  static const String pinnedFingerprintHex = String.fromEnvironment(
    'PINNED_CERT_SHA256',
    defaultValue: '',
  );

  static List<String> get pinnedHosts => pinnedHostsCsv
      .split(',')
      .map((host) => host.trim())
      .where((host) => host.isNotEmpty)
      .toList();

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  static const String sessions = '/sessions';
  static const String activeSessions = '/sessions/active';
  static const String sessionCheckout = '/sessions/{id}/checkout';

  static const String lots = '/lots';
  static const String lotSpots = '/lots/{id}/spots';

  static const String payments = '/payments';
  static const String paymentQr = '/payments/qr';

  static const String reportsRevenue = '/reports/revenue';
  static const String reportsOccupancy = '/reports/occupancy';
  static const String reportsEmployeePerformance = '/reports/employees';

  static const String employees = '/employees';
  static const String rates = '/rates';
  static const String cameraPreRegister = '/camera/pre-register';
  static const String cameraPair = '/camera/pair';
  static const String cameraConfig = '/camera/config';
  static const String cameraDevices = '/camera/devices';
  static const String cameraFrame = '/camera/frame';
  static const String cameraWebSocket = '$wsBaseUrl/camera';

  static const String businessRegister = '/businesses/register';
  static const String businessMe = '/businesses/me';
}
