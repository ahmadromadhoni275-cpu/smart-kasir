class StoreUserModel {
  final int storeUserId;
  final int storeId;
  final int userId;
  final String role; // OWNER, MANAGER, KASIR
  final String status;
  
  // Data tambahan hasil JOIN yang sering dibutuhkan di UI
  final String? userName;
  final String? userPhone;
  final String? storeName;

  StoreUserModel({
    required this.storeUserId,
    required this.storeId,
    required this.userId,
    required this.role,
    required this.status,
    this.userName,
    this.userPhone,
    this.storeName,
  });

  factory StoreUserModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return StoreUserModel(storeUserId: 0, storeId: 0, userId: 0, role: 'KASIR', status: 'INACTIVE');
    }
    return StoreUserModel(
      storeUserId: int.tryParse(json['store_user_id']?.toString() ?? '0') ?? 0,
      storeId: int.tryParse(json['store_id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      role: json['role']?.toString().toUpperCase() ?? 'KASIR',
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      userName: json['user_name']?.toString(),
      userPhone: json['user_phone']?.toString(),
      storeName: json['store_name']?.toString(),
    );
  }
}
