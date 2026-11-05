class ReturnReportItem {
  final int returnId;
  final String returnNumber;
  final String invoiceNumber;
  final String userName;
  final String returnStatus;
  final String refundStatus;
  final String refundMethod;
  final String reason;
  final String createdAt;
  
  final int totalQuantity;
  final double returnTotal;
  final double refundedAmount;

  ReturnReportItem({
    required this.returnId,
    required this.returnNumber,
    required this.invoiceNumber,
    required this.userName,
    required this.returnStatus,
    required this.refundStatus,
    required this.refundMethod,
    required this.reason,
    required this.createdAt,
    required this.totalQuantity,
    required this.returnTotal,
    required this.refundedAmount,
  });

  factory ReturnReportItem.fromJson(Map<String, dynamic> json) {
    return ReturnReportItem(
      returnId: int.tryParse(json['return_id']?.toString() ?? '0') ?? 0,
      returnNumber: json['return_number']?.toString() ?? 'RET-???',
      invoiceNumber: json['invoice_number']?.toString() ?? '-',
      userName: json['user_name']?.toString() ?? json['cashier_name']?.toString() ?? 'Kasir',
      returnStatus: json['return_status']?.toString().toUpperCase() ?? json['status']?.toString().toUpperCase() ?? 'COMPLETED',
      refundStatus: json['refund_status']?.toString().toUpperCase() ?? 'PENDING',
      refundMethod: json['refund_method']?.toString().toUpperCase() ?? 'CASH',
      reason: json['reason']?.toString() ?? 'Tidak ada keterangan',
      createdAt: json['created_at']?.toString() ?? '',
      
      totalQuantity: int.tryParse(json['total_quantity']?.toString() ?? json['item_count']?.toString() ?? '0') ?? 0,
      // Mengambil total_amount karena struktur tabel returns menggunakan total_amount untuk nilai retur
      returnTotal: double.tryParse(json['return_total']?.toString() ?? json['total_amount']?.toString() ?? '0') ?? 0.0,
      refundedAmount: double.tryParse(json['refunded_amount']?.toString() ?? json['total_amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}
