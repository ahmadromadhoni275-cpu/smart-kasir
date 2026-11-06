class SubscriptionModel {
  final int subscriptionId;
  final String planName;
  final String status;
  final String expiredAt;
  final int maxStores;
  final int maxUsers;
  final int maxProducts;

  SubscriptionModel({
    required this.subscriptionId,
    required this.planName,
    required this.status,
    required this.expiredAt,
    required this.maxStores,
    required this.maxUsers,
    required this.maxProducts,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return SubscriptionModel(subscriptionId: 0, planName: 'Belum Berlangganan', status: 'INACTIVE', expiredAt: '-', maxStores: 1, maxUsers: 1, maxProducts: 100);
    }
    return SubscriptionModel(
      subscriptionId: int.tryParse(json['subscription_id']?.toString() ?? '0') ?? 0,
      planName: json['plan_name']?.toString() ?? 'Paket Dasar',
      status: json['status']?.toString() ?? 'INACTIVE',
      expiredAt: json['expired_at']?.toString() ?? '-',
      maxStores: int.tryParse(json['max_stores']?.toString() ?? '1') ?? 1,
      maxUsers: int.tryParse(json['max_users']?.toString() ?? '1') ?? 1,
      maxProducts: int.tryParse(json['max_products']?.toString() ?? '100') ?? 100,
    );
  }
}
