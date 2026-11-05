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
    required this.grossSales,
    required this.totalDiscount,
    required this.totalReturns,
    required this.netSales,
    required this.totalCogs,
    required this.grossProfit,
    required this.totalExpenses,
    required this.netProfit,
    required this.transactionCount,
  });

  factory ProfitLossData.fromJson(Map<String, dynamic> json) {
    return ProfitLossData(
      grossSales: double.tryParse(json['gross_sales']?.toString() ?? '0') ?? 0,
      totalDiscount: double.tryParse(json['total_discount']?.toString() ?? '0') ?? 0,
      totalReturns: double.tryParse(json['total_returns']?.toString() ?? '0') ?? 0,
      netSales: double.tryParse(json['net_sales']?.toString() ?? '0') ?? 0,
      totalCogs: double.tryParse(json['total_cogs']?.toString() ?? '0') ?? 0,
      grossProfit: double.tryParse(json['gross_profit']?.toString() ?? '0') ?? 0,
      totalExpenses: double.tryParse(json['total_expenses']?.toString() ?? '0') ?? 0,
      netProfit: double.tryParse(json['net_profit']?.toString() ?? '0') ?? 0,
      transactionCount: int.tryParse(json['transaction_count']?.toString() ?? '0') ?? 0,
    );
  }

  bool get isLoss => netProfit < 0;
}
