import 'transaction_model.dart'; // Untuk TransactionReport (opsional jika dipakai ulang)
import 'transaction_item_model.dart';
import 'payment_model.dart';
import 'receipt_model.dart';

class TransactionDetailModel {
  final Map<String, dynamic> rawTransaction; // Data mentah tabel transactions
  final List<TransactionItemModel> items;
  final List<PaymentModel> payments;
  final PaymentModel? legacyPayment; // Untuk kompatibilitas aplikasi lama
  final ReceiptModel receipt;

  TransactionDetailModel({
    required this.rawTransaction,
    required this.items,
    required this.payments,
    this.legacyPayment,
    required this.receipt,
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw Exception('Data detail transaksi kosong');
    }

    // Parsing daftar item
    var itemsList = (json['items'] as List?)?.map((i) {
      return TransactionItemModel(
        productId: int.tryParse(i['product_id']?.toString() ?? ''),
        itemType: i['item_type']?.toString() ?? 'PRODUCT',
        name: i['product_name']?.toString() ?? 'Item',
        price: double.tryParse(i['price']?.toString() ?? '0') ?? 0,
        purchasePrice: double.tryParse(i['purchase_price']?.toString() ?? '0') ?? 0,
        quantity: int.tryParse(i['quantity']?.toString() ?? '1') ?? 1,
        maxStock: 0, 
        orderType: i['order_type']?.toString() ?? 'DINE_IN',
        note: i['note']?.toString(),
      );
    }).toList() ?? [];

    // Parsing daftar pembayaran (Mendukung Split Payment)
    var paymentsList = (json['payments'] as List?)
        ?.map((p) => PaymentModel.fromJson(p))
        .toList() ?? [];

    // Parsing single payment (Legacy)
    PaymentModel? singlePayment;
    if (json['payment'] != null) {
      singlePayment = PaymentModel.fromJson(json['payment']);
    }

    return TransactionDetailModel(
      rawTransaction: json['transaction'] ?? {},
      items: itemsList,
      payments: paymentsList,
      legacyPayment: singlePayment,
      receipt: ReceiptModel.fromJson(json['receipt']),
    );
  }
}
