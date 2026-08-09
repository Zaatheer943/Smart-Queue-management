import 'package:queuewise/shared/models/queue_history_model.dart';

/// History repository interface
abstract class HistoryRepository {
  /// Get user's queue history
  Future<List<QueueHistoryModel>> getUserQueueHistory(String userId);

  /// Get queue history for a specific organisation
  Future<List<QueueHistoryModel>> getOrganisationHistory(String organisationId);
}
