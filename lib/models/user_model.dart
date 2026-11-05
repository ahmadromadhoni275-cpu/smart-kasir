class UserModel {
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String role; // Role di toko saat ini (OWNER, MANAGER, KASIR)
  final String status; // Status akses di toko (ACTIVE, INACTIVE)

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Tanpa Nama',
      email: json['email']?.toString() ?? '-',
      phone: json['phone']?.toString() ?? '-',
      role: json['role']?.toString().toUpperCase() ?? 'KASIR',
      status: json['status']?.toString().toUpperCase() ?? 'INACTIVE',
    );
  }

  bool get isActive => status == 'ACTIVE';
  bool get isOwner => role == 'OWNER';
  bool get isManager => role == 'MANAGER';
}
