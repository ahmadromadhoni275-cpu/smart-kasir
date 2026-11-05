class ReferralSummaryModel {
  final String referralCode;
  final int validReferrals;
  final int totalInvites;
  final int rewardsClaimed;
  final int nextTarget;
  final int remaining;

  ReferralSummaryModel({
    required this.referralCode,
    required this.validReferrals,
    required this.totalInvites,
    required this.rewardsClaimed,
    required this.nextTarget,
    required this.remaining,
  });

  factory ReferralSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ReferralSummaryModel(
        referralCode: '-', validReferrals: 0, totalInvites: 0, 
        rewardsClaimed: 0, nextTarget: 10, remaining: 10
      );
    }
    return ReferralSummaryModel(
      referralCode: json['referral_code']?.toString() ?? '-',
      validReferrals: int.tryParse(json['valid_referrals']?.toString() ?? '0') ?? 0,
      totalInvites: int.tryParse(json['total_invites']?.toString() ?? '0') ?? 0,
      rewardsClaimed: int.tryParse(json['rewards_claimed']?.toString() ?? '0') ?? 0,
      nextTarget: int.tryParse(json['next_target']?.toString() ?? '10') ?? 10,
      remaining: int.tryParse(json['remaining']?.toString() ?? '10') ?? 10,
    );
  }
  
  double get progress => nextTarget > 0 ? (validReferrals / nextTarget).clamp(0.0, 1.0) : 1.0;
}
