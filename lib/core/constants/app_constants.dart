class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'ParkFlow Manager';
  static const String appVersion = '1.0.0';

  // Vehicle Sizes
  static const String vehicleSizeSmall = 'small';
  static const String vehicleSizeMedium = 'medium';
  static const String vehicleSizeLarge = 'large';

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentDigital = 'digital';

  // User Roles
  static const String roleEmployee = 'employee';
  static const String roleManager = 'manager';

  // Session Status
  static const String sessionActive = 'active';
  static const String sessionCompleted = 'completed';
  static const String sessionFlaggedForCheckout = 'flagged_for_checkout';

  // Spot Status
  static const String spotAvailable = 'available';
  static const String spotOccupied = 'occupied';
  static const String spotReserved = 'reserved';

  // Sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
}
