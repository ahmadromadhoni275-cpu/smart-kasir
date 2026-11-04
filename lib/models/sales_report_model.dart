class SalesReportItem {
  final String invoiceNumber;
  final double grandTotal;
  final String transactionStatus;
  final String paymentStatus;
  final String createdAt;

  SalesReportItem({
    required this.invoiceNumber,
    required this.grandTotal,
    required this.transactionStatus,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory SalesReportItem.fromJson(Map<String, dynamic> json) {
    return SalesReportItem(
      invoiceNumber: json['invoice_number']?.toString() ?? '-',
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0.0,
      transactionStatus: json['transaction_status']?.toString() ?? 'COMPLETED',
      paymentStatus: json['payment_status']?.toString() ?? 'PAID',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
