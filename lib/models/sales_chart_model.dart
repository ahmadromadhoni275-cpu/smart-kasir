class SalesChartModel {
  final String date;
  final double revenue;

  SalesChartModel({required this.date, required this.revenue});

  factory SalesChartModel.fromJson(Map<String, dynamic> json) {
    return SalesChartModel(
      date: json['tanggal']?.toString() ?? '',
      revenue: double.tryParse(json['pendapatan']?.toString() ?? '0') ?? 0.0,
    );
  }
}
