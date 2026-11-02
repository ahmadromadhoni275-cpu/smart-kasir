class PaymentMethodModel {
  final String type; // CASH, QRIS, TRANSFER, dll
  final String name; 
  final String? accountNumber;
  final String? accountName;
  final String? qrisImage;

  PaymentMethodModel({
    required this.type,
    required this.name,
    this.accountNumber,
    this.accountName,
    this.qrisImage,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      type: json['method']?.toString().toUpperCase() ?? 'CASH',
      name: json['name']?.toString() ?? 'Tunai',
      accountNumber: json['account_number']?.toString(),
      accountName: json['account_name']?.toString(),
      qrisImage: json['qris_image']?.toString(),
    );
  }
}
