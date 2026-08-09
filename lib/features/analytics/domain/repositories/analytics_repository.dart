import 'package:queuewise/shared/models/analytics_model.dart';

/// Analytics repository interface
abstract class AnalyticsRepository {
  /// Get analytics for an organisation
  Future<List<AnalyticsModel>> getOrganisationAnalytics(String organisationId);

  /// Get analytics for a specific service
  Future<List<AnalyticsModel>> getServiceAnalytics(String organisationId, String serviceId);

  /// Get analytics for a date range
  Future<List<AnalyticsModel>> getAnalyticsByDateRange(
    String organisationId,
    DateTime startDate,
    DateTime endDate,
  );
}
