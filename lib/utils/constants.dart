class ApiConstants {
  // Primary API URL
  static const String baseUrl = 'https://api.sagansa.id';

  // Fallback API URL (jika primary tidak bisa diakses)
  static const String fallbackBaseUrl = 'https://153.92.13.250';

  // Development/testing flags
  static const bool bypassNetworkCheck = bool.fromEnvironment(
      'BYPASS_NETWORK_CHECK',
      defaultValue: true); // Default true untuk bypass
  static const bool enableDetailedLogging = bool.fromEnvironment(
      'DETAILED_LOGGING',
      defaultValue: false); // Disable by default
  static const bool aggressiveMode = bool.fromEnvironment('AGGRESSIVE_MODE',
      defaultValue: true); // Skip semua network check

  // Get base URL with fallback logic
  static String getBaseUrl() {
    return const String.fromEnvironment('API_URL', defaultValue: baseUrl);
  }

  // Auth Endpoints
  static String get login => '${getBaseUrl()}/login';
  static String get logout => '${getBaseUrl()}/logout';

  // Presence Endpoints
  static String get userPresence => '${getBaseUrl()}/user-presence';
  static String get leaves => '${getBaseUrl()}/leaves';
  static String get checkIn => '${getBaseUrl()}/check-in';
  static String get checkOut => '${getBaseUrl()}/check-out';
  static String get todayPresenceEndpoint => '${getBaseUrl()}/presences/today';
  static String get historyPresenceEndpoint =>
      '${getBaseUrl()}/presences/history';

  // Store Endpoints
  static String get stores => '${getBaseUrl()}/stores';
  static String get shiftStores => '${getBaseUrl()}/shift-stores';

  // Calendar Endpoints
  static String get calendar => '${getBaseUrl()}/calendar';

  // Product Endpoints
  static String get products => '${getBaseUrl()}/products';
  static String get categories => '${getBaseUrl()}/products/categories';

  // Cart Endpoints
  static String get carts => '${getBaseUrl()}/carts';

  // Transaction Endpoints
  static String get transactions => '${getBaseUrl()}/transactions';

  // Salary Endpoints
  static String get salaries => '${getBaseUrl()}/salaries';

  static Map<String, String> headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

class AppConstants {
  // Shared Preferences Keys
  static const String tokenKey = 'token';
  static const String loginDataKey = 'loginData';

  // Status Codes
  static const int statusSuccess = 200;
  static const int statusUnauthorized = 401;

  // Leave Status
  static const int leaveStatusPending = 1;
  static const int leaveStatusApproved = 2;
  static const int leaveStatusRejected = 3;

  // Leave Status Text Colors
  static const Map<int, String> leaveStatusColors = {
    1: '#FFA500', // Orange untuk pending
    2: '#4CAF50', // Green untuk approved
    3: '#F44336', // Red untuk rejected
  };
}
