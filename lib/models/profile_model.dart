class ProfileModel {
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String globalRole;
  final String status;
  final String? referralCode;

  ProfileModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.globalRole,
    required this.status,
    this.referralCode,
  });

  factory ProfileModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ProfileModel(userId: 0, name: 'User', email: '', phone: '', globalRole: 'USER', status: 'UNVERIFIED');
    }
    return ProfileModel(
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Ahmad Romadhoni',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      globalRole: json['global_role']?.toString().toUpperCase() ?? 'USER',
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      referralCode: json['referral_code']?.toString(),
    );
  }
}
