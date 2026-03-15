class ApiConstants {
  ApiConstants._();

  // ──────────── Environment-Based Configuration ────────────
  // Pass via --dart-define at build time:
  //   flutter run --dart-define=API_BASE_URL=https://staging.parkflow.com/v1
  //   flutter run --dart-define=WS_BASE_URL=wss://staging.parkflow.com/ws

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.parkflow.example.com/v1',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://api.parkflow.example.com/ws',
  );

  // ──────────── Timeouts ────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // ──────────── Certificate Pinning ────────────
  // Hosts that are allowed for network requests
  static const List<String> pinnedHosts = [
    'api.parkflow.example.com',
    // Add staging/dev hosts as needed via dart-define
  ];

  // SHA-256 fingerprints of trusted server certificates.
  // Replace with actual fingerprints before release.
  // Generate with:
  //   openssl s_client -connect api.parkflow.example.com:443 \
  //     | openssl x509 -fingerprint -sha256 -noout
  static const List<List<int>> pinnedCertFingerprints = [
    // Primary cert fingerprint (placeholder — MUST replace before production)
    // Example: [0xAB, 0xCD, 0xEF, ...]
  ];

  // ──────────── Auth Endpoints ────────────
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // ──────────── Parking Session Endpoints ────────────
  static const String sessions = '/sessions';
  static const String activeSessions = '/sessions/active';
  static const String sessionCheckout = '/sessions/{id}/checkout';

  // ──────────── Lot Endpoints ────────────
  static const String lots = '/lots';
  static const String lotSpots = '/lots/{id}/spots';

  // ──────────── Payment Endpoints ────────────
  static const String payments = '/payments';
  static const String paymentQr = '/payments/qr';

  // ──────────── Report Endpoints ────────────
  static const String reportsRevenue = '/reports/revenue';
  static const String reportsOccupancy = '/reports/occupancy';
  static const String reportsEmployeePerformance = '/reports/employees';

  // ──────────── Employee Endpoints ────────────
  static const String employees = '/employees';

  // ──────────── Rate Endpoints ────────────
  static const String rates = '/rates';

  // ──────────── Camera WebSocket ────────────
  static const String cameraWebSocket = '$wsBaseUrl/camera';
}
