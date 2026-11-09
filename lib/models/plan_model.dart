class PlanModel {
  final int planId;
  final String name;
  final double price;
  final String billingCycle;
  final int maxStores;
  final int maxUsers;
  final int maxProducts;
  final List<String> features;

  PlanModel({
    required this.planId,
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.maxStores,
    required this.maxUsers,
    required this.maxProducts,
    required this.features,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      planId: int.tryParse(json['plan_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Tanpa Nama',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      billingCycle: json['billing_cycle']?.toString() ?? 'MONTHLY',
      maxStores: int.tryParse(json['max_stores']?.toString() ?? '1') ?? 1,
      maxUsers: int.tryParse(json['max_users']?.toString() ?? '1') ?? 1,
      maxProducts: int.tryParse(json['max_products']?.toString() ?? '100') ?? 100,
      // Mengubah array of dynamic menjadi List<String>
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
