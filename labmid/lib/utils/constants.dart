/// App constants
class AppConstants {
  // App info
  static const String appName = 'Smart POS';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Full Inventory Management System';
  
  // Validation rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  
  // Error messages
  static const String networkError = 'Please check your internet connection';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String authError = 'Authentication failed. Please try again.';
  
  // Success messages
  static const String signupSuccess = 'Account created successfully!';
  static const String loginSuccess = 'Welcome back!';
  static const String logoutSuccess = 'Logged out successfully';
  static const String resetPasswordSuccess = 'Password reset link sent to your email';
  
  // Firebase collection names
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String inventoryCollection = 'inventory';
  static const String categoriesCollection = 'categories';
  static const String stockMovementsCollection = 'stock_movements';
  
  // SharedPreferences keys
  static const String rememberMeKey = 'remember_me';
  static const String userEmailKey = 'user_email';
  static const String userIdKey = 'user_id';
  
  // Database
  static const String databaseName = 'smartpos.db';
  static const int databaseVersion = 5; // Incremented for ledger table
  
  // UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const Duration splashDuration = Duration(seconds: 3);
}
