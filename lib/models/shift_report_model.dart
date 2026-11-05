class ShiftReportItem {
  final int shiftId;
  final String userName;
  final String status;
  final String openedAt;
  final String closedAt;
  
  final double openingCash;
  final double cashSales;
  final double cashIn;
  final double cashOut;
  final double withdrawal;
  final double actualCash;
  final double expectedCash;
  final double difference;

  ShiftReportItem({
    required this.shiftId,
    required this.userName,
    required this.status,
    required this.openedAt,
    required this.closedAt,
    required this.openingCash,
    required this.cashSales,
    required this.cashIn,
    required this.cashOut,
    required this.withdrawal,
    required this.actualCash,
    required this.expectedCash,
    required this.difference,
  });

  factory ShiftReportItem.fromJson(Map<String, dynamic> json) {
    double opening = double.tryParse(json['opening_cash']?.toString() ?? '0') ?? 0;
    double sales = double.tryParse(json['cash_sales']?.toString() ?? '0') ?? 0;
    double inCash = double.tryParse(json['cash_in']?.toString() ?? '0') ?? 0;
    double outCash = double.tryParse(json['cash_out']?.toString() ?? '0') ?? 0;
    double wDraw = double.tryParse(json['withdrawal']?.toString() ?? '0') ?? 0;
    double actual = double.tryParse(json['actual_cash']?.toString() ?? '0') ?? 0;
    
    // Hitung expected cash jika dari server null
    double expected = double.tryParse(json['expected_cash']?.toString() ?? '0') ?? 0;
    if (json['expected_cash'] == null) {
      expected = opening + sales + inCash - outCash - wDraw;
    }

    String stat = json['status']?.toString().toUpperCase() ?? 'OPEN';
    
    // Hitung selisih jika dari server null (Hanya jika CLOSED)
    double diff = double.tryParse(json['difference']?.toString() ?? '0') ?? 0;
    if (json['difference'] == null && stat == 'CLOSED') {
      diff = actual - expected;
    }

    return ShiftReportItem(
      shiftId: int.tryParse(json['shift_id']?.toString() ?? '0') ?? 0,
      userName: json['user_name']?.toString() ?? json['kasir_name']?.toString() ?? 'Kasir',
      status: stat,
      openedAt: json['opened_at']?.toString() ?? '',
      closedAt: json['closed_at']?.toString() ?? '',
      openingCash: opening,
      cashSales: sales,
      cashIn: inCash,
      cashOut: outCash,
      withdrawal: wDraw,
      actualCash: actual,
      expectedCash: expected,
      difference: diff,
    );
  }

  bool get isClosed => status == 'CLOSED';
}
