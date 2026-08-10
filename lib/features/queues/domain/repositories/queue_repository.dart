import 'package:queuewise/shared/models/queue_model.dart';
import 'package:queuewise/shared/models/token_model.dart';

/// Queue repository interface
abstract class QueueRepository {
  /// Get or create queue for organisation and service
  Future<QueueModel> getOrCreateQueue(String organisationId, String serviceId);

  /// Get queue by ID
  Future<QueueModel?> getQueue(String queueId);

  /// Join queue (atomic token generation)
  Future<TokenModel> joinQueue({
    required String organisationId,
    required String serviceId,
    required String userId,
  });

  /// Get user's active token
  Future<TokenModel?> getUserActiveToken(String userId);

  /// Cancel token
  Future<void> cancelToken(String tokenId);

  /// Get tokens for a queue
  Future<List<TokenModel>> getQueueTokens(String queueId);

  /// Calculate people ahead for a token
  Future<int> calculatePeopleAhead(String queueId, int tokenNumber);

  /// Update queue statistics
  Future<void> updateQueueStats(String queueId, int totalWaiting);

  /// Staff: Call next customer in queue
  Future<TokenModel?> callNextCustomer(String organisationId, String queueId);

  /// Staff: Start serving a customer
  Future<void> startServing(String tokenId);

  /// Staff: Complete service for a customer
  Future<void> completeService(String tokenId);

  /// Staff: Skip a customer
  Future<void> skipCustomer(String tokenId);

  /// Staff: Recall a skipped customer
  Future<void> recallCustomer(String tokenId);

  /// Staff: Mark customer as no-show
  Future<void> markNoShow(String tokenId);

  /// Get queue statistics
  Future<Map<String, dynamic>> getQueueStatistics(String organisationId);
}
