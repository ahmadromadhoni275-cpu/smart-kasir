class StoreModel {
  final int storeId;
  final int businessId;
  final String name;
  final String address;
  final String phone;
  final String? logo;
  final String status;
  final String role; // Diperoleh dari tabel store_users
  final String accessStatus;
  final bool enableTableNumber;
  final bool enableServices;
  final bool enableOrderType;

  StoreModel({
    required this.storeId,
    required this.businessId,
    required this.name,
    required this.address,
    required this.phone,
    this.logo,
    required this.status,
    required this.role,
    required this.accessStatus,
    required this.enableTableNumber,
    required this.enableServices,
    required this.enableOrderType,
  });

  factory StoreModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return StoreModel(
        storeId: 0, businessId: 0, name: 'Toko Tidak Dikenal', address: '', 
        phone: '', status: 'INACTIVE', role: 'KASIR', accessStatus: 'INACTIVE', 
        enableTableNumber: false, enableServices: false, enableOrderType: false
      );
    }
    return StoreModel(
      storeId: int.tryParse(json['store_id']?.toString() ?? '0') ?? 0,
      businessId: int.tryParse(json['business_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Cabang Utama',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      logo: json['logo']?.toString(),
      status: json['store_status']?.toString() ?? 'ACTIVE',
      role: json['role']?.toString().toUpperCase() ?? 'KASIR',
      accessStatus: json['access_status']?.toString() ?? 'ACTIVE',
      // Konversi integer (1/0) dari MySQL TINYINT(1) ke boolean Dart
      enableTableNumber: (json['enable_table_number']?.toString() == '1'),
      enableServices: (json['enable_services']?.toString() == '1'),
      enableOrderType: (json['enable_order_type']?.toString() == '1'),
    );
  }
}
