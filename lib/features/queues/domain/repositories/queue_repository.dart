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
}
