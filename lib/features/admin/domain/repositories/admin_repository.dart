import 'package:queuewise/shared/models/token_model.dart';

/// Admin repository interface
abstract class AdminRepository {
  /// Call next token in queue
  Future<TokenModel?> callNextToken(String queueId);

  /// Mark token as serving
  Future<void> markTokenAsServing(String tokenId);

  /// Mark token as served
  Future<void> markTokenAsServed(String tokenId);

  /// Mark token as no-show
  Future<void> markTokenAsNoShow(String tokenId);

  /// Get waiting tokens for a queue
  Future<List<TokenModel>> getWaitingTokens(String queueId);

  /// Get current serving token
  Future<TokenModel?> getCurrentServingToken(String queueId);
}
