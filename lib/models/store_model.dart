
class StoreModel {
  // Mengubah nilai dari API/MySQL menjadi boolean dengan aman.
  static bool _toBool(dynamic value) {
    if (value == true || value == 1) return true;

    final String text = value?.toString().toLowerCase() ?? '';

    return text == '1' ||
        text == 'true' ||
        text == 'yes';
  }

  // Mengubah nilai menjadi integer dengan aman.
  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
  }

  // Mengubah nilai menjadi String dengan aman.
  static String _toString(
    dynamic value, {
    String defaultValue = '',
  }) {
    if (value == null) return defaultValue;

    return value.toString();
  }

  // Properti data cabang.
  final int storeId;
  final int businessId;
  final String name;
  final String address;
  final String phone;
  final String? logo;
  final String status;
  final String role;
  final String accessStatus;

  // Pengaturan fitur per cabang.
  final bool enableTableNumber;
  final bool enableServices;
  final bool enableOrderType;

  // Constructor.
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

  // Mengubah JSON API menjadi StoreModel.
  factory StoreModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return StoreModel(
        storeId: 0,
        businessId: 0,
        name: 'Toko Tidak Dikenal',
        address: '',
        phone: '',
        logo: null,
        status: 'INACTIVE',
        role: 'KASIR',
        accessStatus: 'INACTIVE',
        enableTableNumber: false,
        enableServices: false,
        enableOrderType: false,
      );
    }

    return StoreModel(
      storeId: _toInt(json['store_id']),
      businessId: _toInt(json['business_id']),

      name: _toString(
        json['name'],
        defaultValue: 'Cabang Utama',
      ),

      address: _toString(json['address']),
      phone: _toString(json['phone']),

      logo: json['logo'] == null
          ? null
          : json['logo'].toString(),

      // Backend mengirim store_status.
      status: _toString(
        json['store_status'] ?? json['status'],
        defaultValue: 'ACTIVE',
      ).toUpperCase(),

      role: _toString(
        json['role'],
        defaultValue: 'KASIR',
      ).toUpperCase(),

      accessStatus: _toString(
        json['access_status'],
        defaultValue: 'INACTIVE',
      ).toUpperCase(),

      enableTableNumber: _toBool(
        json['enable_table_number'],
      ),

      enableServices: _toBool(
        json['enable_services'],
      ),

      enableOrderType: _toBool(
        json['enable_order_type'],
      ),
    );
  }

  // Mengubah StoreModel menjadi JSON.
  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'business_id': businessId,
      'name': name,
      'address': address,
      'phone': phone,
      'logo': logo,
      'store_status': status,
      'role': role,
      'access_status': accessStatus,
      'enable_table_number': enableTableNumber,
      'enable_services': enableServices,
      'enable_order_type': enableOrderType,
    };
  }
}
