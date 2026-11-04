class ShiftModel {
  final int shiftId;
  final int storeId;
  final int userId;
  final String? userName;
  final String? shiftName;
  final String status;
  final double openingCash;
  final double expectedCash;
  final double actualCash;
  final double difference;
  final String openedAt;
  final String? closedAt;

  ShiftModel({
    required this.shiftId,
    required this.storeId,
    required this.userId,
    this.userName,
    this.shiftName,
    required this.status,
    required this.openingCash,
    required this.expectedCash,
    required this.actualCash,
    required this.difference,
    required this.openedAt,
    this.closedAt,
  });

  factory ShiftModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ShiftModel(shiftId: 0, storeId: 0, userId: 0, status: 'CLOSED', openingCash: 0, expectedCash: 0, actualCash: 0, difference: 0, openedAt: '');
    return ShiftModel(
      shiftId: int.tryParse(json['shift_id']?.toString() ?? '0') ?? 0,
      storeId: int.tryParse(json['store_id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: json['user_name']?.toString() ?? json['kasir_name']?.toString(),
      shiftName: json['shift_name']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'OPEN',
      openingCash: double.tryParse(json['opening_cash']?.toString() ?? '0') ?? 0.0,
      expectedCash: double.tryParse(json['expected_cash']?.toString() ?? '0') ?? 0.0,
      actualCash: double.tryParse(json['actual_cash']?.toString() ?? '0') ?? 0.0,
      difference: double.tryParse(json['difference']?.toString() ?? '0') ?? 0.0,
      openedAt: json['opened_at']?.toString() ?? '',
      closedAt: json['closed_at']?.toString(),
    );
  }
}
