import 'dashboard_statistics_model.dart';
import 'sales_chart_model.dart';
import 'best_selling_product_model.dart';
import 'recent_transaction_model.dart';

class DashboardModel {
  final DashboardStatisticsModel summary;
  final List<SalesChartModel> chart;
  final List<BestSellingProductModel> bestProducts;
  final List<RecentTransactionModel> recentTransactions;
  final Map<String, dynamic>? activeShift;
  final List<dynamic> banners;

  DashboardModel({
    required this.summary,
    required this.chart,
    required this.bestProducts,
    required this.recentTransactions,
    this.activeShift,
    required this.banners,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      summary: DashboardStatisticsModel.fromJson(json['summary']),
      chart: (json['chart'] as List?)?.map((e) => SalesChartModel.fromJson(e)).toList() ?? [],
      bestProducts: (json['best_products'] as List?)?.map((e) => BestSellingProductModel.fromJson(e)).toList() ?? [],
      recentTransactions: (json['recent_transactions'] as List?)?.map((e) => RecentTransactionModel.fromJson(e)).toList() ?? [],
      activeShift: json['active_shift'],
      banners: json['banners'] as List? ?? [],
    );
  }
}
