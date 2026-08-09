/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'QueueWise';
  static const String appVersion = '1.0.0';

  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String organisationsCollection = 'organisations';
  static const String servicesCollection = 'services';
  static const String queuesCollection = 'queues';
  static const String tokensCollection = 'tokens';
  static const String analyticsCollection = 'analytics';
  static const String queueHistoryCollection = 'queueHistory';

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleAdmin = 'admin';

  // Token Status
  static const String tokenStatusWaiting = 'waiting';
  static const String tokenStatusCalled = 'called';
  static const String tokenStatusServing = 'serving';
  static const String tokenStatusServed = 'served';
  static const String tokenStatusCancelled = 'cancelled';
  static const String tokenStatusNoShow = 'no_show';

  // Queue Defaults
  static const int defaultAverageServiceDuration = 5; // minutes
  static const int defaultNotificationThreshold = 2; // people ahead
  static const int maxTokenRetries = 3;

  // Pagination
  static const int defaultPageSize = 20;
  static const int historyPageSize = 20;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
}
