class ChartDataItem {
  final String date;
  final double total;

  ChartDataItem({
    required this.date,
    required this.total,
  });

  factory ChartDataItem.fromJson(Map<String, dynamic> json) {
    return ChartDataItem(
      date: json['date']?.toString() ?? '',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class TopProductItem {
  final String productName;
  final int qty;
  final double revenue;

  TopProductItem({
    required this.productName,
    required this.qty,
    required this.revenue,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> json) {
    return TopProductItem(
      productName: json['product_name']?.toString() ?? 'Produk Tidak Diketahui',
      qty: int.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      revenue: double.tryParse(json['revenue']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ReportSummaryModel {
  final double netSales;
  final int transactionCount;
  final double averageTransaction;
  final List<ChartDataItem> chartData;
  final List<TopProductItem> topProducts;

  ReportSummaryModel({
    required this.netSales,
    required this.transactionCount,
    required this.averageTransaction,
    required this.chartData,
    required this.topProducts,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ReportSummaryModel(
        netSales: 0.0,
        transactionCount: 0,
        averageTransaction: 0.0,
        chartData: [],
        topProducts: [],
      );
    }

    final rawChart = json['chart_data'] ?? json['chart'] ?? json['grafik'] ?? [];
    final rawTop = json['top_products'] ?? json['top'] ?? json['terlaris'] ?? [];

    return ReportSummaryModel(
      netSales: double.tryParse((json['net_sales'] ?? json['total_sales'] ?? json['revenue'] ?? '0').toString()) ?? 0.0,
      transactionCount: int.tryParse((json['transaction_count'] ?? json['total_transactions'] ?? json['transactions'] ?? '0').toString()) ?? 0,
      averageTransaction: double.tryParse((json['average_transaction'] ?? json['avg_transaction'] ?? '0').toString()) ?? 0.0,
      chartData: (rawChart as List).map((e) => ChartDataItem.fromJson(e as Map<String, dynamic>)).toList(),
      topProducts: (rawTop as List).map((e) => TopProductItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
