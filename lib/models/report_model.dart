class SalesReportItem {
  final String invoiceNumber;
  final double grandTotal;
  final String transactionStatus;
  final String paymentStatus;
  final String createdAt;

  SalesReportItem({required this.invoiceNumber, required this.grandTotal, required this.transactionStatus, required this.paymentStatus, required this.createdAt});

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

class PaymentReportItem {
  final String paymentGroup;
  final double totalAmount;
  final int paymentCount;

  PaymentReportItem({required this.paymentGroup, required this.totalAmount, required this.paymentCount});

  factory PaymentReportItem.fromJson(Map<String, dynamic> json) {
    return PaymentReportItem(
      paymentGroup: json['payment_group']?.toString() ?? 'CASH',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentCount: int.tryParse(json['payment_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class ProductReportData {
  final List<dynamic> products;
  final List<dynamic> categories;

  ProductReportData({required this.products, required this.categories});

  factory ProductReportData.fromJson(Map<String, dynamic> json) {
    return ProductReportData(
      products: json['products'] ?? [],
      categories: json['categories'] ?? [],
    );
  }
}

class ProfitLossData {
  final double grossSales;
  final double totalDiscount;
  final double totalReturns;
  final double netSales;
  final double totalCogs;
  final double grossProfit;
  final double totalExpenses;
  final double netProfit;
  final int transactionCount;

  ProfitLossData({
    required this.grossSales, required this.totalDiscount, required this.totalReturns,
    required this.netSales, required this.totalCogs, required this.grossProfit,
    required this.totalExpenses, required this.netProfit, required this.transactionCount
  });

  factory ProfitLossData.fromJson(Map<String, dynamic> json) {
    return ProfitLossData(
      grossSales: double.tryParse(json['gross_sales']?.toString() ?? '0') ?? 0.0,
      totalDiscount: double.tryParse(json['total_discount']?.toString() ?? '0') ?? 0.0,
      totalReturns: double.tryParse(json['total_returns']?.toString() ?? '0') ?? 0.0,
      netSales: double.tryParse(json['net_sales']?.toString() ?? '0') ?? 0.0,
      totalCogs: double.tryParse(json['total_cogs']?.toString() ?? '0') ?? 0.0,
      grossProfit: double.tryParse(json['gross_profit']?.toString() ?? '0') ?? 0.0,
      totalExpenses: double.tryParse(json['total_expenses']?.toString() ?? '0') ?? 0.0,
      netProfit: double.tryParse(json['net_profit']?.toString() ?? '0') ?? 0.0,
      transactionCount: int.tryParse(json['transaction_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class ReturnReportItem {
  final String returnNumber;
  final String invoiceNumber;
  final String userName;
  final String createdAt;
  final String returnStatus;
  final double refundedAmount;
  final String reason;

  ReturnReportItem({
    required this.returnNumber, required this.invoiceNumber, required this.userName,
    required this.createdAt, required this.returnStatus, required this.refundedAmount, required this.reason
  });

  factory ReturnReportItem.fromJson(Map<String, dynamic> json) {
    return ReturnReportItem(
      returnNumber: json['return_number']?.toString() ?? '-',
      invoiceNumber: json['invoice_number']?.toString() ?? '-',
      userName: json['user_name']?.toString() ?? 'Sistem',
      createdAt: json['created_at']?.toString() ?? '',
      returnStatus: json['return_status']?.toString() ?? 'COMPLETED',
      refundedAmount: double.tryParse(json['refunded_amount']?.toString() ?? '0') ?? 0.0,
      reason: json['reason']?.toString() ?? '-',
    );
  }
}
