class PaymentModel {
  final int paymentId;
  final int transactionId;
  final String method; // CASH, QRIS, TRANSFER
  final double amount;
  final String? referenceNumber;
  final String status; // SUCCESS
  final DateTime? paidAt;

  PaymentModel({
    required this.paymentId,
    required this.transactionId,
    required this.method,
    required this.amount,
    this.referenceNumber,
    required this.status,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PaymentModel(paymentId: 0, transactionId: 0, method: 'CASH', amount: 0, status: 'SUCCESS');
    return PaymentModel(
      paymentId: int.tryParse(json['payment_id']?.toString() ?? '0') ?? 0,
      transactionId: int.tryParse(json['transaction_id']?.toString() ?? '0') ?? 0,
      method: json['method']?.toString().toUpperCase() ?? 'CASH',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      referenceNumber: json['reference_number']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'SUCCESS',
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'].toString()) : null,
    );
  }
}
