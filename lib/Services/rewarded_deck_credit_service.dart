import 'package:mmobile/Helpers/ad_inventory.dart';
import 'package:mmobile/Objects/recommendation_discovery_session.dart';
import 'package:mmobile/Services/product_analytics.dart';
import 'package:mmobile/Services/service_agent.dart';

/// Persists SDK-authoritative reward value before any generation attempt.
///
/// UXR74 owns the optional sheet and provider playback. This service owns only
/// the durable handoff from UXR69's authoritative callback to UXR73's ledger;
/// it never starts recommendation generation.
class RewardedDeckCreditService {
  RewardedDeckCreditService({
    ServiceAgent? serviceAgent,
    ProductAnalytics? analytics,
  })  : _serviceAgent = serviceAgent ?? ServiceAgent(),
        _analytics = analytics ?? ProductAnalytics.instance;

  final ServiceAgent _serviceAgent;
  final ProductAnalytics _analytics;

  Future<RewardedDeckCreditGrant?> grantAuthoritativeReward({
    required String userId,
    required AuthoritativeAdReward reward,
  }) async {
    if (userId.isEmpty ||
        reward.idempotencyKey.isEmpty ||
        reward.amount <= 0 ||
        reward.type.trim().isEmpty) {
      return null;
    }

    final grant = await _serviceAgent.grantRewardedDeckCredit(
      userId: userId,
      transactionId: reward.idempotencyKey,
      rewardAmount: reward.amount,
      rewardType: reward.type,
    );
    await trackRewardedCreditTransitions(
      grant?.allowance,
      analytics: _analytics,
    );
    return grant;
  }

  Future<RecommendationAllowance?> refreshAllowance(String userId) async {
    final allowance = await _serviceAgent.getRecommendationAllowance(userId);
    await trackRewardedCreditTransitions(allowance, analytics: _analytics);
    return allowance;
  }
}
