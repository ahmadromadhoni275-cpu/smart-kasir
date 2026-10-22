class PrinterJobModel {
  final String id;
  final String invoiceNumber;
  final String documentType;
  final String printerName;
  final String connectionType;
  final String status; // QUEUED, PRINTING, SENT, FAILED, UNKNOWN
  final String? errorMessage;
  final DateTime createdAt;

  PrinterJobModel({
    required this.id,
    required this.invoiceNumber,
    required this.documentType,
    required this.printerName,
    required this.connectionType,
    required this.status,
    this.errorMessage,
    required this.createdAt,
  });

  factory PrinterJobModel.fromJson(Map<String, dynamic> json) {
    return PrinterJobModel(
      id: json['print_job_id']?.toString() ?? '',
      invoiceNumber: json['transaction_id'] ?? '-',
      documentType: json['document_type'] ?? 'Struk Transaksi',
      printerName: json['printer_name'] ?? 'Unknown Printer',
      connectionType: json['connection_type'] ?? 'Bluetooth',
      status: json['status'] ?? 'UNKNOWN',
      errorMessage: json['error_message'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
