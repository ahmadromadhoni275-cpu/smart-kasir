class DashboardStatisticsModel {
  final double sales;
  final int transactions;
  final double profit;
  final int products;
  final int lowStock;

  DashboardStatisticsModel({
    required this.sales,
    required this.transactions,
    required this.profit,
    required this.products,
    required this.lowStock,
  });

  factory DashboardStatisticsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DashboardStatisticsModel(sales: 0, transactions: 0, profit: 0, products: 0, lowStock: 0);
    return DashboardStatisticsModel(
      // Parsing aman: MySQL SUM() sering menjadi String di JSON API
      sales: double.tryParse(json['sales']?.toString() ?? '0') ?? 0.0,
      transactions: int.tryParse(json['transactions']?.toString() ?? '0') ?? 0,
      profit: double.tryParse(json['profit']?.toString() ?? '0') ?? 0.0,
      products: int.tryParse(json['products']?.toString() ?? '0') ?? 0,
      lowStock: int.tryParse(json['low_stock']?.toString() ?? '0') ?? 0,
    );
  }
}
