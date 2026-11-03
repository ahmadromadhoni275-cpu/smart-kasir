import 'transaction_item_model.dart';
import 'payment_model.dart';

class StoreInfoModel {
  final String name;
  final String? address;
  final String? phone;
  final String? logo;

  StoreInfoModel({required this.name, this.address, this.phone, this.logo});

  factory StoreInfoModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return StoreInfoModel(name: 'SMART KASIR');
    return StoreInfoModel(
      name: json['name']?.toString() ?? 'SMART KASIR',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      logo: json['logo']?.toString(),
    );
  }
}

class ReceiptModel {
  final StoreInfoModel store;
  final String invoiceNumber;
  final String createdAt;
  final String cashierName;
  final List<TransactionItemModel> items;
  final List<PaymentModel> payments;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final String paymentStatus; // PAID, UNPAID
  final String transactionStatus; // COMPLETED, CANCELED

  ReceiptModel({
    required this.store,
    required this.invoiceNumber,
    required this.createdAt,
    required this.cashierName,
    required this.items,
    required this.payments,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
    required this.paymentStatus,
    required this.transactionStatus,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) throw Exception("Data struk kosong");
    
    var itemsList = (json['items'] as List?)?.map((i) {
      return TransactionItemModel(
        productId: int.tryParse(i['product_id']?.toString() ?? ''),
        itemType: i['item_type']?.toString() ?? 'PRODUCT',
        name: i['product_name']?.toString() ?? 'Item',
        price: double.tryParse(i['price']?.toString() ?? '0') ?? 0,
        purchasePrice: double.tryParse(i['purchase_price']?.toString() ?? '0') ?? 0,
        quantity: int.tryParse(i['quantity']?.toString() ?? '1') ?? 1,
        maxStock: 0, // Tidak relevan di receipt
        orderType: i['order_type']?.toString() ?? 'DINE_IN',
        note: i['note']?.toString(),
      );
    }).toList() ?? [];

    var paymentsList = (json['payments'] as List?)?.map((p) => PaymentModel.fromJson(p)).toList() ?? [];

    return ReceiptModel(
      store: StoreInfoModel.fromJson(json['store']),
      invoiceNumber: json['invoice_number']?.toString() ?? '-',
      createdAt: json['created_at']?.toString() ?? '',
      cashierName: json['cashier_name']?.toString() ?? 'Kasir',
      items: itemsList,
      payments: paymentsList,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0,
      tax: double.tryParse(json['tax']?.toString() ?? '0') ?? 0,
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0,
      paymentStatus: json['payment_status']?.toString().toUpperCase() ?? 'UNPAID',
      transactionStatus: json['transaction_status']?.toString().toUpperCase() ?? 'COMPLETED',
    );
  }
}
