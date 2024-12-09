class ApiConstants {
  // static const String baseUrl =
  //     String.fromEnvironment('API_URL', defaultValue: 'https://api.sagansa.id');
  static const String baseUrl = 'https://api.sagansa.id';

  // Auth Endpoints
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';

  // Presence Endpoints
  static const String userPresence = '$baseUrl/user-presence';
  static const String leaves = '$baseUrl/leaves';
  static const String checkIn = '$baseUrl/check-in';
  static const String checkOut = '$baseUrl/check-out';
  static const String todayPresenceEndpoint = '$baseUrl/presences/today';
  static const String historyPresenceEndpoint = '$baseUrl/presences/history';

  // Store Endpoints
  static const String stores = '$baseUrl/stores';
  static const String shiftStores = '$baseUrl/shift-stores';

  // Calendar Endpoints
  static const String calendar = '$baseUrl/calendar';

  // Product Endpoints
  static const String products = '$baseUrl/products';
  static const String categories = '$baseUrl/products/categories';

  // Cart Endpoints
  static const String carts = '$baseUrl/carts';

  // Transaction Endpoints
  static const String transactions = '$baseUrl/transactions';

  // Salary Endpoints
  static const String salaries = '$baseUrl/salaries';

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
