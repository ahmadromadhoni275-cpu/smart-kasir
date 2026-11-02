class ShiftModel {
  final int shiftId;
  final int storeId;
  final int userId;
  final String? shiftName;
  final String status;
  final double expectedCash;

  ShiftModel({
    required this.shiftId,
    required this.storeId,
    required this.userId,
    this.shiftName,
    required this.status,
    required this.expectedCash,
  });

  factory ShiftModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ShiftModel(shiftId: 0, storeId: 0, userId: 0, status: 'CLOSED', expectedCash: 0);
    return ShiftModel(
      shiftId: int.tryParse(json['shift_id']?.toString() ?? '0') ?? 0,
      storeId: int.tryParse(json['store_id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      shiftName: json['shift_name']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'OPEN',
      expectedCash: double.tryParse(json['expected_cash']?.toString() ?? '0') ?? 0.0,
    );
  }
}
