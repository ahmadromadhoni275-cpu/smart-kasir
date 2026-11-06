class PlanModel {
  final int planId;
  final String name;
  final String code;
  final double price;
  final String billingCycle;
  final int maxStores;
  final int maxUsers;
  final int maxProducts;
  final List<String> features;

  PlanModel({
    required this.planId,
    required this.name,
    required this.code,
    required this.price,
    required this.billingCycle,
    required this.maxStores,
    required this.maxUsers,
    required this.maxProducts,
    required this.features,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    var featureList = json['features'] as List? ?? [];
    return PlanModel(
      planId: int.tryParse(json['plan_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      billingCycle: json['billing_cycle']?.toString() ?? 'MONTHLY',
      maxStores: int.tryParse(json['max_stores']?.toString() ?? '1') ?? 1,
      maxUsers: int.tryParse(json['max_users']?.toString() ?? '1') ?? 1,
      maxProducts: int.tryParse(json['max_products']?.toString() ?? '100') ?? 100,
      features: featureList.map((e) => e.toString()).toList(),
    );
  }
}
