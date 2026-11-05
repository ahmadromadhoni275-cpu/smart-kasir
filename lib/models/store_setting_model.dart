class StoreSettingModel {
  final bool enableProducts;
  final bool enableServices;
  final bool enableTableNumber;
  final bool enableOrderType;

  StoreSettingModel({
    required this.enableProducts,
    required this.enableServices,
    required this.enableTableNumber,
    required this.enableOrderType,
  });

  factory StoreSettingModel.fromJson(Map<String, dynamic> json) {
    return StoreSettingModel(
      // Default true untuk produk, sisanya default false
      enableProducts: (json['enable_products']?.toString() == '1' || json['enable_products'] == true) ? true : false,
      enableServices: (json['enable_services']?.toString() == '1' || json['enable_services'] == true) ? true : false,
      enableTableNumber: (json['enable_table_number']?.toString() == '1' || json['enable_table_number'] == true) ? true : false,
      enableOrderType: (json['enable_order_type']?.toString() == '1' || json['enable_order_type'] == true) ? true : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_products': enableProducts ? 1 : 0,
      'enable_services': enableServices ? 1 : 0,
      'enable_table_number': enableTableNumber ? 1 : 0,
      'enable_order_type': enableOrderType ? 1 : 0,
    };
  }
}
