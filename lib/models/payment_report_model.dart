class PaymentReportItem {
  final String methodGroup;
  final double totalAmount;
  final int paymentCount;

  PaymentReportItem({
    required this.methodGroup,
    required this.totalAmount,
    required this.paymentCount,
  });

  factory PaymentReportItem.fromJson(Map<String, dynamic> json) {
    return PaymentReportItem(
      methodGroup: json['payment_group']?.toString() ?? json['method']?.toString() ?? 'LAINNYA',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentCount: int.tryParse(json['payment_count']?.toString() ?? '0') ?? 0,
    );
  }
}
