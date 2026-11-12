class PlanModel {
  final int planId;
  final String name;
  final double price;
  final String billingCycle;
  final List<String> features;

  PlanModel({
    required this.planId,
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.features,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      planId: int.tryParse(json['plan_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Paket',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      billingCycle: json['billing_cycle']?.toString() ?? 'MONTHLY',
      features: json['features'] != null ? List<String>.from(json['features']) : [],
    );
  }
}
