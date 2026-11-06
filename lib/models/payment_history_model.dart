class PaymentHistoryModel {
  final int paymentId;
  final String invoiceNumber;
  final double amount;
  final String planName;
  final String status;
  final String createdAt;
  final String? notes;

  PaymentHistoryModel({
    required this.paymentId,
    required this.invoiceNumber,
    required this.amount,
    required this.planName,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      paymentId: int.tryParse(json['payment_id']?.toString() ?? '0') ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? '-',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      planName: json['plan_name']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['created_at']?.toString() ?? '-',
      notes: json['notes']?.toString(),
    );
  }
}
